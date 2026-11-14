class_name HudController
extends CanvasLayer
## In-run interface. Kept small and quiet: no panels, no labels for things the player can see,
## outlined pixel type straight over the art. The layer is scaled by Display.ui, so coordinates
## are interface pixels: 576x324 at the design size, and W x H follow the window everywhere else.
## Top-left: the comms line (Sara and The Echo take turns). Top-right: Neural Sync.
## Bottom: tutorial hints, stage name, boss. Clock, loops and modules live on the pause screen.
## Everything animates on real time.

signal module_choice(choice: String)
signal pause_action(action: String)
signal ending_closed

var U: int = 2  ## screen pixels per interface pixel (Display.ui)
var W: int = 576  ## interface size; follows the window (Display.ui_size)
var H: int = 324
const LH: int = 11  ## line height at 1x

const CYAN: Color = Color("#00F0FF")
const MAGENTA: Color = Color("#FF0055")
const CRIMSON: Color = Color("#FF0033")
const AMBER: Color = Color("#FF9900")
const TEXT: Color = Color("#ECEFF5")
const ECHO_TEXT: Color = Color("#FFC4CE")
const HINT: Color = Color("#FFE2B8")
const DIM: Color = Color("#8B94AD")
const INK: Color = Color("#0A0814")
const GLITCH_CHARS: String = "#%&@!?<>=+*01"

var player: Player
var boss: BossGunship
var show_gameplay: bool = false

var _overlay: Control

var _queue: Array[Dictionary] = []
var _line: Dictionary = {}
var _wrapped: PackedStringArray = []
var _line_t: float = 0.0
var _reveal: float = 0.0
var _sys_lines: PackedStringArray = []
var _sys_t: float = 0.0
var _card_t: float = -1.0
var _card_index: int = 0
var _loop_t: float = -1.0
var _loop_n: int = 0
var _back_t: float = -1.0
var _saved_t: float = -1.0
var _module_open: bool = false
var _module_stage: int = 0
var _module_t: float = 0.0
var _paused: bool = false
var _ending_open: bool = false
var _ending_id: String = ""
var _ending_t: float = 0.0
var _real_t: float = 0.0
var _last_ms: int = 0
var _sync_display: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_overlay = Control.new()
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)
	_last_ms = Time.get_ticks_msec()
	Display.changed.connect(_apply_display)
	_apply_display()


func _apply_display() -> void:
	U = Display.ui
	W = int(Display.ui_size.x)
	H = int(Display.ui_size.y)
	transform = Transform2D.IDENTITY.scaled(Vector2(U, U))
	_overlay.size = Vector2(W, H)


func _oy() -> float:
	## Keeps blocks designed for a 324-pixel-tall interface centred on a taller or shorter one.
	return floorf(float(H - 324) * 0.5)


func _ox() -> float:
	## Left margin of the modal screens: 48 at the design width, never under 24.
	return maxf(24.0, 48.0 + floorf(float(W - 576) * 0.5))


# ================================================================= frame

func _process(_delta: float) -> void:
	var now: int = Time.get_ticks_msec()
	var dt: float = minf(float(now - _last_ms) / 1000.0, 0.1)
	_last_ms = now
	_real_t += dt
	_tick_comms(dt)
	## A hint waits while the stage name is up; both live at the bottom of the screen.
	if _card_t < 0.0:
		_sys_t -= dt
	if _card_t >= 0.0:
		_card_t += dt
		if _card_t > 2.8:
			_card_t = -1.0
	if _loop_t >= 0.0:
		_loop_t += dt
		if _loop_t > 0.9:
			_loop_t = -1.0
	if _back_t >= 0.0:
		_back_t += dt
		if _back_t > 1.1:
			_back_t = -1.0
	if _saved_t >= 0.0:
		_saved_t += dt
		if _saved_t > 1.8:
			_saved_t = -1.0
	if _module_open:
		_module_t += dt
	if _ending_open:
		_ending_t += dt
	_sync_display = lerpf(_sync_display, GameState.sync_rate, clampf(dt * 10.0, 0.0, 1.0))
	var playing: bool = show_gameplay and not _module_open and not _ending_open
	## Confined while playing: in a window, a click that lands outside it would take focus away
	## from the game and every key would stop working until the player clicked back in.
	## (Browsers cannot confine the pointer, so the web build only hides it.)
	var play_mode: int = Input.MOUSE_MODE_HIDDEN if OS.get_name() == "Web" else Input.MOUSE_MODE_CONFINED_HIDDEN
	Input.mouse_mode = (play_mode if playing and not get_tree().paused else Input.MOUSE_MODE_VISIBLE) as Input.MouseMode
	_overlay.queue_redraw()


