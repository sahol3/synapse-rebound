extends Node

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
			var max_h: float = 300.5 if float(w) / float(h) >= 1.5 else 420.0
			var bad: bool = view.x < 320.0 or view.y < 150.0 or view.y > max_h \
					or (sc2.y > 1 and (ui.x < 480.0 or ui.y < 270.0))
			if bad and sweep_detail.length() < 200:
				sweep_detail += " %dx%d view=%s ui=%s;" % [w, h, str(view), str(ui)]
			sweep_ok = sweep_ok and not bad
	_check("D2 every landscape window keeps a playable view and a readable interface", sweep_ok,
			"%d sizes%s" % [sweep_n, sweep_detail])

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

	Director.reset_profile()
	var fresh := PackedFloat32Array([1.0, 0.125, 0.05, 0.17, 0.0, 0.3])
	var fed_up := PackedFloat32Array([1.0, 0.75, 0.5, 0.83, 1.0, 0.7])
	_check("Q1 starting weights: a first death reads low risk, a long streak reads high",
			Director.predict_quit(fresh) < 0.15 and Director.predict_quit(fed_up) > 0.6,
			"fresh=%.2f fed_up=%.2f" % [Director.predict_quit(fresh), Director.predict_quit(fed_up)])
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
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

	Director.reset_profile()
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

	Director.reset_profile()
	Director.enabled = true
	var calls: Array = []
	var scores: Array = []
	var on_call: Callable = func(w: String) -> void: calls.append(w)
	var on_score: Callable = func(h: bool) -> void: scores.append(h)
	Director.call_made.connect(on_call)
	Director.call_scored.connect(on_score)
	_check("F1 a change of movement gets a word, coming down from a jump gets none",
			Director.call_word(2, 5) == "JUMP" and Director.call_word(4, 1) == "" and Director.call_word(1, 0) == "LEFT"
			and Director.call_word(1, 2) == "RIGHT" and Director.call_word(2, 1) == "STOP", "")
	for i: int in 100:
		Director._last_call = -1000.0
		Director.move_observe(cycle[i % cycle.size()])
	_check("F2 no call and no outline before 120 samples", calls.is_empty() and not Director.prediction_visible(),
			"calls=%d" % calls.size())
	for i: int in range(100, 600):
		Director._last_call = -1000.0
		Director.move_observe(cycle[i % cycle.size()])
	var landed: int = scores.count(true)
	_check("F3 a habit is called before it happens, and the calls land",
			calls.size() >= 50 and calls.count("JUMP") == calls.size() and landed >= int(scores.size() * 0.9),
			"calls=%d landed=%d of %d" % [calls.size(), landed, scores.size()])
	_check("F4 the run percentage is the real hit rate and the outline is on",
			Director.run_predicted_percent() >= 80 and Director.prediction_visible() and absf(Director.predicted_offset()) > 6.0,
			"run=%d%% offset=%.1f px" % [Director.run_predicted_percent(), Director.predicted_offset()])
	var before_cool: int = calls.size()
	for i: int in 300:
		Director.move_observe(cycle[i % cycle.size()])
	_check("F5 calls are spaced by the cooldown", calls.size() - before_cool <= 1, "new calls=%d" % (calls.size() - before_cool))
	scores.clear()
	var broke: bool = false
	for i: int in 400:
		Director._last_call = -1000.0
		var want: int = cycle[i % cycle.size()]
		if Director._call_tok >= 0 and not broke:
			want = 0
			broke = true
		Director.move_observe(want)
	_check("F6 doing something else on a called step scores a miss", broke and scores.count(false) >= 1,
			"misses=%d" % scores.count(false))
	Director.model_stolen = true
	var before_theft: int = calls.size()
	for i: int in 200:
		Director._last_call = -1000.0
		Director.move_observe(cycle[i % cycle.size()])
	_check("F7 once the model is taken it stops reading the player",
			calls.size() == before_theft and not Director.prediction_visible(), "new calls=%d" % (calls.size() - before_theft))
	Director.run_started()
	_check("F8 a new run starts with his model back and the count at zero",
			not Director.model_stolen and Director.run_calls == 0 and Director.run_predicted_percent() == -1, "")
	Director.challenge = 0.0
	var floor_on: float = Director.lead_amount()
	Director.enabled = false
	var floor_off: float = Director.lead_amount()
	Director.enabled = true
	_check("F9 some fire always goes to the outline while the director is on",
			is_equal_approx(floor_on, Director.LEAD_FLOOR) and floor_off == 0.0, "on=%.2f off=%.2f" % [floor_on, floor_off])
	Director.call_made.disconnect(on_call)
	Director.call_scored.disconnect(on_score)

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
	var mf: FileAccess = FileAccess.open(GameState.meta_path(), FileAccess.WRITE)
	mf.store_string(JSON.stringify({"memories": [GameState.OLD_HANDLER_ID, "guard"], "endings": []}))
	mf.close()
	GameState._meta_from = ""
	var kept: Array = GameState.meta()["memories"]
	_check("S6 a Lore entry saved under the handler's old name is kept under the new one",
			"saif" in kept and "guard" in kept and not (GameState.OLD_HANDLER_ID in kept), str(kept))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameState.meta_path()))
	GameState._meta_from = ""
	GameState.persist = false
	GameState.save_run(1)
	_check("S6 with saving off nothing is written", not FileAccess.file_exists(GameState.save_path))

	GameState.save_path = "user://save_test.json"
	GameState.persist = true
	var meta_file: String = ProjectSettings.globalize_path(GameState.meta_path())
	if FileAccess.file_exists(GameState.meta_path()):
		DirAccess.remove_absolute(meta_file)
	GameState._meta_from = ""
	_check("X1 three Lore entries are readable before anything is recovered", GameState.memory_count() == 3,
			"count=%d path=%s" % [GameState.memory_count(), GameState.meta_path()])
	var first_unlock: bool = GameState.unlock_memory("blackout")
	var second_unlock: bool = GameState.unlock_memory("blackout")
	GameState._meta_from = ""
	_check("X2 a recovered memory is saved once and read back from the file",
			first_unlock and not second_unlock and GameState.has_memory("blackout") and GameState.memory_count() == 4,
			"first=%s second=%s count=%d" % [str(first_unlock), str(second_unlock), GameState.memory_count()])
	GameState.run_time = 200.0
	var end1: Dictionary = GameState.record_ending("A")
	GameState.run_time = 150.0
	var end2: Dictionary = GameState.record_ending("A")
	GameState._meta_from = ""
	var mt: Dictionary = GameState.meta()
	_check("X3 endings seen, finishes and the best time are kept across runs",
			end1["new_ending"] and not end1["best_time"] and not end2["new_ending"] and end2["best_time"]
			and (mt["endings"] as Array).size() == 1 and int(mt["finished"]) == 2
			and is_equal_approx(float(mt["best_time"]), 150.0) and GameState.has_memory("saif") and GameState.has_memory("end_A"),
			str(mt))
	DirAccess.remove_absolute(meta_file)
	GameState.persist = false
	GameState._meta_from = ""
	GameState.unlock_memory("guard")
	_check("X4 with saving off a recovery lasts for the session and no file is written",
			GameState.memory_count() == 4 and not FileAccess.file_exists(GameState.meta_path()),
			"count=%d file=%s" % [GameState.memory_count(), str(FileAccess.file_exists(GameState.meta_path()))])
	GameState._meta_from = ""
	GameState.run_time = 0.0

	var radio: int = AudioServer.get_bus_index("Radio")
	var echo_bus: int = AudioServer.get_bus_index("Echo")
	_check("V1 the Radio bus band-limits and overdrives, and the Echo bus exists",
			radio >= 0 and echo_bus >= 0 and AudioServer.get_bus_effect_count(radio) == 4
			and AudioServer.get_bus_effect(radio, 0) is AudioEffectHighPassFilter
			and AudioServer.get_bus_effect(radio, 1) is AudioEffectLowPassFilter
			and AudioServer.get_bus_effect(radio, 2) is AudioEffectDistortion,
			"radio=%d echo=%d effects=%d" % [radio, echo_bus, AudioServer.get_bus_effect_count(radio) if radio >= 0 else -1])
	_check("V2 a line nobody has recorded plays nothing and stays text",
			is_zero_approx(AudioManager.play_voice("SAIF", "no_such_line_1")) and not AudioManager.voice_playing(), "")
	var stand_in: AudioStream = AudioManager._streams["drone"][0]
	AudioManager.register_voice("SAIF", "test_line_1", stand_in)
	var spoken: float = AudioManager.play_voice("SAIF", "test_line_1")
	_check("V3 a recorded line plays on the Radio bus over the static bed and reports its length",
			spoken > 0.5 and is_equal_approx(spoken, stand_in.get_length()) and AudioManager._vox.bus == "Radio"
			and AudioManager._vox.playing and AudioManager._bed.playing
			and AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")) < -1.0,
			"len=%.2f bus=%s vox=%s bed=%s" % [spoken, AudioManager._vox.bus, str(AudioManager._vox.playing), str(AudioManager._bed.playing)])
	AudioManager.stop_voice()
	_check("V4 stopping the line stops the voice and the static and restores the music",
			not AudioManager._vox.playing and not AudioManager._bed.playing
			and is_zero_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))), "")
	var every_line_keyed: bool = true
	for id: String in DialogueData.LINES:
		for ln: Dictionary in DialogueData.LINES[id]:
			if not (ln["who"] in ["SAIF", "ECHO", "LOG", "SYS", "WORLD"]):
				every_line_keyed = false
	_check("V5 every line has a known speaker, and each choice and stage has its reaction lines",
			every_line_keyed and DialogueData.LINES.has("after_Q_1") and DialogueData.LINES.has("after_E_3")
			and DialogueData.LINES.has("resume_4") and DialogueData.LINES["s3_rally"][1]["who"] == "LOG", "")

	var epilogue_ok: bool = true
	for ending: String in ["A", "B", "C"]:
		var entries: Array = DialogueData.EPILOGUE.get(ending, [])
		var names: Array = []
		for entry: Dictionary in entries:
			names.append(entry["who"])
		if entries.size() < 4 or not ("VINCENT" in names and "SAIF" in names and "THE ECHO" in names):
			epilogue_ok = false
	_check("V9 every ending has an epilogue that covers Vincent, Saif and The Echo", epilogue_ok, "")
	AudioManager.register_voice("SAIF", "test_line_1", AudioManager._streams["drone"][0])
	GameState.set_voice(false)
	var muted: float = AudioManager.play_voice("SAIF", "test_line_1")
	var silent: bool = not AudioManager.voice_playing() and not GameState.voice_on()
	GameState.set_voice(true)
	_check("V10 with the voice turned off a recorded line plays nothing; turned on again it plays",
			is_zero_approx(muted) and silent and AudioManager.play_voice("SAIF", "test_line_1") > 0.5 and GameState.voice_on(), "")
	AudioManager.stop_voice()

	Director.enabled = true
	Director.reset_profile()
	_check("M10a no bar and no praise before three samples",
			is_inf(Director.pb_threshold("streak")) and not Director.pb_check("streak", 50.0), "")
	for v: float in [4.0, 6.0, 5.0, 5.0]:
		Director.pb_close("streak", v)
	var bar: float = Director.pb_threshold("streak")
	_check("M10b the bar sits just above the player's usual streak", bar >= 5.0 and bar < 8.0, "bar=%.2f" % bar)
	var below: bool = Director.pb_check("streak", bar - 0.5)
	var hit1: bool = Director.pb_check("streak", bar + 1.0)
	var hit2: bool = Director.pb_check("streak", bar + 2.0)
	_check("M10c passing the bar praises once per streak", not below and hit1 and not hit2,
			"below=%s first=%s second=%s" % [str(below), str(hit1), str(hit2)])
	Director.pb_close("streak", bar + 2.0)
	_check("M10d a second praise waits for the cooldown", not Director.pb_check("streak", 40.0), "")
	var saved_pb: Dictionary = Director.to_dict()
	Director.reset_profile()
	for v: float in [20.0, 24.0, 22.0, 26.0]:
		Director.pb_close("streak", v)
	var bar_expert: float = Director.pb_threshold("streak")
	_check("M10e the bar follows the player: an expert's is higher", bar_expert > bar + 10.0,
			"beginner=%.1f expert=%.1f" % [bar, bar_expert])
	Director.enabled = false
	Director._last_praise = -1000.0
	var off_praise: bool = Director.pb_check("streak", 999.0)
	Director.enabled = true
	Director.from_dict(saved_pb)
	_check("M10f with the director off there is no praise, and the bar survives save and load",
			not off_praise and int(Director.pb_n.get("streak", 0)) == 5 and Director.pb_threshold("streak") >= 5.0,
			"off=%s n=%d bar=%.2f" % [str(off_praise), int(Director.pb_n.get("streak", 0)), Director.pb_threshold("streak")])

	Director.enabled = true
	Director.reset_profile()
	var rng4 := RandomNumberGenerator.new()
	rng4.seed = 11
	for i: int in 5:
		Director.timing_learn(0.30)
	_check("M4a no personal deflect window before 8 swings were measured", is_zero_approx(Director.timing_bonus()),
			"bonus=%.3f n=%d" % [Director.timing_bonus(), Director.time_n])
	for i: int in 40:
		Director.timing_learn(maxf(rng4.randfn(0.27, 0.05), 0.0))
	var early_p: float = Director.predict_on_time(0.0)
	var early_bonus: float = Director.timing_bonus()
	_check("M4b a player who swings early is predicted late and gets a wider window",
			early_p < 0.6 and early_bonus > 0.02 and early_bonus <= 0.08,
			"on_time=%.2f bonus=%.3f mean=%.3f sd=%.3f" % [early_p, early_bonus, Director.time_mean, sqrt(Director.time_var)])
	_check("M4c the wider window raises the predicted on-time rate", Director.predict_on_time(0.08) > early_p + 0.1,
			"%.2f -> %.2f" % [early_p, Director.predict_on_time(0.08)])
	Director.reset_profile()
	for i: int in 40:
		Director.timing_learn(maxf(rng4.randfn(0.08, 0.03), 0.0))
	_check("M4d a player with tight timing gets no extra window", is_zero_approx(Director.timing_bonus()),
			"on_time=%.2f bonus=%.3f" % [Director.predict_on_time(0.0), Director.timing_bonus()])

	Director.reset_profile()
	Director.room_entered(1, 0, false)
	var fresh_speed: float = Director.shot_speed_mult()
	Director.room_entered(3, 1, false)
	for i: int in 6:
		Director.room_result(false)
	var hard_p: float = Director.predict_clear()
	var hard_ease: float = Director.room_ease()
	var hard_speed: float = Director.shot_speed_mult()
	Director.room_entered(3, 2, false)
	var next_p: float = Director.predict_clear()
	_check("M5a six deaths in one room: low clear chance there, and that room is eased, the next is not",
			hard_p < 0.30 and hard_ease > 0.03 and next_p > hard_p + 0.1 and is_zero_approx(Director.room_ease()),
			"hard=%.2f ease=%.3f next=%.2f" % [hard_p, hard_ease, next_p])
	_check("M5b shots are slower in the room that beat the player", hard_speed < fresh_speed - 0.01,
			"%.3f vs %.3f" % [hard_speed, fresh_speed])
	Director.room_entered(3, 1, false)
	for i: int in 8:
		Director.room_result(true)
	_check("M5c clearing the room again and again removes the easing", is_zero_approx(Director.room_ease()),
			"clear=%.2f ease=%.3f" % [Director.predict_clear(), Director.room_ease()])

	Director.reset_profile()
	var rng6 := RandomNumberGenerator.new()
	rng6.seed = 23
	var picks: Array[int] = [0, 0, 0]
	for i: int in 90:
		var a: int = Director.arm_choose()
		picks[a] += 1
		Director.arm_score(a, rng6.randf() < (0.8 if a == Director.LEVER_PACE else 0.2))
	_check("M6a the bandit finds the lever that helps (pace helps 80%, the others 20%)",
			picks[Director.LEVER_PACE] > 45 and picks[0] >= 3 and picks[2] >= 3, str(picks))
	Director.reset_profile()
	Director.tilt = 0.6
	var win_plain: float = Director.parry_window_bonus()
	var speed_plain: float = Director.shot_speed_mult()
	Director.arm = Director.LEVER_TIMING
	_check("M6b a boosted timing lever widens the deflect window and leaves shot speed alone",
			Director.parry_window_bonus() > win_plain + 0.005 and is_equal_approx(Director.shot_speed_mult(), speed_plain),
			"window %.3f -> %.3f, speed %.3f -> %.3f" % [win_plain, Director.parry_window_bonus(), speed_plain, Director.shot_speed_mult()])
	Director.arm = Director.LEVER_PACE
	_check("M6c a boosted pace lever slows shots and leaves the window alone",
			Director.shot_speed_mult() < speed_plain - 0.01 and is_equal_approx(Director.parry_window_bonus(), win_plain),
			"speed %.3f -> %.3f" % [speed_plain, Director.shot_speed_mult()])

	Director.reset_profile()
	var calm_interval: float = Director.fire_interval_mult()
	Director.bump(0.5)
	Director.bump(0.5)
	_check("M7a after a peak the enemies fire slower", Director.fire_interval_mult() > calm_interval * 1.3,
			"%.2f -> %.2f" % [calm_interval, Director.fire_interval_mult()])
	Director.decay(6.0)
	_check("M7b the release ends after five seconds and intensity has halved",
			is_equal_approx(Director.fire_interval_mult(), calm_interval) and Director.intensity < 0.51,
			"interval=%.2f intensity=%.2f" % [Director.fire_interval_mult(), Director.intensity])
	Director.decay(40.0)
	Director.challenge = 0.8
	Director.tilt = 0.0
	_check("M7c in a long calm at high challenge they fire a little faster",
			is_equal_approx(Director.fire_interval_mult(), lerpf(1.50, 0.85, 0.8) * 0.92),
			"%.3f" % Director.fire_interval_mult())

	Director.reset_profile()
	Director.skill_used("parry")
	Director.skills_close(1.5)
	_check("M8a a life under three seconds is not an observation", Director.skill_lives == 0 and Director.skill_p.is_empty())
	for i: int in 4:
		Director.skill_used("parry")
		Director.skill_used("dash")
		Director.skills_close(10.0)
	_check("M8b used every life: known. Never used: the weakest. Never had the chance (rebound): not judged",
			float(Director.skill_p["parry"]) > 0.8 and Director.weakest_skill() == "airjump" and not Director.skill_p.has("rebound"),
			"%s weakest=%s" % [str(Director.skill_p), Director.weakest_skill()])
	_check("M8c hints alternate: stage hint first, then the weakest mechanic",
			Director.hint_skill() == "" and Director.hint_skill() == "airjump")
	for i: int in 3:
		Director.skill_used("airjump")
		Director.skill_used("parry")
		Director.skill_used("dash")
		Director.skills_close(10.0)
	_check("M8d once the mechanic is used the skill hint stops", Director.weakest_skill() == "", str(Director.skill_p))

	Director.reset_profile()
	for i: int in 12:
		Director.timing_learn(0.2)
	Director.room_entered(2, 1, false)
	Director.room_result(false)
	Director.arm_score(1, true)
	Director.skill_used("dash")
	Director.skills_close(10.0)
	var snap: Dictionary = JSON.parse_string(JSON.stringify(Director.to_dict()))
	Director.reset_profile()
	var loaded: bool = Director.from_dict(snap)
	_check("M9a the new models survive a save and load",
			loaded and Director.time_n == 12 and Director.room_r.has("2:1") and is_equal_approx(Director.arm_n[1], 1.0)
			and Director.skill_p.has("dash") and Director.skill_lives == 1,
			"n=%d rooms=%s arms=%s skills=%s" % [Director.time_n, str(Director.room_r), str(Director.arm_n), str(Director.skill_p)])
	for k: String in ["time_mean", "time_var", "time_n", "no_react", "player_r", "room_r", "arm_n", "arm_r", "life_ema", "skill_p", "skill_lives"]:
		snap.erase(k)
	snap["hit_n"] = 77
	Director.reset_profile()
	_check("M9b a profile saved before these models existed still loads",
			Director.from_dict(snap) and Director.hit_n == 77 and Director.time_n == 0 and Director.room_r.is_empty())
	Director.room_entered(3, 1, false)
	for i: int in 6:
		Director.room_result(false)
	for i: int in 20:
		Director.timing_learn(0.4)
	Director.arm = Director.LEVER_PACE
	Director.bump(1.0)
	Director.no_react = 1.0
	Director.enabled = false
	_check("M9c with the director off every knob is the original fixed value",
			is_equal_approx(Director.shot_speed_mult(), 1.0) and is_equal_approx(Director.fire_interval_mult(), 1.0)
			and is_equal_approx(Director.charge_time(), 0.45) and is_zero_approx(Director.parry_window_bonus())
			and Director.max_threats() == 99 and is_equal_approx(Director.parry_radius_mult(), 1.0),
			"speed=%.2f interval=%.2f charge=%.2f window=%.2f" % [Director.shot_speed_mult(), Director.fire_interval_mult(),
			Director.charge_time(), Director.parry_window_bonus()])
	Director.enabled = true
	Director.reset_profile()

	print("DIRECTORTEST passed=%d failed=%d" % [passed, failed])
	get_tree().quit(1 if failed > 0 else 0)
