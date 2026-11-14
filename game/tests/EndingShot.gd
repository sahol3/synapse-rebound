extends SceneTree

var _dir: String = ""
var _ending: String = "C"


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_dir = arg.get_slice("=", 1)
		if arg.begins_with("--ending="):
			_ending = arg.get_slice("=", 1)
	_run()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var err: Error = root.get_texture().get_image().save_png(_dir.path_join(name))
	print("ENDINGSHOT ", name, " err=", err)


func _run() -> void:
	await process_frame
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.2).timeout
	if _ending == "C":
		await _shot("card_s4.png")
	var gs: Node = root.get_node("GameState")
	gs.parries = 148
	gs.loop_deaths = 9
	gs.rebounds = 6
	gs.best_rally = 5
	gs.overclock_count = 3 if _ending == "B" else (0 if _ending == "A" else 1)
	gs.stabilize_count = 3 - gs.overclock_count
	main._on_boss_defeated()
	await create_timer(10.5, true, false, true).timeout
	await _shot("ending_%s.png" % _ending)
	var hud: Node = main.hud
	await create_timer(hud.EPI_AUTO - 10.5 + 2.5 + 3.0, true, false, true).timeout
	for i: int in 4:
		print("ENDINGSHOT beat=", hud._epi_beat, " epilogue=", main._epilogue != null)
		await _shot("epilogue_%s_%d.png" % [_ending, i])
		await create_timer(hud.EPI_BEAT, true, false, true).timeout
	quit()
