extends SceneTree
## Generates every .tscn through Godot's own PackedScene API (no hand-written scene text,
## UIDs stay valid). Each scene is a root node + script; children are built in code at runtime.
## Run: tools\bin\godot.cmd --headless --path game --script ..\scripts\build_scenes.gd

const SCENES: Array = [
	["res://scenes/Main.tscn", "Node", "res://scripts/Main.gd", "Main"],
	["res://scenes/ui/MainMenu.tscn", "Node2D", "res://scripts/ui/MainMenu.gd", "MainMenu"],
	["res://scenes/ui/HUD.tscn", "CanvasLayer", "res://scripts/ui/HudController.gd", "HUD"],
	["res://scenes/entities/Player.tscn", "CharacterBody2D", "res://scripts/entities/Player.gd", "Player"],
	["res://scenes/entities/Projectile.tscn", "Area2D", "res://scripts/entities/Projectile.gd", "Projectile"],
	["res://scenes/entities/EnemyTurret.tscn", "Node2D", "res://scripts/entities/EnemyBase.gd", "EnemyTurret"],
	["res://scenes/levels/Stage01_Alley.tscn", "Node2D", "res://scripts/levels/Stage01Alley.gd", "Stage01_Alley"],
	["res://scenes/levels/Stage02_Highway.tscn", "Node2D", "res://scripts/levels/Stage02Highway.gd", "Stage02_Highway"],
	["res://scenes/levels/Stage03_Shaft.tscn", "Node2D", "res://scripts/levels/Stage03Shaft.gd", "Stage03_Shaft"],
	["res://scenes/levels/Stage04_RooftopBoss.tscn", "Node2D", "res://scripts/levels/Stage04RooftopBoss.gd", "Stage04_RooftopBoss"],
	["res://tests/MechTest.tscn", "Node", "res://tests/MechTest.gd", "MechTest"],
]


func _init() -> void:
	var failed: int = 0
	for s: Array in SCENES:
		var node: Node = ClassDB.instantiate(s[1])
		node.name = s[3]
		## --script mode has no autoloads, so the real scripts can't compile here. A stand-in
		## script takes over the real path; the saved scene then points at the real .gd file.
		var stub := GDScript.new()
		stub.source_code = "extends %s\n" % s[1]
		stub.reload()
		stub.take_over_path(s[2])
		node.set_script(stub)
		var ps := PackedScene.new()
		var err: int = ps.pack(node)
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(String(s[0]).get_base_dir()))
		if err == OK:
			err = ResourceSaver.save(ps, s[0])
		print("%s %s" % ["OK  " if err == OK else "FAIL", s[0]])
		if err != OK:
			failed += 1
		node.free()
	print("BUILD_SCENES failed=%d" % failed)
	quit(1 if failed > 0 else 0)
