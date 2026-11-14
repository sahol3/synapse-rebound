extends Node

signal changed

const DESIGN_VIEW: Vector2 = Vector2(384, 216)
const MIN_VIEW_W: float = 320.0
const MAX_VIEW_H: float = 300.0
const MIN_UI: Vector2 = Vector2(480, 270)
const DESIGN_UI_H: float = 324.0

var art: int = 3
var ui: int = 2
var size: Vector2 = Vector2(1152, 648)
var view: Vector2 = Vector2(384, 216)
var ui_size: Vector2 = Vector2(576, 324)

var _shot_path: String = ""
var _shot_frame: int = 150
var _frame: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var win: Window = get_window()
	win.min_size = Vector2i(640, 360)
	get_tree().root.size_changed.connect(_recompute)
	_recompute()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			_shot_path = arg.get_slice("=", 1)
		elif arg.begins_with("--shot-frame="):
			_shot_frame = int(arg.get_slice("=", 1))
	set_process(_shot_path != "")
	if _should_maximize():
		win.mode = Window.MODE_MAXIMIZED


func _process(_delta: float) -> void:
	_frame += 1
	if _frame == _shot_frame:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(_shot_path)
		get_tree().quit()


func _should_maximize() -> bool:
	if OS.get_name() == "Web" or DisplayServer.get_name() == "headless" or OS.has_feature("editor") or OS.has_feature("movie") or GameState.is_dev_run():
		return false
	var design := Vector2i(int(ProjectSettings.get_setting("display/window/size/viewport_width")),
			int(ProjectSettings.get_setting("display/window/size/viewport_height")))
	return get_window().size == design


static func scales_for(window: Vector2) -> Vector2i:
	var a: int = maxi(1, int(floor(window.y / DESIGN_VIEW.y + 0.25)))
	while window.y / float(a) > MAX_VIEW_H:
		a += 1
	while a > 1 and window.x / float(a) < MIN_VIEW_W:
		a -= 1
	var u: int = maxi(1, int(round(window.y / DESIGN_UI_H)))
	while u > 1 and (window.x / float(u) < MIN_UI.x or window.y / float(u) < MIN_UI.y):
		u -= 1
	return Vector2i(a, u)


func _recompute() -> void:
	var s: Vector2 = Vector2(get_tree().root.size)
	if s.x < 1.0 or s.y < 1.0:
		return
	var sc: Vector2i = scales_for(s)
	var new_view: Vector2 = (s / float(sc.x)).floor()
	var new_ui: Vector2 = (s / float(sc.y)).floor()
	if s == size and sc.x == art and sc.y == ui:
		return
	size = s
	art = sc.x
	ui = sc.y
	view = new_view
	ui_size = new_ui
	changed.emit()


func _input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.physical_keycode == KEY_F11 or (key.physical_keycode == KEY_ENTER and key.alt_pressed):
		var win: Window = get_window()
		var full: bool = win.mode == Window.MODE_FULLSCREEN or win.mode == Window.MODE_EXCLUSIVE_FULLSCREEN
		win.mode = Window.MODE_MAXIMIZED if full else Window.MODE_FULLSCREEN
		get_viewport().set_input_as_handled()
