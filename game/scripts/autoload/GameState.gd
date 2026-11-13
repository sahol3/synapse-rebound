extends Node
## Run-wide state: Neural Sync Rate, module choices, deaths, stats, input map.
## Every gameplay number that an upgrade changes is read through a function here,
## so the Stabilize / Overclock choices stay in one place.

signal sync_changed(value: float, tier: int)
signal tier_changed(tier: int)
signal module_chosen(stage: int, choice: String)
signal stats_changed

enum Tier { DEGRADED, SYNCHRONIZED, OVERCLOCKED, BERSERK }

const SYNC_MAX: float = 400.0
const SYNC_PER_PARRY: float = 15.0
const SYNC_PER_AIR_CHAIN: float = 25.0
const SYNC_REBOUND: float = 50.0
const SYNC_DECAY_PER_SEC: float = 7.0
const SYNC_DECAY_DELAY: float = 2.5

## Physics layer bits (see project.godot [layer_names]).
const BIT_WORLD_FG: int = 1
const BIT_WORLD_BG: int = 2
const BIT_PLAYER_HURT: int = 4
const BIT_ENEMY_HURT: int = 8
const BIT_TRIGGER: int = 32

const TIER_NAMES: PackedStringArray = ["DEGRADED", "SYNCHRONIZED", "OVERCLOCKED", "BERSERK OVERDRIVE"]
const TIER_COLORS: Array[Color] = [
	Color("#00F0FF"), Color("#5CFFB0"), Color("#FF0055"), Color("#FF9900"),
]

## Module upgrade ids per stage: [stabilize, overclock].
const MODULE_MODS: Array = [
	["phase_dash", "shockwave_dash"],
	["chrono_sight", "prism_split"],
	["aegis", "berserk_lock"],
]

var sync_rate: float = 0.0
var tier: int = Tier.DEGRADED
var loop_deaths: int = 0
var current_stage: int = 1
var choices: Array[String] = []
var overclock_count: int = 0
var stabilize_count: int = 0
var corruption_count: int = 0
var run_time: float = 0.0
var timer_running: bool = false
var parries: int = 0
var kills: int = 0
var best_rally: int = 0
var rebounds: int = 0
var flags: Dictionary = {}
var current_lane: int = 0

var _since_last_sync_gain: float = 0.0


func _enter_tree() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_register_inputs()


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	var real_delta: float = delta / maxf(Engine.time_scale, 0.0001)
	if timer_running:
		run_time += real_delta
	_since_last_sync_gain += real_delta
	if has_mod("berserk_lock"):
		if sync_rate < SYNC_MAX:
			set_sync(SYNC_MAX)
		return
	if _since_last_sync_gain > SYNC_DECAY_DELAY and sync_rate > sync_floor():
		set_sync(maxf(sync_floor(), sync_rate - SYNC_DECAY_PER_SEC * real_delta))


# ---------------------------------------------------------------- sync

func add_sync(amount: float) -> void:
	_since_last_sync_gain = 0.0
	set_sync(sync_rate + amount)


func set_sync(value: float) -> void:
	var clamped: float = clampf(value, sync_floor(), SYNC_MAX)
	if has_mod("berserk_lock"):
		clamped = SYNC_MAX
	sync_rate = clamped
	var new_tier: int = tier_for(sync_rate)
	if new_tier != tier:
		tier = new_tier
		tier_changed.emit(tier)
	sync_changed.emit(sync_rate, tier)


func tier_for(value: float) -> int:
	if value >= 300.0:
		return Tier.BERSERK
	if value >= 200.0:
		return Tier.OVERCLOCKED
	if value >= 100.0:
		return Tier.SYNCHRONIZED
	return Tier.DEGRADED


func sync_floor() -> float:
	## Each Overclock choice burns in a permanent +100% floor.
	return minf(100.0 * float(overclock_count), 300.0)


# ---------------------------------------------------------------- modules

