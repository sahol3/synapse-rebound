class_name HudController
extends CanvasLayer
## Evangelion sync gauge, Sara's cyan comms (top-left), The Echo's crimson glitch toast,
## system banners, Blackout timer, boss bar, stage cards, [Q]/[E] module modal, endings,
## pause menu, and the aim reticle. Everything animates on real time.

signal module_choice(choice: String)
signal pause_action(action: String)
signal ending_closed

const CYAN: Color = Color("#00F0FF")
const MAGENTA: Color = Color("#FF0055")
const CRIMSON: Color = Color("#FF0033")
const AMBER: Color = Color("#FF9900")
const VIOLET: Color = Color("#4A00E0")
const INK: Color = Color(0.02, 0.01, 0.06, 0.82)
const GLITCH_CHARS: String = "#%&@!?/\\|<>=+*01"

var player: Player
var boss: BossGunship
var show_gameplay: bool = false

var _font: Font
var _root: Control
var _overlay: Control
var _comms: PanelContainer
var _comms_body: Label
var _echo: PanelContainer
var _echo_body: Label
var _sys: Label
var _card: VBoxContainer
var _card_title: Label
var _card_name: Label
var _loop_label: Label
var _module_panel: Control
var _ending_panel: Control
var _pause_panel: Control

var _sara_queue: Array[String] = []
var _echo_queue: Array[String] = []
var _sara_t: float = 0.0
var _echo_t: float = 0.0
var _sys_t: float = 0.0
var _sara_text: String = ""
var _echo_text: String = ""
var _sara_reveal: float = 0.0
var _echo_reveal: float = 0.0
var _module_open: bool = false
var _ending_open: bool = false
var _real_t: float = 0.0
var _last_ms: int = 0
var _sync_display: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_font = _make_font()
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var theme := Theme.new()
	theme.default_font = _font
	theme.default_font_size = 18
	_root.theme = theme
	add_child(_root)
	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.draw.connect(_draw_overlay)
	_root.add_child(_overlay)
	_build_comms()
	_build_echo()
	_build_sys()
	_build_card()
	_build_loop_label()
	_last_ms = Time.get_ticks_msec()


func _make_font() -> Font:
	var sf := SystemFont.new()
	sf.font_names = PackedStringArray(["Consolas", "Cascadia Mono", "DejaVu Sans Mono", "Menlo", "Courier New", "monospace"])
	sf.font_weight = 600
	sf.fallbacks = [ThemeDB.fallback_font]
	return sf


func _panel_style(border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = INK
	s.border_color = border
	s.border_width_left = 4
	s.border_width_top = 1
	s.border_width_bottom = 1
	s.content_margin_left = 16
	s.content_margin_right = 14
	s.content_margin_top = 8
	s.content_margin_bottom = 10
	s.skew = Vector2(-0.08, 0)
	return s


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 4)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _build_comms() -> void:
	_comms = PanelContainer.new()
	_comms.add_theme_stylebox_override("panel", _panel_style(CYAN))
	_comms.position = Vector2(22, 20)
	_comms.custom_minimum_size = Vector2(500, 0)
	_comms.size = Vector2(500, 0)
	var v := VBoxContainer.new()
	v.add_child(_label("CH-A // SARA // HANDLER  ))) LIVE", 13, CYAN.darkened(0.15)))
	_comms_body = _label("", 17, Color(0.85, 1.0, 1.0))
	_comms_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_comms_body.custom_minimum_size = Vector2(468, 0)
	v.add_child(_comms_body)
	_comms.add_child(v)
	_comms.modulate.a = 0.0
	_root.add_child(_comms)


