class_name StageBase
extends Node2D
## Builds a stage in code from the Ansimuz Warped City tileset: buildings, catwalks, two depth
## lanes (foreground layer 1 / background layer 2), props, traffic, rain, parallax, enemies by room,
## checkpoints for the 0.3s VHS rewind, dialogue triggers, Z-rings and the module carrier.
## Subclasses override build() and on_trigger().

signal dialogue(id: String)
signal module_collected(stage_index: int)
signal stage_finished(stage_index: int)

const T: int = 16
const BG_TINT: Color = Color(0.62, 0.72, 0.95)
const ANIM_PROPS: Dictionary = {
	"banner_big": ["banner-big/banner-big-%d.png", 4],
	"banner_coke": ["banner-coke/banner-coke-%d.png", 3],
	"banner_neon": ["banner-neon/banner-neon-%d.png", 4],
	"banner_scroll": ["banner-scroll/banner-scroll-%d.png", 4],
	"banner_side": ["banner-side/banner-side-%d.png", 4],
	"banner_sushi": ["banner-sushi/banner-sushi-%d.png", 3],
	"monitor": ["monitorface/monitor-face-%d.png", 4],
}
const STATIC_PROPS: PackedStringArray = [
	"antenna", "banner-arrow", "banner-floor", "banner-open", "banner-small", "banners",
	"control-box-1", "control-box-2", "control-box-3", "hotel-sign",
]
const VEHICLES: PackedStringArray = ["v-police", "v-red", "v-truck", "v-yellow"]

static var current: StageBase
static var _tileset: TileSet

var stage_index: int = 1
var has_lanes: bool = false
var kill_y: float = 600.0
var bottom_row: int = 40
var bounds: Rect2i = Rect2i(0, -10, 120, 40)
var music: String = "stage"
var spawn_point: Vector2 = Vector2(48, 160)
var spawn_lane: int = 0
var camera_mode: String = "follow"
var parallax_mode: String = "street"

var checkpoint_pos: Vector2
var checkpoint_lane: int = 0
var current_room: int = 0

var tiles_fg: TileMapLayer
var tiles_bg: TileMapLayer
var solids: Node2D
var props: Node2D
var enemies_node: Node2D
var projectiles_node: Node2D
var fx: Node2D
var triggers_node: Node2D
var world_text: Node2D
var traffic: Node2D

var _enemy_defs: Array[Dictionary] = []
var _live: Dictionary = {}
var _checkpoints: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()
var _traffic_items: Array[Dictionary] = []
var _module_spawned: bool = false
var _echo_cd: float = 6.0


static func spawn(node: Node) -> void:
	if current != null and is_instance_valid(current):
		current.projectiles_node.add_child.call_deferred(node)


func _ready() -> void:
	current = self
	_rng.seed = 1000 + stage_index
	_make_layers()
	_build_parallax()
	build()
	checkpoint_pos = spawn_point
	checkpoint_lane = spawn_lane
	_spawn_rooms_from(0)
	var rain := Rain.new()
	rain.z_index = 35
	add_child(rain)


func _exit_tree() -> void:
	if current == self:
		current = null


func _process(delta: float) -> void:
	_update_traffic(delta)
	if GameState.tier >= GameState.Tier.OVERCLOCKED:
		_echo_cd -= delta
		if _echo_cd <= 0.0:
			_echo_cd = randf_range(5.0, 8.0)
			var frag: String = DialogueData.ECHO_FRAGMENTS[randi() % DialogueData.ECHO_FRAGMENTS.size()]
			burn_text(frag, 0.6)


## Override in stages.
func build() -> void:
	pass


func on_trigger(_id: String) -> void:
	pass


func on_enemy_killed(_e: EnemyBase) -> void:
	pass


func start() -> void:
	pass


# ================================================================= layers