# ================================================================= dialogue

func say(id: String) -> void:
	for line: Dictionary in DialogueData.lines(id):
		var who: String = line["who"]
		var text: String = line["text"]
		match who:
			"SARA", "ECHO":
				_queue.append({"who": who, "text": PixelFont.clean(text)})
			"SYS":
				system(text)
			"WORLD":
				if StageBase.current:
					StageBase.current.burn_text(text)


func system(text: String, seconds: float = 5.0) -> void:
	_sys_lines = PixelFont.wrap(text, 340)
	_sys_t = seconds


func _tick_comms(dt: float) -> void:
	if _line_t > 0.0:
		_line_t -= dt
		var speed: float = 40.0 if _line["who"] == "ECHO" else 55.0
		_reveal = minf(_reveal + dt * speed, float(String(_line["text"]).length()))
		if _line_t <= 0.0:
			_line = {}
	elif not _queue.is_empty():
		_line = _queue.pop_front()
		_wrapped = PixelFont.wrap(_line["text"], 278)
		_reveal = 0.0
		var n: float = float(String(_line["text"]).length())
		_line_t = (1.6 + n * 0.045) if _line["who"] == "SARA" else (2.0 + n * 0.05)
		AudioManager.play_sfx("sara_comms" if _line["who"] == "SARA" else "echo_glitch")


func clear_dialogue() -> void:
	_queue.clear()
	_line = {}
	_line_t = 0.0
	_sys_t = 0.0


func stage_card(index: int) -> void:
	_card_index = index
	_card_t = 0.0


func saved_flash() -> void:
	## A checkpoint was reached and the run was written to disk.
	_saved_t = 0.0


func loop_flash(deaths: int) -> void:
	_loop_n = deaths
	_loop_t = 0.0


func back_flash() -> void:
	## The player deflected a shot during Blackout and is back on their feet.
	_back_t = 0.0


func comms_idle() -> bool:
	## True when neither voice is speaking or waiting to speak.
	return _line.is_empty() and _queue.is_empty()


# ================================================================= modals

func open_module_choice(stage_index: int) -> void:
	_module_open = true
	_module_stage = stage_index
	_module_t = 0.0


func set_paused_panel(on: bool) -> void:
	_paused = on


func show_ending(id: String) -> void:
	_ending_open = true
	_ending_id = id
	_ending_t = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if _module_open:
		if event.is_action_pressed("choose_stabilize"):
			_close_module("Q")
		elif event.is_action_pressed("choose_overclock"):
			_close_module("E")
		return
	if _ending_open and event.is_action_pressed("restart"):
		_ending_open = false
		ending_closed.emit()
		return
	if _paused:
		## [ESC] itself is handled by Main (it toggles); here only the panel's extra keys.
		if event.is_action_pressed("restart"):
			pause_action.emit("restart")
			get_viewport().set_input_as_handled()
		elif event is InputEventKey and event.pressed and (event as InputEventKey).physical_keycode == KEY_M:
			pause_action.emit("menu")


func _close_module(choice: String) -> void:
	_module_open = false
	AudioManager.play_sfx("ui_select")
	module_choice.emit(choice)