func _build_echo() -> void:
	_echo = PanelContainer.new()
	_echo.add_theme_stylebox_override("panel", _panel_style(CRIMSON))
	_echo.custom_minimum_size = Vector2(620, 0)
	_echo.size = Vector2(620, 0)
	_echo.position = Vector2(266, 520)
	var v := VBoxContainer.new()
	v.add_child(_label("CH-B // ?#%! // THE ECHO  [PRE-WIPE RECORDING]", 13, CRIMSON))
	_echo_body = _label("", 18, Color(1.0, 0.78, 0.82))
	_echo_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_echo_body.custom_minimum_size = Vector2(588, 0)
	v.add_child(_echo_body)
	_echo.add_child(v)
	_echo.modulate.a = 0.0
	_root.add_child(_echo)


func _build_sys() -> void:
	_sys = _label("", 15, AMBER)
	_sys.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sys.position = Vector2(176, 118)
	_sys.size = Vector2(800, 30)
	_sys.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sys.modulate.a = 0.0
	_root.add_child(_sys)


func _build_card() -> void:
	_card = VBoxContainer.new()
	_card.position = Vector2(0, 230)
	_card.size = Vector2(1152, 160)
	_card.alignment = BoxContainer.ALIGNMENT_CENTER
	_card_title = _label("", 22, CYAN)
	_card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card_name = _label("", 48, Color.WHITE)
	_card_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card_name.add_theme_constant_override("outline_size", 10)
	_card.add_child(_card_title)
	_card.add_child(_card_name)
	_card.modulate.a = 0.0
	_root.add_child(_card)


func _build_loop_label() -> void:
	_loop_label = _label("", 40, Color.WHITE)
	_loop_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loop_label.position = Vector2(0, 280)
	_loop_label.size = Vector2(1152, 60)
	_loop_label.modulate.a = 0.0
	_root.add_child(_loop_label)


# ================================================================= frame

func _process(_delta: float) -> void:
	var now: int = Time.get_ticks_msec()
	var dt: float = minf(float(now - _last_ms) / 1000.0, 0.1)
	_last_ms = now
	_real_t += dt
	_tick_comms(dt)
	_tick_echo(dt)
	if _sys_t > 0.0:
		_sys_t -= dt
		_sys.modulate.a = clampf(_sys_t * 2.0, 0.0, 1.0)
	_sync_display = lerpf(_sync_display, GameState.sync_rate, clampf(dt * 10.0, 0.0, 1.0))
	var playing: bool = show_gameplay and not _module_open and not _ending_open
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if playing and not get_tree().paused else Input.MOUSE_MODE_VISIBLE
	_overlay.queue_redraw()


# ================================================================= dialogue

func say(id: String) -> void:
	for line: Dictionary in DialogueData.lines(id):
		var who: String = line["who"]
		var text: String = line["text"]
		match who:
			"SARA":
				_sara_queue.append(text)
			"ECHO":
				_echo_queue.append(text)
			"SYS":
				system(text)
			"WORLD":
				if StageBase.current:
					StageBase.current.burn_text(text)


func system(text: String, seconds: float = 5.0) -> void:
	_sys.text = text
	_sys_t = seconds
	_sys.modulate.a = 1.0


func _tick_comms(dt: float) -> void:
	if _sara_t > 0.0:
		_sara_t -= dt
		_sara_reveal = minf(_sara_reveal + dt * 55.0, float(_sara_text.length()))
		_comms_body.text = _sara_text.substr(0, int(_sara_reveal))
		_comms.modulate.a = clampf(_sara_t * 3.0, 0.0, 1.0)
		_comms.position.x = 22.0 + (1.0 - _comms.modulate.a) * -30.0
	elif not _sara_queue.is_empty():
		_sara_text = _sara_queue.pop_front()
		_sara_reveal = 0.0
		_sara_t = 1.6 + float(_sara_text.length()) * 0.045
		AudioManager.play_sfx("sara_comms")
	else:
		_comms.modulate.a = 0.0


