extends Node
## Proves Stage 3 can be climbed from the floor to the roof deck with the keyboard alone:
## A/D, Space, and Space again in mid-air (the upward dash). No mouse aim, no deflections.
## Enemies are frozen; this test is about the geometry and the controls, not the fight.
## It climbs twice: once pressing the second Space at the top of the jump (best case) and once
## pressing it early, 0.12 s after take-off (the sloppy case a new player produces).
## Run: tools\bin\godot.cmd --headless --path game res://tests/ClimbTest.tscn
## Prints PASS/FAIL per check and "CLIMBTEST passed=N failed=M"; exit code 1 on any failure.

const T: int = 16
const FLOOR_ROW: int = 18
const TOP_ROW: int = -104
## The same ladder Stage03Shaft.gd builds: [first column, last column, row].
const PLATS: Array = [
	[4, 26, 18],
	[5, 10, 14], [16, 22, 10], [8, 13, 6], [19, 25, 2],
	[5, 11, -3], [15, 20, -7], [21, 25, -12], [8, 14, -16],
	[4, 8, -21], [13, 18, -25], [21, 26, -30], [11, 15, -35], [4, 9, -40],
	[14, 19, -45], [22, 26, -50], [12, 16, -55], [4, 9, -60], [16, 22, -65],
	[8, 13, -70], [19, 25, -75], [10, 15, -80], [4, 8, -85], [14, 20, -90],
	[21, 26, -95], [10, 16, -100],
	[4, 26, -104],
]

var main: Node
var passed: int = 0
var failed: int = 0

var _bot: bool = false
var _early: bool = false
var _no_air: bool = false
var _air_t: float = 0.0
var _air_jumped: bool = false
var _was_floor: bool = true
var _release_jump: bool = false
var _held_t: float = 0.0
var _jumps: int = 0
var _air_jumps: int = 0
var _falls: int = 0
var _last_index: int = 0


func _ready() -> void:
	Director.enabled = false
	Director.persist = false
	main = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	_run.call_deferred()


func _p() -> Player:
	var pl: Variant = main.get("player")
	return pl as Player if pl != null and is_instance_valid(pl) else null


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec, true, false, true).timeout


func _check(name: String, ok: bool, detail: String = "") -> void:
	if ok:
		passed += 1
		print("PASS  ", name, "  ", detail)
	else:
		failed += 1
		print("FAIL  ", name, "  ", detail)


func _index_under(p: Player) -> int:
	## Which ladder platform the player is standing on (-1 if none).
	var feet: float = p.global_position.y + Player.FEET_Y
	for i: int in PLATS.size():
		var pl: Array = PLATS[i]
		if absf(feet - float(int(pl[2]) * T)) < 6.0 and p.global_position.x > float(int(pl[0]) * T) - 8.0 \
				and p.global_position.x < float((int(pl[1]) + 1) * T) + 8.0:
			return i
	return -1


func _hold(action: String, on: bool) -> void:
	if on and not Input.is_action_pressed(action):
		Input.action_press(action)
	elif not on and Input.is_action_pressed(action):
		Input.action_release(action)


func _physics_process(delta: float) -> void:
	var p: Player = _p()
	if not _bot or p == null or p.dead:
		_hold("move_left", false)
		_hold("move_right", false)
		_hold("jump", false)
		return
	if _release_jump:
		## One physics frame with Space up, so the next press counts as a new press.
		_hold("jump", false)
		_release_jump = false
		return
	var on_floor: bool = p.is_on_floor()
	if on_floor and (not _was_floor or (Input.is_action_pressed("jump") and _held_t > 0.2)):
		## Just landed, or a held Space did nothing: let go so the next press is a fresh one.
		_hold("jump", false)
		_held_t = 0.0
		_was_floor = true
		return
	_held_t = _held_t + delta if Input.is_action_pressed("jump") else 0.0
	if on_floor:
		var here: int = _index_under(p)
		if here >= 0:
			if here < _last_index:
				_falls += 1
			_last_index = here
		_air_t = 0.0
		_air_jumped = false
		if here < 0 or here >= PLATS.size() - 1:
			_hold("move_left", false)
			_hold("move_right", false)
			_hold("jump", false)
			_was_floor = true
			return
		var cur: Array = PLATS[here]
		var nxt: Array = PLATS[here + 1]
		var target_x: float = (float(int(nxt[0])) + float(int(nxt[1]) + 1)) * 0.5 * T
		## Walk to the point of this platform nearest the next one, then jump toward it.
		var launch_x: float = clampf(target_x, float(int(cur[0]) * T) + 10.0, float((int(cur[1]) + 1) * T) - 10.0)
		var dx: float = launch_x - p.global_position.x
		if absf(dx) > 5.0:
			_hold("move_right", dx > 0.0)
			_hold("move_left", dx < 0.0)
			_hold("jump", false)
		else:
			_hold("move_right", target_x > p.global_position.x + 4.0)
			_hold("move_left", target_x < p.global_position.x - 4.0)
			if not Input.is_action_pressed("jump"):
				Input.action_press("jump")
				_jumps += 1
	else:
		_air_t += delta
		var goal: Array = PLATS[mini(_last_index + 1, PLATS.size() - 1)]
		var gx: float = clampf(p.global_position.x, float(int(goal[0]) * T) + 12.0, float((int(goal[1]) + 1) * T) - 12.0)
		_hold("move_right", gx > p.global_position.x + 3.0)
		_hold("move_left", gx < p.global_position.x - 3.0)
		var time_to_press: bool = _air_t >= 0.12 if _early else p.velocity.y > -30.0
		if not _no_air and not _air_jumped and time_to_press and _air_t > 0.05:
			if Input.is_action_pressed("jump"):
				_release_jump = true
			else:
				Input.action_press("jump")
				_air_jumped = true
				_air_jumps += 1
	_was_floor = on_floor


