extends Node
## Adaptive difficulty director. Three small models that learn from this player only, on this
## machine only (saved to user://director.json, nothing is sent anywhere):
##
##  1. Hit model   - online logistic regression. Predicts P(an incoming shot hits the player)
##                   from shot speed, how many shots are in the air, airborne or not, and range.
##                   Trained by one SGD step on every shot that was deflected, dodged or taken.
##  2. Quit model  - online logistic regression. Predicts P(the player quits before the next
##                   checkpoint) at each death, from the death streak, time stuck, deaths per
##                   minute, how short the last life was and the recent deflect rate. Starts from
##                   hand-set weights; real outcomes (quit, went idle, or reached a checkpoint)
##                   correct it over time.
##  3. Move model  - n-gram over six movement states, sampled five times a second. It looks at
##                   the last three steps and backs off to two, then one, where it has seen too
##                   little. Predicts where the player will be when a shot arrives, and is
##                   trusted only as far as it has been right lately.
##
## The director keeps one number, `challenge` in [0, 1]. It solves the hit model for the
## challenge at which the predicted hit rate equals a target (26% of threatening shots, falling
## to 10% as quit risk rises) and walks toward it, faster down than up. Every knob below reads
## `challenge`. With `enabled = false` every knob returns the original fixed value.
##
## Five more models shape how that one number is spent:
##
##  4. Timing model - running mean and spread of how early this player swings (seconds between
##                    the click and the shot reaching the deflect radius). Predicts P(the next
##                    swing is on time) and widens the deflect window just enough to reach 75%.
##                    It also tracks how often a hit lands with no swing at all, and lengthens
##                    the muzzle telegraph for players who do not react.
##  5. Room model   - a rating for the player and one for every room, updated like chess Elo on
##                    each death (room wins) and each room cleared (player wins). Predicts
##                    P(clear this room on this attempt). A room that has beaten this player
##                    before is eased the moment they walk in, not after three more deaths.
##  6. Lever bandit - three kinds of help: timing (deflect window, radius, arc), pace (shot
##                    speed, fire rate) and density (shots in the air, telegraph). On a death
##                    streak it picks one lever by UCB1, gives it an extra boost for the next
##                    life, and scores it by whether that life went better. It learns which
##                    kind of help works for this player.
##  7. Pacing wave  - an intensity meter fed by hits, deflects and near misses. After a peak
##                    the enemies fire slower for five seconds; in a long calm at high challenge
##                    they fire a little faster. Fights get a rhythm of pressure and release.
##  8. Skill tracing - Bayesian knowledge tracing per mechanic (deflect, dash, air dash, rebound,
##                    lane change): P(the player knows it), updated once per life from whether
##                    they used it. A stuck player gets the hint for the mechanic they have not
##                    shown, in place of the general stage hint.

signal assist_changed(kind: String)
## The player looks stuck: the game shows the stage's one-line hint again.
signal stuck

const SAVE_PATH: String = "user://director.json"
const VERSION: int = 1
const START_CHALLENGE: float = 0.25
const BASE_SHOT_SPEED: float = 140.0
const HIT_PRIOR: Array[float] = [-1.3, 2.0, 0.9, 0.4, 0.5]
const QUIT_PRIOR: Array[float] = [-3.0, 2.4, 1.2, 1.4, 0.6, 1.0]
const MOVE_SYMS: int = 6
const MOVE_STEP: float = 0.2
const MOVE_MIN_SEEN: float = 3.0
const TARGET_HIT_CALM: float = 0.26
const TARGET_HIT_TILTED: float = 0.10
const LEVER_TIMING: int = 0
const LEVER_PACE: int = 1
const LEVER_DENSITY: int = 2
const LEVER_NAMES: PackedStringArray = ["timing", "pace", "density"]
const TIMING_MIN_N: int = 8
const TIMING_GOAL: float = 0.75
const SKILLS: PackedStringArray = ["parry", "rebound", "airjump", "dash", "lane"]
const BKT_START: float = 0.15
const BKT_LEARN: float = 0.12
const BKT_SLIP: float = 0.15
const BKT_GUESS: float = 0.10

var enabled: bool = true
var persist: bool = true
var debug: bool = false
var challenge: float = START_CHALLENGE
var tilt: float = 0.0

# --- model state (saved)
var hit_w: PackedFloat32Array = PackedFloat32Array(HIT_PRIOR)
var hit_n: int = 0
var quit_w: PackedFloat32Array = PackedFloat32Array(QUIT_PRIOR)
var quit_n: int = 0
var move_c1: PackedFloat32Array = PackedFloat32Array()  # next state after 1 step of context
var move_c2: PackedFloat32Array = PackedFloat32Array()  # after 2 steps
var move_c3: PackedFloat32Array = PackedFloat32Array()  # after 3 steps
var move_acc: float = 0.34
var move_base_acc: float = 0.34
var move_n: int = 0
var parry_rate: float = 0.5
var runs: int = 0
var time_mean: float = 0.12     # model 4: seconds between the swing and the shot arriving
var time_var: float = 0.01
var time_n: int = 0
var no_react: float = 0.0       # share of hits taken with no swing at all
var player_r: float = 0.0       # model 5
var room_r: Dictionary = {}     # "stage:room" -> rating
var arm_n: PackedFloat32Array = PackedFloat32Array([0.0, 0.0, 0.0])  # model 6
var arm_r: PackedFloat32Array = PackedFloat32Array([0.0, 0.0, 0.0])
var life_ema: float = 12.0
var skill_p: Dictionary = {}    # model 8: skill -> P(known); a skill appears once it had a chance
var skill_lives: int = 0

