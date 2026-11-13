extends Node
## Hit-stop, slow motion, camera trauma, shockwave rings, Sandevistan afterimages,
## screen flashes. Owns Engine.time_scale so overlapping effects never fight:
## base_time_scale is the "world speed" (Blackout, Chrono-Sight, module prompt),
## hit-stop temporarily overrides it and always restores to the current base.

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


# ---------------------------------------------------------------- time

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
	## Temporary base slowdown (Chrono-Sight). Never overrides a slower base (Blackout).
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


# ---------------------------------------------------------------- camera / screen

func shake(trauma: float) -> void:
	if camera and camera.has_method("add_trauma"):
		camera.add_trauma(trauma)


func flash(color: Color, duration: float = 0.12) -> void:
	if post_fx and post_fx.has_method("flash"):
		post_fx.flash(color, duration)


func screen_shockwave(world_pos: Vector2, strength: float = 1.0) -> void:
	if post_fx and post_fx.has_method("shockwave"):
		post_fx.shockwave(world_pos, strength)


# ---------------------------------------------------------------- spawners

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
	## Sandevistan afterimage: a frozen copy of the current frame that fades out.
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
	## Small world-space kinetic number ("x3 RALLY", "+50%").
	if fx_root == null:
		return
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size * 4)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.02, 0.0, 0.06))
	l.add_theme_constant_override("outline_size", 10)
	l.scale = Vector2(0.25, 0.25)
	l.z_index = 40
	l.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	fx_root.add_child(l)
	l.global_position = pos + Vector2(-l.get_minimum_size().x * 0.125, -14)
	var tw := l.create_tween()
	tw.set_ignore_time_scale(true)
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 18.0, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.6).set_delay(0.25)
	tw.chain().tween_callback(l.queue_free)