func _tick_echo(dt: float) -> void:
	if _echo_t > 0.0:
		_echo_t -= dt
		_echo_reveal = minf(_echo_reveal + dt * 40.0, float(_echo_text.length()))
		var shown: String = _echo_text.substr(0, int(_echo_reveal))
		if _rng.randf() < 0.35 and shown.length() > 2:
			var i: int = _rng.randi_range(0, shown.length() - 1)
			shown = shown.substr(0, i) + GLITCH_CHARS[_rng.randi() % GLITCH_CHARS.length()] + shown.substr(i + 1)
		_echo_body.text = shown
		_echo.modulate.a = clampf(_echo_t * 3.0, 0.0, 1.0) * (0.75 + 0.25 * _rng.randf())
		_echo.position = Vector2(266, 520) + Vector2(_rng.randf_range(-2, 2), 0) * (1.0 if _rng.randf() < 0.3 else 0.0)
	elif not _echo_queue.is_empty():
		_echo_text = _echo_queue.pop_front()
		_echo_reveal = 0.0
		_echo_t = 2.0 + float(_echo_text.length()) * 0.05
		AudioManager.play_sfx("echo_glitch")
	else:
		_echo.modulate.a = 0.0


func clear_dialogue() -> void:
	_sara_queue.clear()
	_echo_queue.clear()
	_sara_t = 0.0
	_echo_t = 0.0
	_sys_t = 0.0


# ================================================================= cards

func stage_card(index: int) -> void:
	var s: Dictionary = DialogueData.STAGES[index - 1]
	_card_title.text = "%s  //  %s" % [s["title"], s["time"]]
	_card_name.text = s["name"]
	_card.modulate.a = 0.0
	_card.scale = Vector2.ONE
	var tw := create_tween()
	tw.set_ignore_time_scale(true)
	tw.tween_property(_card, "modulate:a", 1.0, 0.25)
	tw.tween_interval(1.8)
	tw.tween_property(_card, "modulate:a", 0.0, 0.5)


func loop_flash(deaths: int) -> void:
	_loop_label.text = "LOOP %02d  //  REWIND -0.3s" % deaths
	_loop_label.add_theme_color_override("font_color", MAGENTA if deaths % 2 == 0 else CYAN)
	_loop_label.modulate.a = 1.0
	var tw := create_tween()
	tw.set_ignore_time_scale(true)
	tw.tween_interval(0.5)
	tw.tween_property(_loop_label, "modulate:a", 0.0, 0.4)


# ================================================================= module modal