# ================================================================= drawing helpers

func _t(pos: Vector2, text: String, scale: int, col: Color, align: int = 0) -> void:
	PixelFont.draw(_overlay, pos, text, scale, col, align)


func _dim(alpha: float) -> void:
	_overlay.draw_rect(Rect2(0, 0, W, H), Color(INK.r, INK.g, INK.b, alpha))


# ================================================================= drawing

func _draw_overlay() -> void:
	if _ending_open:
		_draw_ending()
		return
	if not show_gameplay:
		return
	_draw_comms()
	_draw_sync()
	if boss and is_instance_valid(boss) and boss.phase > 0:
		_draw_boss()
	if _sys_t > 0.0 and not _module_open and _card_t < 0.0:
		var bottom: float = H - (54.0 if boss and is_instance_valid(boss) and boss.phase > 0 else 18.0)
		var y: float = bottom - _sys_lines.size() * LH
		for i: int in _sys_lines.size():
			_t(Vector2(W * 0.5, y + i * LH), _sys_lines[i], 1, HINT, 2)
	if _card_t >= 0.0:
		_draw_card()
	if _loop_t >= 0.0:
		_draw_loop()
	if _back_t >= 0.0 and not (_back_t < 0.3 and int(_back_t * 20.0) % 3 == 2):
		_t(Vector2(W * 0.5, 120 + _oy()), "BOUNCED BACK", 2, AMBER, 2)
	if player and is_instance_valid(player):
		if player.in_blackout:
			_draw_blackout()
		if player.lane_charged() and StageBase.current and StageBase.current.has_lanes:
			var sp: Vector2 = player.get_global_transform_with_canvas().origin / float(U)
			_t(sp + Vector2(0, -38), "W/S", 1, AMBER, 2)
		if not _module_open and not _paused:
			_draw_reticle()
	if _saved_t >= 0.0 and not Director.debug and not _module_open and not _paused:
		_t(Vector2(W - 12.0, 50), "saved", 1, DIM, 1)
	if Director.debug and not _module_open and not _paused:
		var dbg: PackedStringArray = Director.debug_lines()
		for i: int in dbg.size():
			_t(Vector2(W - 12.0, 56 + i * LH), dbg[i], 1, DIM, 1)
	if _module_open:
		_draw_module()
	elif _paused:
		_draw_pause()


func _draw_comms() -> void:
	if _line.is_empty():
		return
	var echo: bool = _line["who"] == "ECHO"
	var name_s: String = "SARA" if not echo else "ECHO"
	if echo and _rng.randf() < 0.12:
		name_s = "EC" + GLITCH_CHARS[_rng.randi() % GLITCH_CHARS.length()] + "O"
	_t(Vector2(12, 10), name_s, 1, CRIMSON if echo else CYAN)
	var left: int = int(_reveal)
	for i: int in _wrapped.size():
		if left <= 0:
			break
		var s: String = _wrapped[i].substr(0, left)
		left -= _wrapped[i].length() + 1
		if echo and _rng.randf() < 0.08 and s.length() > 2:
			var k: int = _rng.randi_range(0, s.length() - 1)
			if s[k] != " ":
				s = s.substr(0, k) + GLITCH_CHARS[_rng.randi() % GLITCH_CHARS.length()] + s.substr(k + 1)
		_t(Vector2(12, 23 + i * LH), s, 1, ECHO_TEXT if echo else TEXT)


