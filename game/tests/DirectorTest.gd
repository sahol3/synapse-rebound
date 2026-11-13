extends Node
## Headless checks of the adaptive director's three models and the display scale rule.
## Pure logic plus simulated players; no stage is loaded.
## Run: tools\bin\godot.cmd --headless --path game res://tests/DirectorTest.tscn
## Prints PASS/FAIL per check and "DIRECTORTEST passed=N failed=M"; exit code 1 on any failure.

var passed: int = 0
var failed: int = 0


func _ready() -> void:
	Director.persist = false
	_run.call_deferred()


func _check(name: String, ok: bool, detail: String = "") -> void:
	if ok:
		passed += 1
		print("PASS  ", name, "  ", detail)
	else:
		failed += 1
		print("FAIL  ", name, "  ", detail)


static func _sig(z: float) -> float:
	return 1.0 / (1.0 + exp(-z))


func _sim_player(skill_bias: float, shots: int, seed_n: int) -> Dictionary:
	## A simulated player whose true chance of taking a shot rises with shot speed and crowding
	## and falls with the wider parry window the director hands out at low challenge.
	Director.reset_profile()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_n
	var recent: Array[float] = []
	for i: int in shots:
		var c: float = Director.challenge
		var s: float = Director.shot_speed_mult() - 1.0
		var crowd: float = float(rng.randi_range(0, int(round(lerpf(0.0, 2.0, c))))) / 3.0
		var air: float = 1.0 if rng.randf() < 0.3 else 0.0
		var close: float = 1.0 if rng.randf() < 0.35 else 0.0
		var logit: float = skill_bias + 3.0 * s + 1.2 * crowd + 0.5 * air + 0.6 * close - 4.0 * Director.parry_window_bonus()
		var hit: bool = rng.randf() < _sig(logit)
		Director.hit_learn(PackedFloat32Array([1.0, s, crowd, air, close]), hit)
		recent.append(1.0 if hit else 0.0)
		if recent.size() > 150:
			recent.pop_front()
	var rate: float = 0.0
	for v: float in recent:
		rate += v
	return {"c": Director.challenge, "rate": rate / float(recent.size())}