func open_module_choice(stage_index: int) -> void:
	_module_open = true
	var m: Dictionary = DialogueData.MODULES[stage_index - 1]
	var c: Dictionary = DialogueData.MODULE_COMMON
	_module_panel = Control.new()
	_module_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_module_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.03, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_module_panel.add_child(dim)
	var title := _label("NEURAL MODULE RECOVERED", 18, Color("#5CFFB0"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 150)
	title.size = Vector2(1152, 30)
	_module_panel.add_child(title)
	var name_l := _label(m["name"], 34, Color.WHITE)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.position = Vector2(0, 182)
	name_l.size = Vector2(1152, 50)
	_module_panel.add_child(name_l)
	_module_panel.add_child(_choice_card(Vector2(156, 260), "[Q]", c["q_tag"], m["q_name"], m["q_desc"], c["q_extra"], CYAN))
	_module_panel.add_child(_choice_card(Vector2(606, 260), "[E]", c["e_tag"], m["e_name"], m["e_desc"], c["e_extra"], CRIMSON))
	_root.add_child(_module_panel)
	_module_panel.modulate.a = 0.0
	var tw := create_tween()
	tw.set_ignore_time_scale(true)
	tw.tween_property(_module_panel, "modulate:a", 1.0, 0.25)


func _choice_card(pos: Vector2, key: String, tag: String, n: String, desc: String, extra: String, col: Color) -> Control:
	var p := PanelContainer.new()
	var st := _panel_style(col)
	st.border_width_left = 6
	st.border_width_top = 2
	st.border_width_bottom = 2
	st.border_width_right = 2
	p.add_theme_stylebox_override("panel", st)
	p.position = pos
	p.custom_minimum_size = Vector2(390, 230)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.add_child(_label(key + "  " + tag, 15, col))
	v.add_child(_label(n, 28, Color.WHITE))
	var d := _label(desc, 16, Color(0.88, 0.92, 1.0))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size = Vector2(350, 0)
	v.add_child(d)
	var e := _label(extra, 13, col.lightened(0.2))
	e.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	e.custom_minimum_size = Vector2(350, 0)
	v.add_child(e)
	p.add_child(v)
	return p


func _unhandled_input(event: InputEvent) -> void:
	if _module_open:
		if event.is_action_pressed("choose_stabilize"):
			_close_module("Q")
		elif event.is_action_pressed("choose_overclock"):
			_close_module("E")
		return
	if _ending_open and event.is_action_pressed("restart"):
		_ending_open = false
		if _ending_panel:
			_ending_panel.queue_free()
		ending_closed.emit()
		return
	if _pause_panel != null:
		## [ESC] itself is handled by Main (it toggles); here only the panel's extra keys.
		if event.is_action_pressed("restart"):
			pause_action.emit("restart")
			get_viewport().set_input_as_handled()
		elif event is InputEventKey and event.pressed and (event as InputEventKey).physical_keycode == KEY_M:
			pause_action.emit("menu")


func _close_module(choice: String) -> void:
	_module_open = false
	AudioManager.play_sfx("ui_select")
	var tw := create_tween()
	tw.set_ignore_time_scale(true)
	tw.tween_property(_module_panel, "modulate:a", 0.0, 0.25)
	tw.tween_callback(_module_panel.queue_free)
	module_choice.emit(choice)


# ================================================================= pause / ending

func set_paused_panel(on: bool) -> void:
	if on and _pause_panel == null:
		_pause_panel = Control.new()
		_pause_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		var dim := ColorRect.new()
		dim.color = Color(0, 0, 0.04, 0.7)
		dim.set_anchors_preset(Control.PRESET_FULL_RECT)
		_pause_panel.add_child(dim)
		var l := _label("SIGNAL PAUSED", 46, CYAN)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.position = Vector2(0, 230)
		l.size = Vector2(1152, 60)
		_pause_panel.add_child(l)
		var h := _label("[ESC] RESUME     [R] REWIND TO CHECKPOINT     [M] MAIN MENU", 18, Color.WHITE)
		h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		h.position = Vector2(0, 310)
		h.size = Vector2(1152, 30)
		_pause_panel.add_child(h)
		_root.add_child(_pause_panel)
	elif not on and _pause_panel != null:
		_pause_panel.queue_free()
		_pause_panel = null


func show_ending(id: String) -> void:
	_ending_open = true
	var e: Dictionary = DialogueData.ENDINGS[id]
	var col: Color = e["color"]
	_ending_panel = Control.new()
	_ending_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.01, 0.0, 0.04, 0.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ending_panel.add_child(bg)
	var title := _label(e["title"], 40, col)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 110)
	title.size = Vector2(1152, 60)
	_ending_panel.add_child(title)
	var body := _label(e["body"], 20, Color(0.92, 0.95, 1.0))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.position = Vector2(176, 190)
	body.size = Vector2(800, 160)
	body.visible_ratio = 0.0
	_ending_panel.add_child(body)
	var choices: String = ""
	for ch: String in GameState.choices:
		choices += ("STABILIZE " if ch == "Q" else "OVERCLOCK ")
	var stats := _label("TIME %s    LOOPS %d    DEFLECTIONS %d    BEST RALLY x%d    REBOUNDS %d\nMODULES: %s" % [
		GameState.format_time(GameState.run_time), GameState.loop_deaths, GameState.parries,
		GameState.best_rally, GameState.rebounds, choices], 16, AMBER)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.position = Vector2(0, 400)
	stats.size = Vector2(1152, 60)
	_ending_panel.add_child(stats)
	var again := _label("[R]  BOUNCE BACK AGAIN", 22, Color.WHITE)
	again.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	again.position = Vector2(0, 500)
	again.size = Vector2(1152, 40)
	_ending_panel.add_child(again)
	var credit := _label("SYNAPSE // REBOUND  -  Hack Club Haven Dhaka 2026  -  art & music: Ansimuz, BDragon1727 (see CREDITS.md)", 12, Color(0.6, 0.65, 0.8))
	credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	credit.position = Vector2(0, 600)
	credit.size = Vector2(1152, 20)
	_ending_panel.add_child(credit)
	_root.add_child(_ending_panel)
	var tw := create_tween()
	tw.set_ignore_time_scale(true)
	tw.tween_property(bg, "color:a", 0.92, 1.2)
	tw.tween_property(body, "visible_ratio", 1.0, 4.0)


