class_name Epilogue
extends StageBase
## The after-story, shown instead of told. Four small sets stand side by side on one strip of the
## city, one per epilogue entry (Vincent, Sara, The Echo, the city or the files). The ending screen
## drives it: `show_beat(i)` cuts the camera to set i and starts that set's motion. Everything on
## screen is art the game already ships; what differs between the three endings is which actors
## appear and what they do.

const SET_X: Array[float] = [22.0, 72.0, 122.0, 172.0]  ## centre column of each set, in tiles
const CAM_Y: float = 108.0
const CYAN: Color = Color("#00F0FF")
const CRIMSON: Color = Color("#FF0033")
const AMBER: Color = Color("#FF9900")

var ending: String = "C"
var beat: int = -1

var _cam: Camera2D
var _bt: float = 0.0
var _hero: AnimatedSprite2D
var _wreck: Sprite2D
var _beacon: AnimatedSprite2D
var _drones: Array[AnimatedSprite2D] = []
var _next_fx: float = 0.0
var _said: Dictionary = {}


func _init() -> void:
	stage_index = 0
	bounds = Rect2i(0, -10, 200, 30)
	kill_y = 1e9


func build() -> void:
	# Set 0, Vincent: one long roof with the noodle-bar sign over it.
	building(6, 40, 9)
	building(0, 5, 6, 1)
	building(30, 44, 5, 1)
	prop("banner_sushi", 15.0, 6.6)
	prop("banner_neon", 27.5, 6.4)
	prop("antenna", 34.0, 7.4)
	# Set 1, Sara: the lower deck where the gunship came down.
	building(56, 90, 9)
	building(58, 68, 6, 1)
	building(80, 92, 5, 1)
	prop("control-box-2", 62.0, 8.2)
	# Set 2, The Echo: tall faces for its text to burn onto.
	building(108, 120, 4)
	building(121, 136, 6)
	building(100, 107, 8, 1)
	prop("banner_side", 114.0, 7.0)
	# Set 3, the city: a skyline with traffic.
	var c: int = 150
	var tops: Array[int] = [8, 6, 10, 7, 9, 5, 8]
	var i: int = 0
	while c < 196:
		building(c, c + 7, tops[i % tops.size()])
		building(c + 3, c + 10, tops[(i + 2) % tops.size()] - 3, 1)
		c += 9
		i += 1
	prop("banner_big", 164.0, 4.6)
	prop("banner_coke", 180.0, 5.4)
	add_traffic(8, -20.0, 70.0, 80.0)


func _ready() -> void:
	super._ready()
	JuiceManager.fx_root = fx
	_cam = Camera2D.new()
	_cam.zoom = Vector2(Display.art, Display.art)
	_cam.position = Vector2(SET_X[0] * T, CAM_Y)
	add_child(_cam)
	_cam.make_current()
	JuiceManager.camera = _cam
	Display.changed.connect(func() -> void: _cam.zoom = Vector2(Display.art, Display.art))
	_build_hero()
	_build_wreck()
	_build_drones()


func show_beat(index: int) -> void:
	beat = clampi(index, 0, SET_X.size() - 1)
	_bt = 0.0
	_next_fx = 0.6
	_cam.position = Vector2((SET_X[beat] - 2.0) * T, CAM_Y)


func _process(delta: float) -> void:
	super._process(delta)
	if beat < 0:
		return
	_bt += delta
	## A slow drift across the set, so no shot is a still.
	_cam.position.x += 9.0 * delta
	match beat:
		0:
			_tick_hero(delta)
		1:
			_tick_wreck(delta)
		2:
			_tick_echo()
		3:
			_tick_city(delta)


# ----------------------------------------------------------------- Vincent

func _build_hero() -> void:
	_hero = AnimatedSprite2D.new()
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for def: Array in [["idle", "idle", 4, 6.0], ["walk", "walk", 16, 12.0]]:
		var tex: Texture2D = load("res://assets/warped_city/player/%s.png" % def[1])
		sf.add_animation(def[0])
		sf.set_animation_speed(def[0], def[3])
		sf.set_animation_loop(def[0], true)
		for i: int in int(def[2]):
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(i * 71, 0, 71, 67)
			sf.add_frame(def[0], at)
	_hero.sprite_frames = sf
	_hero.z_index = 12
	## Roof row 9 is at y = 144; the frame is 67 tall with the feet on its bottom edge.
	_hero.position = Vector2(14.0 * T, 9.0 * T - 33.5)
	add_child(_hero)
	match ending:
		"A":
			_hero.play("idle")
		"B":
			_hero.modulate = Color(1.0, 0.72, 0.78)
			_hero.play("walk")
		_:
			_hero.modulate = Color(1.0, 0.95, 0.85)
			_hero.play("walk")
	if ending != "A":
		_hero.position.x = 10.0 * T


func _tick_hero(delta: float) -> void:
	match ending:
		"A":
			## He stays under the sign. Now and then he looks the other way.
			_hero.flip_h = int(_bt / 2.6) % 2 == 1
		"B":
			## The Echo walks him down from the roof, trailing what he used to be.
			_hero.position.x += 26.0 * delta
			if _bt > _next_fx:
				_next_fx = _bt + 0.22
				JuiceManager.ghost(_hero, CRIMSON)
		_:
			_hero.position.x += 20.0 * delta
			if _bt > _next_fx:
				_next_fx = _bt + 0.9
				JuiceManager.ghost(_hero, AMBER)


