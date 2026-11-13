class_name BossGunship
extends Node2D
## Stage 4: Sara's Valkyrie Interceptor Gunship (Warped City police hull + two turret hardpoints).
## Phase 1  Foreground Barrage: plasma spreads; deflect shots into the two wing turrets.
## Phase 2  Depth Retreat: hull moves to the background lane and fires rail-missiles across planes;
##          parry them back across the depth plane into the hull.
## Phase 3  5-Bounce Execution Rally (at 15% HP): she parries the Overcharged Core back.
##          Win the rally to bounce 5 and the core shatters the cockpit.

signal phase_changed(phase: int)
signal defeated

const HP_MAX: int = 20
const P3_THRESHOLD: int = 3
const BG_SCALE: float = 0.78
const BG_TINT: Color = Color(0.65, 0.75, 0.95)

var lane: int = 0
var lane_agnostic: bool = false
var alive: bool = true
var hp: int = HP_MAX
var phase: int = 0
var arena: Rect2 = Rect2(80, 40, 360, 40)
var display_name: String = "VALKYRIE INTERCEPTOR // SARA"

var _t: float = 0.0
var _fire_t: float = 2.5
var _move_dir: float = 1.0
var _wings: Array[EnemyBase] = []
var _core: Projectile
var _core_cd: float = 0.0
var _body: Node2D
var _hull: Sprite2D
var _flash_mat: ShaderMaterial
var _flash_t: float = 0.0
var _hurtbox: Area2D
var _overlay: Node2D
var _cockpit_shield: bool = false
var _transitioning: bool = false
var _shield_pulse: float = 0.0
var _lane_visual: float = 0.0


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("boss")
	_body = Node2D.new()
	add_child(_body)
	_hull = Sprite2D.new()
	_hull.texture = load("res://assets/warped_city/vehicles/v-police.png")
	_hull.modulate = Color(1.25, 0.55, 1.2)
	_flash_mat = ShaderMaterial.new()
	_flash_mat.shader = load("res://shaders/hit_flash.gdshader")
	_hull.material = _flash_mat
	_body.add_child(_hull)
	for side: float in [-1.0, 1.0]:
		var glow := FxLib.sprite("orb", "magenta")
		glow.position = Vector2(side * 46.0, 24.0)
		glow.scale = Vector2(1.6, 1.0)
		_body.add_child(glow)
	_hurtbox = Area2D.new()
	_hurtbox.collision_layer = GameState.BIT_ENEMY_HURT
	_hurtbox.collision_mask = 0
	_hurtbox.monitoring = false
	_hurtbox.set_meta("entity", self)
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(120, 40)
	cs.shape = rect
	_hurtbox.add_child(cs)
	add_child(_hurtbox)
	_overlay = Node2D.new()
	_overlay.z_index = 3
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)
	z_index = 4


func start() -> void:
	phase = 1
	phase_changed.emit(1)
	for side: float in [-1.0, 1.0]:
		var w := EnemyBase.create(EnemyBase.Kind.WING, Vector2(side * 62.0, 20.0), 0)
		w.killed.connect(_on_wing_killed)
		add_child(w)
		_wings.append(w)
	AudioManager.play_sfx("boss_alarm")


func _physics_process(delta: float) -> void:
	if not alive or phase == 0:
		return
	_t += delta
	_flash_t -= delta
	_shield_pulse -= delta
	if _flash_t <= 0.0:
		_flash_mat.set_shader_parameter("active", false)
	if _transitioning:
		_overlay.queue_redraw()
		return
	_lane_visual = move_toward(_lane_visual, float(lane), delta * 3.0)
	match phase:
		1:
			_sweep(delta, 70.0, arena.position.y)
			_barrage(delta)
		2:
			_sweep(delta, 45.0, arena.position.y - 34.0)
			_missiles(delta)
		3:
			_hover_center(delta)
			_core_logic(delta)
	_body.rotation = sin(_t * 1.7) * 0.04
	_overlay.queue_redraw()


func _sweep(delta: float, speed: float, y: float) -> void:
	position.x += _move_dir * speed * delta
	if position.x > arena.end.x:
		_move_dir = -1.0
	elif position.x < arena.position.x:
		_move_dir = 1.0
	position.y = lerpf(position.y, y + sin(_t * 1.3) * 8.0, clampf(delta * 2.0, 0.0, 1.0))
	_hull.flip_h = _move_dir < 0.0


func _hover_center(delta: float) -> void:
	var target := Vector2(arena.get_center().x + sin(_t * 0.8) * 50.0, arena.position.y + sin(_t * 1.6) * 6.0)
	position = position.lerp(target, clampf(delta * 1.6, 0.0, 1.0))


