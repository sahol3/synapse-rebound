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


func reset_profile() -> void:
	## Forget everything learned (tests, or a fresh player).
	_reset_models()
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

func shot_speed_mult() -> float:
	return lerpf(0.70, 1.15, challenge) if enabled else 1.0


func fire_interval_mult() -> float:
	return lerpf(1.50, 0.85, challenge) if enabled else 1.0


func charge_time() -> float:
	## Muzzle telegraph before an enemy fires.
	return lerpf(0.70, 0.40, challenge) if enabled else 0.45


func max_threats() -> int:
	## How many enemy shots may be in the air near the player before the next enemy holds fire.
	if not enabled or challenge >= 0.85:
		return 99
	if challenge < 0.25:
		return 1
	return 2 if challenge < 0.6 else 3


func parry_window_bonus() -> float:
	return lerpf(0.10, 0.0, challenge) if enabled else 0.0


func parry_radius_mult() -> float:
	return lerpf(1.22, 1.0, challenge) if enabled else 1.0


func parry_arc_mult() -> float:
	return lerpf(1.40, 1.0, challenge) if enabled else 1.0


func blackout_bonus() -> float:
	if not enabled:
		return 0.0
	return lerpf(1.0, 0.0, challenge) + (0.5 if tilt > 0.35 else 0.0)


func mercy_enabled() -> bool:
	## At every challenge level: a hit always leaves one shot to rebound off. Without it the
	## Blackout window is only survivable when a second shot happens to be beside the player.
	return enabled


func show_sights() -> bool:
	return enabled and challenge < 0.4


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
	if x.is_empty() or in_blackout:
		return
	hit_learn(x, false)


func player_hit(p: Projectile, in_blackout: bool) -> void:
	var x: PackedFloat32Array = _take_sample(p)
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
	_streak += 1
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


# ================================================================= mercy shot (Blackout)

func blackout_started() -> void:
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


func stage_loaded(_index: int) -> void:
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
	])


# ================================================================= persistence

func to_dict() -> Dictionary:
	return {
		"v": VERSION, "challenge": challenge, "hit_w": Array(hit_w), "hit_n": hit_n,
		"quit_w": Array(quit_w), "quit_n": quit_n, "move_c1": Array(move_c1), "move_c2": Array(move_c2),
		"move_c3": Array(move_c3),
		"move_acc": move_acc, "move_base_acc": move_base_acc, "move_n": move_n,
		"parry_rate": parry_rate, "runs": runs,
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
