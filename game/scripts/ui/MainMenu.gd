class_name MainMenu
extends Node2D
## Title screen over a drifting, rain-soaked Warped City skyline.

signal start_requested

var _cam: Camera2D
var _title: Label
var _prompt: Label
var _t: float = 0.0
var _started: bool = false


class Backdrop extends StageBase:
	func _init() -> void:
		stage_index = 0
		bounds = Rect2i(0, -10, 200, 30)
		kill_y = 1e9

	func build() -> void:
		var c: int = 0
		var tops: Array[int] = [9, 7, 10, 6, 8, 11, 5, 9, 7, 10]
		var i: int = 0
		while c < 190:
			var w: int = 7 + (i * 5) % 6
			building(c, c + w, tops[i % tops.size()])
			if i % 2 == 0:
				building(c + 3, c + w + 4, tops[(i + 3) % tops.size()] - 4, 1)
			c += w + 3
			i += 1
		for k: int in 12:
			prop(["banner_neon", "banner_big", "banner_coke", "banner_side"][k % 4], 6.0 + float(k) * 15.0, 12.0)
		add_traffic(10, -40.0, 60.0, 80.0)


func _ready() -> void:
	var bd := Backdrop.new()
	add_child(bd)
	JuiceManager.fx_root = bd.fx
	_cam = Camera2D.new()
	_cam.zoom = Vector2(3, 3)
	_cam.position = Vector2(400, 110)
	add_child(_cam)
	_cam.make_current()
	JuiceManager.camera = null
	var ui := CanvasLayer.new()
	ui.layer = 55
	add_child(ui)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(root)
	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.0, 0.05, 0.45)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shade)
	_title = _label("SYNAPSE // REBOUND", 78, Color("#00F0FF"))
	_title.position = Vector2(0, 150)
	_title.size = Vector2(1152, 100)
	var glitch := ShaderMaterial.new()
	glitch.shader = load("res://shaders/glitch_text.gdshader")
	glitch.set_shader_parameter("tint", Color("#00F0FF"))
	glitch.set_shader_parameter("intensity", 0.5)
	_title.material = glitch
	root.add_child(_title)
	var sub := _label("NEO-DHAKA  //  00:00:00  //  LAZARUS LOOP ARMED  //  BOUNCE BACK", 18, Color("#FF0055"))
	sub.position = Vector2(0, 250)
	sub.size = Vector2(1152, 30)
	root.add_child(sub)
	_prompt = _label("CLICK  OR  PRESS  SPACE  TO  WAKE  UP", 26, Color.WHITE)
	_prompt.position = Vector2(0, 340)
	_prompt.size = Vector2(1152, 40)
	root.add_child(_prompt)
	var controls := _label("[A][D] MOVE    [SPACE] JUMP    [MOUSE] AIM    [CLICK] DEFLECT    [SHIFT] AIR-DASH\n[W][S] SWITCH DEPTH LANE AFTER A DEFLECTION    [Q][E] MODULE CHOICE    [R] REWIND    [ESC] PAUSE", 15, Color(0.75, 0.85, 1.0))
	controls.position = Vector2(0, 450)
	controls.size = Vector2(1152, 60)
	root.add_child(controls)
	var credit := _label("Hack Club Haven Dhaka 2026  //  Art & music: Ansimuz \"Warped City\", BDragon1727 effects  //  No AI-generated art or audio", 12, Color(0.55, 0.6, 0.75))
	credit.position = Vector2(0, 606)
	credit.size = Vector2(1152, 20)
	root.add_child(credit)
	AudioManager.play_music("stage")
	AudioManager.set_menu_muffle(true)


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 8)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _process(delta: float) -> void:
	_t += delta
	_cam.position.x += 22.0 * delta
	if _cam.position.x > 2600.0:
		_cam.position.x = 400.0
	_prompt.modulate.a = 0.55 + 0.45 * sin(_t * 4.0)


func _unhandled_input(event: InputEvent) -> void:
	if _started or _t < 0.6:
		return
	if event.is_action_pressed("jump") or event.is_action_pressed("parry"):
		_started = true
		AudioManager.play_sfx("ui_select")
		AudioManager.play_sfx("vhs_rewind")
		start_requested.emit()
