class_name Rain
extends Node2D

const BASE_COUNT: int = 140
const BASE_AREA: Vector2 = Vector2(460, 300)

var _area: Vector2 = BASE_AREA
var _drops: PackedVector2Array = PackedVector2Array()
var _speeds: PackedFloat32Array = PackedFloat32Array()
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 77
	Display.changed.connect(_rebuild)
	_rebuild()


func _rebuild() -> void:
	_area = Vector2(maxf(BASE_AREA.x, Display.view.x + 76.0), maxf(BASE_AREA.y, Display.view.y + 84.0))
	var count: int = int(round(float(BASE_COUNT) * (_area.x * _area.y) / (BASE_AREA.x * BASE_AREA.y)))
	_drops.clear()
	_speeds.clear()
	for i: int in count:
		_drops.append(Vector2(_rng.randf_range(-_area.x, _area.x) * 0.5, _rng.randf_range(-_area.y, _area.y) * 0.5))
		_speeds.append(_rng.randf_range(260.0, 420.0))


func _process(delta: float) -> void:
	var cam: Camera2D = JuiceManager.camera
	if cam:
		global_position = cam.get_screen_center_position()
	for i: int in _drops.size():
		var d: Vector2 = _drops[i]
		d += Vector2(-0.18, 1.0) * _speeds[i] * delta
		if d.y > _area.y * 0.5:
			d.y -= _area.y
			d.x = _rng.randf_range(-_area.x, _area.x) * 0.5
		if d.x < -_area.x * 0.5:
			d.x += _area.x
		_drops[i] = d
	queue_redraw()


func _draw() -> void:
	var tilt := Vector2(-0.18, 1.0) * 7.0
	for i: int in _drops.size():
		var a: float = 0.12 + 0.18 * (_speeds[i] - 260.0) / 160.0
		draw_line(_drops[i], _drops[i] + tilt, Color(0.6, 0.85, 1.0, a), 1.0)
