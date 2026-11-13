class_name Player
extends CharacterBody2D
## VINCENT-09. Celeste-style movement (coyote time, jump/parry buffers, corner correction),
## a 360-degree mouse-aimed kinetic deflector, SANABI air recoil, 2.5D Z-lane switching,
## kinetic wall-slam, Sandevistan afterimages, and the 1.5s Blackout Rebound.

signal died
signal deflected(p: Projectile)
signal lane_switched(new_lane: int)
signal blackout_started
signal blackout_ended(rebounded: bool)

const RUN_SPEED: float = 150.0
const ACCEL: float = 1500.0
const AIR_ACCEL: float = 1050.0
const FRICTION: float = 1700.0
const AIR_DRAG: float = 260.0
const GRAVITY: float = 920.0
const FALL_GRAVITY_MULT: float = 1.25
const MAX_FALL: float = 540.0
const JUMP_VELOCITY: float = -318.0
const JUMP_CUT: float = 0.45
const COYOTE_TIME: float = 0.12
const JUMP_BUFFER: float = 0.10
const PARRY_BUFFER: float = 0.10
const PARRY_COOLDOWN: float = 0.26
const PARRY_RADIUS: float = 42.0
const RECOIL_FORCE: float = 330.0
const DASH_SPEED: float = 410.0
const DASH_TIME: float = 0.14
const LANE_TWEEN: float = 0.18
const LANE_CHARGE_TIME: float = 0.45
const CORNER_NUDGE: int = 4
const WALL_SLAM_WINDOW_MS: int = 100
const BG_SCALE: float = 0.78
const BG_TINT: Color = Color(0.65, 0.75, 0.95)
const FEET_Y: float = 20.0
const ASSIST_ANGLE: float = deg_to_rad(24.0)

var lane: int = 0
var aim_dir: Vector2 = Vector2.RIGHT
var input_enabled: bool = true
var dead: bool = false
var in_blackout: bool = false
## Non-zero overrides mouse aim (automated tests, future gamepad stick).
var aim_override: Vector2 = Vector2.ZERO

var _coyote: float = 0.0
var _jump_buffer: float = 0.0
var _jump_held: bool = false
var _jumping: bool = false
var _parry_buffer: float = 0.0
var _parry_active: float = 0.0
var _parry_cd: float = 0.0
var _parry_aim: Vector2 = Vector2.RIGHT
var _parry_hold: float = 0.0
var _last_parry_ms: int = -10000
var _dash_time: float = 0.0
var _dash_cd: float = 0.0
var _dash_dir: Vector2 = Vector2.RIGHT
var _air_dashes: int = 1
var _invuln: float = 0.0
var _lane_charge: float = 0.0
var _lane_cd: float = 0.0
var _blackout_left: float = 0.0
var _heartbeat_t: float = 0.0
var _ghost_t: float = 0.0
var _air_chain: int = 0
var _was_on_floor: bool = true
var _last_wall_ms: int = -10000
var _wall_normal: Vector2 = Vector2.ZERO
var _wall_vel: Vector2 = Vector2.ZERO
var _slam_time: float = 0.0
var _knockback: float = 0.0
var _prism_count: int = 0
var _aegis_active: float = 0.0
var _aegis_cd: float = 0.0
var _shoot_pose: float = 0.0
var _flash_t: float = 0.0
var _facing: int = 1
var _last_ms: int = 0
var _lane_visual: float = 0.0

var _visual: Node2D
var _sprite: AnimatedSprite2D
var _flash_mat: ShaderMaterial
var _hurtbox: Area2D
var _arc: Node2D