# --- session state of models 4 to 8 (not saved)
var intensity: float = 0.0      # model 7
var arm: int = -1               # lever boosted for this life, -1 = none
var _relax_left: float = 0.0
var _room_key: String = ""
var _stage_idx: int = 0
var _last_press_ms: int = -100000
var _life_used: Dictionary = {}
var _life_blackout: bool = false
var _hint_flip: bool = false

# --- session counters (not saved)
var mercy_shots: int = 0
var samples_this_run: int = 0
var deaths_by_cause: Dictionary = {}

var _streak: int = 0
var _fall_streak: int = 0
var _death_times: Array[float] = []
var _pending: Array[Dictionary] = []
var _last_progress: float = 0.0
var _life_start: float = 0.0
var _in_run: bool = false
var _last_input_ms: int = 0
var _idle_flagged: bool = false
var _eased_announced: bool = false
var _hard_announced: bool = false
var _mercy_open: bool = false
var _mercy_at: float = 0.0
var _blackout_end: float = 0.0
var _m1: int = 1
var _m2: int = 1
var _m3: int = 1
var _m_t: float = 0.0
var _near_tick: int = 0
var _last_ms: int = 0
var _last_hint: float = 0.0
var _last_save: float = 0.0
var save_path: String = SAVE_PATH


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_reset_models()
	## Tests, captures and debug starts neither read nor write the player's profile.
	persist = not GameState.is_dev_run()
	if persist:
		_load()
	for arg: String in OS.get_cmdline_user_args():
		## Dev check of the real save path in an exported build: `-- --profile-file=name.json`
		## writes the profile to that file even on a debug start, never to the player's own.
		if arg.begins_with("--profile-file="):
			save_path = "user://" + arg.get_slice("=", 1).get_file()
			persist = true
			_load()
	_last_ms = Time.get_ticks_msec()
	_last_input_ms = _last_ms


func _reset_models() -> void:
	hit_w = PackedFloat32Array(HIT_PRIOR)
	hit_n = 0
	quit_w = PackedFloat32Array(QUIT_PRIOR)
	quit_n = 0
	move_c1 = PackedFloat32Array()
	move_c1.resize(MOVE_SYMS * MOVE_SYMS)
	move_c1.fill(0.0)
	move_c2 = PackedFloat32Array()
	move_c2.resize(MOVE_SYMS * MOVE_SYMS * MOVE_SYMS)
	move_c2.fill(0.0)
	move_c3 = PackedFloat32Array()
	move_c3.resize(MOVE_SYMS * MOVE_SYMS * MOVE_SYMS * MOVE_SYMS)
	move_c3.fill(0.0)
	_m1 = 1
	_m2 = 1
	_m3 = 1
	move_acc = 0.34
	move_base_acc = 0.34
	move_n = 0
	parry_rate = 0.5
	challenge = START_CHALLENGE
	tilt = 0.0
	time_mean = 0.12
	time_var = 0.01
	time_n = 0
	no_react = 0.0
	player_r = 0.0
	room_r = {}
	arm_n = PackedFloat32Array([0.0, 0.0, 0.0])
	arm_r = PackedFloat32Array([0.0, 0.0, 0.0])
	life_ema = 12.0
	skill_p = {}
	skill_lives = 0


func reset_profile() -> void:
	## Forget everything learned (tests, or a fresh player).
	_reset_models()
	intensity = 0.0
	arm = -1
	_relax_left = 0.0
	_room_key = ""
	_stage_idx = 0
	_life_used.clear()
	_life_blackout = false
	_hint_flip = false
	_streak = 0
	_fall_streak = 0
	_death_times.clear()
	_pending.clear()
	_eased_announced = false
	_hard_announced = false
	mercy_shots = 0
	samples_this_run = 0
	deaths_by_cause.clear()


func _now() -> float:
	return float(Time.get_ticks_msec()) / 1000.0


# ================================================================= knobs read by the game

func level(lever: int = -1) -> float:
	## The challenge a knob actually reads: the global number, lowered in a room that has beaten
	## this player before (model 5) and lowered again for the lever the bandit is boosting (model 6).
	var c: float = challenge - room_ease()
	if lever >= 0 and arm == lever:
		c -= arm_boost()
	return clampf(c, 0.0, 1.0)


func shot_speed_mult() -> float:
	return lerpf(0.70, 1.15, level(LEVER_PACE)) if enabled else 1.0


func fire_interval_mult() -> float:
	return lerpf(1.50, 0.85, level(LEVER_PACE)) * pace_mult() if enabled else 1.0


func charge_time() -> float:
	## Muzzle telegraph before an enemy fires. Longer for a player who often takes a hit
	## without swinging at all (model 4).
	if not enabled:
		return 0.45
	return lerpf(0.70, 0.40, level(LEVER_DENSITY)) + 0.15 * no_react * (1.0 - challenge)


