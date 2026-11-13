class_name Projectile
extends Area2D
## Every bullet in the game. Carries bounce_count through the Ping-Pong Death Rally:
## each bounce scales speed x1.32, size x1.15, shifts colour magenta -> cyan -> gold -> crimson
## and steps the rally ping up in pitch. Bounce 3 (or Berserk Lock) turns it into a piercing railgun.

enum Team { ENEMY, PLAYER }

const COLOR_KEYS: PackedStringArray = ["magenta", "cyan", "gold", "gold"]
const TINTS: Array[Color] = [
	Color(1.0, 0.45, 0.95), Color("#00F0FF"), Color("#FFD400"), Color("#FF1A40"),
]
const MAX_SPEED: float = 860.0
const CORE_MAX_SPEED: float = 470.0
const RAIL_SPEED: float = 940.0
const BG_SCALE: float = 0.78
const BG_TINT: Color = Color(0.65, 0.75, 0.95)

var velocity: Vector2 = Vector2.ZERO
var team: int = Team.ENEMY
var bounce_count: int = 0
var lane: int = 0
var origin_lane: int = 0
var heavy: bool = false
var is_core: bool = false
var rail: bool = false
var explosive: bool = false
var damage: int = 1
var life: float = 5.0
var ricochets: int = 0
var shooter: Node2D
var homing: Node2D
var homing_turn: float = 7.0
var is_shard: bool = false
var parryable: bool = true

var _sprite: AnimatedSprite2D
var _trail: Line2D
var _shape: CollisionShape2D
var _base_scale: float = 1.0
var _hit_ids: Dictionary = {}
var _dead: bool = false
var _lane_visual: float = 0.0


static func make(pos: Vector2, vel: Vector2, p_team: int, p_lane: int, opts: Dictionary = {}) -> Projectile:
	var p := Projectile.new()
	p.velocity = vel
	p.team = p_team
	p.lane = p_lane
	p.origin_lane = int(opts.get("origin_lane", p_lane))
	p.heavy = bool(opts.get("heavy", false))
	p.is_core = bool(opts.get("core", false))
	p.explosive = bool(opts.get("explosive", false))
	p.shooter = opts.get("shooter", null)
	p.is_shard = bool(opts.get("shard", false))
	p.homing = opts.get("homing", null)
	p.damage = int(opts.get("damage", 1))
	p.position = pos
	return p


func _ready() -> void:
	add_to_group("projectiles")
	collision_layer = 0
	collision_mask = GameState.BIT_PLAYER_HURT | GameState.BIT_ENEMY_HURT
	monitorable = false
	_shape = CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 9.0 if is_core else (6.0 if heavy else 4.0)
	_shape.shape = circle
	add_child(_shape)
	_trail = Line2D.new()
	_trail.top_level = true
	_trail.width = 5.0 if heavy or is_core else 3.0
	_trail.joint_mode = Line2D.LINE_JOINT_ROUND
	_trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_trail.end_cap_mode = Line2D.LINE_CAP_ROUND
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0))
	curve.add_point(Vector2(1, 1))
	_trail.width_curve = curve
	add_child(_trail)
	_sprite = AnimatedSprite2D.new()
	add_child(_sprite)
	_lane_visual = float(origin_lane)
	_refresh_visual()
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	if _dead:
		return
	life -= delta
	if life <= 0.0:
		_fizzle()
		return
	if homing != null and is_instance_valid(homing) and not homing.is_queued_for_deletion():
		var want: float = (homing.global_position - global_position).angle()
		var diff: float = wrapf(want - velocity.angle(), -PI, PI)
		velocity = velocity.rotated(clampf(diff, -homing_turn * delta, homing_turn * delta))
	var motion: Vector2 = velocity * delta
	var hit: Dictionary = _ray(global_position, global_position + motion)
	if not hit.is_empty():
		_on_wall(hit)
		if _dead:
			return
	else:
		global_position += motion
	_sprite.rotation = velocity.angle()
	_update_lane_visual(delta)
	_update_trail()


# ---------------------------------------------------------------- rally

func deflect(dir: Vector2, by_player: bool) -> void:
	bounce_count += 1
	team = Team.PLAYER if by_player else Team.ENEMY
	var cap: float = CORE_MAX_SPEED if is_core else MAX_SPEED
	var spd: float = clampf(velocity.length() * GameState.rally_accel(), 170.0, cap)
	velocity = dir.normalized() * spd
	_base_scale = minf(_base_scale * 1.15, 2.6)
	life = 4.0
	homing = null
	ricochets = 1 if by_player else 0
	_hit_ids.clear()
	if by_player and GameState.has_mod("berserk_lock") and not is_core:
		explosive = true
		_become_rail()
	elif bounce_count >= 3 and not is_core:
		_become_rail()
	_refresh_visual()


func cross_to_lane(new_lane: int) -> void:
	lane = new_lane


func _become_rail() -> void:
	if rail:
		return
	rail = true
	damage = 3
	velocity = velocity.normalized() * RAIL_SPEED
	life = 1.6
	AudioManager.play_sfx("rail")
	JuiceManager.shake(0.35)
	JuiceManager.ring(global_position, TINTS[3], 34.0, 0.3, 3.0, true)


func _color_index() -> int:
	if is_shard:
		return 3
	return mini(bounce_count, 3)


