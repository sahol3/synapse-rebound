extends Node
## End-to-end check of the adaptive director inside the real game: Stage 1, the player parked in
## front of the first turret, two bots in turn.
##   weak bot   - lets about two shots in three through in normal play, but always deflects
##                while in Blackout (so a mercy shot becomes a rebound).
##   strong bot - deflects everything.
## Expect: challenge falls for the weak bot and rises for the strong one, the shots are really
## being followed by the hit model, and the mercy shot turns Blackouts into rebounds.
## Run: tools\bin\godot.cmd --headless --path game res://tests/DirectorLive.tscn
## Prints PASS/FAIL per check and "DIRECTORLIVE passed=N failed=M"; exit code 1 on any failure.

var main: Node
var passed: int = 0
var failed: int = 0

var _bot: bool = false
var _skip_rate: float = 0.0
var _release_next: bool = false
var _decided: Dictionary = {}
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	Director.persist = false
	Director.enabled = true
	Director.reset_profile()
	_rng.seed = 21
	main = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	_run.call_deferred()


func _p() -> Player:
	var pl: Variant = main.get("player")
	return pl as Player if pl != null and is_instance_valid(pl) else null


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec, true, false, true).timeout


func _check(name: String, ok: bool, detail: String = "") -> void:
	if ok:
		passed += 1
		print("PASS  ", name, "  ", detail)
	else:
		failed += 1
		print("FAIL  ", name, "  ", detail)


func _press(action: String, on: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = on
	Input.parse_input_event(ev)


func _physics_process(_delta: float) -> void:
	if _release_next:
		_press("parry", false)
		_release_next = false
	var p: Player = _p()
	if not _bot or p == null or p.dead:
		return
	for node: Node in get_tree().get_nodes_in_group("projectiles"):
		var pr: Projectile = node as Projectile
		if pr == null or pr.team != Projectile.Team.ENEMY or pr.lane != p.lane:
			continue
		var id: int = pr.get_instance_id()
		if not _decided.has(id):
			## Decide once per shot whether this bot fumbles it.
			_decided[id] = _rng.randf() < _skip_rate
		if bool(_decided[id]) and not p.in_blackout:
			continue
		if pr.global_position.distance_to(p.chest()) < 40.0 and p.parry_ready() >= 1.0:
			## Send it up and away: a shot straight back would kill the turret and end the session.
			p.aim_override = (pr.global_position - p.chest()).normalized().rotated(-0.8)
			_press("parry", true)
			_release_next = true
			return


func _session(skip_rate: float, seconds: float) -> Dictionary:
	Director.reset_profile()
	main._begin_run(1)
	await _wait(1.6)
	var p: Player = _p()
	p.global_position.x = 10.0 * 16.0
	_skip_rate = skip_rate
	_decided.clear()
	var c0: float = Director.challenge
	var reb0: int = GameState.rebounds
	_bot = true
	var t: float = 0.0
	var low: float = c0
	var high: float = c0
	while t < seconds:
		await _wait(0.5)
		t += 0.5
		low = minf(low, Director.challenge)
		high = maxf(high, Director.challenge)
		p = _p()
		## Keep the bot in front of the turret (Blackout knocks it back; a rewind moves it to spawn).
		if p != null and not p.dead and not p.in_blackout and p.is_on_floor() and absf(p.global_position.x - 160.0) > 40.0:
			p.global_position.x = 160.0
	_bot = false
	return {"c0": c0, "c": Director.challenge, "low": low, "high": high, "n": Director.hit_n,
			"mercy": Director.mercy_shots, "rebounds": GameState.rebounds - reb0, "deaths": GameState.loop_deaths,
			"tilt": Director.tilt, "causes": str(Director.deaths_by_cause)}


func _run() -> void:
	await _wait(0.3)
	var weak: Dictionary = await _session(0.66, 45.0)
	_check("L1 weak bot: the hit model saw real shots", int(weak["n"]) >= 5, "samples=%d" % weak["n"])
	_check("L2 weak bot: challenge fell", float(weak["c"]) < float(weak["c0"]) - 0.05,
			"challenge %.2f -> %.2f (lowest %.2f)" % [weak["c0"], weak["c"], weak["low"]])
	_check("L3 weak bot: mercy shots fired in Blackout", int(weak["mercy"]) >= 1, "mercy=%d" % weak["mercy"])
	_check("L4 weak bot: mercy shots became rebounds, not deaths",
			int(weak["rebounds"]) >= 1 and int(weak["rebounds"]) >= int(weak["deaths"]),
			"rebounds=%d deaths=%d causes=%s" % [weak["rebounds"], weak["deaths"], weak["causes"]])
	var strong: Dictionary = await _session(0.0, 45.0)
	_check("L5 strong bot: the hit model saw real shots", int(strong["n"]) >= 5, "samples=%d" % strong["n"])
	_check("L6 strong bot: challenge rose", float(strong["c"]) > float(strong["c0"]) + 0.15,
			"challenge %.2f -> %.2f (highest %.2f)" % [strong["c0"], strong["c"], strong["high"]])
	_check("L7 strong bot: never died", int(strong["deaths"]) == 0, "deaths=%d" % strong["deaths"])
	var dbg: PackedStringArray = Director.debug_lines()
	_check("L8 strong bot: the timing model measured real swings and the room model knows the room",
			Director.time_n >= 5 and Director._room_key != "" and dbg.size() == 10,
			"swings=%d mean=%.2fs room=%s | %s | %s" % [Director.time_n, Director.time_mean, Director._room_key, dbg[5], dbg[7]])
	## Fire control on a real player: after a minute and a half of play the model has its samples,
	## and walking back and forth puts the outline ahead of the courier.
	_bot = false
	var pl: Player = get_tree().get_first_node_in_group("player") as Player
	var shown: int = 0
	var ahead: int = 0
	for leg: int in 6:
		var act: String = "move_right" if leg % 2 == 0 else "move_left"
		Input.action_press(act)
		var t: float = 0.0
		while t < 1.0:
			await _wait(0.1)
			t += 0.1
			if pl != null and is_instance_valid(pl) and pl._pred != null and pl._pred.visible:
				shown += 1
				var off: float = pl._pred.global_position.x - pl._sprite.global_position.x
				if (off > 0.0) == (leg % 2 == 0):
					ahead += 1
		Input.action_release(act)
	_check("L9 real play: the outline shows, and mostly on the side the player is heading",
			Director.move_n >= Director.CALL_MIN_SAMPLES and shown >= 20 and ahead * 10 >= shown * 6,
			"samples=%d shown=%d of 60 ahead=%d predicted=%d%%" % [Director.move_n, shown, ahead, Director.predicted_percent()])
	print("DIRECTORLIVE passed=%d failed=%d" % [passed, failed])
	get_tree().quit(1 if failed > 0 else 0)