func max_threats() -> int:
	## How many enemy shots may be in the air near the player before the next enemy holds fire.
	var c: float = level(LEVER_DENSITY)
	if not enabled or c >= 0.85:
		return 99
	var cap: int = 1 if c < 0.25 else (2 if c < 0.6 else 3)
	if _relax_left > 0.0:
		cap = maxi(cap - 1, 1)
	return cap


func parry_window_bonus() -> float:
	return lerpf(0.10, 0.0, level(LEVER_TIMING)) + timing_bonus() if enabled else 0.0


func parry_radius_mult() -> float:
	return lerpf(1.22, 1.0, level(LEVER_TIMING)) if enabled else 1.0


func parry_arc_mult() -> float:
	return lerpf(1.40, 1.0, level(LEVER_TIMING)) if enabled else 1.0


func blackout_bonus() -> float:
	if not enabled:
		return 0.0
	return lerpf(1.0, 0.0, level()) + (0.5 if tilt > 0.35 else 0.0)


func mercy_enabled() -> bool:
	## At every challenge level: a hit always leaves one shot to rebound off. Without it the
	## Blackout window is only survivable when a second shot happens to be beside the player.
	return enabled


func show_sights() -> bool:
	return enabled and level() < 0.4


func lead_amount() -> float:
	## 0 = enemies aim where the player is, 1 = where the move model says the player will be.
	return smoothstep(0.6, 1.0, challenge) if enabled else 0.0


func extra_air_dashes() -> int:
	return 1 if enabled and _fall_streak >= 2 else 0


func coyote_bonus() -> float:
	return 0.08 if enabled and _fall_streak >= 2 else 0.0


func percent() -> int:
	return int(round(challenge * 100.0))


# ================================================================= model 1: hit model

static func _sig(z: float) -> float:
	return 1.0 / (1.0 + exp(-clampf(z, -30.0, 30.0)))


static func _dot(w: PackedFloat32Array, x: PackedFloat32Array) -> float:
	var s: float = 0.0
	for i: int in mini(w.size(), x.size()):
		s += w[i] * x[i]
	return s


func predict_hit(x: PackedFloat32Array) -> float:
	return _sig(_dot(hit_w, x))


func _reference_shot(c: float) -> PackedFloat32Array:
	## The typical shot the player would face at challenge c.
	return PackedFloat32Array([1.0, lerpf(0.70, 1.15, c) - 1.0, lerpf(0.0, 0.5, c), 0.3, 0.35])


func target_hit_rate() -> float:
	return lerpf(TARGET_HIT_CALM, TARGET_HIT_TILTED, clampf(tilt, 0.0, 1.0))


func solve_challenge() -> float:
	## Bisection: the challenge at which the predicted hit rate meets the target.
	var target: float = target_hit_rate()
	if predict_hit(_reference_shot(0.0)) >= target:
		return 0.0
	if predict_hit(_reference_shot(1.0)) <= target:
		return 1.0
	var lo: float = 0.0
	var hi: float = 1.0
	for i: int in 16:
		var mid: float = (lo + hi) * 0.5
		if predict_hit(_reference_shot(mid)) < target:
			lo = mid
		else:
			hi = mid
	return (lo + hi) * 0.5


func hit_learn(x: PackedFloat32Array, hit: bool) -> void:
	var y: float = 1.0 if hit else 0.0
	var p: float = predict_hit(x)
	var lr: float = 0.25 if hit_n < 30 else 0.12
	for i: int in hit_w.size():
		hit_w[i] += lr * (y - p) * x[i]
	hit_w[0] = clampf(hit_w[0], -4.0, 3.0)
	hit_w[1] = clampf(hit_w[1], 0.8, 5.0)  # faster shots never count as easier
	hit_w[2] = clampf(hit_w[2], 0.0, 4.0)  # nor do more shots at once
	hit_w[3] = clampf(hit_w[3], -2.0, 3.0)
	hit_w[4] = clampf(hit_w[4], -2.0, 3.0)
	hit_n += 1
	samples_this_run += 1
	parry_rate = lerpf(parry_rate, 1.0 - y, 0.12)
	_walk_challenge(0.04, 0.07)


func _walk_challenge(up: float, down: float) -> void:
	var goal: float = solve_challenge()
	if goal > challenge:
		challenge = minf(challenge + up, goal)
	else:
		challenge = maxf(challenge - down, goal)
	challenge = clampf(challenge, 0.0, 1.0)
	if challenge > 0.85 and not _hard_announced and _in_run:
		_hard_announced = true
		assist_changed.emit("hard")


func _player() -> Player:
	return get_tree().get_first_node_in_group("player") as Player


func track_shot(p: Projectile) -> void:
	## Called for every enemy-team shot when it is fired or reflected back at the player.
	var pl: Player = _player()
	if pl == null or p.is_core or p.has_meta("mercy"):
		return
	var crowd: int = 0
	for node: Node in get_tree().get_nodes_in_group("projectiles"):
		var o: Projectile = node as Projectile
		if o != null and o != p and not o.spent() and o.team == Projectile.Team.ENEMY and o.lane == pl.lane \
				and o.global_position.distance_to(pl.chest()) < 260.0:
			crowd += 1
	var x := PackedFloat32Array([
		1.0,
		clampf(p.velocity.length() / BASE_SHOT_SPEED - 1.0, -0.6, 2.5),
		float(mini(crowd, 3)) / 3.0,
		0.0,
		1.0 if p.global_position.distance_to(pl.chest()) < 110.0 else 0.0,
	])
	p.set_meta("dx", x)
	p.set_meta("dnear", false)