func _refresh_visual() -> void:
	var idx: int = _color_index()
	var anim: String = "core" if is_core else ("heavy" if heavy else "bullet")
	if is_shard:
		anim = "shard"
	_sprite.sprite_frames = FxLib.frames(anim, COLOR_KEYS[idx] if team == Team.PLAYER or bounce_count > 0 else "magenta")
	_sprite.play("default")
	var tint: Color = TINTS[idx]
	if idx == 3:
		_sprite.modulate = Color(1.6, 0.35, 0.45)
	elif idx == 2:
		_sprite.modulate = Color(1.25, 1.1, 0.55)
	else:
		_sprite.modulate = Color(1.15, 1.15, 1.15)
	scale = Vector2.ONE * _base_scale
	var g := Gradient.new()
	var tail: Color = tint
	tail.a = 0.0
	g.set_color(0, tail)
	g.set_color(1, Color(tint.r, tint.g, tint.b, 0.85))
	_trail.gradient = g
	_trail.width = (7.0 if rail else (5.0 if heavy or is_core else 3.0)) * _base_scale
	if rail:
		var hot := Gradient.new()
		hot.set_color(0, Color(1.0, 0.0, 0.2, 0.0))
		hot.set_color(1, Color(1.0, 0.85, 0.9, 1.0))
		hot.add_point(0.6, Color(1.0, 0.1, 0.25, 0.9))
		_trail.gradient = hot


func _update_trail() -> void:
	_trail.add_point(global_position)
	var max_points: int = 26 if rail else (14 if bounce_count > 0 else 8)
	while _trail.get_point_count() > max_points:
		_trail.remove_point(0)


func _update_lane_visual(delta: float) -> void:
	_lane_visual = move_toward(_lane_visual, float(lane), delta * 4.0)
	var k: float = _lane_visual
	var s: float = lerpf(1.0, BG_SCALE, k)
	_sprite.scale = Vector2(s, s)
	var tint: Color = Color.WHITE.lerp(BG_TINT, k)
	self_modulate = tint
	_trail.modulate = tint
	z_index = -4 if k > 0.5 else 6
	_trail.z_index = z_index - 1


# ---------------------------------------------------------------- collisions

func _ray(from: Vector2, to: Vector2) -> Dictionary:
	if from.is_equal_approx(to):
		return {}
	var space := get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(from, to, GameState.BIT_WORLD_BG if lane == 1 else GameState.BIT_WORLD_FG)
	q.collide_with_areas = false
	q.hit_from_inside = false
	return space.intersect_ray(q)


func _on_wall(hit: Dictionary) -> void:
	var n: Vector2 = hit["normal"]
	var pos: Vector2 = hit["position"]
	var body: Object = hit.get("collider")
	if body is StaticBody2D and body.has_meta("one_way") and (velocity.y <= 0.0 or n.y > -0.5):
		global_position += velocity * get_physics_process_delta_time()
		return
	if team == Team.PLAYER and ricochets > 0 and not rail and not is_core:
		ricochets -= 1
		global_position = pos + n * 2.0
		velocity = velocity.bounce(n)
		JuiceManager.fx("star", "cyan", pos, 0.0, 1.0)
		AudioManager.play_sfx("parry_hit", 1.4, -8.0)
		return
	global_position = pos
	if explosive:
		_explode()
	else:
		_fizzle()


func _on_area_entered(area: Area2D) -> void:
	if _dead:
		return
	var target: Object = area.get_meta("entity", null)
	if target == null or not is_instance_valid(target):
		return
	if team == Team.ENEMY and target is Player:
		var player: Player = target
		if player.lane != lane:
			return
		if player.receive_projectile(self):
			_impact(false)
	elif team == Team.PLAYER and target.has_method("receive_projectile") and not (target is Player):
		if int(target.get("lane")) != lane and not bool(target.get("lane_agnostic")):
			return
		var id: int = target.get_instance_id()
		if _hit_ids.has(id):
			return
		_hit_ids[id] = true
		var result: String = target.receive_projectile(self)
		if result == "hit":
			if explosive:
				_explode()
			elif not rail:
				_impact(true)


func _impact(on_enemy: bool) -> void:
	var key: String = COLOR_KEYS[_color_index()]
	JuiceManager.fx("spark", key, global_position, randf() * TAU, 1.2 * _base_scale)
	if on_enemy:
		JuiceManager.fx("ring", key, global_position, 0.0, 1.5)
	_die()


func _fizzle() -> void:
	FxLib.spawn(JuiceManager.fx_root, "shot_hit", "", global_position, velocity.angle(), _base_scale)
	_die()


func _explode() -> void:
	var pos: Vector2 = global_position
	JuiceManager.fx("burst", "gold", pos, 0.0, 2.4, Color(1.5, 0.5, 0.4))
	JuiceManager.ring(pos, Color("#FF3300"), 46.0, 0.3, 4.0, true)
	JuiceManager.shake(0.3)
	AudioManager.play_sfx("explosion", randf_range(0.9, 1.1), -4.0)
	for e: Node in get_tree().get_nodes_in_group("enemies"):
		var n2: Node2D = e
		if n2 == null or not is_instance_valid(n2):
			continue
		if int(e.get("lane")) != lane and not bool(e.get("lane_agnostic")):
			continue
		if n2.global_position.distance_to(pos) < 42.0 and e.has_method("take_damage"):
			e.take_damage(2, self)
	_die()


func _die() -> void:
	if _dead:
		return
	_dead = true
	set_deferred("monitoring", false)
	visible = false
	var tw := create_tween()
	tw.tween_interval(0.05)
	tw.tween_callback(queue_free)