func _make_layers() -> void:
	traffic = _node("Traffic", -9)
	tiles_bg = TileMapLayer.new()
	tiles_bg.name = "TilesBG"
	tiles_bg.tile_set = _get_tileset()
	tiles_bg.z_index = -6
	tiles_bg.modulate = BG_TINT
	add_child(tiles_bg)
	world_text = _node("WorldText", -3)
	props = _node("Props", -1)
	tiles_fg = TileMapLayer.new()
	tiles_fg.name = "TilesFG"
	tiles_fg.tile_set = _get_tileset()
	tiles_fg.z_index = 0
	add_child(tiles_fg)
	solids = _node("Solids", 0)
	triggers_node = _node("Triggers", 0)
	enemies_node = _node("Enemies", 0)
	projectiles_node = _node("Projectiles", 0)
	fx = _node("FX", 20)


func _node(n: String, z: int) -> Node2D:
	var node := Node2D.new()
	node.name = n
	node.z_index = z
	add_child(node)
	return node


static func _get_tileset() -> TileSet:
	if _tileset != null:
		return _tileset
	var ts := TileSet.new()
	ts.tile_size = Vector2i(T, T)
	var src := TileSetAtlasSource.new()
	src.texture = load("res://assets/warped_city/tileset.png")
	src.texture_region_size = Vector2i(T, T)
	ts.add_source(src, 0)
	for y: int in 16:
		for x: int in 24:
			src.create_tile(Vector2i(x, y))
	_tileset = ts
	return ts


func _layer(lane: int) -> TileMapLayer:
	return tiles_bg if lane == 1 else tiles_fg


func _cell(lane: int, c: int, r: int, atlas: Vector2i) -> void:
	_layer(lane).set_cell(Vector2i(c, r), 0, atlas)


# ================================================================= geometry API (tile units)

func building(c0: int, c1: int, top: int, lane: int = 0, deco: bool = true, bottom: int = -9999, one_way: bool = false) -> void:
	## A block from `top` down to `bottom` (default: the stage's bottom row, i.e. off-screen).
	var layer_bit: int = GameState.BIT_WORLD_BG if lane == 1 else GameState.BIT_WORLD_FG
	var bot: int = bottom_row if bottom == -9999 else bottom
	_roof(c0, c1, top, lane)
	for r: int in range(top + 1, bot + 1):
		var k: int = (r - top - 1) % 3
		_cell(lane, c0, r, Vector2i(1, 1 + k))
		_cell(lane, c1, r, Vector2i(7, 1 + k))
		for c: int in range(c0 + 1, c1):
			_cell(lane, c, r, Vector2i(4, 4))
	if deco and c1 - c0 >= 4 and bot - top > 6:
		_decorate(c0 + 1, c1 - 1, top + 1, lane, bot)
	if one_way:
		_solid_rect(Rect2(c0 * T, top * T + 1, (c1 - c0 + 1) * T, 6), layer_bit, true)
	else:
		_solid_rect(Rect2(c0 * T, top * T + 1, (c1 - c0 + 1) * T, (bot - top + 1) * T), layer_bit, false)


func overpass(c0: int, c1: int, row: int, lane: int = 1) -> void:
	## Thin elevated deck (3 rows) with support pylons every 6 columns.
	building(c0, c1, row, lane, false, row + 2, true)
	var c: int = c0 + 3
	while c < c1 - 1:
		for r: int in range(row + 3, row + 9):
			_cell(lane, c, r, Vector2i(12, 1 + (r - row - 3) % 3))
		c += 6


func catwalk(c0: int, c1: int, row: int, lane: int = 0, poles: bool = true) -> void:
	var layer_bit: int = GameState.BIT_WORLD_BG if lane == 1 else GameState.BIT_WORLD_FG
	_roof(c0, c1, row, lane)
	if poles:
		for c: int in [c0 + 1, c1 - 1]:
			if c > c0 and c < c1:
				_cell(lane, c, row + 1, Vector2i(12, 4))
	_solid_rect(Rect2(c0 * T, row * T + 1, (c1 - c0 + 1) * T, 6), layer_bit, true)