func _ready() -> void:
	add_to_group("player")
	collision_layer = 0
	collision_mask = GameState.BIT_WORLD_FG
	floor_snap_length = 4.0
	floor_max_angle = deg_to_rad(50.0)
	var shape := CollisionShape2D.new()
	var cap := CapsuleShape2D.new()
	cap.radius = 6.5
	cap.height = 40.0
	shape.shape = cap
	add_child(shape)
	_visual = Node2D.new()
	add_child(_visual)
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = _build_frames()
	_sprite.position = Vector2(0, FEET_Y - 33.5)
	_flash_mat = ShaderMaterial.new()
	_flash_mat.shader = load("res://shaders/hit_flash.gdshader")
	_sprite.material = _flash_mat
	_sprite.play("idle")
	_visual.add_child(_sprite)
	_arc = Node2D.new()
	_arc.z_index = 25
	_arc.draw.connect(_draw_arc)
	add_child(_arc)
	_hurtbox = Area2D.new()
	_hurtbox.collision_layer = GameState.BIT_PLAYER_HURT
	_hurtbox.collision_mask = GameState.BIT_ENEMY_HURT
	_hurtbox.set_meta("entity", self)
	var hs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(10, 28)
	hs.shape = rect
	hs.position = Vector2(0, 2)
	_hurtbox.add_child(hs)
	add_child(_hurtbox)
	_last_ms = Time.get_ticks_msec()


# ================================================================= main loop

func _physics_process(delta: float) -> void:
	var now: int = Time.get_ticks_msec()
	var real_delta: float = minf(float(now - _last_ms) / 1000.0, 0.1)
	_last_ms = now
	_tick(delta, real_delta)
	if dead:
		return
	if aim_override != Vector2.ZERO:
		aim_dir = aim_override.normalized()
	else:
		var to_mouse: Vector2 = get_global_mouse_position() - chest()
		if to_mouse.length() > 2.0:
			aim_dir = to_mouse.normalized()
	if input_enabled:
		_read_input()
	_move(delta)
	_parry_scan()
	_shockwave_dash_scan()
	_slam_scan()
	_afterimages(real_delta)
	_animate()
	_update_lane_visual(real_delta)
	_arc.queue_redraw()
	if StageBase.current != null and global_position.y > StageBase.current.kill_y:
		die()


func _tick(delta: float, real_delta: float) -> void:
	_coyote -= delta
	_jump_buffer -= delta
	_parry_buffer -= delta
	_parry_active -= delta
	_parry_cd -= delta
	_dash_cd -= delta
	_lane_charge -= real_delta
	_lane_cd -= real_delta
	_invuln -= real_delta
	_slam_time -= delta
	_knockback -= delta
	_aegis_active -= delta
	_aegis_cd -= delta
	_shoot_pose -= delta
	if _flash_t > 0.0:
		_flash_t -= real_delta
		if _flash_t <= 0.0:
			_flash_mat.set_shader_parameter("active", false)
	if in_blackout and not dead:
		_blackout_left -= real_delta
		_heartbeat_t -= real_delta
		if _heartbeat_t <= 0.0:
			_heartbeat_t = 0.62
			AudioManager.play_sfx("blackout_heartbeat")
		if _blackout_left <= 0.0:
			die()


func _read_input() -> void:
	if Input.is_action_just_pressed("jump"):
		_jump_buffer = JUMP_BUFFER
	_jump_held = Input.is_action_pressed("jump")
	if Input.is_action_just_pressed("parry"):
		_parry_buffer = PARRY_BUFFER
		_parry_hold = 0.0
	if Input.is_action_pressed("parry"):
		_parry_hold += get_physics_process_delta_time()
		if GameState.has_mod("aegis") and _parry_hold > 0.15 and _aegis_cd <= 0.0:
			_aegis_active = 0.4
			_aegis_cd = 1.4
			AudioManager.play_sfx("shield", 1.3)
			JuiceManager.ring(chest(), Color("#00F0FF"), PARRY_RADIUS, 0.4, 3.0)
	if _parry_buffer > 0.0 and _parry_cd <= 0.0:
		_start_parry()
	if Input.is_action_just_pressed("dash") and _dash_cd <= 0.0 and (is_on_floor() or _air_dashes > 0):
		_start_dash()
	var lanes_ok: bool = StageBase.current != null and StageBase.current.has_lanes and _lane_cd <= 0.0
	if lanes_ok and _lane_charge > 0.0:
		if Input.is_action_just_pressed("lane_back") and lane == 0:
			switch_lane(1)
		elif Input.is_action_just_pressed("lane_front") and lane == 1:
			switch_lane(0)
		elif Input.is_action_just_pressed("lane_toggle"):
			switch_lane(1 - lane)


