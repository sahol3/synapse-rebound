extends SceneTree
## Dev capture of the title screen, the Lore tab (an open entry and a locked one) and the prologue.
## Run with a window:
##   godot --path game --script res://tests/MenuShot.gd -- --save-file=shotchk.json --profile-file=shotchk_dir.json --out=<abs dir>
## The two file arguments keep the run away from the player's own save, progress and profile.

var _dir: String = ""


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_dir = arg.get_slice("=", 1)
	_run()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var err: Error = root.get_texture().get_image().save_png(_dir.path_join(name))
	print("MENUSHOT ", name, " err=", err)


func _run() -> void:
	await process_frame
	var gs: Node = root.get_node("GameState")
	gs.unlock_memory("blackout")
	gs.unlock_memory("guard")
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.0).timeout
	await _shot("title.png")
	main.menu._panel = "lore"
	main.menu._lore_sel = 2
	await create_timer(0.2).timeout
	await _shot("lore_open.png")
	main.menu._lore_sel = 9
	await create_timer(0.2).timeout
	await _shot("lore_locked.png")
	main.menu._panel = ""
	main._start_new_game()
	await create_timer(8.6).timeout
	await _shot("prologue.png")
	await create_timer(6.0).timeout
	print("MENUSHOT state=", main._state, " stage=", gs.current_stage)
	await _shot("after_prologue.png")
	quit()
