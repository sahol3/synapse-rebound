extends Node
## Run-wide state: Neural Sync Rate, module choices, deaths, stats, input map.
## Every gameplay number that an upgrade changes is read through a function here,
## so the Stabilize / Overclock choices stay in one place.

signal sync_changed(value: float, tier: int)
signal tier_changed(tier: int)
signal module_chosen(stage: int, choice: String)
signal stats_changed
signal memory_unlocked(id: String)

enum Tier { DEGRADED, SYNCHRONIZED, OVERCLOCKED, BERSERK }

const SYNC_MAX: float = 400.0
const SYNC_PER_PARRY: float = 15.0
const SYNC_PER_AIR_CHAIN: float = 25.0
const SYNC_REBOUND: float = 50.0
const SYNC_DECAY_PER_SEC: float = 7.0
const SYNC_DECAY_DELAY: float = 2.5
const SAVE_VERSION: int = 1

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
## Progress saving. Off for tests, captures and debug starts (see is_dev_run).
var persist: bool = true
var save_path: String = "user://save.json"

var _since_last_sync_gain: float = 0.0


func _enter_tree() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	persist = not is_dev_run()
	for arg: String in OS.get_cmdline_user_args():
		## Dev check of the real save path in an exported build: `-- --save-file=name.json` saves to
		## that file in the user folder even on a debug start, and never to the player's own save.
		if arg.begins_with("--save-file="):
			save_path = "user://" + arg.get_slice("=", 1).get_file()
			persist = true
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
	return 0.18 + 0.03 * float(stabilize_count) + Director.parry_window_bonus()


func parry_arc_degrees() -> float:
	var arc: float = 150.0
	if tier >= Tier.OVERCLOCKED:
		arc *= 1.25
	return minf(arc * Director.parry_arc_mult(), 300.0)


func blackout_duration() -> float:
	var base: float = 2.2 if has_mod("chrono_sight") else 1.5
	return base + 0.1 * float(stabilize_count) + Director.blackout_bonus()


func dash_cooldown() -> float:
	return 0.55 * (0.6 if has_mod("phase_dash") else 1.0)


func move_speed_mult() -> float:
	return 1.15 if tier >= Tier.SYNCHRONIZED else 1.0


func rally_accel() -> float:
	return 1.64 if has_mod("berserk_lock") else 1.32


func telegraph_sights() -> bool:
	return stabilize_count > 0 or Director.show_sights()


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


# ---------------------------------------------------------------- progress saving

static func is_dev_run() -> bool:
	## Tests, frame captures and the `--stage=N` debug start must never touch the player's files.
	if DisplayServer.get_name() == "headless" or OS.has_feature("movie"):
		return true
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--stage=") or a.begins_with("--shot="):
			return true
	return false


func save_run(room: int) -> void:
	## Called at every stage start, checkpoint and death. One small JSON file.
	if not persist:
		return
	var f: FileAccess = FileAccess.open(save_path, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({
		"v": SAVE_VERSION, "stage": current_stage, "room": room, "choices": Array(choices),
		"loop_deaths": loop_deaths, "run_time": run_time, "parries": parries, "kills": kills,
		"best_rally": best_rally, "rebounds": rebounds, "flags": flags.keys(),
	}))
	f.close()