func _player() -> Player:
	return get_tree().get_first_node_in_group("player") as Player


func _barrage(delta: float) -> void:
	_fire_t -= delta
	if _fire_t > 0.0:
		return
	_fire_t = 2.1 * Director.fire_interval_mult()
	var player: Player = _player()
	if player == null or player.dead:
		return
	var from: Vector2 = global_position + Vector2(0, 16)
	var base: Vector2 = (player.chest() - from).normalized()
	for i: int in 5:
		var a: float = (float(i) - 2.0) * 0.22
		var p := Projectile.make(from, base.rotated(a) * 120.0, Projectile.Team.ENEMY, 0, {"shooter": self})
		StageBase.spawn(p)
	AudioManager.play_sfx("heavy_shot", 0.8)
	JuiceManager.fx("ring", "magenta", from, 0.0, 2.0)


func _missiles(delta: float) -> void:
	_fire_t -= delta
	if _fire_t > 0.0:
		return
	_fire_t = 1.7 * Director.fire_interval_mult()
	var player: Player = _player()
	if player == null or player.dead:
		return
	var from: Vector2 = global_position + Vector2(0, 14) * BG_SCALE
	var dir: Vector2 = (player.chest() - from).normalized()
	var p := Projectile.make(from, dir * 150.0, Projectile.Team.ENEMY, player.lane,
			{"heavy": true, "shooter": self, "origin_lane": 1})
	StageBase.spawn(p)
	AudioManager.play_sfx("heavy_shot", 0.6)
	AudioManager.play_sfx("laser_lock", 1.6, -6.0)
	JuiceManager.fx("star", "magenta", from, 0.0, 1.6)


func _core_logic(delta: float) -> void:
	if _core != null and is_instance_valid(_core) and not _core.is_queued_for_deletion() and _core.visible:
		return
	_core = null
	_core_cd -= delta
	if _core_cd > 0.0:
		return
	_core_cd = 2.0
	var player: Player = _player()
	if player == null or player.dead:
		return
	var from: Vector2 = global_position + Vector2(0, 22)
	var dir: Vector2 = (player.chest() - from).normalized()
	_core = Projectile.make(from, dir * 105.0, Projectile.Team.ENEMY, 0, {"core": true, "shooter": self, "damage": 0})
	_core.life = 30.0
	StageBase.spawn(_core)
	AudioManager.play_sfx("rail", 0.5)
	JuiceManager.ring(from, Color("#FF0055"), 50.0, 0.5, 4.0, true)


# ================================================================= damage

func receive_projectile(p: Projectile) -> String:
	if not alive or _transitioning:
		return "ignore"
	match phase:
		1:
			JuiceManager.text_pop(p.global_position, "ARMOR", Color("#FF9900"), 8)
			AudioManager.play_sfx("shield", 0.8)
			return "hit"
		2:
			take_damage(6 if p.rail else 3, p)
			return "hit"
		3:
			if not p.is_core:
				JuiceManager.text_pop(p.global_position, "DEFLECTOR", Color("#FF0055"), 8)
				return "hit"
			if p.bounce_count >= 5:
				_core_shatter(p)
				return "hit"
			_cockpit_reflect(p)
			return "reflect"
	return "ignore"


func take_damage(amount: int, _source: Object = null) -> void:
	if phase != 2 or not alive:
		return
	hp = maxi(hp - amount, P3_THRESHOLD)
	_flash(Color(1, 1, 1), 0.1)
	JuiceManager.shake(0.4)
	JuiceManager.fx("burst", "gold", global_position + Vector2(randf_range(-40, 40), randf_range(-10, 10)) * BG_SCALE, 0.0, 2.0)
	AudioManager.play_sfx("explosion", 1.2, -4.0)
	if hp <= P3_THRESHOLD:
		_begin_phase3()


func _cockpit_reflect(p: Projectile) -> void:
	var player: Player = _player()
	var target: Vector2 = player.chest() if player else global_position + Vector2(0, 100)
	var dir: Vector2 = (target - global_position).normalized()
	p.global_position = global_position + dir * 30.0
	if player and p.lane != player.lane:
		p.cross_to_lane(player.lane)
	p.deflect(dir, false)
	_shield_pulse = 0.3
	var b: int = p.bounce_count
	AudioManager.play_sfx("shield", 1.0 + float(b) * 0.14)
	JuiceManager.hitstop(0.06 + 0.01 * float(b))
	JuiceManager.shake(0.25 + 0.1 * float(b))
	JuiceManager.ring(p.global_position, Color("#FF0055"), 30.0 + 8.0 * float(b), 0.3, 3.0)
	if p.is_core:
		JuiceManager.text_pop(global_position + Vector2(0, -40), "RALLY %d / 5" % b, Projectile.TINTS[mini(b, 3)], 11)


