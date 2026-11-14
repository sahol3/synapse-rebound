extends SceneTree
## Dev capture of two screens that are slow to reach by hand: the Stage 4 card and the ending.
## Run with a window: godot --path game --script res://tests/EndingShot.gd -- --stage=4 --out=<abs dir>
## (`--stage=` marks the run as a dev run, so the player's save and profile are not touched.)

var _dir: String = ""


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_dir = arg.get_slice("=", 1)
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
	await _shot("card_s4.png")
	var gs: Node = root.get_node("GameState")
	gs.parries = 148
	gs.loop_deaths = 9
	gs.rebounds = 6
	gs.best_rally = 5
	main._on_boss_defeated()
	await create_timer(10.5, true, false, true).timeout
	await _shot("ending.png")
	quit()