func _take_sample(p: Projectile) -> PackedFloat32Array:
	if not p.has_meta("dx"):
		return PackedFloat32Array()
	var x: PackedFloat32Array = p.get_meta("dx")
	p.remove_meta("dx")
	var pl: Player = _player()
	if pl != null and not pl.is_on_floor():
		x[3] = 1.0
	return x


func shot_deflected(p: Projectile, in_blackout: bool) -> void:
	var x: PackedFloat32Array = _take_sample(p)
	## Blackout runs at quarter speed, so its deflections say nothing about normal play.
	bump(0.07)
	if not in_blackout:
		_life_used["parry"] = true
		no_react = lerpf(no_react, 0.0, 0.08)
	if x.is_empty() or in_blackout:
		return
	hit_learn(x, false)


func player_hit(p: Projectile, in_blackout: bool) -> void:
	var x: PackedFloat32Array = _take_sample(p)
	bump(0.5)
	if not in_blackout:
		## Did the player swing at all in the half second before the hit?
		var swung: bool = Time.get_ticks_msec() - _last_press_ms < 500
		no_react = lerpf(no_react, 0.0 if swung else 1.0, 0.15)
	if x.is_empty() or in_blackout:
		return
	hit_learn(x, true)


func shot_ended(p: Projectile) -> void:
	## A shot that passed close to the player and was neither deflected nor taken was dodged.
	if p.team != Projectile.Team.ENEMY or not p.has_meta("dx"):
		return
	var near: bool = bool(p.get_meta("dnear", false))
	var x: PackedFloat32Array = _take_sample(p)
	var pl: Player = _player()
	if near and not x.is_empty() and pl != null and not pl.in_blackout and not pl.dead:
		bump(0.12)
		hit_learn(x, false)


# ================================================================= model 2: quit model

func _quit_features(short_life: bool) -> PackedFloat32Array:
	var now: float = _now()
	return PackedFloat32Array([
		1.0,
		float(mini(_streak, 8)) / 8.0,
		minf(now - _last_progress, 180.0) / 180.0,
		float(mini(_death_times.size(), 6)) / 6.0,
		1.0 if short_life else 0.0,
		1.0 - parry_rate,
	])


func predict_quit(x: PackedFloat32Array) -> float:
	return _sig(_dot(quit_w, x))


func quit_learn(x: PackedFloat32Array, quit_happened: bool) -> void:
	var y: float = 1.0 if quit_happened else 0.0
	var p: float = predict_quit(x)
	for i: int in quit_w.size():
		quit_w[i] += 0.10 * (y - p) * x[i]
		quit_w[i] = clampf(quit_w[i], -6.0, 6.0)
	## A longer death streak never lowers the predicted risk.
	quit_w[1] = maxf(quit_w[1], 0.5)
	quit_n += 1


func player_died(cause: String, _pos: Vector2 = Vector2.ZERO) -> void:
	deaths_by_cause[cause] = int(deaths_by_cause.get(cause, 0)) + 1
	var now: float = _now()
	var life: float = now - _life_start
	if cause != "restart":
		room_result(false)
		skills_close(life)
	if arm >= 0:
		arm_score(arm, life > life_ema * 1.15)
	life_ema = lerpf(life_ema, clampf(life, 1.0, 120.0), 0.2)
	intensity = 0.0
	_relax_left = 0.0
	_streak += 1
	## On a death streak one kind of help gets an extra boost for the next life.
	arm = arm_choose() if _streak >= 2 and cause != "restart" else -1
	_death_times.append(now)
	while not _death_times.is_empty() and now - _death_times[0] > 60.0:
		_death_times.pop_front()
	if cause == "fall":
		_fall_streak += 1
	var x: PackedFloat32Array = _quit_features(now - _life_start < 6.0)
	var risk: float = predict_quit(x)
	tilt = maxf(tilt, lerpf(tilt, risk, 0.7))
	_pending.append({"x": x, "t": now})
	challenge = clampf(challenge - 0.05 * (1.0 + tilt), 0.0, 1.0)
	_life_start = now
	if _streak in [2, 4, 7] and cause != "restart":
		_last_hint = now
		stuck.emit()
	if tilt > 0.5 and not _eased_announced and enabled:
		_eased_announced = true
		assist_changed.emit("ease")
	_save()


func progress(_kind: String) -> void:
	## Checkpoint reached, module collected or boss beaten: the pending deaths did not end in a quit.
	for s: Dictionary in _pending:
		quit_learn(s["x"], false)
	_pending.clear()
	if arm >= 0:
		arm_score(arm, true)
		arm = -1
	skills_close(999.0)
	if _streak == 0:
		challenge = clampf(challenge + 0.05, 0.0, 1.0)
	_streak = 0
	_fall_streak = 0
	_last_progress = _now()
	tilt *= 0.45
	_save()


func quit(_kind: String) -> void:
	## Left for the menu, closed the window, or walked away. Deaths in the last 90 s get the label.
	var now: float = _now()
	for s: Dictionary in _pending:
		quit_learn(s["x"], now - float(s["t"]) <= 90.0)
	_pending.clear()
	_in_run = false
	_save()