# ================================================================= movement

func _move(delta: float) -> void:
	var axis: float = Input.get_axis("move_left", "move_right") if input_enabled else 0.0
	if _dash_time > 0.0:
		_dash_time -= delta
		velocity = _dash_dir * DASH_SPEED
		if _dash_time <= 0.0:
			velocity *= 0.55
	else:
		var target: float = axis * RUN_SPEED * GameState.move_speed_mult()
		var on_floor: bool = is_on_floor()
		if _knockback > 0.0 or _slam_time > 0.0:
			velocity.x = move_toward(velocity.x, target, AIR_DRAG * delta)
		elif absf(axis) > 0.01:
			var a: float = ACCEL if on_floor else AIR_ACCEL
			if absf(velocity.x) > absf(target) and signf(velocity.x) == signf(target) and not on_floor:
				a = AIR_DRAG
			velocity.x = move_toward(velocity.x, target, a * delta)
			_facing = 1 if axis > 0.0 else -1
		else:
			velocity.x = move_toward(velocity.x, 0.0, (FRICTION if on_floor else AIR_DRAG * 1.6) * delta)
		var g: float = GRAVITY * (FALL_GRAVITY_MULT if velocity.y > 0.0 else 1.0)
		if velocity.y >= 0.0:
			_jumping = false
		if _jumping and not _jump_held and velocity.y < 0.0:
			g *= 2.2
		velocity.y = minf(velocity.y + g * delta, MAX_FALL)
		if _jump_buffer > 0.0 and (on_floor or _coyote > 0.0):
			velocity.y = JUMP_VELOCITY
			_jumping = true
			_jump_buffer = 0.0
			_coyote = 0.0
			AudioManager.play_sfx("jump", randf_range(0.95, 1.05))
	if velocity.y < 0.0:
		_corner_correct(delta)
	var pre: Vector2 = velocity
	move_and_slide()
	_post_move(pre)


func _corner_correct(delta: float) -> void:
	var up := Vector2(0, velocity.y * delta)
	if not test_move(global_transform, up):
		return
	for i: int in range(1, CORNER_NUDGE + 1):
		for dir: int in [-1, 1]:
			var t: Transform2D = global_transform.translated(Vector2(i * dir, 0))
			if not test_move(t, up):
				global_position.x += i * dir
				return


func _post_move(pre: Vector2) -> void:
	var now: int = Time.get_ticks_msec()
	var on_floor: bool = is_on_floor()
	if on_floor:
		_coyote = COYOTE_TIME
		_air_dashes = 1
		_air_chain = 0
		if not _was_on_floor and pre.y > 220.0:
			AudioManager.play_sfx("land", randf_range(0.9, 1.1))
			JuiceManager.fx("puff", "cyan", global_position + Vector2(0, FEET_Y - 4), 0.0, 1.0, Color(1, 1, 1, 0.6))
			_squash()
	_was_on_floor = on_floor
	if is_on_wall() and absf(pre.x) > 150.0:
		_last_wall_ms = now
		_wall_normal = get_wall_normal()
		_wall_vel = pre
		if now - _last_parry_ms <= WALL_SLAM_WINDOW_MS:
			_wall_slam()


func _start_dash() -> void:
	var dir: Vector2 = aim_dir
	if absf(dir.y) < 0.25:
		dir = Vector2(signf(dir.x) if dir.x != 0.0 else float(_facing), 0.0)
	_dash_dir = dir.normalized()
	_dash_time = DASH_TIME
	_dash_cd = GameState.dash_cooldown()
	if not is_on_floor():
		_air_dashes -= 1
	if GameState.has_mod("phase_dash"):
		_invuln = maxf(_invuln, DASH_TIME + 0.25)
	AudioManager.play_sfx("dash")
	JuiceManager.ghost(_sprite)
	_facing = 1 if _dash_dir.x >= 0.0 else -1


