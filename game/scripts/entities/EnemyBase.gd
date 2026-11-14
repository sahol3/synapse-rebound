class_name EnemyBase
extends Node2D

signal killed(enemy: EnemyBase)
signal sniper_locked

enum Kind { TURRET, DRONE, SNIPER, ENFORCER, HEAVY, DEFLECTOR, WING }
static var _last_scream_ms: int = -100000

const BG_SCALE: float = 0.78
const BG_TINT: Color = Color(0.65, 0.75, 0.95)
const SHIELD_COLOR: Color = Color("#FF0055")
const SV: String = "res://assets/sideview_scifi/"
const SKINS: Dictionary = {
	"marine": {
		"anims": [["idle", "space-marine-idle.png", 48, 48, 4, 7.0, 0, 48], ["walk", "space-marine-run.png", 48, 48, 11, 14.0, 0, 48],
				["shoot", "space-marine-shoot.png", 64, 48, 2, 12.0, 7, 48]],
		"pos": Vector2(6, -4), "faces": 1, "hurt": Vector2(16, 32), "hurt_pos": Vector2(0, 3),
		"shield": 23.0, "shield_pos": Vector2(0, 2), "muzzle": Vector2(14, -3),
	},
	"bipedal": {
		"anims": [["idle", "bipedal-unit.png", 80, 64, 1, 1.0, 0, 80], ["walk", "bipedal-unit.png", 80, 64, 7, 10.0, 0, 80],
				["shoot", "bipedal-unit.png", 80, 64, 1, 1.0, 0, 80]],
		"pos": Vector2(2, -12), "faces": 1, "hurt": Vector2(28, 50), "hurt_pos": Vector2(0, -6),
		"shield": 33.0, "shield_pos": Vector2(0, -8), "muzzle": Vector2(12, -14),
	},
	"mech": {
		"anims": [["idle", "mech-unit.png", 96, 80, 1, 1.0, 0, 96], ["walk", "mech-unit.png", 96, 80, 10, 9.0, 0, 96],
				["shoot", "mech-unit.png", 96, 80, 1, 1.0, 0, 96]],
		"pos": Vector2(4, -13), "faces": 1, "hurt": Vector2(30, 56), "hurt_pos": Vector2(0, -2),
		"shield": 37.0, "shield_pos": Vector2(0, -5), "muzzle": Vector2(16, -12),
	},
	"tank": {
		"anims": [["default", "tank-unit.png", 128, 64, 4, 8.0, 0, 128]],
		"pos": Vector2(0, -32), "faces": 1, "hurt": Vector2(70, 36), "hurt_pos": Vector2(0, -20),
		"shield": 0.0, "shield_pos": Vector2.ZERO, "muzzle": Vector2(53, -34),
	},
	"wasp": {
		"anims": [["default", "alien-enemy-flying%d.png", 83, 64, 8, 12.0, 0, 83]],
		"pos": Vector2(-8, 2), "faces": -1, "hurt": Vector2(40, 40), "hurt_pos": Vector2.ZERO,
		"shield": 34.0, "shield_pos": Vector2.ZERO, "muzzle": Vector2.ZERO,
	},
}

var kind: int = Kind.TURRET
var lane: int = 0
var lane_agnostic: bool = false
var alive: bool = true
var hp: int = 1
var shielded: bool = false
var room: int = 0
var carries_module: bool = false
var fire_interval: float = 1.8
var fire_range: float = 270.0
var shot_speed: float = 135.0
var patrol: float = 0.0
var base_scale: float = 1.0
var active: bool = true
var skin: String = ""

var _fire_t: float = 1.0
var _charge_t: float = 0.0
var _charge_full: float = 0.45
var _anchor: Vector2
var _t: float = 0.0
var _shove: Vector2 = Vector2.ZERO
var _stun: float = 0.0
var _dir: int = -1
var _flash_t: float = 0.0
var _shield_flash: float = 0.0
var _sniper_state: int = 0
var _sniper_t: float = 0.0
var _lock_point: Vector2

var _body: Node2D
var _sprite: AnimatedSprite2D
var _flash_mat: ShaderMaterial
var _hurtbox: Area2D
var _laser: Line2D
var _overlay: Node2D


static func create(p_kind: int, pos: Vector2, p_lane: int = 0, opts: Dictionary = {}) -> EnemyBase:
	var e := EnemyBase.new()
	e.kind = p_kind
	e.position = pos
	e.lane = p_lane
	e.room = int(opts.get("room", 0))
	e.carries_module = bool(opts.get("module", false))
	e.patrol = float(opts.get("patrol", 0.0))
	if opts.has("interval"):
		e.fire_interval = float(opts["interval"])
	e.skin = String(opts.get("skin", ""))
	return e