func saved_run() -> Dictionary:
	## The saved run, or an empty dictionary when there is none or the file is unusable.
	if not FileAccess.file_exists(save_path):
		return {}
	var f: FileAccess = FileAccess.open(save_path, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if not (parsed is Dictionary):
		return {}
	var d: Dictionary = parsed
	var stage: int = int(d.get("stage", 0))
	var picked: Variant = d.get("choices", [])
	if int(d.get("v", 0)) != SAVE_VERSION or stage < 1 or stage > 4 or not (picked is Array):
		return {}
	## A stage can only be reached with one module choice per earlier stage.
	if (picked as Array).size() != stage - 1:
		return {}
	for c: Variant in picked:
		if not (c is String) or not (c in ["Q", "E"]):
			return {}
	return d


func apply_save(d: Dictionary) -> void:
	## Restore a saved run. Call after reset_run().
	var picked: Array = d.get("choices", [])
	for i: int in picked.size():
		choose_module(i + 1, String(picked[i]))
	current_stage = int(d.get("stage", 1))
	loop_deaths = int(d.get("loop_deaths", 0))
	run_time = float(d.get("run_time", 0.0))
	parries = int(d.get("parries", 0))
	kills = int(d.get("kills", 0))
	best_rally = int(d.get("best_rally", 0))
	rebounds = int(d.get("rebounds", 0))
	for k: Variant in d.get("flags", []):
		flags[String(k)] = true
	set_sync(sync_floor())
	stats_changed.emit()


func clear_save() -> void:
	if persist and FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))


# ---------------------------------------------------------------- lifetime progress (across runs)

var _meta: Dictionary = {}
var _meta_from: String = ""


func meta_path() -> String:
	## Sits beside the run save, so a test or dev run that redirects the save redirects this too.
	return save_path.get_basename() + "_meta.json"


func meta() -> Dictionary:
	## Recovered memories, endings seen and personal bests. Read from disk once per path, and only
	## when saving is on, so a dev run never shows or changes the player's own progress.
	var path: String = meta_path() + ("" if persist else "?off")
	if _meta_from == path:
		return _meta
	_meta_from = path
	_meta = {"memories": [], "endings": [], "best_time": 0.0, "best_rally": 0, "finished": 0}
	if not persist or not FileAccess.file_exists(meta_path()):
		return _meta
	var f: FileAccess = FileAccess.open(meta_path(), FileAccess.READ)
	if f == null:
		return _meta
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if not (parsed is Dictionary):
		return _meta
	for key: String in ["memories", "endings"]:
		var list: Variant = (parsed as Dictionary).get(key, [])
		if list is Array:
			for v: Variant in list:
				if v is String and not (v in _meta[key]):
					_meta[key].append(v)
	_meta["best_time"] = maxf(float((parsed as Dictionary).get("best_time", 0.0)), 0.0)
	_meta["best_rally"] = maxi(int((parsed as Dictionary).get("best_rally", 0)), 0)
	_meta["finished"] = maxi(int((parsed as Dictionary).get("finished", 0)), 0)
	return _meta


func _save_meta() -> void:
	if not persist:
		return
	var f: FileAccess = FileAccess.open(meta_path(), FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(_meta))
	f.close()


func has_memory(id: String) -> bool:
	return not DialogueData.memory(id).has("how") or id in meta()["memories"]


func memory_count() -> int:
	var n: int = 0
	for m: Dictionary in DialogueData.MEMORIES:
		if has_memory(m["id"]):
			n += 1
	return n


func unlock_memory(id: String) -> bool:
	## True the first time. Recovered memories stay recovered across runs.
	if has_memory(id) or DialogueData.memory(id).is_empty():
		return false
	meta()["memories"].append(id)
	_save_meta()
	memory_unlocked.emit(id)
	return true


func note_rally(bounces: int) -> bool:
	## True when this is the longest rally the player has ever held.
	if bounces <= int(meta()["best_rally"]):
		return false
	meta()["best_rally"] = bounces
	_save_meta()
	return true


func record_ending(id: String) -> Dictionary:
	## Called once when the boss falls. Says what was new about this finish.
	var m: Dictionary = meta()
	var out: Dictionary = {"new_ending": not (id in m["endings"]), "best_time": false}
	if out["new_ending"]:
		m["endings"].append(id)
	if float(m["best_time"]) <= 0.0 or run_time < float(m["best_time"]):
		out["best_time"] = int(m["finished"]) > 0
		m["best_time"] = run_time
	m["finished"] = int(m["finished"]) + 1
	_save_meta()
	unlock_memory("sara")
	unlock_memory("end_" + id)
	return out


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