func _draw_sync() -> void:
	var t: int = GameState.tier
	var col: Color = GameState.TIER_COLORS[t]
	if t == GameState.Tier.BERSERK:
		col = AMBER if int(_real_t * 6.0) % 2 == 0 else CRIMSON
	var r: float = W - 12.0
	_t(Vector2(r, 10), "%d%%" % int(round(_sync_display)), 2, col, 1)
	_t(Vector2(r, 29), GameState.TIER_NAMES[t].to_lower(), 1, Color(col.r, col.g, col.b, 0.75), 1)
	## Four segments, one per tier, filled continuously; the bar is the only chrome on screen.
	var seg_w: float = 30.0
	var x0: float = r - (seg_w * 4.0 + 6.0)
	for i: int in 4:
		var x: float = x0 + i * (seg_w + 2.0)
		var fill: float = clampf((_sync_display - i * 100.0) / 100.0, 0.0, 1.0)
		var c: Color = GameState.TIER_COLORS[i]
		_overlay.draw_rect(Rect2(x, 41, seg_w, 2), Color(INK.r, INK.g, INK.b, 0.7))
		if fill > 0.0:
			_overlay.draw_rect(Rect2(x, 41, floorf(seg_w * fill), 2), c)
	if GameState.sync_floor() > 0.0:
		var fi: int = int(GameState.sync_floor() / 100.0)
		_overlay.draw_rect(Rect2(x0 + fi * (seg_w + 2.0) - 1.0, 39, 1, 6), MAGENTA)


func _draw_boss() -> void:
	var w: float = 200.0
	var x0: float = (W - w) * 0.5
	var name_s: String = boss.display_name.split(" // ")[0]
	_t(Vector2(W * 0.5, H - 40.0), name_s, 1, MAGENTA, 2)
	var nw: float = PixelFont.width(name_s)
	for p: int in 3:
		var c: Color = AMBER if p < boss.phase else Color(AMBER.r, AMBER.g, AMBER.b, 0.25)
		_overlay.draw_rect(Rect2(W * 0.5 + nw * 0.5 + 6 + p * 5, H - 38.0, 3, 3), c)
	var lit: int = int(ceil(clampf(boss.hp_fraction(), 0.0, 1.0) * BossGunship.HP_MAX))
	var sw: float = w / BossGunship.HP_MAX
	for i: int in BossGunship.HP_MAX:
		var c: Color = MAGENTA if i < lit else Color(INK.r, INK.g, INK.b, 0.7)
		_overlay.draw_rect(Rect2(x0 + i * sw, H - 26.0, sw - 1.0, 3), c)


func _draw_card() -> void:
	## Stage name, bottom-left, switched on and off in two steps.
	if _card_t < 0.08 or (_card_t > 2.5 and int(_card_t * 20.0) % 2 == 0):
		return
	var s: Dictionary = DialogueData.STAGES[_card_index - 1]
	var parts: PackedStringArray = String(s["name"]).split(" // ")
	_t(Vector2(12, H - 48.0), "%02d" % _card_index, 1, AMBER)
	_t(Vector2(30, H - 48.0), s["beat"], 1, DIM)
	_t(Vector2(12, H - 36.0), parts[0], 2, TEXT)


func _draw_loop() -> void:
	if _loop_t < 0.3 and int(_loop_t * 20.0) % 3 == 2:
		return
	var col: Color = MAGENTA if _loop_n % 2 == 0 else CYAN
	_t(Vector2(W * 0.5, 120 + _oy()), "LOOP %02d" % _loop_n, 2, col, 2)


func _draw_blackout() -> void:
	var f: float = player.blackout_fraction()
	var on: bool = int(_real_t * 8.0) % 2 == 0
	var oy: float = _oy()
	_t(Vector2(W * 0.5, 104 + oy), "BLACKOUT", 1, CRIMSON if on else TEXT, 2)
	var w: float = 80.0
	var x0: float = (W - w) * 0.5
	_overlay.draw_rect(Rect2(x0, 117 + oy, w, 2), Color(0.25, 0.0, 0.05, 0.9))
	_overlay.draw_rect(Rect2(x0, 117 + oy, floorf(w * f), 2), CRIMSON)