func _climb(early: bool, limit: float, no_air: bool = false) -> Dictionary:
	_no_air = no_air
	main.load_stage(3)
	await _wait(1.5)
	for e: Node in get_tree().get_nodes_in_group("enemies"):
		if e is EnemyBase:
			(e as EnemyBase).active = false
	_early = early
	_jumps = 0
	_air_jumps = 0
	_falls = 0
	_last_index = 0
	var deaths0: int = GameState.loop_deaths
	_bot = true
	var t: float = 0.0
	while t < limit and _last_index < PLATS.size() - 1:
		await _wait(0.25)
		t += 0.25
	_bot = false
	await _wait(0.2)
	return {"top": _last_index, "t": t, "jumps": _jumps, "air": _air_jumps, "falls": _falls,
			"deaths": GameState.loop_deaths - deaths0}


func _run() -> void:
	await _wait(0.3)
	# Save and Continue in the real game, on a throwaway save file.
	GameState.save_path = "user://save_test.json"
	GameState.persist = true
	main._begin_run(3)
	await _wait(1.0)
	main.stage._enter_room(2)
	GameState.loop_deaths = 4
	GameState.save_run(main.stage.current_room)
	var cp: Vector2 = main.stage.checkpoint_pos
	main.show_menu()
	await _wait(0.8)
	_check("R1 the title screen offers Continue when a save exists",
			main.menu != null and "Continue" in Array(main.menu._items), str(main.menu._items if main.menu else []))
	main._continue_run()
	await _wait(1.5)
	var pr: Player = _p()
	_check("R2 Continue resumes at the saved stage and checkpoint",
			main.stage != null and main.stage.stage_index == 3 and main.stage.current_room == 2 and pr != null
			and pr.global_position.distance_to(cp) < 40.0 and not pr.dead,
			"stage=%d room=%d player=%s checkpoint=%s" % [main.stage.stage_index, main.stage.current_room, str(pr.global_position), str(cp)])
	_check("R3 modules and the loop count come back", GameState.choices.size() == 2 and GameState.loop_deaths == 4,
			"choices=%s loops=%d" % [str(GameState.choices), GameState.loop_deaths])
	_check("R4 rooms before the checkpoint are cleared, the room ahead is not",
			main.stage.enemies_alive_in_room(0) == 0 and main.stage.enemies_alive_in_room(1) == 0 and main.stage.enemies_alive_in_room(2) > 0,
			"room0=%d room1=%d room2=%d" % [main.stage.enemies_alive_in_room(0), main.stage.enemies_alive_in_room(1), main.stage.enemies_alive_in_room(2)])
	GameState.clear_save()
	GameState.persist = false
	main._begin_run(3)
	await _wait(1.0)
	# Freeze check: die after climbing well above the last checkpoint (any cause), then again at once.
	var fp: Player = _p()
	fp.global_position.y -= 420.0
	fp.velocity = Vector2.ZERO
	await _wait(0.2)
	var loops0: int = GameState.loop_deaths
	fp.die("hit")
	await _wait(1.5)
	_check("F1 dying high above the checkpoint rewinds; the character is never left frozen",
			not fp.dead and not main._busy and fp.input_enabled, "dead=%s busy=%s loops +%d kill_y=%.0f player_y=%.0f"
			% [str(fp.dead), str(main._busy), GameState.loop_deaths - loops0, main.stage.kill_y, fp.global_position.y])
	fp.die("hit")
	await _wait(0.2)
	fp.die("hit")
	await _wait(1.5)
	_check("F2 a second death during the rewind is not lost", not fp.dead and not main._busy,
			"dead=%s busy=%s" % [str(fp.dead), str(main._busy)])
	var last: int = PLATS.size() - 1
	## Control: the same bot with plain jumps only. It must fail, or this test proves nothing.
	var plain: Dictionary = await _climb(false, 12.0, true)
	_check("C0 control: plain jumps alone never leave the shaft floor (a jump is 55 px, the first step is 64)",
			int(plain["top"]) == 0, "reached platform %d in %.0fs with %d jumps" % [plain["top"], plain["t"], plain["jumps"]])
	var best: Dictionary = await _climb(false, 150.0)
	_check("C1 keyboard-only climb reaches the roof deck (second Space at the top of the jump)",
			int(best["top"]) == last, "platform %d of %d in %.1fs, %d jumps, %d air-dashes, %d slips, %d deaths"
			% [best["top"], last, best["t"], best["jumps"], best["air"], best["falls"], best["deaths"]])
	_check("C1 without dying", int(best["deaths"]) == 0, "deaths=%d" % best["deaths"])
	var sloppy: Dictionary = await _climb(true, 150.0)
	_check("C2 keyboard-only climb reaches the roof deck (second Space pressed early)",
			int(sloppy["top"]) == last, "platform %d of %d in %.1fs, %d jumps, %d air-dashes, %d slips, %d deaths"
			% [sloppy["top"], last, sloppy["t"], sloppy["jumps"], sloppy["air"], sloppy["falls"], sloppy["deaths"]])
	_check("C2 without dying", int(sloppy["deaths"]) == 0, "deaths=%d" % sloppy["deaths"])
	print("CLIMBTEST passed=%d failed=%d" % [passed, failed])
	get_tree().quit(1 if failed > 0 else 0)