func _squash() -> void:
	var tw := create_tween()
	_sprite.scale = Vector2(1.18, 0.82)
	tw.tween_property(_sprite, "scale", Vector2.ONE, 0.12)


# ================================================================= parry

func _start_parry() -> void:
	_parry_buffer = 0.0
	_parry_active = GameState.parry_window()
	_parry_cd = PARRY_COOLDOWN
	_parry_aim = aim_dir
	_shoot_pose = 0.18
	_facing = 1 if _parry_aim.x >= 0.0 else -1
	_last_parry_ms = Time.get_ticks_msec()
	var c: Vector2 = chest()
	JuiceManager.fx("slash", "cyan", c + _parry_aim * 16.0 * _visual_scale(), _parry_aim.angle(), 1.6 * _visual_scale())
	AudioManager.play_sfx("swing", randf_range(0.9, 1.15))
	if _last_parry_ms - _last_wall_ms <= WALL_SLAM_WINDOW_MS and _wall_vel.length() > 150.0:
		_wall_slam()


func _parry_scan() -> void:
	var omni: bool = _aegis_active > 0.0
	if _parry_active <= 0.0 and not omni:
		return
	var c: Vector2 = chest()
	var half_arc: float = deg_to_rad(GameState.parry_arc_degrees()) * 0.5
	var radius: float = PARRY_RADIUS * _visual_scale()
	for node: Node in get_tree().get_nodes_in_group("projectiles"):
		var p: Projectile = node as Projectile
		if p == null or p.team != Projectile.Team.ENEMY or not p.parryable or p.lane != lane:
			continue
		var d: Vector2 = p.global_position - c
		var reach: float = radius + 6.0 * p.scale.x
		if d.length() > reach:
			continue
		if not omni and d.length() > 12.0 and absf(angle_difference(d.angle(), _parry_aim.angle())) > half_arc:
			continue
		_deflect(p)


func _deflect(p: Projectile) -> void:
	var dir: Vector2 = _parry_aim if _parry_active > 0.0 else (p.global_position - chest()).normalized()
	var target: Node2D = _assist_target(dir, p)
	if target != null:
		dir = (target.global_position - p.global_position).normalized()
		var t_lane: int = int(target.get("lane"))
		if t_lane != p.lane:
			p.cross_to_lane(t_lane)
	p.global_position = chest() + dir * 10.0 * _visual_scale()
	p.deflect(dir, true)
	var bounce: int = p.bounce_count
	GameState.register_parry(bounce)
	var airborne: bool = not is_on_floor()
	if airborne:
		_air_chain += 1
	GameState.add_sync(GameState.SYNC_PER_AIR_CHAIN if airborne and _air_chain >= 2 else GameState.SYNC_PER_PARRY)
	JuiceManager.hitstop(clampf(0.08 + 0.02 * float(bounce - 1), 0.08, 0.14))
	AudioManager.play_parry(bounce)
	var key: String = Projectile.COLOR_KEYS[mini(bounce, 3)]
	JuiceManager.fx("spark", key, p.global_position, randf() * TAU, 1.8)
	JuiceManager.fx("ring", key, p.global_position, 0.0, 1.4)
	JuiceManager.shake(0.16 + 0.06 * float(bounce))
	_flash(Color(0.6, 1.0, 1.0), 0.05)
	if bounce >= 2:
		JuiceManager.text_pop(p.global_position, "x%d RALLY" % bounce, Projectile.TINTS[mini(bounce, 3)], 9)
	if airborne:
		velocity = -_parry_aim * RECOIL_FORCE
		_air_dashes = 1
		_dash_time = 0.0
	_lane_charge = LANE_CHARGE_TIME
	_prism_count += 1
	if GameState.has_mod("prism_split") and _prism_count % 3 == 0:
		_spawn_prism_shards(p)
	if in_blackout:
		_rebound()
	deflected.emit(p)