func choose_module(stage: int, choice: String) -> void:
	choices.append(choice)
	if choice == "E":
		overclock_count += 1
	else:
		stabilize_count += 1
		corruption_count = 0
	module_chosen.emit(stage, choice)
	set_sync(sync_rate)


func has_mod(id: String) -> bool:
	for i: int in choices.size():
		var pair: Array = MODULE_MODS[i]
		var picked: String = pair[0] if choices[i] == "Q" else pair[1]
		if picked == id:
			return true
	return false


func ending_id() -> String:
	if choices.size() < 3:
		return "C"
	if overclock_count == 0:
		return "A"
	if stabilize_count == 0:
		return "B"
	return "C"


# ---------------------------------------------------------------- tuning read by entities

func parry_window() -> float:
	return 0.18 + 0.03 * float(stabilize_count)


func parry_arc_degrees() -> float:
	var arc: float = 150.0
	if tier >= Tier.OVERCLOCKED:
		arc *= 1.25
	return arc


func blackout_duration() -> float:
	var base: float = 2.2 if has_mod("chrono_sight") else 1.5
	return base + 0.1 * float(stabilize_count)


func dash_cooldown() -> float:
	return 0.55 * (0.6 if has_mod("phase_dash") else 1.0)


func move_speed_mult() -> float:
	return 1.15 if tier >= Tier.SYNCHRONIZED else 1.0


func rally_accel() -> float:
	return 1.64 if has_mod("berserk_lock") else 1.32


func telegraph_sights() -> bool:
	return stabilize_count > 0


# ---------------------------------------------------------------- run lifecycle

func once(key: String) -> bool:
	## True the first time a key is seen this run.
	if flags.has(key):
		return false
	flags[key] = true
	return true


func reset_run() -> void:
	sync_rate = 0.0
	tier = Tier.DEGRADED
	loop_deaths = 0
	current_stage = 1
	choices.clear()
	overclock_count = 0
	stabilize_count = 0
	corruption_count = 0
	run_time = 0.0
	parries = 0
	kills = 0
	best_rally = 0
	rebounds = 0
	flags.clear()
	current_lane = 0
	timer_running = false
	sync_changed.emit(sync_rate, tier)
	stats_changed.emit()


func register_death() -> void:
	loop_deaths += 1
	corruption_count += 1
	stats_changed.emit()


func register_parry(bounce: int) -> void:
	parries += 1
	best_rally = maxi(best_rally, bounce)
	stats_changed.emit()


func register_kill() -> void:
	kills += 1
	stats_changed.emit()


func format_time(seconds: float) -> String:
	var m: int = int(seconds) / 60
	var s: float = fmod(seconds, 60.0)
	return "%02d:%05.2f" % [m, s]


# ---------------------------------------------------------------- input

func _register_inputs() -> void:
	_add_keys("move_left", [KEY_A, KEY_LEFT])
	_add_keys("move_right", [KEY_D, KEY_RIGHT])
	_add_keys("jump", [KEY_SPACE])
	_add_keys("dash", [KEY_SHIFT, KEY_K])
	_add_keys("lane_back", [KEY_W, KEY_UP])
	_add_keys("lane_front", [KEY_S, KEY_DOWN])
	_add_keys("choose_stabilize", [KEY_Q])
	_add_keys("choose_overclock", [KEY_E])
	_add_keys("pause", [KEY_ESCAPE, KEY_P])
	_add_keys("restart", [KEY_R])
	_add_keys("parry", [KEY_J])
	_add_mouse("parry", [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT])
	_add_mouse("lane_toggle", [MOUSE_BUTTON_MIDDLE])


func _add_keys(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.3)
	for k: int in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k as Key
		InputMap.action_add_event(action, ev)


func _add_mouse(action: String, buttons: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.3)
	for b: int in buttons:
		var ev := InputEventMouseButton.new()
		ev.button_index = b as MouseButton
		InputMap.action_add_event(action, ev)