func _run() -> void:
	# ------------------------------------------------------------ display scale rule
	var table: Array = [
		[Vector2(1152, 648), 3, 2], [Vector2(1920, 1080), 5, 3], [Vector2(1366, 768), 3, 2],
		[Vector2(1280, 720), 3, 2], [Vector2(1600, 900), 4, 3], [Vector2(2560, 1440), 6, 4],
		[Vector2(3840, 2160), 10, 7], [Vector2(1024, 768), 3, 2], [Vector2(960, 540), 2, 2],
		[Vector2(2560, 1080), 5, 3], [Vector2(800, 600), 2, 1], [Vector2(640, 360), 2, 1],
	]
	var table_ok: bool = true
	var table_detail: String = ""
	for row: Array in table:
		var sc: Vector2i = Display.scales_for(row[0])
		if sc != Vector2i(int(row[1]), int(row[2])):
			table_ok = false
			table_detail += " %s got %s want (%d, %d);" % [str(row[0]), str(sc), row[1], row[2]]
	_check("D1 scale table (12 window sizes)", table_ok, table_detail)
	var sweep_ok: bool = true
	var sweep_detail: String = ""
	var sweep_n: int = 0
	for w: int in range(640, 3841, 64):
		for h: int in range(360, 2161, 40):
			if float(w) / float(h) < 1.2 or float(w) / float(h) > 3.6:
				continue
			sweep_n += 1
			var sc2: Vector2i = Display.scales_for(Vector2(w, h))
			var view: Vector2 = Vector2(w, h) / float(sc2.x)
			var ui: Vector2 = Vector2(w, h) / float(sc2.y)
			## Near-square windows trade height for the 320-pixel minimum width, so they may run taller.
			var max_h: float = 300.5 if float(w) / float(h) >= 1.5 else 420.0
			var bad: bool = view.x < 320.0 or view.y < 150.0 or view.y > max_h \
					or (sc2.y > 1 and (ui.x < 480.0 or ui.y < 270.0))
			if bad and sweep_detail.length() < 200:
				sweep_detail += " %dx%d view=%s ui=%s;" % [w, h, str(view), str(ui)]
			sweep_ok = sweep_ok and not bad
	_check("D2 every landscape window keeps a playable view and a readable interface", sweep_ok,
			"%d sizes%s" % [sweep_n, sweep_detail])

	# ------------------------------------------------------------ knobs
	Director.reset_profile()
	Director.enabled = true
	var mono: bool = true
	var prev: Array = []
	for i: int in 11:
		Director.challenge = float(i) / 10.0
		var cur: Array = [Director.shot_speed_mult(), -Director.fire_interval_mult(), -Director.charge_time(),
				-Director.parry_window_bonus(), -Director.parry_radius_mult(), -Director.blackout_bonus(),
				float(Director.max_threats()), Director.lead_amount()]
		if not prev.is_empty():
			for k: int in cur.size():
				if float(cur[k]) < float(prev[k]) - 0.0001:
					mono = false
		prev = cur
	_check("K1 every knob gets harder (or holds) as challenge rises", mono)
	Director.enabled = false
	_check("K2 disabled director returns the original fixed values",
			is_equal_approx(Director.shot_speed_mult(), 1.0) and is_equal_approx(Director.charge_time(), 0.45)
			and is_equal_approx(Director.parry_window_bonus(), 0.0) and Director.max_threats() == 99
			and not Director.mercy_enabled() and is_equal_approx(Director.blackout_bonus(), 0.0))
	Director.enabled = true

	# ------------------------------------------------------------ model 1: hit model
	var novice: Dictionary = _sim_player(1.2, 400, 11)
	var mid: Dictionary = _sim_player(-1.0, 400, 12)
	var expert: Dictionary = _sim_player(-4.5, 400, 13)
	_check("H1 struggling player: challenge falls to the floor", float(novice["c"]) <= 0.10,
			"challenge=%.2f hit rate=%.2f" % [novice["c"], novice["rate"]])
	_check("H2 expert player: challenge climbs to the ceiling", float(expert["c"]) >= 0.90,
			"challenge=%.2f hit rate=%.2f" % [expert["c"], expert["rate"]])
	_check("H3 middling player: settles between, near the 26% target hit rate",
			float(mid["c"]) > 0.10 and float(mid["c"]) < 0.90 and float(mid["rate"]) > 0.15 and float(mid["rate"]) < 0.37,
			"challenge=%.2f hit rate=%.2f" % [mid["c"], mid["rate"]])
	var spread: Array[float] = []
	for s: int in 5:
		spread.append(float(_sim_player(-1.0, 400, 100 + s)["rate"]))
	_check("H4 same player, five random seeds: hit rate stays in the 15-37% band every time",
			spread.min() > 0.15 and spread.max() < 0.37, str(spread))
	Director.reset_profile()
	Director.tilt = 0.0
	var calm_goal: float = Director.solve_challenge()
	Director.tilt = 0.9
	var tilted_goal: float = Director.solve_challenge()
	_check("H5 high quit risk lowers the challenge the hit model asks for", tilted_goal < calm_goal,
			"calm=%.2f tilted=%.2f" % [calm_goal, tilted_goal])

	# ------------------------------------------------------------ model 2: quit model
	Director.reset_profile()
	var fresh := PackedFloat32Array([1.0, 0.125, 0.05, 0.17, 0.0, 0.3])
	var fed_up := PackedFloat32Array([1.0, 0.75, 0.5, 0.83, 1.0, 0.7])
	_check("Q1 starting weights: a first death reads low risk, a long streak reads high",
			Director.predict_quit(fresh) < 0.15 and Director.predict_quit(fed_up) > 0.6,
			"fresh=%.2f fed_up=%.2f" % [Director.predict_quit(fresh), Director.predict_quit(fed_up)])
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	## A stubborn player: quits only when the last life was short, however long the streak.
	for i: int in 600:
		var x := PackedFloat32Array([1.0, rng.randf(), rng.randf(), rng.randf(), 1.0 if rng.randf() < 0.5 else 0.0, rng.randf()])
		Director.quit_learn(x, x[4] > 0.5 and rng.randf() < 0.9)
	var right: int = 0
	for i: int in 300:
		var x2 := PackedFloat32Array([1.0, rng.randf(), rng.randf(), rng.randf(), 1.0 if rng.randf() < 0.5 else 0.0, rng.randf()])
		if (Director.predict_quit(x2) > 0.5) == (x2[4] > 0.5):
			right += 1
	_check("Q2 learns a player unlike the starting weights (300 held-out deaths)", right >= 255,
			"%d of 300 right, n=%d" % [right, Director.quit_n])
	Director.reset_profile()
	Director.run_started()
	var c0: float = Director.challenge
	for i: int in 5:
		Director.player_died("hit")
	var tilt_after: float = Director.tilt
	_check("Q3 five deaths in a row: quit risk rises and challenge drops",
			tilt_after > 0.3 and Director.challenge < c0, "tilt=%.2f challenge %.2f -> %.2f" % [tilt_after, c0, Director.challenge])
	Director.progress("checkpoint")
	_check("Q4 reaching the checkpoint labels those five deaths 'did not quit' and calms the risk",
			Director.quit_n == 5 and Director.tilt < tilt_after, "n=%d tilt=%.2f" % [Director.quit_n, Director.tilt])
	var w_before: float = Director.quit_w[1]
	for i: int in 3:
		Director.player_died("fall")
	Director.quit("menu")
	_check("Q5 quitting labels the last deaths 'quit' and pushes the streak weight up",
			Director.quit_n == 8 and Director.quit_w[1] > w_before, "n=%d w %.3f -> %.3f" % [Director.quit_n, w_before, Director.quit_w[1]])
	_check("Q6 two fall deaths switch on the fall assist (extra air-dash, longer coyote time)",
			Director.extra_air_dashes() == 1 and Director.coyote_bonus() > 0.0)

	# ------------------------------------------------------------ model 3: move model
	Director.reset_profile()
	## Run right three steps, jump right two steps, repeat: a habit, not a held key.
	var cycle: Array[int] = [2, 2, 2, 5, 5]
	for i: int in 800:
		Director.move_observe(cycle[i % cycle.size()])
	_check("M1 habitual movement: the n-gram beats 'same as last step'",
			Director.move_acc > Director.move_base_acc + 0.10,
			"model=%.2f repeat-last=%.2f" % [Director.move_acc, Director.move_base_acc])
	_check("M2 predicts the player keeps heading right", Director.expected_dir() > 0.5, "E[dir]=%.2f" % Director.expected_dir())
	var pl: Player = load("res://scenes/entities/Player.tscn").instantiate()
	add_child(pl)
	pl.global_position = Vector2(0, 0)
	await get_tree().physics_frame
	var straight: Vector2 = Director.aim_point(pl, Vector2(-200, 0), 140.0, 0.0)
	var led: Vector2 = Director.aim_point(pl, Vector2(-200, 0), 140.0, 1.0)
	_check("M3 a led shot aims ahead of the player, an unled one at the chest",
			straight.is_equal_approx(pl.chest()) and led.x > pl.chest().x + 20.0, "lead=%.1f px" % (led.x - pl.chest().x))
	pl.queue_free()
	Director.reset_profile()
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 9
	var tok: int = 1
	for i: int in 1500:
		if rng2.randf() > 0.8:
			tok = rng2.randi_range(0, 5)
		Director.move_observe(tok)
	_check("M4 a player with no habit: the model is no worse than 'same as last step'",
			Director.move_acc >= Director.move_base_acc - 0.05,
			"model=%.2f repeat-last=%.2f" % [Director.move_acc, Director.move_base_acc])

	# ------------------------------------------------------------ persistence
	Director.challenge = 0.61
	Director.hit_w[0] = -2.25
	var saved: Dictionary = Director.to_dict()
	var text: String = JSON.stringify(saved)
	Director.reset_profile()
	var ok_load: bool = Director.from_dict(JSON.parse_string(text))
	_check("P1 profile survives a save and load through JSON",
			ok_load and is_equal_approx(Director.challenge, 0.61) and is_equal_approx(Director.hit_w[0], -2.25)
			and Director.move_n == 1500, "challenge=%.2f w0=%.2f move_n=%d" % [Director.challenge, Director.hit_w[0], Director.move_n])
	saved["v"] = 999
	_check("P2 a profile from another version is refused", not Director.from_dict(saved))

	# ------------------------------------------------------------ progress saving (file logic)
	GameState.save_path = "user://save_test.json"
	GameState.persist = true
	GameState.reset_run()
	GameState.choose_module(1, "Q")
	GameState.choose_module(2, "E")
	GameState.current_stage = 3
	GameState.loop_deaths = 7
	GameState.run_time = 123.5
	GameState.parries = 40
	GameState.once("first_death")
	GameState.save_run(2)
	var sv: Dictionary = GameState.saved_run()
	_check("S1 a saved run reads back: stage, checkpoint and module choices",
			int(sv.get("stage", 0)) == 3 and int(sv.get("room", -1)) == 2 and sv.get("choices", []) == ["Q", "E"], str(sv))
	GameState.reset_run()
	GameState.apply_save(sv)
	_check("S2 loading restores modules, loop count, clock, stats, seen-once lines and the sync floor",
			Array(GameState.choices) == ["Q", "E"] and GameState.loop_deaths == 7 and is_equal_approx(GameState.run_time, 123.5)
			and GameState.parries == 40 and not GameState.once("first_death") and GameState.sync_rate >= 100.0,
			"choices=%s loops=%d time=%.1f sync=%.0f" % [str(GameState.choices), GameState.loop_deaths, GameState.run_time, GameState.sync_rate])
	var bad_file: FileAccess = FileAccess.open(GameState.save_path, FileAccess.WRITE)
	bad_file.store_string("{not json")
	bad_file.close()
	_check("S3 a damaged save file is ignored", GameState.saved_run().is_empty())
	bad_file = FileAccess.open(GameState.save_path, FileAccess.WRITE)
	bad_file.store_string(JSON.stringify({"v": 1, "stage": 4, "room": 0, "choices": ["Q"]}))
	bad_file.close()
	_check("S4 an impossible save (stage 4 with one module) is ignored", GameState.saved_run().is_empty())
	GameState.clear_save()
	_check("S5 clearing the save removes the file", not FileAccess.file_exists(GameState.save_path))
	GameState.persist = false
	GameState.save_run(1)
	_check("S6 with saving off nothing is written", not FileAccess.file_exists(GameState.save_path))

	print("DIRECTORTEST passed=%d failed=%d" % [passed, failed])
	get_tree().quit(1 if failed > 0 else 0)