# ================================================================= model 3: move model

func _move_token(pl: Player) -> int:
	var d: int = 1
	if pl.velocity.x > 30.0:
		d = 2
	elif pl.velocity.x < -30.0:
		d = 0
	return d + (0 if pl.is_on_floor() else 3)


func _row_sum(counts: PackedFloat32Array, row: int) -> float:
	var s: float = 0.0
	for k: int in MOVE_SYMS:
		s += counts[row + k]
	return s


func move_predict() -> PackedFloat32Array:
	## Distribution over the next movement state. Uses the longest context (3, then 2, then 1
	## steps) that has been seen often enough, plus a light pull toward "same as now".
	var r1: int = _m1 * MOVE_SYMS
	var r2: int = (_m2 * MOVE_SYMS + _m1) * MOVE_SYMS
	var r3: int = ((_m3 * MOVE_SYMS + _m2) * MOVE_SYMS + _m1) * MOVE_SYMS
	var counts: PackedFloat32Array = move_c1
	var row: int = r1
	if _row_sum(move_c3, r3) >= MOVE_MIN_SEEN:
		counts = move_c3
		row = r3
	elif _row_sum(move_c2, r2) >= MOVE_MIN_SEEN:
		counts = move_c2
		row = r2
	var out := PackedFloat32Array()
	out.resize(MOVE_SYMS)
	var total: float = 0.0
	for k: int in MOVE_SYMS:
		out[k] = counts[row + k] + (0.3 if k == _m1 else 0.05)
		total += out[k]
	for k: int in MOVE_SYMS:
		out[k] /= total
	return out


func move_observe(tok: int) -> void:
	## Score the prediction that was made for this step, then learn from what happened.
	var dist: PackedFloat32Array = move_predict()
	var best: int = _m1
	for k: int in MOVE_SYMS:
		if dist[k] > dist[best]:
			best = k
	move_acc = lerpf(move_acc, 1.0 if best == tok else 0.0, 0.03)
	move_base_acc = lerpf(move_base_acc, 1.0 if _m1 == tok else 0.0, 0.03)
	var rows: Array = [
		[move_c1, _m1 * MOVE_SYMS],
		[move_c2, (_m2 * MOVE_SYMS + _m1) * MOVE_SYMS],
		[move_c3, ((_m3 * MOVE_SYMS + _m2) * MOVE_SYMS + _m1) * MOVE_SYMS],
	]
	for r: Array in rows:
		var counts: PackedFloat32Array = r[0]
		var row: int = r[1]
		for k: int in MOVE_SYMS:
			counts[row + k] *= 0.995  # old habits fade
		counts[row + tok] += 1.0
	move_n += 1
	_m3 = _m2
	_m2 = _m1
	_m1 = tok


func expected_dir() -> float:
	## Expected horizontal direction of the next step, -1 (left) to 1 (right).
	var dist: PackedFloat32Array = move_predict()
	var e: float = 0.0
	for k: int in MOVE_SYMS:
		e += dist[k] * float((k % 3) - 1)
	return e


func aim_point(pl: Player, from: Vector2, speed: float, lead: float = -1.0) -> Vector2:
	## Where an enemy should aim. With lead, the shot goes where the move model expects the
	## player to be; the lead is trusted only as far as the model has been right lately.
	var amount: float = lead_amount() if lead < 0.0 else lead
	var chest: Vector2 = pl.chest()
	if amount <= 0.0:
		return chest
	var flight: float = minf(from.distance_to(chest) / maxf(speed, 1.0), 0.5)
	var trust: float = clampf((move_acc - 0.45) / 0.35, 0.0, 1.0)
	return chest + Vector2(expected_dir() * Player.RUN_SPEED * flight * trust * amount, 0.0)


# ================================================================= model 4: timing model

func parry_pressed(pl: Player) -> void:
	## Called when a swing starts. Measures how early it was: the seconds until the nearest
	## incoming shot reaches the deflect radius. A swing with nothing on the way is not a sample.
	_last_press_ms = Time.get_ticks_msec()
	if pl == null or pl.in_blackout:
		return
	var chest: Vector2 = pl.chest()
	var radius: float = Player.PARRY_RADIUS * parry_radius_mult()
	var best: float = 99.0
	for node: Node in get_tree().get_nodes_in_group("projectiles"):
		var p: Projectile = node as Projectile
		if p == null or p.spent() or p.team != Projectile.Team.ENEMY or p.lane != pl.lane or not p.parryable:
			continue
		var rel: Vector2 = chest - p.global_position
		var dist: float = rel.length()
		if dist > 420.0:
			continue
		var closing: float = p.velocity.dot(rel / maxf(dist, 0.001))
		if closing < 30.0:
			continue
		best = minf(best, maxf(dist - radius, 0.0) / closing)
	if best <= 1.0:
		timing_learn(best)


func timing_learn(early: float) -> void:
	if time_n == 0:
		time_mean = early
	else:
		var d: float = early - time_mean
		time_mean += 0.15 * d
		time_var = 0.85 * (time_var + 0.15 * d * d)
	time_n += 1


func predict_on_time(extra: float = 0.0) -> float:
	## P(the next swing is still active when the shot arrives), for the current deflect window
	## plus `extra` seconds. Normal distribution, logistic approximation of its CDF.
	var window: float = 0.18 + lerpf(0.10, 0.0, level(LEVER_TIMING)) + extra
	var sd: float = sqrt(maxf(time_var, 0.0004))
	return _sig(1.702 * (window - time_mean) / sd)


