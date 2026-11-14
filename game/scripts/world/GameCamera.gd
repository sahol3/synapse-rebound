class_name GameCamera
extends Camera2D

const LOOK_AHEAD: float = 0.16
const MAX_OFFSET: Vector2 = Vector2(14, 10)
const MAX_ROLL: float = 0.025

var target: Node2D
var trauma: float = 0.0
var fixed_point: Vector2 = Vector2.ZERO
var use_fixed: bool = false
var vertical_bias: float = -18.0
var lock_y: float = NAN

var _noise := FastNoiseLite.new()
var _t: float = 0.0
var _last_ms: int = 0
var _limit_rect: Rect2
var _has_limits: bool = false


func _ready() -> void:
	Display.changed.connect(_apply_display)
	_apply_display()
	position_smoothing_enabled = true
	position_smoothing_speed = 7.0
	ignore_rotation = false
	_noise.seed = 4
	_noise.frequency = 0.9
	_last_ms = Time.get_ticks_msec()
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS


func add_trauma(amount: float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)


func set_limits(rect: Rect2) -> void:
	_limit_rect = rect
	_has_limits = true
	_apply_limits()


func _apply_display() -> void:
	zoom = Vector2(Display.art, Display.art)
	if _has_limits:
		_apply_limits()


func _apply_limits() -> void:
	var r: Rect2 = _limit_rect
	var v: Vector2 = Display.view
	if v.x > r.size.x:
		r.position.x -= (v.x - r.size.x) * 0.5
		r.size.x = v.x
	if v.y > r.size.y:
		r.position.y -= (v.y - r.size.y) * 0.5
		r.size.y = v.y
	limit_left = int(floor(r.position.x))
	limit_top = int(floor(r.position.y))
	limit_right = int(ceil(r.end.x))
	limit_bottom = int(ceil(r.end.y))


func snap_to_target() -> void:
	if target:
		global_position = target.global_position + Vector2(0, vertical_bias)
		if not is_nan(lock_y):
			global_position.y = lock_y
		reset_smoothing()


func _physics_process(_delta: float) -> void:
	var now: int = Time.get_ticks_msec()
	var real_delta: float = minf(float(now - _last_ms) / 1000.0, 0.1)
	_last_ms = now
	_t += real_delta
	if use_fixed:
		global_position = fixed_point
	elif target and is_instance_valid(target):
		var look: Vector2 = (get_global_mouse_position() - target.global_position) * LOOK_AHEAD
		look = look.clamp(Vector2(-70, -40), Vector2(70, 40))
		global_position = target.global_position + Vector2(0, vertical_bias) + look
		if not is_nan(lock_y):
			global_position.y = lock_y
	trauma = maxf(trauma - real_delta * 1.6, 0.0)
	var shake: float = trauma * trauma
	offset = Vector2(_noise.get_noise_2d(_t * 60.0, 0.0), _noise.get_noise_2d(0.0, _t * 60.0)) * MAX_OFFSET * shake
	rotation = _noise.get_noise_2d(_t * 40.0, 99.0) * MAX_ROLL * shake