func wall(c0: int, c1: int, r0: int, r1: int, lane: int = 0) -> void:
	## Solid facade block for wall-slams and shaft walls.
	var layer_bit: int = GameState.BIT_WORLD_BG if lane == 1 else GameState.BIT_WORLD_FG
	for r: int in range(r0, r1 + 1):
		var k: int = (r - r0) % 4
		for c: int in range(c0, c1 + 1):
			var atlas := Vector2i(4, 4)
			if c == c0:
				atlas = Vector2i(1, 1 + (r - r0) % 3)
			elif c == c1:
				atlas = Vector2i(7, 1 + (r - r0) % 3)
			elif (c1 - c0) >= 2 and k < 4 and (c - c0) % 3 == 1:
				atlas = Vector2i(9 + ((c - c0) / 3) % 2, 1 + k)
			_cell(lane, c, r, atlas)
	_solid_rect(Rect2(c0 * T, r0 * T, (c1 - c0 + 1) * T, (r1 - r0 + 1) * T), layer_bit, false)


func _roof(c0: int, c1: int, row: int, lane: int) -> void:
	for c: int in range(c0, c1 + 1):
		var atlas := Vector2i(7 + (c % 2), 11)
		if c == c0:
			atlas = Vector2i(6, 11)
		elif c == c1:
			atlas = Vector2i(9, 11)
		_cell(lane, c, row, atlas)


func _decorate(c0: int, c1: int, r0: int, lane: int, bot: int) -> void:
	var r: int = r0 + 1
	while r + 4 <= bot - 2:
		var c: int = c0
		while c + 2 <= c1:
			var roll: float = _rng.randf()
			if roll < 0.35:
				_stamp(lane, c, r, Vector2i(3, 1), Vector2i(3, 4))
				c += 4
			elif roll < 0.5:
				var lit_row: int = [1, 6, 11][_rng.randi() % 3]
				_stamp(lane, c, r, Vector2i(14, lit_row), Vector2i(3, 4))
				c += 4
			elif roll < 0.62:
				_stamp(lane, c, r, Vector2i(12, 1), Vector2i(1, 4))
				c += 2
			elif roll < 0.72:
				_stamp(lane, c, r + 1, Vector2i(11, 9), Vector2i(2, 2))
				c += 3
			elif roll < 0.8:
				_stamp(lane, c, r, Vector2i([18, 20, 22][_rng.randi() % 3], 6), Vector2i(1, 2))
				c += 2
			else:
				c += 2
		r += 5


func _stamp(lane: int, c: int, r: int, atlas: Vector2i, size: Vector2i) -> void:
	for y: int in size.y:
		for x: int in size.x:
			_cell(lane, c + x, r + y, atlas + Vector2i(x, y))


func _solid_rect(rect: Rect2, layer_bit: int, one_way: bool) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = layer_bit
	body.collision_mask = 0
	if one_way:
		body.set_meta("one_way", true)
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	cs.shape = shape
	cs.position = rect.position + rect.size * 0.5
	cs.one_way_collision = one_way
	cs.one_way_collision_margin = 4.0
	body.add_child(cs)
	solids.add_child(body)


# ================================================================= props, traffic, text

func prop(name_id: String, c: float, r: float, lane: int = 0) -> Node2D:
	var node: Node2D
	if ANIM_PROPS.has(name_id):
		var def: Array = ANIM_PROPS[name_id]
		var paths: Array = []
		for i: int in int(def[1]):
			paths.append("res://assets/warped_city/props/" + (String(def[0]) % (i + 1)))
		var s := AnimatedSprite2D.new()
		s.sprite_frames = FxLib.strip_frames(paths, 6.0, true)
		s.play("default")
		s.frame = _rng.randi() % int(def[1])
		node = s
	else:
		var sp := Sprite2D.new()
		sp.texture = load("res://assets/warped_city/props/%s.png" % name_id)
		node = sp
	node.position = Vector2(c * T, r * T)
	if lane == 1:
		node.modulate = BG_TINT
		node.z_index = -6
	props.add_child(node)
	return node


