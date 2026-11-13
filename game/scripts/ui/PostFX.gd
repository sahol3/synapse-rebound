class_name PostFX
extends CanvasLayer
## Screen-space shader stack, each pass behind its own BackBufferCopy so they chain:
## shockwave -> blackout_crimson -> vhs_rewind -> crt_cyberpunk (scanlines, aberration, tier border, flashes).
## All animation runs on real time.

var _shock: ShaderMaterial
var _blackout: ShaderMaterial
var _vhs: ShaderMaterial
var _crt: ShaderMaterial
var _shock_rect: ColorRect
var _blackout_rect: ColorRect
var _vhs_rect: ColorRect
var _blackout_tw: Tween
var _flash_tw: Tween


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_shock_rect = _pass("res://shaders/shockwave.gdshader")
	_shock = _shock_rect.material
	_shock_rect.visible = false
	_blackout_rect = _pass("res://shaders/blackout_crimson.gdshader")
	_blackout = _blackout_rect.material
	_blackout_rect.visible = false
	_vhs_rect = _pass("res://shaders/vhs_rewind.gdshader")
	_vhs = _vhs_rect.material
	_vhs_rect.visible = false
	var crt_rect: ColorRect = _pass("res://shaders/crt_cyberpunk.gdshader")
	_crt = crt_rect.material
	GameState.tier_changed.connect(_on_tier)
	_on_tier(GameState.tier)


func _pass(shader_path: String) -> ColorRect:
	var bb := BackBufferCopy.new()
	bb.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	add_child(bb)
	var r := ColorRect.new()
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = load(shader_path)
	r.material = m
	add_child(r)
	return r


func _tween() -> Tween:
	var tw := create_tween()
	tw.set_ignore_time_scale(true)
	return tw


func flash(color: Color, duration: float) -> void:
	if _flash_tw:
		_flash_tw.kill()
	_crt.set_shader_parameter("flash_color", color)
	_flash_tw = _tween()
	_flash_tw.tween_method(func(a: float) -> void:
		_crt.set_shader_parameter("flash_color", Color(color.r, color.g, color.b, a)), color.a, 0.0, duration)


func shockwave(world_pos: Vector2, strength: float = 1.0) -> void:
	var vp := get_viewport()
	var screen: Vector2 = vp.get_canvas_transform() * world_pos
	var size: Vector2 = vp.get_visible_rect().size
	_shock.set_shader_parameter("center", screen / size)
	_shock.set_shader_parameter("aspect", size.x / size.y)
	_shock.set_shader_parameter("strength", 0.025 * strength)
	_shock_rect.visible = true
	var tw := _tween()
	tw.tween_method(func(r: float) -> void: _shock.set_shader_parameter("radius", r), 0.0, 0.9, 0.45)
	tw.tween_callback(func() -> void: _shock_rect.visible = false)


func set_blackout(active: bool) -> void:
	if _blackout_tw:
		_blackout_tw.kill()
	_blackout_rect.visible = true
	var cur: Variant = _blackout.get_shader_parameter("intensity")
	var from: float = float(cur) if cur != null else 0.0
	_blackout_tw = _tween()
	_blackout_tw.tween_method(func(v: float) -> void: _blackout.set_shader_parameter("intensity", v),
			from, 1.0 if active else 0.0, 0.12 if active else 0.2)
	if not active:
		_blackout_tw.tween_callback(func() -> void: _blackout_rect.visible = false)


func vhs(duration: float = 0.3) -> void:
	_vhs_rect.visible = true
	var tw := _tween()
	tw.tween_method(func(v: float) -> void: _vhs.set_shader_parameter("intensity", v), 1.0, 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void: _vhs_rect.visible = false)


func vhs_hold(on: bool) -> void:
	_vhs_rect.visible = on
	_vhs.set_shader_parameter("intensity", 0.85 if on else 0.0)


func _on_tier(t: int) -> void:
	_crt.set_shader_parameter("border_color", GameState.TIER_COLORS[t])
	## Frame only from Overclocked up; Degraded and Synced leave the screen edge alone.
	_crt.set_shader_parameter("border_strength", [0.0, 0.0, 0.8, 1.0][t])
	_crt.set_shader_parameter("berserk", 1.0 if t == GameState.Tier.BERSERK else 0.0)
	_crt.set_shader_parameter("aberration", 0.0)
