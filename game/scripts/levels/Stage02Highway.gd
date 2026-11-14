extends StageBase

const K := EnemyBase.Kind


func _init() -> void:
	stage_index = 2
	has_lanes = true
	bottom_row = 32
	kill_y = 330.0
	bounds = Rect2i(0, -10, 124, 25)
	spawn_point = Vector2(3 * T, 9 * T)


func build() -> void:
	building(0, 30, 11)
	overpass(6, 40, 6)
	enemy(K.SNIPER, 24, 6, 1, 0)
	enemy(K.TURRET, 27, 11, 0, 0)
	zring(14, 8.5)
	prop("banner_big", 4, 13.0)
	prop("hotel-sign", 19, 13.0)
	prop("control-box-2", 10, 10.1)

	checkpoint(32, 11)
	building(32, 43, 11)
	building(49, 62, 11)
	overpass(42, 66, 6)
	zring(38, 8.5)
	enemy(K.SNIPER, 46, 6, 1, 1)
	enemy(K.TURRET, 54, 6, 1, 1)
	enemy(K.DRONE, 58, 2.5, 1, 1, {"patrol": 18.0})
	enemy(K.TURRET, 60, 11, 0, 1)
	zring(64, 4.0, Vector2(0, -260))
	prop("banner_neon", 36, 12.6)
	prop("banner_coke", 52, 13.0)
	trigger(Rect2(45, -10, 1, 30), "ambush")

	checkpoint(66, 11)
	building(64, 92, 11)
	wall(76, 78, 2, 10)
	overpass(70, 96, 6)
	enemy(K.DRONE, 70, 7.0, 0, 2, {"patrol": 10.0})
	enemy(K.DRONE, 73, 4.5, 0, 2, {"patrol": 8.0})
	enemy(K.SNIPER, 84, 6, 1, 2)
	enemy(K.TURRET, 88, 11, 0, 2)
	zring(74, 8.5)
	zring(86, 4.0, Vector2(0, -240))
	trigger(Rect2(68, -10, 1, 30), "wallslam")
	prop("banner_side", 77, 7.0)
	prop("monitor", 80, 13.0)

	checkpoint(94, 11)
	building(94, 118, 11)
	overpass(98, 118, 6)
	wall(119, 123, -10, 11)
	enemy(K.SNIPER, 112, 6, 1, 3)
	enemy(K.HEAVY, 109, 11, 0, 3, {"module": true, "patrol": 48.0})
	trigger(Rect2(97, -10, 1, 30), "heavy")
	prop("banner_big", 120.5, 6.0)
	prop("banner_sushi", 103, 12.8)

	add_traffic(10, -40.0, 70.0, 110.0)


func start() -> void:
	dialogue.emit("s2_intro")


func on_trigger(id: String) -> void:
	match id:
		"ambush":
			dialogue.emit("s2_ambush")
		"wallslam":
			dialogue.emit("s2_wallslam")
		"heavy":
			dialogue.emit("s2_heavy")


func on_lane_switched(new_lane: int) -> void:
	if new_lane == 1 and GameState.once("s2_first_lane"):
		dialogue.emit("s2_first_lane")