func _ready() -> void:
	add_to_group("enemies")
	_anchor = position
	_t = randf() * 10.0
	_configure()
	_body = Node2D.new()
	add_child(_body)
	_sprite = AnimatedSprite2D.new()
	_flash_mat = ShaderMaterial.new()
	_flash_mat.shader = load("res://shaders/hit_flash.gdshader")
	_sprite.material = _flash_mat
	_body.add_child(_sprite)
	_build_sprite()
	_hurtbox = Area2D.new()
	_hurtbox.collision_layer = GameState.BIT_ENEMY_HURT
	_hurtbox.collision_mask = 0
	_hurtbox.monitoring = false
	_hurtbox.set_meta("entity", self)
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = _hurt_size()
	cs.shape = rect
	if skin != "":
		cs.position = SKINS[skin]["hurt_pos"]
	elif kind in [Kind.TURRET, Kind.WING]:
		cs.position = Vector2(0, -10)
	_hurtbox.add_child(cs)
	add_child(_hurtbox)
	_laser = Line2D.new()
	_laser.width = 1.0
	_laser.default_color = Color(1, 0.05, 0.2, 0.0)
	_laser.top_level = true
	_laser.z_index = 15
	add_child(_laser)
	_overlay = Node2D.new()
	_overlay.z_index = 2
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)
	_fire_t = fire_interval * randf_range(0.5, 1.0) * Director.fire_interval_mult()
	_apply_lane_visual()


func _configure() -> void:
	if skin == "":
		skin = String({Kind.ENFORCER: "marine", Kind.HEAVY: "mech", Kind.SNIPER: "tank", Kind.DEFLECTOR: "wasp"}.get(kind, ""))
	match kind:
		Kind.TURRET:
			hp = 1
			fire_interval = 1.7
			shot_speed = 140.0
		Kind.DRONE:
			hp = 1
			fire_interval = 2.3
			shot_speed = 125.0
			if patrol == 0.0:
				patrol = 40.0
		Kind.SNIPER:
			hp = 1
			fire_range = 520.0
			lane_agnostic = false
			_sniper_t = 2.2
		Kind.ENFORCER:
			hp = 1
			shielded = true
			fire_interval = 2.1
			shot_speed = 115.0
			fire_range = 300.0
		Kind.HEAVY:
			hp = 6
			shielded = true
			fire_interval = 2.3
			shot_speed = 110.0
			fire_range = 320.0
			base_scale = 1.35
		Kind.DEFLECTOR:
			hp = 1
			shielded = true
			fire_interval = 2.0
			shot_speed = 135.0
			if patrol == 0.0:
				patrol = 30.0
		Kind.WING:
			hp = 2
			fire_interval = 1.5
			shot_speed = 150.0
			fire_range = 600.0


func _build_sprite() -> void:
	if skin != "":
		_sprite.sprite_frames = _skin_frames(SKINS[skin])
		_sprite.position = SKINS[skin]["pos"]
		_sprite.play("default" if _sprite.sprite_frames.has_animation("default") else "idle")
		_body.scale = Vector2.ONE
		return
	match kind:
		Kind.TURRET, Kind.WING:
			_sprite.sprite_frames = FxLib.frames("turret")
			_sprite.position = Vector2(0, -11)
			if kind == Kind.WING:
				_sprite.modulate = Color(1.3, 0.6, 1.2)
		_:
			_sprite.sprite_frames = FxLib.frames("drone")
	_sprite.play("default" if _sprite.sprite_frames.has_animation("default") else "idle")
	_body.scale = Vector2.ONE * base_scale


func _hurt_size() -> Vector2:
	if skin != "":
		return SKINS[skin]["hurt"]
	match kind:
		Kind.DRONE, Kind.DEFLECTOR:
			return Vector2(30, 22)
		Kind.ENFORCER:
			return Vector2(16, 34)
		Kind.HEAVY:
			return Vector2(22, 46)
	return Vector2(20, 18)