# ================================================================= drawing

func _draw_overlay() -> void:
	if not show_gameplay:
		return
	_draw_sync_gauge()
	_draw_status()
	if player and is_instance_valid(player):
		if player.in_blackout:
			_draw_blackout()
		_draw_reticle()
	if boss and is_instance_valid(boss) and boss.phase > 0:
		_draw_boss_bar()


func _txt(pos: Vector2, text: String, size: int, col: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0) -> void:
	if align == HORIZONTAL_ALIGNMENT_RIGHT and width < 0.0:
		pos.x -= _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		align = HORIZONTAL_ALIGNMENT_LEFT
	_overlay.draw_string_outline(_font, pos, text, align, width, size, 5, Color(0, 0, 0, 0.85))
	_overlay.draw_string(_font, pos, text, align, width, size, col)


func _draw_sync_gauge() -> void:
	var t: int = GameState.tier
	var col: Color = GameState.TIER_COLORS[t]
	if t == GameState.Tier.BERSERK:
		col = AMBER if int(_real_t * 6.0) % 2 == 0 else CRIMSON
	var origin := Vector2(820, 22)
	var w: float = 310.0
	_overlay.draw_rect(Rect2(origin - Vector2(10, 6), Vector2(w + 20, 104)), INK)
	_overlay.draw_rect(Rect2(origin - Vector2(10, 6), Vector2(4, 104)), col)
	_txt(origin + Vector2(2, 16), "NEURAL SYNC RATE", 13, col.darkened(0.1))
	_txt(origin + Vector2(w, 58), "%d%%" % int(round(_sync_display)), 46, Color.WHITE.lerp(col, 0.35), HORIZONTAL_ALIGNMENT_RIGHT, -1.0)
	_txt(origin + Vector2(2, 50), GameState.TIER_NAMES[t], 15, col)
	var segs: int = 40
	var seg_w: float = w / float(segs)
	for i: int in segs:
		var v: float = float(i) * 10.0
		var lit: bool = _sync_display > v
		var c: Color = GameState.TIER_COLORS[GameState.tier_for(v + 1.0)]
		if not lit:
			c = Color(c.r, c.g, c.b, 0.12)
		var h: float = 14.0 if i % 10 == 0 else 10.0
		_overlay.draw_rect(Rect2(origin + Vector2(float(i) * seg_w, 74 + (14.0 - h)), Vector2(seg_w - 2.0, h)), c)
	for mark: int in [100, 200, 300]:
		_txt(origin + Vector2(float(mark) / 400.0 * w - 12, 96), str(mark), 10, Color(1, 1, 1, 0.5))
	if GameState.sync_floor() > 0.0:
		var fx: float = GameState.sync_floor() / 400.0 * w
		_overlay.draw_line(origin + Vector2(fx, 70), origin + Vector2(fx, 90), MAGENTA, 2.0)