func _assist_target(dir: Vector2, p: Projectile) -> Node2D:
	var best: Node2D = null
	var best_angle: float = ASSIST_ANGLE
	for e: Node in get_tree().get_nodes_in_group("enemies"):
		var n: Node2D = e as Node2D
		if n == null or not is_instance_valid(n) or not bool(e.get("alive")):
			continue
		var e_lane: int = int(e.get("lane"))
		if e_lane != lane and e_lane != p.origin_lane and not bool(e.get("lane_agnostic")):
			continue
		var to: Vector2 = n.global_position - p.global_position
		if to.length() > 420.0:
			continue
		var ang: float = absf(angle_difference(to.angle(), dir.angle()))
		if ang < best_angle:
			best_angle = ang
			best = n
	return best


func _nearest_enemy(from: Vector2, max_dist: float = 400.0) -> Node2D:
	var best: Node2D = null
	var best_d: float = max_dist
	for e: Node in get_tree().get_nodes_in_group("enemies"):
		var n: Node2D = e as Node2D
		if n == null or not bool(e.get("alive")):
			continue
		var d: float = n.global_position.distance_to(from)
		if d < best_d:
			best_d = d
			best = n
	return best


func _spawn_prism_shards(src: Projectile) -> void:
	for side: float in [-0.45, 0.45]:
		var v: Vector2 = src.velocity.rotated(side) * 0.85
		var shard := Projectile.make(src.global_position, v, Projectile.Team.PLAYER, lane,
				{"shard": true, "homing": _nearest_enemy(src.global_position), "origin_lane": lane})
		shard.bounce_count = 3
		StageBase.spawn(shard)


func _shockwave_dash_scan() -> void:
	if _dash_time <= 0.0 or not GameState.has_mod("shockwave_dash"):
		return
	for node: Node in get_tree().get_nodes_in_group("projectiles"):
		var p: Projectile = node as Projectile
		if p == null or p.team != Projectile.Team.ENEMY or p.lane != lane:
			continue
		if p.global_position.distance_to(chest()) < 22.0:
			var t: Node2D = _nearest_enemy(p.global_position)
			var dir: Vector2 = (t.global_position - p.global_position).normalized() if t else _dash_dir
			p.deflect(dir, true)
			p.velocity *= 2.0
			GameState.register_parry(p.bounce_count)
			GameState.add_sync(GameState.SYNC_PER_PARRY)
			AudioManager.play_parry(p.bounce_count)
			JuiceManager.fx("spark", "cyan", p.global_position, 0.0, 1.6)


# ================================================================= wall slam

func _wall_slam() -> void:
	if _wall_vel.length() < 150.0:
		return
	var out: Vector2 = _wall_vel.bounce(_wall_normal)
	if out.length() < 1.0:
		out = _wall_normal
	out = out.normalized() * maxf(_wall_vel.length() * 1.25, 400.0)
	out.y = minf(out.y, -140.0)
	velocity = out
	_wall_vel = Vector2.ZERO
	_last_wall_ms = -10000
	_slam_time = 0.45
	_dash_time = 0.0
	_air_dashes = 1
	_invuln = maxf(_invuln, 0.3)
	GameState.add_sync(20.0)
	AudioManager.play_sfx("rail", 1.3)
	JuiceManager.hitstop(0.09)
	JuiceManager.shake(0.45)
	JuiceManager.ring(global_position, Color("#FF0055"), 48.0, 0.3, 4.0, true)
	JuiceManager.text_pop(global_position, "WALL-SLAM", Color("#FF0055"), 9)
	if GameState.once("tut_wallslam_done"):
		pass


func _slam_scan() -> void:
	if _slam_time <= 0.0:
		return
	for a: Area2D in _hurtbox.get_overlapping_areas():
		var e: Object = a.get_meta("entity", null)
		if e != null and is_instance_valid(e) and e.has_method("take_damage") and int(e.get("lane")) == lane:
			e.take_damage(3, self)


# ================================================================= lanes