func add_traffic(count: int, y_min: float, y_max: float, speed: float = 70.0) -> void:
	for i: int in count:
		var sp := Sprite2D.new()
		sp.texture = load("res://assets/warped_city/vehicles/%s.png" % VEHICLES[i % VEHICLES.size()])
		var dir: float = 1.0 if i % 2 == 0 else -1.0
		sp.flip_h = dir < 0.0
		var depth: float = _rng.randf_range(0.45, 0.8)
		sp.scale = Vector2.ONE * depth
		sp.modulate = Color(0.55, 0.6, 0.9).lerp(Color.WHITE, depth - 0.4)
		sp.position = Vector2(_rng.randf_range(bounds.position.x * T, bounds.end.x * T), _rng.randf_range(y_min, y_max))
		traffic.add_child(sp)
		_traffic_items.append({"node": sp, "speed": speed * dir * depth * _rng.randf_range(0.8, 1.4)})


func _update_traffic(delta: float) -> void:
	var left: float = bounds.position.x * T - 200.0
	var right: float = bounds.end.x * T + 200.0
	for item: Dictionary in _traffic_items:
		var n: Sprite2D = item["node"]
		n.position.x += float(item["speed"]) * delta
		if n.position.x > right:
			n.position.x = left
		elif n.position.x < left:
			n.position.x = right


func burn_text(text: String, intensity: float = 1.0) -> void:
	var cam: Camera2D = JuiceManager.camera
	var center: Vector2 = cam.get_screen_center_position() if cam else Vector2.ZERO
	var g := WorldGlitchText.new()
	g.text = text
	g.intensity = intensity
	world_text.add_child(g)
	## Upper-middle band: below the comms line, above the player's head; whole pixels only.
	g.global_position = (center + Vector2(0, -36 + randf_range(-4, 4))).round()
	AudioManager.play_sfx("echo_glitch", 0.75)


# ================================================================= enemies & rooms

func enemy(kind: int, c: float, r: float, lane: int = 0, room: int = 0, opts: Dictionary = {}) -> void:
	_enemy_defs.append({"kind": kind, "c": c, "r": r, "lane": lane, "room": room, "opts": opts})


func checkpoint(c: float, r: float, lane: int = 0, trigger_rect: Rect2 = Rect2()) -> void:
	## Room boundary. Entering it moves the rewind point here and locks earlier rooms as cleared.
	var idx: int = _checkpoints.size() + 1
	var pos := Vector2(c * T, r * T - 20.0)
	_checkpoints.append({"pos": pos, "lane": lane})
	var rect: Rect2 = trigger_rect
	if rect.size == Vector2.ZERO:
		rect = Rect2(c * T - 8, -2000, 16, 4000)
	_area(rect, func() -> void: _enter_room(idx), false)


func trigger(rect_tiles: Rect2, id: String) -> void:
	var rect := Rect2(rect_tiles.position * T, rect_tiles.size * T)
	_area(rect, func() -> void: on_trigger(id), true)


func zring(c: float, r: float, impulse: Vector2 = Vector2(0, -340)) -> void:
	var z := ZRing.new()
	z.impulse = impulse
	z.position = Vector2(c * T, r * T)
	triggers_node.add_child(z)


func _area(rect: Rect2, cb: Callable, once: bool) -> void:
	var a := Area2D.new()
	a.collision_layer = 0
	a.collision_mask = GameState.BIT_PLAYER_HURT
	a.monitorable = false
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	cs.shape = shape
	cs.position = rect.position + rect.size * 0.5
	a.add_child(cs)
	triggers_node.add_child(a)
	var fired: Array[bool] = [false]
	a.area_entered.connect(func(other: Area2D) -> void:
		if not (other.get_meta("entity", null) is Player):
			return
		if once and fired[0]:
			return
		fired[0] = true
		cb.call())