func timing_bonus() -> float:
	## The smallest extra deflect window that brings this player's swings to 75% on time,
	## at most 0.08 s, and less of it the higher the challenge.
	if not enabled or time_n < TIMING_MIN_N:
		return 0.0
	var extra: float = 0.0
	while extra < 0.08 and predict_on_time(extra) < TIMING_GOAL:
		extra += 0.01
	return minf(extra, 0.08) * lerpf(1.0, 0.35, challenge)


# ================================================================= model 5: room model

func room_entered(stage: int, room: int, cleared_previous: bool) -> void:
	if cleared_previous and _room_key != "":
		room_result(true)
	_stage_idx = stage
	_room_key = "%d:%d" % [stage, room]


func predict_clear() -> float:
	## P(the player clears the current room on this attempt).
	if _room_key == "":
		return 0.5
	return _sig(player_r - float(room_r.get(_room_key, 0.0)))


func room_result(cleared: bool) -> void:
	if _room_key == "":
		return
	var err: float = (1.0 if cleared else 0.0) - predict_clear()
	player_r = clampf(player_r + 0.15 * err, -4.0, 4.0)
	room_r[_room_key] = clampf(float(room_r.get(_room_key, 0.0)) - 0.35 * err, -4.0, 4.0)


func room_ease() -> float:
	## How much challenge is taken off in this room. Nothing while the player is expected to
	## clear it within about two and a half attempts.
	if not enabled or _room_key == "":
		return 0.0
	return clampf((0.40 - predict_clear()) * 0.5, 0.0, 0.18)


# ================================================================= model 6: lever bandit

func arm_choose() -> int:
	## UCB1: the lever with the best record so far, with a bonus for levers tried less often.
	var total: float = 0.0
	for i: int in arm_n.size():
		if arm_n[i] < 1.0:
			return i
		total += arm_n[i]
	var best: int = 0
	var best_score: float = -1.0
	for i: int in arm_n.size():
		var score: float = arm_r[i] / arm_n[i] + sqrt(0.8 * log(total) / arm_n[i])
		if score > best_score:
			best_score = score
			best = i
	return best


func arm_score(which: int, went_better: bool) -> void:
	if which < 0 or which >= arm_n.size():
		return
	for i: int in arm_n.size():
		## Old results fade slowly: what helps a beginner may not help the same player later.
		arm_n[i] *= 0.995
		arm_r[i] *= 0.995
	arm_n[which] += 1.0
	if went_better:
		arm_r[which] += 1.0


func arm_boost() -> float:
	## Extra challenge taken off the boosted lever: more of it the longer the streak and the
	## higher the quit risk.
	return 0.20 * clampf(float(_streak) / 5.0 + tilt, 0.3, 1.0)


# ================================================================= model 7: pacing wave

func bump(amount: float) -> void:
	intensity = minf(intensity + amount, 1.0)
	if intensity >= 0.8 and _relax_left <= 0.0:
		_relax_left = 5.0


func decay(dt: float) -> void:
	intensity *= pow(0.5, dt / 6.0)
	_relax_left = maxf(_relax_left - dt, 0.0)


func pace_mult() -> float:
	## Multiplier on the time between enemy shots: release after a peak, a little more
	## pressure in a long calm when the player is doing well.
	if not enabled:
		return 1.0
	if _relax_left > 0.0:
		return 1.35
	if challenge > 0.5 and tilt < 0.2 and intensity < 0.12:
		return 0.92
	return 1.0


# ================================================================= model 8: skill tracing

func skill_used(skill: String) -> void:
	_life_used[skill] = true


func skills_close(life: float) -> void:
	## One observation per life (or per stretch up to a checkpoint) for every skill that had a
	## chance to be used. Lives shorter than three seconds say nothing.
	if life >= 3.0:
		var lanes: bool = StageBase.current != null and StageBase.current.has_lanes
		for s: String in SKILLS:
			var used: bool = _life_used.has(s)
			var chance: bool = true
			if s == "rebound":
				chance = _life_blackout
			elif s == "lane":
				chance = lanes
			if not chance and not used:
				continue
			var p: float = float(skill_p.get(s, BKT_START))
			if used:
				p = p * (1.0 - BKT_SLIP) / (p * (1.0 - BKT_SLIP) + (1.0 - p) * BKT_GUESS)
			else:
				p = p * BKT_SLIP / (p * BKT_SLIP + (1.0 - p) * (1.0 - BKT_GUESS))
			skill_p[s] = clampf(p + (1.0 - p) * BKT_LEARN, 0.01, 0.99)
		skill_lives += 1
	_life_used.clear()
	_life_blackout = false


func weakest_skill() -> String:
	## The mechanic this player has had a chance to use and most likely does not know yet.
	if skill_lives < 3:
		return ""
	var worst: String = ""
	var worst_p: float = 0.45
	for s: String in SKILLS:
		if skill_p.has(s) and float(skill_p[s]) < worst_p:
			worst_p = float(skill_p[s])
			worst = s
	return worst