func _physics_process(delta: float) -> void:
	if not alive:
		return
	_t += delta
	_stun -= delta
	_flash_t -= delta
	_shield_flash -= delta
	if _flash_t <= 0.0:
		_flash_mat.set_shader_parameter("active", false)
	if _shove.length() > 1.0:
		match kind:
			Kind.DRONE, Kind.DEFLECTOR:
				position += _shove * delta
			Kind.ENFORCER, Kind.HEAVY:
				position.x = clampf(position.x + _shove.x * delta, _anchor.x - patrol, _anchor.x + patrol)
			_:
				pass
		_shove = _shove.move_toward(Vector2.ZERO, 600.0 * delta)
	var player: Player = _player()
	match kind:
		Kind.DRONE, Kind.DEFLECTOR:
			position = position.lerp(_anchor + Vector2(sin(_t * 0.9) * patrol, sin(_t * 2.1) * 6.0), clampf(delta * 4.0, 0.0, 1.0))
			_face(player)
		Kind.ENFORCER, Kind.HEAVY:
			_walk(delta, player)
		Kind.TURRET, Kind.WING, Kind.SNIPER:
			_face(player)
	if kind == Kind.SNIPER:
		_sniper_logic(delta, player)
	elif active:
		_fire_logic(delta, player)
	if skin != "":
		_sprite.position.x = float(SKINS[skin]["pos"].x) * (-1.0 if _sprite.flip_h else 1.0)
	_overlay.queue_redraw()


func _face(player: Player) -> void:
	if player == null:
		return
	var player_right: bool = player.global_position.x > global_position.x
	var art_faces: int = int(SKINS[skin]["faces"]) if skin != "" else -1
	_sprite.flip_h = player_right if art_faces < 0 else not player_right


func _facing_sign() -> float:
	var art_faces: float = float(SKINS[skin]["faces"]) if skin != "" else -1.0
	return -art_faces if _sprite.flip_h else art_faces


func _walk(delta: float, player: Player) -> void:
	if player == null:
		return
	var dx: float = player.global_position.x - global_position.x
	_sprite.flip_h = dx < 0.0
	if patrol <= 0.0 or _stun > 0.0 or _charge_t > 0.0:
		var pose: String = "shoot" if _charge_t > 0.0 and _sprite.sprite_frames.has_animation("shoot") else "idle"
		if _sprite.animation != pose:
			_sprite.play(pose)
		return
	var want: float = 0.0
	if absf(dx) > 150.0:
		want = signf(dx)
	elif absf(dx) < 90.0:
		want = -signf(dx)
	var nx: float = clampf(position.x + want * 28.0 * delta, _anchor.x - patrol, _anchor.x + patrol)
	var moving: bool = absf(nx - position.x) > 0.01
	position.x = nx
	var anim: String = "walk" if moving else "idle"
	if _sprite.animation != anim:
		_sprite.play(anim)


func _fire_logic(delta: float, player: Player) -> void:
	if player == null or player.dead or _stun > 0.0:
		_charge_t = 0.0
		return
	var can_see: bool = _can_target(player)
	if can_see and player.in_blackout and Director.claim_mercy():
		_charge_t = 0.0
		_fire(player, true)
		_fire_t = fire_interval * Director.fire_interval_mult()
		return
	if _charge_t > 0.0:
		_charge_t -= delta
		if int(_charge_t * 20.0) % 2 == 0:
			_flash(Color(1, 1, 1), 0.03)
		if _charge_t <= 0.0:
			if can_see:
				_fire(player)
			_fire_t = fire_interval * randf_range(0.85, 1.15) * Director.fire_interval_mult()
		return
	_fire_t -= delta
	if _fire_t <= 0.0 and can_see and Director.may_fire():
		_charge_t = Director.charge_time()
		_charge_full = _charge_t
		if kind in [Kind.ENFORCER, Kind.HEAVY] and _sprite.sprite_frames.has_animation("shoot"):
			_sprite.play("shoot")


func _can_target(player: Player) -> bool:
	if player.lane != lane and kind != Kind.WING:
		return false
	var to: Vector2 = player.chest() - global_position
	if to.length() > fire_range:
		return false
	if kind == Kind.WING:
		return true
	var space := get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(_muzzle(), player.chest(), GameState.BIT_WORLD_BG if lane == 1 else GameState.BIT_WORLD_FG)
	return space.intersect_ray(q).is_empty()


func _muzzle() -> Vector2:
	if skin != "":
		var m: Vector2 = SKINS[skin]["muzzle"]
		return global_position + Vector2(m.x * _facing_sign(), m.y) * _lane_scale()
	match kind:
		Kind.TURRET, Kind.WING, Kind.SNIPER:
			return global_position + Vector2(0, -14) * _lane_scale()
		Kind.ENFORCER, Kind.HEAVY:
			return global_position + Vector2(0, -6) * base_scale * _lane_scale()
	return global_position


