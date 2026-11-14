extends Node2D

class Roof extends StageBase:
	func _init() -> void:
		stage_index = 0
		bounds = Rect2i(0, -10, 60, 30)
		kill_y = 1e9

	func build() -> void:
		var k := EnemyBase.Kind
		building(0, 44, 10)
		enemy(k.TURRET, 7.5, 10)
		enemy(k.DRONE, 11.5, 6.5, 0, 0, {"patrol": 3.0})
		enemy(k.ENFORCER, 15, 10, 0, 0, {"patrol": 12.0})
		enemy(k.DEFLECTOR, 19.5, 5.5, 0, 0, {"patrol": 3.0})
		enemy(k.ENFORCER, 23, 10, 0, 0, {"patrol": 12.0, "skin": "bipedal"})
		enemy(k.HEAVY, 28.5, 10, 0, 0, {"patrol": 12.0})
		enemy(k.SNIPER, 35.5, 10)


func _ready() -> void:
	Director.enabled = false
	var roof := Roof.new()
	add_child(roof)
	JuiceManager.fx_root = roof.fx
	var cam := Camera2D.new()
	cam.zoom = Vector2(Display.art, Display.art)
	cam.position = Vector2(Display.view.x * 0.5, 100.0)
	add_child(cam)
	cam.make_current()
	JuiceManager.camera = cam
	var pl: Player = load("res://scenes/entities/Player.tscn").instantiate()
	roof.add_child(pl)
	pl.respawn(Vector2(40, 140), 0)
	pl.input_enabled = false
	pl.aim_override = Vector2.RIGHT