func hint_skill() -> String:
	## Every second stuck hint is about the weakest mechanic; the others stay the stage hint.
	_hint_flip = not _hint_flip
	return "" if _hint_flip else weakest_skill()


# ================================================================= mercy shot (Blackout)

func blackout_started() -> void:
	_life_blackout = true
	_mercy_open = mercy_enabled()
	_mercy_at = _now() + 0.25
	_blackout_end = _now() + GameState.blackout_duration()


func claim_mercy() -> bool:
	## One enemy that can see the player may fire at once during Blackout, so there is always
	## a shot to rebound off. Without it the 4x slow motion means nothing arrives in time.
	if not _mercy_open or _now() < _mercy_at:
		return false
	_mercy_open = false
	mercy_shots += 1
	return true


func mercy_speed(dist: float) -> float:
	## Game-time speed that lands the shot about 55% into what is left of the Blackout window.
	var left: float = maxf(_blackout_end - _now(), 0.3)
	var ts: float = maxf(JuiceManager.base_time_scale, 0.05)
	return clampf(dist / (left * 0.55 * ts), 150.0, 900.0)


func may_fire() -> bool:
	var cap: int = max_threats()
	if cap >= 99:
		return true
	var pl: Player = _player()
	if pl == null:
		return true
	var n: int = 0
	for node: Node in get_tree().get_nodes_in_group("projectiles"):
		var o: Projectile = node as Projectile
		if o != null and not o.spent() and o.team == Projectile.Team.ENEMY and o.lane == pl.lane \
				and o.global_position.distance_to(pl.chest()) < 300.0:
			n += 1
	return n < cap


# ================================================================= run lifecycle

func run_started() -> void:
	runs += 1
	_in_run = true
	_streak = 0
	_fall_streak = 0
	_death_times.clear()
	_pending.clear()
	_last_progress = _now()
	_life_start = _now()
	_eased_announced = false
	_hard_announced = challenge > 0.85
	samples_this_run = 0
	tilt = 0.0
	_last_input_ms = Time.get_ticks_msec()
	_idle_flagged = false
	_last_hint = _now()
	intensity = 0.0
	arm = -1
	_relax_left = 0.0
	_room_key = ""
	_stage_idx = 0
	_life_used.clear()
	_life_blackout = false
	_hint_flip = false


func stage_loaded(index: int) -> void:
	## Walking into the next stage means the last room of the one before was cleared.
	room_entered(index, 0, _in_run and index == _stage_idx + 1)
	_save()
	_last_progress = _now()
	_life_start = _now()
	_m1 = 1
	_m2 = 1
	_m3 = 1


func run_ended() -> void:
	_in_run = false
	_save()


# ================================================================= frame

func _physics_process(delta: float) -> void:
	var pl: Player = _player()
	if pl == null or pl.dead or get_tree().paused:
		return
	_m_t += delta
	if _m_t >= MOVE_STEP and pl.input_enabled and not pl.in_blackout:
		_m_t = 0.0
		move_observe(_move_token(pl))
	_near_tick += 1
	if _near_tick % 4 != 0:
		return
	var chest: Vector2 = pl.chest()
	for node: Node in get_tree().get_nodes_in_group("projectiles"):
		var p: Projectile = node as Projectile
		if p != null and p.team == Projectile.Team.ENEMY and p.lane == pl.lane and p.has_meta("dx") \
				and p.global_position.distance_to(chest) < 36.0:
			p.set_meta("dnear", true)


func _process(_delta: float) -> void:
	var now_ms: int = Time.get_ticks_msec()
	var dt: float = minf(float(now_ms - _last_ms) / 1000.0, 0.25)
	_last_ms = now_ms
	if get_tree().paused:
		_last_input_ms = now_ms
		return
	tilt *= pow(0.5, dt / 45.0)
	decay(dt)
	var now: float = _now()
	if _in_run and now - _last_save > 20.0:
		## What the models learned is written during play too, not only at deaths and checkpoints.
		_save()
	if _in_run and now - _last_progress > 50.0 and now - _last_hint > 50.0:
		_last_hint = now
		stuck.emit()
	if _in_run and not _idle_flagged and now_ms - _last_input_ms > 30000:
		## Walked away mid-run: the same signal as quitting, and the only one a browser tab gives.
		_idle_flagged = true
		var was_in_run: bool = _in_run
		quit("idle")
		_in_run = was_in_run


func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton:
		_last_input_ms = Time.get_ticks_msec()
		_idle_flagged = false
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and not key.echo and key.physical_keycode == KEY_F3:
		debug = not debug


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if _in_run:
			quit("close")
		else:
			_save()


# ================================================================= debug / status