func switch_lane(to: int, launch: bool = true) -> void:
	if to == lane or dead:
		return
	var launch_v: float = _lane_launch_velocity(to)
	if is_nan(launch_v):
		## Never let a depth switch be suicide: no standable surface in that lane here.
		JuiceManager.text_pop(chest(), "NO DEPTH SURFACE", Color("#FF9900"), 8)
		AudioManager.play_sfx("echo_glitch", 1.6, -8.0)
		_lane_cd = 0.25
		return
	lane = to
	GameState.current_lane = to
	_lane_cd = 0.25
	_lane_charge = 0.0
	collision_mask = GameState.BIT_WORLD_BG if to == 1 else GameState.BIT_WORLD_FG
	if launch:
		velocity.y = minf(velocity.y, launch_v)
		_air_dashes = 1
	AudioManager.play_sfx("z_lane_whoosh")
	JuiceManager.ring(chest(), Color("#00F0FF") if to == 0 else Color("#4A00E0"), 40.0, LANE_TWEEN + 0.1, 3.0)
	JuiceManager.screen_shockwave(chest(), 0.6)
	JuiceManager.ghost(_sprite)
	if GameState.overclock_count > 0:
		_emp_blast()
	lane_switched.emit(to)


func _lane_launch_velocity(to: int) -> float:
	## Find the first standable surface in the target lane above or just below us and
	## return the upward velocity that lands on it (decks are one-way, so we rise through).
	var feet: float = global_position.y + FEET_Y
	var space := get_world_2d().direct_space_state
	var mask: int = GameState.BIT_WORLD_BG if to == 1 else GameState.BIT_WORLD_FG
	for x_off: float in [0.0, -8.0, 8.0]:
		var from := Vector2(global_position.x + x_off, feet - 150.0)
		var q := PhysicsRayQueryParameters2D.create(from, Vector2(from.x, feet + 120.0), mask)
		q.hit_from_inside = false
		var hit: Dictionary = space.intersect_ray(q)
		if hit.is_empty():
			continue
		var top: float = (hit["position"] as Vector2).y
		if top < feet - 4.0:
			var rise: float = feet - top + 14.0
			return -clampf(sqrt(2.0 * GRAVITY * rise), 200.0, 560.0)
		return -170.0
	return NAN


func _emp_blast() -> void:
	JuiceManager.ring(chest(), Color("#FF0055"), 70.0, 0.35, 3.0, true)
	for node: Node in get_tree().get_nodes_in_group("projectiles"):
		var p: Projectile = node as Projectile
		if p and p.team == Projectile.Team.ENEMY and p.global_position.distance_to(chest()) < 70.0 and not p.is_core:
			p.call("_fizzle")


func _update_lane_visual(real_delta: float) -> void:
	_lane_visual = move_toward(_lane_visual, float(lane), real_delta / LANE_TWEEN)
	var k: float = _ease_cubic(_lane_visual)
	var s: float = lerpf(1.0, BG_SCALE, k)
	_visual.scale = Vector2.ONE * s
	_visual.position.y = FEET_Y * (1.0 - s)
	_visual.modulate = Color.WHITE.lerp(BG_TINT, k)
	z_index = -4 if k > 0.5 else 5


func _ease_cubic(x: float) -> float:
	return 4.0 * x * x * x if x < 0.5 else 1.0 - pow(-2.0 * x + 2.0, 3.0) / 2.0


func _visual_scale() -> float:
	return lerpf(1.0, BG_SCALE, _lane_visual)


# ================================================================= damage / blackout

func receive_projectile(p: Projectile) -> bool:
	## Called by an enemy projectile that overlapped the hurtbox. True = it hit.
	if dead:
		return false
	if _aegis_active > 0.0 and not p.is_core:
		_deflect(p)
		return false
	if _invuln > 0.0 or _slam_time > 0.0:
		return false
	if _dash_time > 0.0 and GameState.has_mod("phase_dash"):
		return false
	take_hit(p.velocity.normalized())
	return true


