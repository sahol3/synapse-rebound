class_name ModulePickup
extends Area2D
## A stolen neural module ripped back from a Command Enforcer.

signal collected

var stage_index: int = 1
var _t: float = 0.0
var _taken: bool = false
var _sprite: AnimatedSprite2D
var _base_y: float


func _ready() -> void:
	collision_layer = 0
	collision_mask = GameState.BIT_PLAYER_HURT
	monitorable = false
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 16.0
	cs.shape = c
	add_child(cs)
	_sprite = FxLib.sprite("pickup", "green")
	_sprite.scale = Vector2(2.4, 2.4)
	add_child(_sprite)
	var l := Label.new()
	l.text = "MODULE 0%d" % stage_index
	l.add_theme_font_size_override("font_size", 28)
	l.add_theme_color_override("font_color", Color("#5CFFB0"))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 6)
	l.scale = Vector2(0.25, 0.25)
	l.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	l.position = Vector2(-l.get_minimum_size().x * 0.125, -30)
	add_child(l)
	z_index = 10
	_base_y = position.y
	area_entered.connect(_on_area)
	JuiceManager.ring(global_position, Color("#5CFFB0"), 60.0, 0.6, 4.0, true)


func _process(delta: float) -> void:
	_t += delta
	position.y = _base_y + sin(_t * 3.0) * 3.0
	if int(_t * 2.0) % 2 == 0 and fmod(_t, 0.5) < delta:
		JuiceManager.ring(global_position, Color("#5CFFB0"), 26.0, 0.5, 2.0)


func _on_area(a: Area2D) -> void:
	if _taken or not (a.get_meta("entity", null) is Player):
		return
	_taken = true
	AudioManager.play_sfx("module")
	JuiceManager.ring(global_position, Color("#5CFFB0"), 120.0, 0.6, 6.0, true)
	JuiceManager.screen_shockwave(global_position, 1.2)
	JuiceManager.flash(Color(0.4, 1.0, 0.7, 0.5), 0.2)
	collected.emit()
	queue_free()