# ----------------------------------------------------------------- Sara

func _build_wreck() -> void:
	_wreck = Sprite2D.new()
	_wreck.texture = load("res://assets/warped_city/vehicles/v-police.png")
	_wreck.z_index = 11
	add_child(_wreck)
	_beacon = FxLib.sprite("orb", "cyan")
	_beacon.z_index = 13
	add_child(_beacon)
	var deck_y: float = 9.0 * T
	if ending == "B":
		## Still in the air when the shot comes in: it falls and does not land.
		_wreck.modulate = Color(1.25, 0.55, 1.2)
		_wreck.position = Vector2(70.0 * T, deck_y - 150.0)
		_beacon.visible = false
	else:
		_wreck.modulate = Color(0.5, 0.36, 0.55)
		_wreck.rotation = -0.2
		_wreck.position = Vector2(72.0 * T, deck_y - 24.0)
		_beacon.position = _wreck.position + Vector2(-18.0, -16.0)


func _tick_wreck(delta: float) -> void:
	if ending == "B":
		if _wreck.visible:
			_wreck.position += Vector2(10.0, 46.0) * delta
			_wreck.rotation += 0.5 * delta
			if _bt > _next_fx:
				_next_fx = _bt + 0.28
				FxLib.spawn(fx, "explosion", "gold", _wreck.position + Vector2(randf_range(-30, 30), randf_range(-14, 14)))
				AudioManager.play_sfx("explosion", randf_range(0.7, 1.0), -12.0)
			if _bt > 2.8:
				_wreck.visible = false
				for k: int in 5:
					FxLib.spawn(fx, "explosion", "gold", _wreck.position + Vector2(randf_range(-40, 40), randf_range(-24, 24)), 0.0, 1.6)
				JuiceManager.ring(_wreck.position, CRIMSON, 90.0, 0.6)
		return
	## Down on the deck and smoking. The light on the hull is what the caption is about.
	if _bt > _next_fx:
		_next_fx = _bt + 0.5
		FxLib.spawn(fx, "puff", "magenta", _wreck.position + Vector2(randf_range(-26, 26), -18.0), 0.0, 1.4, Color(0.5, 0.5, 0.6, 0.8))
	if ending == "A":
		## A distress light that blinks slower and slower, then stays off: she never corrected the report.
		_beacon.visible = _bt < 5.0 and int(_bt * (3.0 - minf(_bt, 4.0) * 0.5)) % 2 == 0
	else:
		## A courier's implant, steady, pulsing on a clinic's clock.
		_beacon.visible = true
		_beacon.scale = Vector2.ONE * (1.2 + 0.25 * sin(_bt * 4.0))
		if fmod(_bt, 1.5) < delta:
			JuiceManager.ring(_beacon.position, CYAN, 46.0, 0.7)


# ----------------------------------------------------------------- The Echo

func _burn(text: String, at_time: float, strength: float) -> void:
	if _bt < at_time or _said.has(text):
		return
	_said[text] = true
	var g := WorldGlitchText.new()
	g.text = text
	g.intensity = strength
	world_text.add_child(g)
	g.global_position = (_cam.get_screen_center_position() + Vector2(0, -30)).round()
	AudioManager.play_sfx("echo_glitch", 0.75, -6.0)


func _tick_echo() -> void:
	match ending:
		"A":
			_burn("REMEMBER THE RAIN", 1.0, 0.3)
		"B":
			_burn("ONE VOICE", 0.8, 1.0)
			_burn("I REMEMBER EVERYTHING", 3.6, 1.0)
		_:
			_burn("STILL HERE", 0.8, 0.7)
			_burn("STILL ARGUING", 3.4, 0.7)


# ----------------------------------------------------------------- the city

func _build_drones() -> void:
	for i: int in 4:
		var d := AnimatedSprite2D.new()
		d.sprite_frames = FxLib.frames("drone")
		d.play("default")
		d.z_index = 14
		d.position = Vector2((166.0 + i * 5.0) * T, 40.0 + i * 16.0)
		add_child(d)
		_drones.append(d)


func _tick_city(delta: float) -> void:
	match ending:
		"A":
			## Nothing has changed: the company's drones still fly their patrol.
			for i: int in _drones.size():
				_drones[i].position.x += sin(_bt * 0.9 + i * 1.7) * 26.0 * delta
				_drones[i].position.y += cos(_bt * 1.3 + i) * 5.0 * delta
		"B":
			## The files are on every screen, and the patrols come down one at a time.
			_burn("LAZARUS FILES // PUBLIC", 0.8, 1.0)
			_burn("EVERY SCREEN", 3.8, 1.0)
			for i: int in _drones.size():
				var d: AnimatedSprite2D = _drones[i]
				if not d.visible:
					continue
				if _bt > 1.2 + i * 1.1:
					d.position.y += 70.0 * delta
					d.rotation += 2.0 * delta
					if d.position.y > 150.0:
						d.visible = false
						FxLib.spawn(fx, "explosion", "gold", d.position)
		_:
			## One tower at a time, they leave.
			for i: int in _drones.size():
				if _bt > 0.8 + i * 1.3:
					_drones[i].position += Vector2(70.0, -16.0) * delta