func debug_lines() -> PackedStringArray:
	var ref: PackedFloat32Array = _reference_shot(challenge)
	return PackedStringArray([
		"challenge %.2f  goal %.2f  quit risk %.2f" % [challenge, solve_challenge(), tilt],
		"hit model  p %.2f  target %.2f  n %d" % [predict_hit(ref), target_hit_rate(), hit_n],
		"quit model  n %d  streak %d  deflect rate %.2f" % [quit_n, _streak, parry_rate],
		"move model  acc %.2f  repeat-last %.2f  n %d" % [move_acc, move_base_acc, move_n],
		"shots x%.2f  interval x%.2f  window +%.2f  cap %d  mercy %d" % [shot_speed_mult(),
				fire_interval_mult(), parry_window_bonus(), max_threats(), mercy_shots],
		"timing  swings %.2fs early +-%.2f  on time %.2f  no swing %.2f  n %d" % [time_mean,
				sqrt(maxf(time_var, 0.0)), predict_on_time(timing_bonus()), no_react, time_n],
		"room %s  clear chance %.2f  eased %.2f  player %.2f" % [_room_key, predict_clear(), room_ease(), player_r],
		"lever %s  tried %d/%d/%d  pace %s x%.2f  intensity %.2f" % [
				LEVER_NAMES[arm] if arm >= 0 else "none", int(round(arm_n[0])), int(round(arm_n[1])),
				int(round(arm_n[2])), "relax" if _relax_left > 0.0 else "build", pace_mult(), intensity],
		"skills  %s" % _skills_text(),
	])


func _skills_text() -> String:
	var parts: PackedStringArray = PackedStringArray()
	for s: String in SKILLS:
		if skill_p.has(s):
			parts.append("%s %.2f" % [s, float(skill_p[s])])
	return "  ".join(parts) if not parts.is_empty() else "no data yet"


# ================================================================= persistence

func to_dict() -> Dictionary:
	return {
		"v": VERSION, "challenge": challenge, "hit_w": Array(hit_w), "hit_n": hit_n,
		"quit_w": Array(quit_w), "quit_n": quit_n, "move_c1": Array(move_c1), "move_c2": Array(move_c2),
		"move_c3": Array(move_c3),
		"move_acc": move_acc, "move_base_acc": move_base_acc, "move_n": move_n,
		"parry_rate": parry_rate, "runs": runs,
		"time_mean": time_mean, "time_var": time_var, "time_n": time_n, "no_react": no_react,
		"player_r": player_r, "room_r": room_r, "arm_n": Array(arm_n), "arm_r": Array(arm_r),
		"life_ema": life_ema, "skill_p": skill_p, "skill_lives": skill_lives,
	}


func from_dict(d: Dictionary) -> bool:
	if int(d.get("v", 0)) != VERSION:
		return false
	var hw: Array = d.get("hit_w", [])
	var qw: Array = d.get("quit_w", [])
	var m1: Array = d.get("move_c1", [])
	var m2: Array = d.get("move_c2", [])
	var m3: Array = d.get("move_c3", [])
	if hw.size() != HIT_PRIOR.size() or qw.size() != QUIT_PRIOR.size() or m1.size() != move_c1.size() \
			or m2.size() != move_c2.size() or m3.size() != move_c3.size():
		return false
	for i: int in hw.size():
		hit_w[i] = float(hw[i])
	for i: int in qw.size():
		quit_w[i] = float(qw[i])
	for i: int in m1.size():
		move_c1[i] = float(m1[i])
	for i: int in m2.size():
		move_c2[i] = float(m2[i])
	for i: int in m3.size():
		move_c3[i] = float(m3[i])
	challenge = clampf(float(d.get("challenge", START_CHALLENGE)), 0.0, 1.0)
	hit_n = int(d.get("hit_n", 0))
	quit_n = int(d.get("quit_n", 0))
	move_acc = float(d.get("move_acc", 0.34))
	move_base_acc = float(d.get("move_base_acc", 0.34))
	move_n = int(d.get("move_n", 0))
	parry_rate = float(d.get("parry_rate", 0.5))
	runs = int(d.get("runs", 0))
	## Models 4 to 8 were added later: a profile without them keeps what it has and starts these fresh.
	time_mean = clampf(float(d.get("time_mean", 0.12)), 0.0, 1.0)
	time_var = clampf(float(d.get("time_var", 0.01)), 0.0, 1.0)
	time_n = int(d.get("time_n", 0))
	no_react = clampf(float(d.get("no_react", 0.0)), 0.0, 1.0)
	player_r = clampf(float(d.get("player_r", 0.0)), -4.0, 4.0)
	room_r = {}
	var rooms: Variant = d.get("room_r", {})
	if rooms is Dictionary:
		for k: Variant in rooms:
			room_r[str(k)] = clampf(float(rooms[k]), -4.0, 4.0)
	var an: Variant = d.get("arm_n", [])
	var ar: Variant = d.get("arm_r", [])
	if an is Array and ar is Array and an.size() == arm_n.size() and ar.size() == arm_r.size():
		for i: int in arm_n.size():
			arm_n[i] = maxf(float(an[i]), 0.0)
			arm_r[i] = clampf(float(ar[i]), 0.0, arm_n[i])
	life_ema = clampf(float(d.get("life_ema", 12.0)), 1.0, 120.0)
	skill_p = {}
	var skills: Variant = d.get("skill_p", {})
	if skills is Dictionary:
		for k: Variant in skills:
			if SKILLS.has(str(k)):
				skill_p[str(k)] = clampf(float(skills[k]), 0.01, 0.99)
	skill_lives = int(d.get("skill_lives", 0))
	return true


func _save() -> void:
	if not persist:
		return
	var f: FileAccess = FileAccess.open(save_path, FileAccess.WRITE)
	if f == null:
		return
	_last_save = _now()
	f.store_string(JSON.stringify(to_dict()))
	f.close()


func _load() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var f: FileAccess = FileAccess.open(save_path, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Dictionary:
		if not from_dict(parsed):
			_reset_models()
