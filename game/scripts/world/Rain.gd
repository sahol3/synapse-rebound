class_name Rain
extends Node2D
## Acid rain drawn as streaks around the camera. Uses scaled delta, so it hangs in the air
## during hit-stop and crawls during Blackout.

const COUNT: int = 140
const AREA: Vector2 = Vector2(460, 300)

var _drops: PackedVector2Array = PackedVector2Array()
var _speeds: PackedFloat32Array = PackedFloat32Array()
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 77
	for i: int in COUNT:
		_drops.append(Vector2(_rng.randf_range(-AREA.x, AREA.x) * 0.5, _rng.randf_range(-AREA.y, AREA.y) * 0.5))
		_speeds.append(_rng.randf_range(260.0, 420.0))


func _process(delta: float) -> void:
	var cam: Camera2D = JuiceManager.camera
	if cam:
		global_position = cam.get_screen_center_position()
	for i: int in COUNT:
		var d: Vector2 = _drops[i]
		d += Vector2(-0.18, 1.0) * _speeds[i] * delta
		if d.y > AREA.y * 0.5:
			d.y -= AREA.y
			d.x = _rng.randf_range(-AREA.x, AREA.x) * 0.5
		if d.x < -AREA.x * 0.5:
			d.x += AREA.x
		_drops[i] = d
	queue_redraw()


func _draw() -> void:
	var tilt := Vector2(-0.18, 1.0) * 7.0
	for i: int in COUNT:
		var a: float = 0.12 + 0.18 * (_speeds[i] - 260.0) / 160.0
		draw_line(_drops[i], _drops[i] + tilt, Color(0.6, 0.85, 1.0, a), 1.0)