func _draw_reticle() -> void:
	var m: Vector2 = _overlay.get_local_mouse_position().floor()
	var ready: float = player.parry_ready()
	var col: Color = CYAN if ready >= 1.0 else DIM
	if player.in_blackout:
		col = CRIMSON
	## Four arms; while the parry recharges they light one by one.
	var arms: Array[Vector2] = [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
	var lit: int = 4 if ready >= 1.0 else int(ready * 4.0)
	for i: int in 4:
		var d: Vector2 = arms[i]
		var a: Vector2 = m + d * 3.0
		var b: Vector2 = m + d * 5.0
		var r := Rect2(Vector2(minf(a.x, b.x), minf(a.y, b.y)), (b - a).abs() + Vector2.ONE)
		_overlay.draw_rect(r.grow(1.0), Color(INK.r, INK.g, INK.b, 0.8))
		_overlay.draw_rect(r, col if i < lit else Color("#3A4258"))
	_overlay.draw_rect(Rect2(m, Vector2.ONE), TEXT)


func _draw_module() -> void:
	if _module_t < 0.05:
		return
	_dim(0.85)
	var m: Dictionary = DialogueData.MODULES[_module_stage - 1]
	var c: Dictionary = DialogueData.MODULE_COMMON
	var parts: PackedStringArray = String(m["name"]).split(": ")
	## Two centred columns; on a small window they narrow instead of running off the screen.
	var col_w: float = minf(228.0, floorf((W - 56.0) * 0.5))
	var x0: float = floorf((W - (col_w * 2.0 + 24.0)) * 0.5)
	var oy: float = maxf(_oy(), -30.0)
	_t(Vector2(x0, 44 + oy), parts[0], 1, AMBER)
	_t(Vector2(x0, 57 + oy), parts[parts.size() - 1], 2, TEXT)
	_choice(Vector2(x0, 104 + oy), "Q", c["q_tag"], m["q_name"], m["q_desc"], c["q_extra"], CYAN, col_w)
	_choice(Vector2(x0 + col_w + 24.0, 104 + oy), "E", c["e_tag"], m["e_name"], m["e_desc"], c["e_extra"], CRIMSON, col_w)


func _choice(o: Vector2, key: String, tag: String, n: String, desc: String, extra: String, col: Color, w: float = 228.0) -> void:
	var tag_parts: PackedStringArray = tag.split(" // ")
	_t(o, key + "  " + tag_parts[0], 1, col)
	if tag_parts.size() > 1:
		var who: String = tag_parts[1].to_lower().replace("sara", "Sara").replace("the echo", "The Echo")
		_t(o + Vector2(0, 12), who.substr(0, 1).to_upper() + who.substr(1), 1, DIM)
	_overlay.draw_rect(Rect2(o + Vector2(0, 26), Vector2(w, 1)), Color(col.r, col.g, col.b, 0.6))
	_t(o + Vector2(0, 34), n, 1, TEXT)
	var y: float = o.y + 48
	for line: String in PixelFont.wrap(desc, int(w)):
		_t(Vector2(o.x, y), line, 1, Color("#C9D2E3"))
		y += LH
	y += 6
	var ex: String = extra.trim_prefix("+ ")
	for line: String in PixelFont.wrap(ex.substr(0, 1).to_upper() + ex.substr(1) + ".", int(w)):
		_t(Vector2(o.x, y), line, 1, col.lerp(TEXT, 0.3))
		y += LH


func _draw_pause() -> void:
	_dim(0.8)
	var x: float = _ox()
	var oy: float = _oy()
	_t(Vector2(x, 92 + oy), "PAUSED", 2, TEXT)
	var rows: Array = [["Esc", "Resume"], ["R", "Rewind to the last checkpoint"], ["M", "Quit to the title screen (progress is saved)"]]
	for i: int in rows.size():
		_t(Vector2(x, 124 + oy + i * 14), rows[i][0], 1, AMBER)
		_t(Vector2(x + 32.0, 124 + oy + i * 14), rows[i][1], 1, TEXT)
	var run: String = "Stage %d    Loop %d    %s" % [GameState.current_stage, GameState.loop_deaths,
			GameState.format_time(GameState.run_time)]
	_t(Vector2(x, 182 + oy), run, 1, DIM)
	var mods: PackedStringArray = []
	for i: int in GameState.choices.size():
		var pair: Array = GameState.MODULE_MODS[i]
		mods.append(String(pair[0] if GameState.choices[i] == "Q" else pair[1]).replace("_", " ").capitalize())
	if not mods.is_empty():
		_t(Vector2(x, 196 + oy), "Modules: " + ", ".join(mods), 1, DIM)
	if Director.enabled:
		_t(Vector2(x, 210 + oy), "Adaptive difficulty  %d%%" % Director.percent(), 1, DIM)


func _draw_ending() -> void:
	## Flows top to bottom from the real interface size: same positions as before at 576x324,
	## tighter gaps on a short window, wider margins on a wide one.
	var e: Dictionary = DialogueData.ENDINGS[_ending_id]
	var col: Color = e["color"]
	_dim(clampf(_ending_t / 1.2, 0.0, 1.0) * 0.94)
	var x0: float = _ox()
	var wrap_w: float = minf(470.0, W - x0 * 2.0)
	var tight: bool = H < 324
	var y: float = maxf(40.0 + _oy(), 12.0)
	var parts: PackedStringArray = String(e["title"]).split(" // ")
	_t(Vector2(x0, y), parts[0], 1, col)
	_t(Vector2(x0, y + 13), " ".join(parts.slice(1)), 2, col)
	y += 36.0 if tight else 44.0
	var lines: PackedStringArray = PixelFont.wrap(e["body"], int(wrap_w))
	var budget: int = int(clampf((_ending_t - 1.2) / 4.0, 0.0, 1.0) * String(e["body"]).length())
	for i: int in lines.size():
		if budget <= 0:
			break
		_t(Vector2(x0, y + i * LH), lines[i].substr(0, budget), 1, TEXT)
		budget -= lines[i].length() + 1
	y += lines.size() * LH + (10.0 if tight else 14.0)
	if not tight:
		y = maxf(y, 184.0 + _oy())
	if _ending_t > 5.2:
		_t(Vector2(x0, y), "You sent %d shots back and got up %d times." % [
				GameState.parries, GameState.loop_deaths + GameState.rebounds], 1, col)
	y += 16.0
	var choices: PackedStringArray = []
	for ch: String in GameState.choices:
		choices.append("Stabilize" if ch == "Q" else "Overclock")
	var stats: Array = [
		["Time", GameState.format_time(GameState.run_time)], ["Loops", str(GameState.loop_deaths)],
		["Shots sent back", str(GameState.parries)], ["Longest rally", "x%d" % GameState.best_rally],
		["Rebounds", str(GameState.rebounds)], ["Modules", ", ".join(choices)],
	]
	var col_step: float = minf(160.0, floorf(wrap_w / 3.0))
	for i: int in stats.size():
		var sx: float = x0 + (i % 3) * col_step
		var sy: float = y + (i / 3) * 24
		_t(Vector2(sx, sy), stats[i][0], 1, DIM)
		_t(Vector2(sx, sy + 11), stats[i][1], 1, TEXT)
	y += 48.0 + (8.0 if tight else 18.0)
	_t(Vector2(x0, y), "R", 1, col)
	_t(Vector2(x0 + 14.0, y), "Bounce back again", 1, TEXT)
	var foot: PackedStringArray = PixelFont.wrap(
			"Hack Club Haven Dhaka 2026. Art and music by Ansimuz, effects by BDragon1727.", int(W - x0 * 2.0))
	for i: int in foot.size():
		_t(Vector2(x0, H - 20.0 - (foot.size() - 1 - i) * LH), foot[i], 1, DIM)