func _draw_status() -> void:
	var o := Vector2(22, 588)
	_overlay.draw_rect(Rect2(o - Vector2(8, 22), Vector2(430, 50)), INK)
	_txt(o, "LOOP %02d" % GameState.loop_deaths, 16, MAGENTA)
	_txt(o + Vector2(100, 0), GameState.format_time(GameState.run_time), 16, Color.WHITE)
	if player and is_instance_valid(player):
		var dash_col: Color = CYAN if player.dash_ready() else Color(0.3, 0.35, 0.45)
		_overlay.draw_rect(Rect2(o + Vector2(222, -12), Vector2(14, 14)), dash_col)
		_txt(o + Vector2(242, 0), "DASH", 13, dash_col)
		if StageBase.current and StageBase.current.has_lanes:
			var lane_name: String = "FG LANE" if player.lane == 0 else "BG LANE"
			var lc: Color = Color("#5CFFB0") if player.lane_charged() else Color(0.55, 0.6, 0.8)
			_txt(o + Vector2(300, 0), lane_name, 13, lc)
			if player.lane_charged():
				_txt(o + Vector2(300, 18), "[W]/[S] Z-JUMP READY", 11, lc)
	var mods: String = ""
	for i: int in GameState.choices.size():
		var pair: Array = GameState.MODULE_MODS[i]
		mods += String(pair[0] if GameState.choices[i] == "Q" else pair[1]).to_upper().replace("_", " ") + "   "
	if mods != "":
		_txt(Vector2(22, 548), mods, 12, Color("#5CFFB0"))


func _draw_blackout() -> void:
	var f: float = player.blackout_fraction()
	var center := Vector2(576, 200)
	var w: float = 420.0
	var pulse: float = 0.6 + 0.4 * sin(_real_t * 18.0)
	_txt(center + Vector2(-w * 0.5, -14), "BLACKOUT // DEFLECT ANY SHOT TO REBOUND", 18, Color(1, 0.1, 0.25, pulse), HORIZONTAL_ALIGNMENT_CENTER, w)
	_overlay.draw_rect(Rect2(center + Vector2(-w * 0.5, 0), Vector2(w, 10)), Color(0.2, 0, 0.05, 0.8))
	_overlay.draw_rect(Rect2(center + Vector2(-w * 0.5, 0), Vector2(w * f, 10)), CRIMSON)
	_txt(center + Vector2(-w * 0.5, 34), "%.2fs" % (f * GameState.blackout_duration()), 16, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, w)


func _draw_boss_bar() -> void:
	var o := Vector2(620, 596)
	var w: float = 510.0
	_overlay.draw_rect(Rect2(o - Vector2(10, 26), Vector2(w + 20, 46)), INK)
	_txt(o + Vector2(0, -6), boss.display_name, 15, MAGENTA)
	var phase_name: String = ["", "PHASE 1 // FOREGROUND BARRAGE", "PHASE 2 // DEPTH RETREAT", "PHASE 3 // EXECUTION RALLY"][boss.phase]
	_txt(o + Vector2(w, -6), phase_name, 12, AMBER, HORIZONTAL_ALIGNMENT_RIGHT, -1.0)
	_overlay.draw_rect(Rect2(o, Vector2(w, 8)), Color(0.15, 0.0, 0.08, 0.85))
	_overlay.draw_rect(Rect2(o, Vector2(w * clampf(boss.hp_fraction(), 0.0, 1.0), 8)), MAGENTA)


func _draw_reticle() -> void:
	var m: Vector2 = _overlay.get_local_mouse_position()
	var ready: float = player.parry_ready()
	var col: Color = CYAN if ready >= 1.0 else Color(0.5, 0.6, 0.7)
	if player.in_blackout:
		col = CRIMSON
	_overlay.draw_arc(m, 11.0, 0.0, TAU * ready, 28, col, 2.0)
	for d: Vector2 in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		_overlay.draw_line(m + d * 5.0, m + d * 9.0, col, 2.0)
	_overlay.draw_circle(m, 1.5, Color.WHITE)