func take_hit(from_dir: Vector2) -> void:
	if dead or _invuln > 0.0:
		return
	if in_blackout:
		die()
		return
	_enter_blackout(from_dir)


func _enter_blackout(from_dir: Vector2) -> void:
	in_blackout = true
	_blackout_left = GameState.blackout_duration()
	_heartbeat_t = 0.0
	_invuln = 0.3
	_knockback = 0.5
	var push_x: float = signf(from_dir.x) if from_dir.x != 0.0 else -float(_facing)
	velocity = Vector2(push_x * 240.0, -210.0)
	_dash_time = 0.0
	_air_dashes = 1
	_flash(Color(1, 0.1, 0.25), 0.12)
	JuiceManager.set_base_time_scale(0.25)
	JuiceManager.shake(0.7)
	JuiceManager.flash(Color(1.0, 0.0, 0.15, 0.35), 0.12)
	AudioManager.play_sfx("hurt")
	AudioManager.set_blackout(true)
	blackout_started.emit()


func _rebound() -> void:
	in_blackout = false
	_invuln = 1.0
	_knockback = 0.0
	GameState.rebounds += 1
	JuiceManager.set_base_time_scale(1.0)
	AudioManager.set_blackout(false)
	AudioManager.play_sfx("blackout_rebound")
	var c: Vector2 = chest()
	JuiceManager.ring(c, Color("#00F0FF"), 150.0, 0.5, 6.0, true)
	JuiceManager.ring(c, Color("#FF0055"), 110.0, 0.4, 3.0)
	JuiceManager.screen_shockwave(c, 1.4)
	JuiceManager.flash(Color(0.8, 1.0, 1.0, 0.6), 0.12)
	JuiceManager.shake(0.8)
	JuiceManager.text_pop(c, "REBOUND +50%", Color("#00F0FF"), 11)
	for e: Node in get_tree().get_nodes_in_group("enemies"):
		var n: Node2D = e as Node2D
		if n and n.global_position.distance_to(c) < 150.0 and e.has_method("shove"):
			e.shove((n.global_position - c).normalized() * 220.0)
	for node: Node in get_tree().get_nodes_in_group("projectiles"):
		var p: Projectile = node as Projectile
		if p and p.team == Projectile.Team.ENEMY and p.global_position.distance_to(c) < 120.0 and not p.is_core:
			p.call("_fizzle")
	GameState.add_sync(GameState.SYNC_REBOUND)
	blackout_ended.emit(true)


func die() -> void:
	if dead:
		return
	dead = true
	if in_blackout:
		in_blackout = false
		AudioManager.set_blackout(false)
		blackout_ended.emit(false)
	JuiceManager.set_base_time_scale(1.0)
	velocity = Vector2.ZERO
	_sprite.play("hurt")
	died.emit()


func respawn(pos: Vector2, new_lane: int) -> void:
	dead = false
	in_blackout = false
	global_position = pos
	velocity = Vector2.ZERO
	lane = new_lane
	GameState.current_lane = new_lane
	_lane_visual = float(new_lane)
	collision_mask = GameState.BIT_WORLD_BG if new_lane == 1 else GameState.BIT_WORLD_FG
	_dash_time = 0.0
	_slam_time = 0.0
	_knockback = 0.0
	_parry_active = 0.0
	_aegis_active = 0.0
	_air_dashes = 1
	_invuln = 0.6
	_flash(Color(0.4, 1.0, 1.0), 0.15)


func zring_launch(to_lane: int, impulse: Vector2) -> void:
	if dead:
		return
	velocity.x = impulse.x if impulse.x != 0.0 else velocity.x
	if to_lane != lane:
		switch_lane(to_lane, true)
	else:
		velocity.y = impulse.y
	_air_dashes = 1


func blackout_fraction() -> float:
	return clampf(_blackout_left / GameState.blackout_duration(), 0.0, 1.0) if in_blackout else 0.0


func dash_ready() -> bool:
	return _dash_cd <= 0.0 and (is_on_floor() or _air_dashes > 0)