func _core_shatter(p: Projectile) -> void:
	alive = false
	_cockpit_shield = false
	remove_from_group("enemies")
	p.call("_die")
	JuiceManager.hitstop(0.35)
	JuiceManager.flash(Color(1, 1, 1, 0.9), 0.3)
	JuiceManager.screen_shockwave(global_position, 2.0)
	JuiceManager.shake(1.0)
	AudioManager.play_sfx("blackout_rebound")
	AudioManager.play_sfx("rail", 0.7)
	_death_sequence()


func _death_sequence() -> void:
	for i: int in 9:
		await get_tree().create_timer(0.16, true, false, true).timeout
		var off := Vector2(randf_range(-60, 60), randf_range(-20, 20))
		FxLib.spawn(JuiceManager.fx_root, "explosion", "", global_position + off, 0.0, randf_range(1.2, 2.2))
		JuiceManager.fx("burst", ["gold", "magenta", "cyan"][i % 3], global_position + off, 0.0, 2.4)
		AudioManager.play_sfx("explosion", randf_range(0.7, 1.1))
		JuiceManager.shake(0.5)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "position", position + Vector2(260, 320), 1.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "rotation", 0.9, 1.6)
	tw.chain().tween_callback(func() -> void:
		defeated.emit()
		queue_free())


# ================================================================= phases

func _on_wing_killed(_w: EnemyBase) -> void:
	for w: EnemyBase in _wings:
		if is_instance_valid(w) and w.alive:
			return
	_begin_phase2()


func _clear_bullets() -> void:
	for n: Node in get_tree().get_nodes_in_group("projectiles"):
		if n is Projectile and not (n as Projectile).is_core:
			n.call("_fizzle")


func _begin_phase2() -> void:
	_transitioning = true
	_clear_bullets()
	AudioManager.play_sfx("boss_alarm")
	JuiceManager.ring(global_position, Color("#4A00E0"), 120.0, 0.6, 5.0, true)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector2.ONE * BG_SCALE, 0.6).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(self, "modulate", BG_TINT, 0.6)
	tw.tween_property(self, "position:y", arena.position.y - 34.0, 0.6)
	tw.chain().tween_callback(func() -> void:
		lane = 1
		z_index = -5
		phase = 2
		_fire_t = 1.2
		_transitioning = false
		phase_changed.emit(2))


func _begin_phase3() -> void:
	_transitioning = true
	_clear_bullets()
	AudioManager.play_sfx("boss_alarm")
	JuiceManager.flash(Color(1, 0.0, 0.2, 0.4), 0.2)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_BACK)
	tw.tween_property(self, "modulate", Color.WHITE, 0.7)
	tw.tween_property(self, "position", Vector2(arena.get_center().x, arena.position.y), 0.7)
	tw.chain().tween_callback(func() -> void:
		lane = 0
		z_index = 4
		phase = 3
		_cockpit_shield = true
		_core_cd = 1.2
		_transitioning = false
		phase_changed.emit(3))


func hp_fraction() -> float:
	if phase == 1:
		var wings_hp: int = 0
		for w: EnemyBase in _wings:
			if is_instance_valid(w) and w.alive:
				wings_hp += w.hp
		return 0.6 + 0.4 * float(wings_hp) / 4.0
	return float(hp) / float(HP_MAX)


func shove(_v: Vector2) -> void:
	pass


func _flash(color: Color, dur: float) -> void:
	_flash_mat.set_shader_parameter("flash_color", color)
	_flash_mat.set_shader_parameter("active", true)
	_flash_t = dur


func _draw_overlay() -> void:
	if _cockpit_shield and alive:
		var r: float = 44.0 + (6.0 if _shield_pulse > 0.0 else 0.0)
		var col := Color(1.0, 0.0, 0.33, 0.45 + 0.2 * sin(_t * 7.0) + (0.4 if _shield_pulse > 0.0 else 0.0))
		var pts := PackedVector2Array()
		for i: int in 7:
			pts.append(Vector2.from_angle(TAU * float(i) / 6.0 + _t) * r)
		_overlay.draw_polyline(pts, col, 2.0 if _shield_pulse <= 0.0 else 4.0)
		_overlay.draw_arc(Vector2.ZERO, r * 0.8, 0.0, TAU, 32, Color(1, 0.6, 0.0, 0.25), 1.0)
