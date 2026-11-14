class_name MainMenu
extends Node2D
## Title screen over a drifting, rain-soaked Warped City skyline. The interface layer is scaled by
## Display.ui, so positions are interface pixels (576x324 at the design size, more on other
## windows; the block stays centred vertically) and all text is PixelFont.
## W/S or the arrow keys move, Space, Enter or a click selects; the mouse also hovers items.
## Esc or Space leaves the Controls and Credits lists.

signal start_requested
signal continue_requested

const CYAN: Color = Color("#00F0FF")
const MAGENTA: Color = Color("#FF0055")
const AMBER: Color = Color("#FF9900")
const TEXT: Color = Color("#E9EEF7")
const DIM: Color = Color("#7F8AA6")
const INK: Color = Color("#0A0814")

const CONTROLS: Array = [
	["A  D", "Move"], ["Space", "Jump, hold for height. Again in the air: dash up"], ["Mouse", "Aim"],
	["Click", "Deflect toward the cursor"], ["Shift", "Air-dash toward the cursor"],
	["W  S", "Change depth lane right after a deflection"], ["Q  E", "Stabilize or Overclock a module"],
	["R", "Rewind to the last checkpoint"], ["Esc", "Pause"], ["F11", "Fullscreen"],
]
const CREDITS: Array = [
	["Art and music", "Warped City by Ansimuz (CC0)"],
	["Enemy characters", "Sideview Sci-Fi by Ansimuz (CC0)"],
	["Effects", "Free Effect and Bullet 16x16 by BDragon1727"],
	["Sound effects", "Kenney sound packs (CC0)"],
	["Typeface", "m5x7 by Daniel Linssen"],
	["Engine", "Godot 4.7"],
	["", "No AI-generated art, music or voice."],
]

var _cam: Camera2D
var _ui: Control
var _layer: CanvasLayer
var _items: PackedStringArray = ["Start", "Controls", "Credits"]
var _sel: int = 0
var _panel: String = ""
var _t: float = 0.0
var _started: bool = false
var _saved_stage: int = 0


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
	_cam.zoom = Vector2(Display.art, Display.art)
	_cam.position = Vector2(400, 110)
	add_child(_cam)
	_cam.make_current()
	JuiceManager.camera = null
	var saved: Dictionary = GameState.saved_run()
	if not saved.is_empty():
		_saved_stage = int(saved["stage"])
		_items = PackedStringArray(["Continue", "New game", "Controls", "Credits"])
	if OS.get_name() != "Web":
		_items.append("Quit")
	var layer := CanvasLayer.new()
	layer.layer = 55
	add_child(layer)
	_layer = layer
	_ui = Control.new()
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.draw.connect(_draw_ui)
	layer.add_child(_ui)
	Display.changed.connect(_apply_display)
	_apply_display()
	AudioManager.play_music("stage")
	AudioManager.set_menu_muffle(true)


func _apply_display() -> void:
	_cam.zoom = Vector2(Display.art, Display.art)
	_layer.transform = Transform2D.IDENTITY.scaled(Vector2(Display.ui, Display.ui))
	_ui.size = Display.ui_size


func _oy() -> float:
	## Vertical offset that keeps the 324-pixel-tall design block centred in a taller or shorter window.
	return floorf((_ui.size.y - 324.0) * 0.5)


func _process(delta: float) -> void:
	_t += delta
	_cam.position.x += 22.0 * delta
	if _cam.position.x > 2600.0:
		_cam.position.x = 400.0
	_cam.position = Vector2(_cam.position.x, 110.0)
	if _panel == "":
		var m: Vector2 = _ui.get_local_mouse_position()
		for i: int in _items.size():
			if Rect2(44, 148 + _oy() + i * 16, 120, 13).has_point(m) and _sel != i and Input.get_last_mouse_velocity().length() > 0.0:
				_sel = i
				AudioManager.play_sfx("ui_move")
	_ui.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if _started or _t < 0.6:
		return
	if _panel != "":
		if event.is_action_pressed("pause") or event.is_action_pressed("jump") or event.is_action_pressed("parry") \
				or event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
			_panel = ""
			AudioManager.play_sfx("ui_move")
		return
	if event.is_action_pressed("lane_back") or event.is_action_pressed("ui_up"):
		_sel = (_sel + _items.size() - 1) % _items.size()
		AudioManager.play_sfx("ui_move")
	elif event.is_action_pressed("lane_front") or event.is_action_pressed("ui_down"):
		_sel = (_sel + 1) % _items.size()
		AudioManager.play_sfx("ui_move")
	elif event.is_action_pressed("jump") or event.is_action_pressed("parry") or event.is_action_pressed("ui_accept"):
		_choose(_items[_sel])


func _choose(item: String) -> void:
	AudioManager.play_sfx("ui_select")
	match item:
		"Start", "New game":
			_started = true
			AudioManager.play_sfx("vhs_rewind")
			start_requested.emit()
		"Continue":
			_started = true
			AudioManager.play_sfx("vhs_rewind")
			continue_requested.emit()
		"Controls":
			_panel = "controls"
		"Credits":
			_panel = "credits"
		"Quit":
			get_tree().quit()


# ================================================================= drawing

func _txt(pos: Vector2, text: String, scale: int, col: Color, align: int = 0) -> void:
	PixelFont.draw(_ui, pos, text, scale, col, align)


func _draw_ui() -> void:
	_ui.draw_rect(Rect2(Vector2.ZERO, _ui.size), Color(INK.r, INK.g, INK.b, 0.38))
	var x: float = 48
	var oy: float = _oy()
	_txt(Vector2(x, 96 + oy), "SYNAPSE", 3, CYAN)
	var w1: float = PixelFont.width("SYNAPSE ", 3)
	_txt(Vector2(x + w1, 96 + oy), "//", 3, MAGENTA)
	_txt(Vector2(x + w1 + PixelFont.width("// ", 3), 96 + oy), "REBOUND", 3, TEXT)
	_txt(Vector2(x, 128 + oy), DialogueData.TAGLINE, 1, DIM)
	if _panel == "":
		for i: int in _items.size():
			var y: float = 150 + oy + i * 16
			var on: bool = i == _sel
			if on:
				_txt(Vector2(x, y), ">", 1, AMBER)
			_txt(Vector2(x + 12, y), _items[i], 1, TEXT if on else DIM)
			if _items[i] == "Continue":
				var stage_name: String = String(DialogueData.STAGES[_saved_stage - 1]["name"]).split(" // ")[0]
				_txt(Vector2(x + 12 + PixelFont.width("Continue   "), y), "%d  %s" % [_saved_stage, stage_name], 1, DIM)
	else:
		_draw_panel(CONTROLS if _panel == "controls" else CREDITS)
	_txt(Vector2(x, _ui.size.y - 20.0), "Hack Club Haven Dhaka 2026", 1, DIM)


func _draw_panel(rows: Array) -> void:
	var x: float = 48
	var key_w: float = 0.0
	for r: Array in rows:
		key_w = maxf(key_w, PixelFont.width(r[0]))
	for i: int in rows.size():
		var ry: float = 150 + _oy() + i * 13
		_txt(Vector2(x, ry), rows[i][0], 1, AMBER)
		_txt(Vector2(x + key_w + 12, ry), rows[i][1], 1, TEXT)