func _fire(player: Player, mercy: bool = false) -> void:
	var from: Vector2 = _muzzle()
	var speed: float = shot_speed
	var aim: Vector2 = Director.aim_point(player, from, shot_speed * Director.shot_speed_mult())
	if mercy:
		var dist: float = from.distance_to(player.chest())
		speed = Director.mercy_speed(dist)
		aim = player.chest() + player.velocity * (dist / speed) * 0.6
	var dir: Vector2 = (aim - from).normalized()
	var heavy: bool = kind in [Kind.ENFORCER, Kind.HEAVY] and not mercy
	var spread: Array = [0.0]
	if kind == Kind.HEAVY and not mercy:
		spread = [-0.12, 0.12]
	for s: float in spread:
		var opts: Dictionary = {"heavy": heavy, "shooter": self}
		if mercy:
			opts["homing"] = player
		var p := Projectile.make(from + dir * 8.0, dir.rotated(s) * speed, Projectile.Team.ENEMY, lane, opts)
		if mercy:
			p.set_meta("mercy", true)
		StageBase.spawn(p)
	AudioManager.play_sfx("heavy_shot" if heavy else "shot", randf_range(0.9, 1.1))
	JuiceManager.fx("star", "magenta", from, 0.0, 0.8)


func _sniper_logic(delta: float, player: Player) -> void:
	_sniper_t -= delta
	match _sniper_state:
		0:
			_laser.default_color.a = 0.0
			if _sniper_t <= 0.0 and player != null and not player.dead and _stun <= 0.0 \
					and global_position.distance_to(player.global_position) < fire_range:
				_sniper_state = 1
				_sniper_t = 1.1 * Director.charge_time() / 0.45
				AudioManager.play_sfx("laser_lock")
				sniper_locked.emit()
				if GameState.has_mod("chrono_sight"):
					JuiceManager.slowmo(0.7, 0.5)
		1:
			if player:
				_lock_point = player.chest()
			_laser_line(0.35 + 0.3 * sin(_t * 30.0), 1.0)
			if _sniper_t <= 0.0:
				_sniper_state = 2
				_sniper_t = 0.25
		2:
			_laser_line(1.0, 2.0)
			if _sniper_t <= 0.0:
				_sniper_state = 0
				_sniper_t = 2.2 * Director.fire_interval_mult()
				_laser.default_color.a = 0.0
				if player and not player.dead:
					var from: Vector2 = _muzzle()
					var dir: Vector2 = (_lock_point - from).normalized()
					var p := Projectile.make(from, dir * 300.0, Projectile.Team.ENEMY, player.lane,
							{"shooter": self, "origin_lane": lane})
					StageBase.spawn(p)
					AudioManager.play_sfx("heavy_shot", 1.4)
					JuiceManager.fx("star", "magenta", from, 0.0, 1.2)


func _laser_line(alpha: float, width: float) -> void:
	_laser.clear_points()
	_laser.add_point(_muzzle())
	_laser.add_point(_lock_point)
	_laser.width = width
	_laser.default_color = Color(1, 0.05, 0.2, alpha)


func receive_projectile(p: Projectile) -> String:
	if not alive:
		return "ignore"
	if shielded and not p.rail:
		_reflect(p)
		return "reflect"
	take_damage(p.damage, p)
	return "hit"


func _reflect(p: Projectile) -> void:
	var player: Player = _player()
	var target: Vector2 = player.chest() if player else global_position + Vector2(-100, 0)
	var dir: Vector2 = (target - global_position).normalized()
	p.global_position = global_position + dir * 16.0 * base_scale
	if p.lane != lane:
		p.cross_to_lane(lane)
	if player and player.lane != p.lane:
		p.cross_to_lane(player.lane)
	p.deflect(dir, false)
	_shield_flash = 0.25
	AudioManager.play_sfx("shield", 1.0 + float(p.bounce_count) * 0.14)
	JuiceManager.hitstop(0.05)
	JuiceManager.shake(0.2)
	JuiceManager.fx("ring", "magenta", p.global_position, 0.0, 1.6)
	JuiceManager.text_pop(global_position + Vector2(0, -24), "x%d RALLY" % p.bounce_count, Projectile.TINTS[mini(p.bounce_count, 3)], 8)


func take_damage(amount: int, _source: Object = null) -> void:
	if not alive:
		return
	hp -= amount
	_flash(Color(1, 1, 1), 0.08)
	JuiceManager.shake(0.15)
	if hp <= 0:
		die()
	elif kind == Kind.HEAVY:
		JuiceManager.text_pop(global_position + Vector2(0, -36), "SHIELD %d%%" % int(100.0 * float(hp) / 6.0), Color("#FF9900"), 8)