func _enter_room(idx: int) -> void:
	if idx <= current_room:
		return
	current_room = idx
	var cp: Dictionary = _checkpoints[idx - 1]
	checkpoint_pos = cp["pos"]
	checkpoint_lane = cp["lane"]


func _spawn_rooms_from(room: int) -> void:
	for i: int in _enemy_defs.size():
		var d: Dictionary = _enemy_defs[i]
		if int(d["room"]) < room:
			continue
		if _live.has(i) and is_instance_valid(_live[i]):
			continue
		_live[i] = _spawn_def(d)


func _spawn_def(d: Dictionary) -> EnemyBase:
	var kind: int = d["kind"]
	var pos := Vector2(float(d["c"]) * T, float(d["r"]) * T)
	var e := EnemyBase.create(kind, pos, d["lane"], d["opts"])
	if kind in [EnemyBase.Kind.ENFORCER, EnemyBase.Kind.HEAVY]:
		var bs: float = 1.35 if kind == EnemyBase.Kind.HEAVY else 1.0
		e.position.y -= 20.0 * bs * (EnemyBase.BG_SCALE if int(d["lane"]) == 1 else 1.0)
	e.killed.connect(_on_killed)
	enemies_node.add_child(e)
	return e


func reset_room() -> void:
	## Called on rewind: enemies of the current and later rooms come back, projectiles vanish.
	for p: Node in projectiles_node.get_children():
		p.queue_free()
	for i: int in _enemy_defs.size():
		var d: Dictionary = _enemy_defs[i]
		if int(d["room"]) >= current_room and _live.has(i) and is_instance_valid(_live[i]):
			_live[i].queue_free()
			_live.erase(i)
	_spawn_rooms_from.call_deferred(current_room)


func _on_killed(e: EnemyBase) -> void:
	if e.carries_module and not _module_spawned:
		_module_spawned = true
		_spawn_module(e.global_position + Vector2(0, -10))
	on_enemy_killed(e)


func _spawn_module(pos: Vector2) -> void:
	var m := ModulePickup.new()
	m.stage_index = stage_index
	m.position = pos
	m.collected.connect(func() -> void: module_collected.emit(stage_index))
	triggers_node.add_child.call_deferred(m)


func enemies_alive_in_room(room: int) -> int:
	var n: int = 0
	for i: int in _enemy_defs.size():
		if int(_enemy_defs[i]["room"]) == room and _live.has(i) and is_instance_valid(_live[i]) and _live[i].alive:
			n += 1
	return n


# ================================================================= parallax

func _build_parallax() -> void:
	var pb := ParallaxBackground.new()
	pb.layer = -10
	add_child(pb)
	var vertical: bool = parallax_mode == "shaft"
	_par_layer(pb, "skyline-a", Vector2(0.08, 0.04 if vertical else 0.0), Vector2(0, 0), Vector2(1024, 240), vertical)
	_par_layer(pb, "buildings-bg", Vector2(0.25, 0.1 if vertical else 0.0), Vector2(0, 116), Vector2(1008, 124), vertical)
	_par_layer(pb, "near-buildings-bg", Vector2(0.45, 0.22 if vertical else 0.0), Vector2(0, 31), Vector2(986, 209), vertical)


func _par_layer(pb: ParallaxBackground, tex: String, motion: Vector2, offset: Vector2, size: Vector2, vertical: bool) -> void:
	var layer := ParallaxLayer.new()
	layer.motion_scale = motion
	layer.motion_mirroring = Vector2(size.x, size.y if vertical else 0.0)
	pb.add_child(layer)
	var tr := TextureRect.new()
	tr.texture = load("res://assets/warped_city/background/%s.png" % tex)
	tr.stretch_mode = TextureRect.STRETCH_TILE
	tr.position = offset
	tr.size = size if not vertical else Vector2(size.x, size.y)
	layer.add_child(tr)
	if tex == "near-buildings-bg":
		layer.modulate = Color(0.85, 0.85, 1.0)
