class_name ZRing
extends Area2D

var impulse: Vector2 = Vector2(0, -340)
var _cd: float = 0.0
var _sprite: AnimatedSprite2D
var _t: float = 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = GameState.BIT_PLAYER_HURT
	monitorable = false
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 13.0
	cs.shape = c
	add_child(cs)
	_sprite = FxLib.sprite("zring", "cyan")
	_sprite.scale = Vector2(2, 2)
	_sprite.z_index = -2
	add_child(_sprite)
	area_entered.connect(_on_area)


func _process(delta: float) -> void:
	_cd -= delta
	_t += delta
	var on: bool = int(_t * 4.0) % 2 == 0
	_sprite.modulate = Color(1, 1, 1, 1.0 if on else 0.7) if _cd <= 0.0 else Color(1, 1, 1, 0.25)


func _on_area(a: Area2D) -> void:
	var p: Player = a.get_meta("entity", null) as Player
	if p == null or _cd > 0.0:
		return
	_cd = 0.7
	p.zring_launch(1 - p.lane, impulse)
	JuiceManager.ring(global_position, Color("#00F0FF"), 36.0, 0.3, 3.0, true)
	JuiceManager.hitstop(0.05)
