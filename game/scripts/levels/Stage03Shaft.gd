extends StageBase
## STAGE 3: THE ASCENT SHAFT. A vertical megastructure elevator shaft. The floor drops away:
## anything below the climb line is gone. Air-deflection chains and gold Deflector-drone rallies.

const K := EnemyBase.Kind
const TOP_ROW: int = -104

var _highest_y: float = 1e9


func _init() -> void:
	stage_index = 3
	has_lanes = false
	bottom_row = 30
	kill_y = 1e9
	bounds = Rect2i(0, -116, 30, 138)
	spawn_point = Vector2(15 * T, 15 * T)
	parallax_mode = "shaft"
	camera_mode = "vertical"


func build() -> void:
	wall(0, 3, -116, 24)
	wall(27, 30, -116, 24)
	building(4, 26, 18)

	# Platform ladder: [c0, c1, row, room]. Spacing 4-5 rows = jump + dash, or pogo off fire.
	var plats: Array = [
		[5, 10, 14, 0], [16, 22, 10, 0], [8, 13, 6, 0], [19, 25, 2, 0],
		[5, 11, -3, 1], [15, 20, -7, 1], [21, 25, -12, 1], [8, 14, -16, 1],
		[4, 8, -21, 2], [13, 18, -25, 2], [21, 26, -30, 2], [11, 15, -35, 2], [4, 9, -40, 2],
		[14, 19, -45, 3], [22, 26, -50, 3], [12, 16, -55, 3], [4, 9, -60, 3], [16, 22, -65, 3],
		[8, 13, -70, 4], [19, 25, -75, 4], [10, 15, -80, 4], [4, 8, -85, 4], [14, 20, -90, 4],
		[21, 26, -95, 4], [10, 16, -100, 4],
	]
	for pl: Array in plats:
		catwalk(pl[0], pl[1], pl[2])

	# Enemies by room.
	enemy(K.TURRET, 19, 10, 0, 0)
	enemy(K.DRONE, 14, 1.0, 0, 0, {"patrol": 30.0})
	enemy(K.TURRET, 23.5, 2, 0, 0)

	checkpoint(8, -3, 0, Rect2(4 * T, -4 * T, 23 * T, T))
	enemy(K.DEFLECTOR, 16, -11, 0, 1, {"patrol": 40.0})
	enemy(K.TURRET, 23, -12, 0, 1)
	enemy(K.DRONE, 8, -19, 0, 1, {"patrol": 20.0})

	checkpoint(6, -21, 0, Rect2(4 * T, -22 * T, 23 * T, T))
	enemy(K.DEFLECTOR, 9, -29, 0, 2, {"patrol": 30.0})
	enemy(K.TURRET, 24, -30, 0, 2)
	enemy(K.DRONE, 20, -38, 0, 2, {"patrol": 36.0})
	enemy(K.TURRET, 6.5, -40, 0, 2)

	checkpoint(16, -45, 0, Rect2(4 * T, -46 * T, 23 * T, T))
	enemy(K.DEFLECTOR, 18, -53, 0, 3, {"patrol": 40.0})
	enemy(K.DEFLECTOR, 9, -58, 0, 3, {"patrol": 20.0})
	enemy(K.TURRET, 20, -65, 0, 3)

	checkpoint(10, -70, 0, Rect2(4 * T, -71 * T, 23 * T, T))
	enemy(K.DRONE, 15, -78, 0, 4, {"patrol": 40.0})
	enemy(K.DEFLECTOR, 18, -88, 0, 4, {"patrol": 30.0})
	enemy(K.TURRET, 23, -95, 0, 4)

	# The roof door: landing deck + Command Enforcer with MODULE 03.
	checkpoint(13, -100, 0, Rect2(4 * T, -101 * T, 23 * T, T))
	catwalk(4, 26, TOP_ROW, 0, false)
	for c: int in range(4, 27):
		_cell(0, c, TOP_ROW + 1, Vector2i(4, 4))
	enemy(K.ENFORCER, 21, TOP_ROW, 0, 5, {"module": true, "patrol": 36.0})
	enemy(K.DEFLECTOR, 9, TOP_ROW - 5, 0, 5, {"patrol": 30.0})

	for i: int in 10:
		var r: float = 12.0 - float(i) * 11.0
		prop(["banner_neon", "banner_side", "monitor", "banner_scroll", "banner_coke"][i % 5], 2.5 if i % 2 == 0 else 28.5, r)
	prop("hotel-sign", 15, TOP_ROW + 2.5)


func start() -> void:
	dialogue.emit("s3_intro")


func _process(delta: float) -> void:
	super._process(delta)
	var player: Player = get_tree().get_first_node_in_group("player") as Player
	if player and not player.dead:
		_highest_y = minf(_highest_y, player.global_position.y)
		kill_y = _highest_y + 230.0


func on_rewind() -> void:
	_highest_y = checkpoint_pos.y


func on_player_deflect(p: Projectile) -> void:
	if p.bounce_count >= 3 and GameState.once("s3_rally"):
		dialogue.emit("s3_rally")
