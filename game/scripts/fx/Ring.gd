class_name Ring
extends Node2D

var max_radius: float = 60.0
var duration: float = 0.35
var color: Color = Color("#00F0FF")
var width: float = 4.0
var filled_flash: bool = false

var _t: float = 0.0
var _last_ms: int = 0


func _ready() -> void:
	_last_ms = Time.get_ticks_msec()
	z_index = 30


func _process(_delta: float) -> void:
	var now: int = Time.get_ticks_msec()
	_t += float(now - _last_ms) / 1000.0
	_last_ms = now
	if _t >= duration:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k: float = clampf(_t / duration, 0.0, 1.0)
	var ease_k: float = 1.0 - pow(1.0 - k, 3.0)
	var r: float = max_radius * ease_k
	var c: Color = color
	c.a = 1.0 - k
	if filled_flash and k < 0.35:
		var fc: Color = Color(1, 1, 1, (0.35 - k) * 1.2)
		draw_circle(Vector2.ZERO, r * 0.8, fc)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, c, maxf(1.0, width * (1.0 - k)))
	var c2: Color = c
	c2.a *= 0.4
	draw_arc(Vector2.ZERO, r * 0.72, 0.0, TAU, 40, c2, maxf(1.0, width * 0.5 * (1.0 - k)))
