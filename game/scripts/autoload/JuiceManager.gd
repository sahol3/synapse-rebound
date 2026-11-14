extends Node

const GHOST_COLORS: Array[Color] = [Color("#00F0FF"), Color("#FF0055"), Color("#4A00E0")]

var fx_root: Node2D
var camera: Camera2D
var post_fx: Node

var base_time_scale: float = 1.0
var _hitstop_until_ms: int = 0
var _slowmo_token: int = 0
var _ghost_index: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	if _hitstop_until_ms > 0 and Time.get_ticks_msec() >= _hitstop_until_ms:
		_hitstop_until_ms = 0
		Engine.time_scale = base_time_scale


func hitstop(duration: float) -> void:
	var end_ms: int = Time.get_ticks_msec() + int(duration * 1000.0)
	if end_ms <= _hitstop_until_ms:
		return
	_hitstop_until_ms = end_ms
	Engine.time_scale = 0.04


func set_base_time_scale(value: float) -> void:
	base_time_scale = value
	if _hitstop_until_ms == 0:
		Engine.time_scale = value


func slowmo(scale: float, real_seconds: float) -> void:
	if base_time_scale < scale:
		return
	_slowmo_token += 1
	var token: int = _slowmo_token
	set_base_time_scale(scale)
	await get_tree().create_timer(real_seconds, true, false, true).timeout
	if token == _slowmo_token and is_equal_approx(base_time_scale, scale):
		set_base_time_scale(1.0)


func reset_time() -> void:
	_slowmo_token += 1
	_hitstop_until_ms = 0
	base_time_scale = 1.0
	Engine.time_scale = 1.0


func shake(trauma: float) -> void:
	if camera and camera.has_method("add_trauma"):
		camera.add_trauma(trauma)


func flash(color: Color, duration: float = 0.12) -> void:
	if post_fx and post_fx.has_method("flash"):
		post_fx.flash(color, duration)


func screen_shockwave(world_pos: Vector2, strength: float = 1.0) -> void:
	if post_fx and post_fx.has_method("shockwave"):
		post_fx.shockwave(world_pos, strength)


func ring(pos: Vector2, color: Color, radius: float = 60.0, duration: float = 0.35,
		width: float = 4.0, flash_fill: bool = false) -> void:
	if fx_root == null or not is_instance_valid(fx_root):
		return
	var r := Ring.new()
	r.max_radius = radius
	r.duration = duration
	r.color = color
	r.width = width
	r.filled_flash = flash_fill
	fx_root.add_child(r)
	r.global_position = pos


func fx(anim: String, color: String, pos: Vector2, rot: float = 0.0, scl: float = 1.0,
		tint: Color = Color.WHITE) -> AnimatedSprite2D:
	return FxLib.spawn(fx_root, anim, color, pos, rot, scl, tint)


func ghost(source: AnimatedSprite2D, color_override: Color = Color(0, 0, 0, 0)) -> void:
	if fx_root == null or source == null or source.sprite_frames == null:
		return
	var tex: Texture2D = source.sprite_frames.get_frame_texture(source.animation, source.frame)
	if tex == null:
		return
	var g := Sprite2D.new()
	g.texture = tex
	g.flip_h = source.flip_h
	g.offset = source.offset
	g.centered = source.centered
	g.z_index = source.z_index - 1 if source.z_index > -4 else -6
	var c: Color = color_override
	if c.a == 0.0:
		c = GHOST_COLORS[_ghost_index % GHOST_COLORS.size()]
		_ghost_index += 1
	c.a = 0.7
	g.modulate = c
	fx_root.add_child(g)
	g.global_transform = source.global_transform
	var tw := g.create_tween()
	tw.set_ignore_time_scale(true)
	tw.tween_property(g, "modulate:a", 0.0, 0.25)
	tw.tween_callback(g.queue_free)


func text_pop(pos: Vector2, text: String, color: Color, size: int = 10) -> void:
	if fx_root == null:
		return
	var l := PixelFont.label(text, 2 if size >= 14 else 1, color)
	l.z_index = 40
	fx_root.add_child(l)
	var start: Vector2 = (pos + Vector2(-l.get_minimum_size().x * 0.5, -16)).round()
	l.global_position = start
	var tw := l.create_tween()
	tw.set_ignore_time_scale(true)
	tw.tween_method(func(k: float) -> void:
		if is_instance_valid(l):
			l.global_position = start + Vector2(0, -roundf(12.0 * (1.0 - pow(1.0 - k, 3.0))))
			l.visible = k < 0.6 or int(k * 30.0) % 2 == 0, 0.0, 1.0, 0.65)
	tw.tween_callback(l.queue_free)