func lane_charged() -> bool:
	return _lane_charge > 0.0


func parry_ready() -> float:
	return clampf(1.0 - _parry_cd / PARRY_COOLDOWN, 0.0, 1.0)


func chest() -> Vector2:
	return global_position + Vector2(0, -6.0 + 14.0 * (1.0 - _visual_scale()))


# ================================================================= visuals

func _flash(color: Color, dur: float) -> void:
	_flash_mat.set_shader_parameter("flash_color", color)
	_flash_mat.set_shader_parameter("active", true)
	_flash_t = dur


func _afterimages(real_delta: float) -> void:
	var trail: bool = _dash_time > 0.0 or _slam_time > 0.0 or GameState.tier >= GameState.Tier.OVERCLOCKED
	if in_blackout:
		trail = true
	if not trail:
		return
	_ghost_t -= real_delta
	if _ghost_t <= 0.0:
		_ghost_t = 0.035
		JuiceManager.ghost(_sprite, Color(1, 0.05, 0.2) if in_blackout else Color(0, 0, 0, 0))


func _animate() -> void:
	var anim: String = "idle"
	if in_blackout or _knockback > 0.2:
		anim = "hurt"
	elif _slam_time > 0.0 or (_dash_time > 0.0 and not is_on_floor()):
		anim = "flip"
	elif _shoot_pose > 0.0:
		anim = "shoot"
	elif not is_on_floor():
		anim = "jump" if velocity.y < 0.0 else "fall"
	elif absf(velocity.x) > 20.0:
		anim = "run"
	if _sprite.animation != anim:
		_sprite.play(anim)
	if anim == "run":
		_sprite.speed_scale = clampf(absf(velocity.x) / RUN_SPEED, 0.6, 1.6)
	else:
		_sprite.speed_scale = 1.0
	_sprite.flip_h = _facing < 0
	_sprite.position.x = -2.5 if _facing > 0 else 2.5


func _draw_arc() -> void:
	var omni: bool = _aegis_active > 0.0
	if _parry_active <= 0.0 and not omni:
		return
	var c: Vector2 = chest() - global_position
	var r: float = PARRY_RADIUS * _visual_scale()
	var k: float = clampf(_parry_active / GameState.parry_window(), 0.0, 1.0)
	if omni:
		_arc.draw_arc(c, r, 0.0, TAU, 40, Color(0.0, 0.94, 1.0, 0.7), 2.0)
		return
	var half: float = deg_to_rad(GameState.parry_arc_degrees()) * 0.5
	var a: float = _parry_aim.angle()
	var col := Color(0.0, 0.94, 1.0, 0.25 + 0.6 * k)
	_arc.draw_arc(c, r, a - half, a + half, 24, col, 2.0)
	_arc.draw_arc(c, r * 0.7, a - half * 0.8, a + half * 0.8, 18, Color(1, 1, 1, 0.35 * k), 1.0)


func _build_frames() -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	_add_strip(sf, "idle", "idle", 4, 8.0, true)
	_add_strip(sf, "run", "run", 8, 14.0, true)
	_add_strip(sf, "jump", "jump", 5, 10.0, false, [0, 1])
	_add_strip(sf, "fall", "jump", 5, 8.0, true, [3, 4])
	_add_strip(sf, "flip", "back-jump", 7, 22.0, true)
	_add_strip(sf, "hurt", "hurt", 1, 1.0, false)
	_add_strip(sf, "shoot", "shoot", 1, 1.0, false)
	return sf


func _add_strip(sf: SpriteFrames, anim: String, file: String, count: int, fps: float, loop: bool, only: Array = []) -> void:
	var tex: Texture2D = load("res://assets/warped_city/player/%s.png" % file)
	sf.add_animation(anim)
	sf.set_animation_speed(anim, fps)
	sf.set_animation_loop(anim, loop)
	var frames: Array = only if not only.is_empty() else range(count)
	for i: int in frames:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(i * 71, 0, 71, 67)
		sf.add_frame(anim, at)
