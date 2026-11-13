extends StageBase
## STAGE 1: THE AWAKENING ALLEY. Rain-slicked lower streets. Teaches the 360 deflection,
## aerial recoil pogo off turret fire, coyote jumps, and the first Enforcer rally.

const K := EnemyBase.Kind

var _echo_done: bool = false


func _init() -> void:
	stage_index = 1
	has_lanes = false
	bottom_row = 32
	kill_y = 330.0
	bounds = Rect2i(0, -12, 96, 27)
	spawn_point = Vector2(4 * T, 1 * T)


func build() -> void:
	# Depth decoration: tall background-lane blocks behind the gaps (no foreground collision).
	building(10, 17, 3, 1)
	building(31, 40, 2, 1)
	building(62, 72, 1, 1)
	building(86, 94, 4, 1)

	# Room 0 - the balcony and the first turret.
	building(0, 12, 10)
	building(15, 24, 10)
	enemy(K.TURRET, 21.5, 10, 0, 0)
	prop("hotel-sign", 6, 12.2)
	prop("antenna", 2, 7.0)
	prop("banner_neon", 10.5, 12.5)
	prop("control-box-1", 17, 9.05)
	trigger(Rect2(13, -10, 1, 30), "tutorial")

	# Room 1 - the wide gap: parry the drone's shot in mid-air to recoil across.
	checkpoint(26, 8)
	building(27, 33, 8)
	trigger(Rect2(31, -10, 1, 30), "pogo")
	enemy(K.DRONE, 38, 4.5, 0, 1, {"patrol": 14.0, "interval": 1.6})
	building(41, 50, 9)
	enemy(K.TURRET, 46.5, 9, 0, 1)
	prop("banner_big", 29.5, 10.2)
	prop("banner_scroll", 44, 11.4)
	prop("monitor", 48, 10.6)

	# Room 2 - climb the scaffolding under crossfire.
	checkpoint(43, 9)
	catwalk(51, 54, 7)
	building(56, 64, 5)
	enemy(K.TURRET, 61, 5, 0, 2)
	enemy(K.DRONE, 66, 1.5, 0, 2, {"patrol": 24.0})
	enemy(K.DRONE, 53, 2.5, 0, 2, {"patrol": 10.0})
	prop("banner_coke", 58, 7.2)
	prop("antenna", 63, 2.0)
	prop("banner_side", 60.5, 8.0)

	# Room 3 - drop into the arena. Syndicate Enforcer holds MODULE 01.
	checkpoint(72, 9)
	building(71, 90, 9)
	wall(91, 95, -12, 9)
	enemy(K.DRONE, 78, 4.5, 0, 3, {"patrol": 20.0})
	enemy(K.ENFORCER, 85, 9, 0, 3, {"module": true, "patrol": 40.0})
	trigger(Rect2(75, -10, 1, 30), "enforcer")
	prop("banner_sushi", 76, 10.6)
	prop("banner_neon", 82.5, 11.4)
	prop("control-box-3", 74, 8.05)
	prop("banner_big", 92.5, 4.0)

	add_traffic(6, -60.0, 70.0, 60.0)


func start() -> void:
	dialogue.emit("s1_intro")


func on_trigger(id: String) -> void:
	match id:
		"tutorial":
			dialogue.emit("s1_tutorial")
		"pogo":
			dialogue.emit("s1_pogo")
		"enforcer":
			dialogue.emit("s1_enforcer")


func on_enemy_killed(_e: EnemyBase) -> void:
	if GameState.once("s1_first_kill"):
		dialogue.emit("s1_first_kill")


func on_rewind() -> void:
	_try_echo()


func _process(delta: float) -> void:
	super._process(delta)
	if GameState.sync_rate >= 200.0:
		_try_echo()


func _try_echo() -> void:
	if _echo_done:
		return
	_echo_done = true
	dialogue.emit("s1_echo")
