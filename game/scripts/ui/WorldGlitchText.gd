class_name WorldGlitchText
extends Node2D
## The Echo's kinetic typography, burned onto the buildings between the depth lane and the
## foreground. Slams in oversized, glitches, then burns out. Real-time animation.

var text: String = ""
var intensity: float = 1.0
var hold: float = 2.4

var _label: Label


func _ready() -> void:
	_label = Label.new()
	_label.text = text
	_label.add_theme_font_size_override("font_size", 64)
	_label.add_theme_color_override("font_color", Color(1, 0.05, 0.2))
	_label.add_theme_color_override("font_outline_color", Color(0.15, 0.0, 0.05))
	_label.add_theme_constant_override("outline_size", 6)
	_label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/glitch_text.gdshader")
	mat.set_shader_parameter("intensity", intensity)
	_label.material = mat
	add_child(_label)
	var size: Vector2 = _label.get_minimum_size()
	_label.position = -size * 0.5
	var base: float = clampf(300.0 / maxf(size.x, 1.0), 0.12, 0.42)
	scale = Vector2.ONE * base * 1.6
	modulate.a = 0.0
	var tw := create_tween()
	tw.set_ignore_time_scale(true)
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector2.ONE * base, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 0.85 * intensity + 0.15, 0.08)
	tw.chain().tween_interval(hold)
	tw.chain().tween_property(self, "modulate:a", 0.0, 0.6)
	tw.chain().tween_callback(queue_free)