func die() -> void:
	if not alive:
		return
	alive = false
	remove_from_group("enemies")
	_laser.visible = false
	var pos: Vector2 = global_position
	var big: float = 1.6 if kind == Kind.HEAVY else 1.0
	FxLib.spawn(JuiceManager.fx_root, "explosion", "", pos, 0.0, big * _lane_scale(), Color(1.2, 1.2, 1.2), -2 if lane == 1 else 22)
	JuiceManager.fx("debris", "gold", pos, 0.0, 2.0 * big)
	JuiceManager.ring(pos, Color("#FF9900"), 40.0 * big, 0.3, 3.0)
	JuiceManager.hitstop(0.06)
	JuiceManager.shake(0.35 * big)
	AudioManager.play_sfx("explosion", randf_range(0.85, 1.1))
	if (kind == Kind.ENFORCER or kind == Kind.SNIPER) and randf() < 0.17 \
			and Time.get_ticks_msec() - _last_scream_ms > 25000:
		_last_scream_ms = Time.get_ticks_msec()
		AudioManager.play_sfx("meme_scream", randf_range(0.96, 1.04))
	GameState.register_kill()
	killed.emit(self)
	queue_free()


func shove(v: Vector2) -> void:
	_shove = v
	_stun = 0.7
	_charge_t = 0.0


func _flash(color: Color, dur: float) -> void:
	_flash_mat.set_shader_parameter("flash_color", color)
	_flash_mat.set_shader_parameter("active", true)
	_flash_t = dur


func _player() -> Player:
	var p: Node = get_tree().get_first_node_in_group("player")
	return p as Player


func _lane_scale() -> float:
	return BG_SCALE if lane == 1 else 1.0


func _apply_lane_visual() -> void:
	scale = Vector2.ONE * _lane_scale()
	modulate = BG_TINT if lane == 1 else Color.WHITE
	z_index = -5 if lane == 1 else 3


func set_lane(new_lane: int) -> void:
	lane = new_lane
	_apply_lane_visual()


func _draw_overlay() -> void:
	if shielded and alive:
		var r: float = (18.0 if kind != Kind.HEAVY else 30.0) * (1.0 if kind != Kind.DEFLECTOR else 1.1)
		var c: Vector2 = Vector2(0, -6 * base_scale) if kind in [Kind.ENFORCER, Kind.HEAVY] else Vector2.ZERO
		if skin != "" and float(SKINS[skin]["shield"]) > 0.0:
			r = SKINS[skin]["shield"]
			c = SKINS[skin]["shield_pos"]
		var a: float = 0.35 + 0.15 * sin(_t * 5.0) + (0.6 if _shield_flash > 0.0 else 0.0)
		var col := SHIELD_COLOR
		if kind == Kind.DEFLECTOR:
			col = Color("#FFD400")
		col.a = a
		var pts := PackedVector2Array()
		for i: int in 7:
			pts.append(c + Vector2.from_angle(TAU * float(i) / 6.0 + _t * 0.6) * r)
		_overlay.draw_polyline(pts, col, 1.5 if _shield_flash <= 0.0 else 3.0)
	if _charge_t > 0.0 and alive and kind != Kind.SNIPER:
		var player: Player = _player()
		var m: Vector2 = _muzzle() - global_position
		var k: float = 1.0 - _charge_t / maxf(_charge_full, 0.01)
		_overlay.draw_circle(m / scale, 2.0 + 4.0 * k, Color(1, 0.2, 0.8, 0.5 + 0.5 * k))
		if player and GameState.telegraph_sights():
			var to: Vector2 = (player.chest() - global_position) / scale
			_overlay.draw_dashed_line(m / scale, to, Color(1, 0.1, 0.3, 0.35 + 0.4 * k), 1.0, 4.0)


func _skin_frames(def: Dictionary) -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for a: Array in def["anims"]:
		var anim: String = a[0]
		var file: String = a[1]
		var count: int = a[4]
		sf.add_animation(anim)
		sf.set_animation_speed(anim, a[5])
		sf.set_animation_loop(anim, true)
		for i: int in count:
			if file.contains("%d"):
				sf.add_frame(anim, load(SV + (file % (i + 1))))
			else:
				var at := AtlasTexture.new()
				at.atlas = load(SV + file)
				at.region = Rect2(i * int(a[2]) + int(a[6]), 0, int(a[7]), int(a[3]))
				sf.add_frame(anim, at)
	return sf
