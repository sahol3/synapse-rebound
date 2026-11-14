extends Node

const POOL_SIZE: int = 10
const LOWPASS_OPEN: float = 20500.0
const LOWPASS_BLACKOUT: float = 650.0
const K: String = "res://assets/audio/sfx/kenney/"
const MEME: String = "res://assets/audio/sfx/meme/"

const MUSIC: Dictionary = {
	"stage": "res://assets/audio/bgm/cyber_runner.ogg",
	"boss": "res://assets/audio/bgm/sci_fi_platformer02.ogg",
}

const SAMPLES: Dictionary = {
	"beam": ["res://assets/audio/sfx/beam.ogg"],
	"explosion": ["res://assets/audio/sfx/explosion.ogg"],
	"hurt": ["res://assets/audio/sfx/hurt.ogg"],
	"metal": [K + "impactMetal_000.ogg", K + "impactMetal_001.ogg", K + "impactMetal_002.ogg", K + "impactMetal_003.ogg", K + "impactMetal_004.ogg"],
	"laser_small": [K + "laserSmall_000.ogg", K + "laserSmall_001.ogg", K + "laserSmall_002.ogg", K + "laserSmall_003.ogg", K + "laserSmall_004.ogg"],
	"laser_large": [K + "laserLarge_000.ogg", K + "laserLarge_001.ogg", K + "laserLarge_002.ogg", K + "laserLarge_003.ogg", K + "laserLarge_004.ogg"],
	"laser_retro": [K + "laserRetro_000.ogg", K + "laserRetro_001.ogg", K + "laserRetro_002.ogg", K + "laserRetro_003.ogg", K + "laserRetro_004.ogg"],
	"force_field": [K + "forceField_000.ogg", K + "forceField_001.ogg", K + "forceField_002.ogg", K + "forceField_003.ogg", K + "forceField_004.ogg"],
	"crunch": [K + "explosionCrunch_000.ogg", K + "explosionCrunch_001.ogg", K + "explosionCrunch_002.ogg", K + "explosionCrunch_003.ogg", K + "explosionCrunch_004.ogg"],
	"low_boom": [K + "lowFrequency_explosion_000.ogg", K + "lowFrequency_explosion_001.ogg"],
	"drone": [K + "spaceEngineLow_000.ogg"],
	"thruster": [K + "thrusterBurst_000.ogg", K + "thrusterBurst_001.ogg"],
	"computer": [K + "computerNoiseShort_000.ogg"],
	"bell": [K + "impactBell_heavy_000.ogg", K + "impactBell_heavy_001.ogg", K + "impactBell_heavy_002.ogg", K + "impactBell_heavy_003.ogg", K + "impactBell_heavy_004.ogg"],
	"thump": [K + "impactSoft_heavy_000.ogg", K + "impactSoft_heavy_001.ogg", K + "impactSoft_heavy_002.ogg", K + "impactSoft_heavy_003.ogg", K + "impactSoft_heavy_004.ogg"],
	"soft": [K + "impactSoft_medium_000.ogg", K + "impactSoft_medium_001.ogg", K + "impactSoft_medium_002.ogg", K + "impactSoft_medium_003.ogg", K + "impactSoft_medium_004.ogg"],
	"step": [K + "footstep_concrete_000.ogg", K + "footstep_concrete_001.ogg", K + "footstep_concrete_002.ogg", K + "footstep_concrete_003.ogg", K + "footstep_concrete_004.ogg"],
	"punch": [K + "impactPunch_medium_000.ogg", K + "impactPunch_medium_001.ogg", K + "impactPunch_medium_002.ogg", K + "impactPunch_medium_003.ogg", K + "impactPunch_medium_004.ogg"],
	"tap": [K + "impactGeneric_light_000.ogg", K + "impactGeneric_light_001.ogg", K + "impactGeneric_light_002.ogg", K + "impactGeneric_light_003.ogg", K + "impactGeneric_light_004.ogg"],
	"scratch": [K + "scratch_001.ogg", K + "scratch_002.ogg", K + "scratch_003.ogg", K + "scratch_004.ogg", K + "scratch_005.ogg"],
	"glitch": [K + "glitch_001.ogg", K + "glitch_002.ogg", K + "glitch_003.ogg", K + "glitch_004.ogg"],
	"bong": [K + "bong_001.ogg"],
	"confirm": [K + "confirmation_001.ogg", K + "confirmation_002.ogg", K + "confirmation_003.ogg", K + "confirmation_004.ogg"],
	"error": [K + "error_005.ogg", K + "error_006.ogg"],
	"glass": [K + "glass_001.ogg", K + "glass_002.ogg", K + "glass_003.ogg"],
	"phase_jump": [K + "phaseJump1.ogg", K + "phaseJump2.ogg", K + "phaseJump3.ogg", K + "phaseJump4.ogg", K + "phaseJump5.ogg"],
	"phaser_down": [K + "phaserDown1.ogg", K + "phaserDown2.ogg", K + "phaserDown3.ogg"],
	"power_up": [K + "powerUp1.ogg", K + "powerUp2.ogg", K + "powerUp3.ogg", K + "powerUp4.ogg", K + "powerUp5.ogg", K + "powerUp6.ogg"],
	"lock_on": [K + "zapThreeToneUp.ogg"],
	"rollover": [K + "rollover1.ogg", K + "rollover2.ogg", K + "rollover3.ogg", K + "rollover4.ogg", K + "rollover5.ogg", K + "rollover6.ogg"],
	"scream": [MEME + "scream_1.ogg", MEME + "scream_2.ogg", MEME + "scream_3.ogg"],
	"beep": [MEME + "censor_beep.ogg"],
}

const CUES: Dictionary = {
	"meme_scream": [["scream", -9.0, 1.0]],
	"meme_beep": [["beep", -8.0, 1.0]],
	"meme_boom": [["low_boom", -1.0, 0.6], ["thump", -3.0, 0.5], ["bell", -16.0, 0.4]],
	"parry_hit": [["metal", -4.0, 1.15], ["laser_small", -13.0, 1.4]],
	"rally_ping": [["bell", -6.0, 1.0], ["glass", -10.0, 1.0]],
	"z_lane_whoosh": [["phase_jump", -6.0, 1.0], ["thruster", -12.0, 1.1]],
	"blackout_heartbeat": [["thump", -1.0, 0.7], ["thump", -4.0, 0.62, 0.2]],
	"blackout_rebound": [["low_boom", -6.0, 1.0], ["force_field", -7.0, 0.8], ["explosion", -11.0, 0.7]],
	"vhs_rewind": [["scratch", -3.0, 0.8], ["scratch", -5.0, 0.7, 0.09], ["phaser_down", -10.0, 1.3]],
	"saif_comms": [["bong", -9.0, 1.2]],
	"echo_glitch": [["glitch", -3.0, 0.75], ["glitch", -5.0, 0.6, 0.05], ["glitch", -4.0, 0.9, 0.11], ["computer", -15.0, 0.75]],
	"shot": [["beam", -11.0, 1.0]],
	"heavy_shot": [["laser_large", -8.0, 0.8]],
	"explosion": [["crunch", -4.0, 1.0], ["explosion", -7.0, 1.0]],
	"hurt": [["hurt", -2.0, 1.0], ["punch", -8.0, 1.0]],
	"dash": [["thruster", -7.0, 1.0]],
	"jump": [["step", -13.0, 1.25]],
	"land": [["soft", -9.0, 0.9], ["step", -12.0, 0.8]],
	"shield": [["force_field", -7.0, 1.15]],
	"rail": [["laser_retro", -7.0, 0.7], ["laser_large", -9.0, 0.6], ["low_boom", -18.0, 1.2]],
	"ui_move": [["rollover", -10.0, 1.0]],
	"ui_select": [["confirm", -7.0, 1.0]],
	"module": [["power_up", -5.0, 1.0]],
	"laser_lock": [["lock_on", -11.0, 1.0]],
	"boss_alarm": [["error", -9.0, 0.85], ["error", -10.0, 0.85, 0.32]],
	"swing": [["tap", -15.0, 1.6]],
}

var _streams: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
var _pool_index: int = 0
var _music: AudioStreamPlayer
var _whine: AudioStreamPlayer
var _music_bus: int = -1
var _sfx_bus: int = -1
var _current_music: String = ""
var _lowpass: AudioEffectLowPassFilter
var _distortion: AudioEffectDistortion
var _highpass: AudioEffectHighPassFilter
var _tier_cutoff: float = LOWPASS_OPEN
var _blackout: bool = false
var _rng := RandomNumberGenerator.new()

const VOICE_DIR: String = "res://assets/audio/voice/"
var _meme: AudioStreamPlayer
var voice_enabled: bool = true
const VOICE_FOLDER: Dictionary = {"SAIF": "saif", "LOG": "saif", "ECHO": "echo"}
const STATIC_BED: String = K + "computerNoise_002.ogg"
const BED_DB: float = -21.0
const BED_LOG_DB: float = -13.0
const DUCK_DB: float = -6.0
var _vox: AudioStreamPlayer
var _bed: AudioStreamPlayer
var _click: AudioStreamPlayer
var _voice_cache: Dictionary = {}
var _voice_end_ms: int = 0
var _radio_bus: int = -1
var _echo_bus: int = -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.seed = 909
	_setup_buses()
	_setup_voice()
	_voice_report.call_deferred()
	for k: String in SAMPLES:
		var list: Array = []
		for path: String in SAMPLES[k]:
			list.append(load(path))
		_streams[k] = list
	for i: int in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	_music.volume_db = -6.0
	add_child(_music)
	_whine = AudioStreamPlayer.new()
	_whine.bus = "SFX"
	var drone: AudioStreamOggVorbis = (_streams["drone"][0] as AudioStreamOggVorbis).duplicate()
	drone.loop = true
	_whine.stream = drone
	_whine.volume_db = -14.0
	_whine.pitch_scale = 0.8
	add_child(_whine)
	GameState.tier_changed.connect(_on_tier_changed)


func play_sfx(key: String, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if not CUES.has(key):
		return
	for layer: Array in CUES[key]:
		var variants: Array = _streams.get(layer[0], [])
		if variants.is_empty():
			continue
		var stream: AudioStream = variants[_rng.randi() % variants.size()]
		var vol: float = float(layer[1]) + volume_db
		var pit: float = clampf(pitch * float(layer[2]), 0.05, 4.0)
		var delay: float = float(layer[3]) if layer.size() > 3 else 0.0
		if delay <= 0.0:
			_voice(stream, vol, pit)
		else:
			get_tree().create_timer(delay, true, false, true).timeout.connect(func() -> void: _voice(stream, vol, pit))


func all_samples_loaded() -> bool:
	for k: String in _streams:
		for s: Variant in _streams[k]:
			if s == null:
				return false
	return _streams.size() == SAMPLES.size()


func play_parry(bounce_count: int) -> void:
	if bounce_count >= 2:
		play_sfx("rally_ping", 1.0 + float(bounce_count) * 0.14)
	else:
		play_sfx("parry_hit", _rng.randf_range(0.95, 1.08))


func play_music(id: String, fade: float = 0.6) -> void:
	if id == _current_music and _music.playing:
		return
	_current_music = id
	var stream: AudioStreamOggVorbis = load(MUSIC[id])
	stream.loop = true
	var tw := create_tween()
	tw.set_ignore_time_scale(true)
	if _music.playing:
		tw.tween_property(_music, "volume_db", -40.0, fade * 0.5)
	tw.tween_callback(func() -> void:
		_music.stream = stream
		_music.play())
	tw.tween_property(_music, "volume_db", -6.0, fade)


func stop_music(fade: float = 1.0) -> void:
	_current_music = ""
	var tw := create_tween()
	tw.set_ignore_time_scale(true)
	tw.tween_property(_music, "volume_db", -60.0, fade)
	tw.tween_callback(_music.stop)


func set_blackout(active: bool) -> void:
	_blackout = active
	if active:
		_whine.play()
	else:
		_whine.stop()
	_apply_filters(0.12 if active else 0.25)


func set_menu_muffle(active: bool) -> void:
	_tier_cutoff = 1800.0 if active else _cutoff_for_tier(GameState.tier)
	_apply_filters(0.4)


func voice_stream(who: String, key: String) -> AudioStream:
	var id: String = String(VOICE_FOLDER.get(who, who.to_lower())) + "/" + key
	if not _voice_cache.has(id):
		var found: AudioStream = null
		for ext: String in ["ogg", "wav", "mp3"]:
			var path: String = VOICE_DIR + id + "." + ext
			if ResourceLoader.exists(path):
				found = load(path) as AudioStream
				break
		_voice_cache[id] = found
	return _voice_cache[id]


func register_voice(who: String, key: String, stream: AudioStream) -> void:
	_voice_cache[String(VOICE_FOLDER.get(who, who.to_lower())) + "/" + key] = stream


func play_voice(who: String, key: String) -> float:
	var stream: AudioStream = voice_stream(who, key) if voice_enabled else null
	if stream == null:
		return 0.0
	var tape: bool = who == "LOG"
	_vox.stream = stream
	_vox.bus = "Echo" if who == "ECHO" else "Radio"
	_vox.pitch_scale = 0.96 if tape else 1.0
	_vox.stream_paused = false
	_vox.play()
	var length: float = stream.get_length() / _vox.pitch_scale
	if who != "ECHO":
		_bed.volume_db = BED_LOG_DB if tape else BED_DB
		_bed.stream_paused = false
		if not _bed.playing:
			_bed.play(_rng.randf_range(0.0, 3.0))
		_key_click()
	_voice_end_ms = Time.get_ticks_msec() + int((length + 0.3) * 1000.0)
	AudioServer.set_bus_volume_db(_music_bus, DUCK_DB)
	return length


func play_meme(key: String, fallback: String = "") -> bool:
	var stream: AudioStream = voice_stream("MEME", key) if voice_enabled else null
	if stream == null:
		if fallback != "":
			play_sfx(fallback)
		return false
	if _meme == null:
		_meme = AudioStreamPlayer.new()
		_meme.bus = "SFX"
		_meme.volume_db = -3.0
		_meme.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(_meme)
	_meme.stream = stream
	_meme.play()
	return true


func stop_voice() -> void:
	if _vox == null:
		return
	_vox.stop()
	_bed.stop()
	_voice_end_ms = 0
	AudioServer.set_bus_volume_db(_music_bus, 0.0)


func pause_voice(on: bool) -> void:
	if _vox == null:
		return
	_vox.stream_paused = on
	_bed.stream_paused = on


func voice_counts() -> Vector2i:
	var have: int = 0
	var total: int = 0
	for id: String in DialogueData.LINES:
		var all: Array = DialogueData.LINES[id]
		for i: int in all.size():
			if all[i]["who"] in ["SAIF", "LOG", "ECHO"]:
				total += 1
				if voice_stream(all[i]["who"], "%s_%d" % [id, i + 1]) != null:
					have += 1
	return Vector2i(have, total)


func _voice_report() -> void:
	var c: Vector2i = voice_counts()
	if c.x > 0:
		print("voice: %d of %d spoken lines have a recording" % [c.x, c.y])


func voice_playing() -> bool:
	return _vox != null and _vox.playing


func _key_click() -> void:
	var taps: Array = _streams.get("tap", [])
	if taps.is_empty():
		return
	_click.stream = taps[_rng.randi() % taps.size()]
	_click.pitch_scale = _rng.randf_range(1.5, 1.8)
	_click.play()


func _process(_delta: float) -> void:
	if _voice_end_ms > 0 and Time.get_ticks_msec() >= _voice_end_ms and not _vox.stream_paused:
		_voice_end_ms = 0
		if _bed.playing:
			_bed.stop()
			_key_click()
		AudioServer.set_bus_volume_db(_music_bus, 0.0)


func _setup_voice() -> void:
	voice_enabled = GameState.voice_on()
	_vox = AudioStreamPlayer.new()
	_vox.bus = "Radio"
	add_child(_vox)
	_click = AudioStreamPlayer.new()
	_click.bus = "Radio"
	_click.volume_db = -8.0
	add_child(_click)
	_bed = AudioStreamPlayer.new()
	_bed.bus = "Radio"
	var bed: AudioStreamOggVorbis = (load(STATIC_BED) as AudioStreamOggVorbis).duplicate()
	bed.loop = true
	_bed.stream = bed
	_bed.volume_db = BED_DB
	add_child(_bed)


func _voice(stream: AudioStream, vol: float, pit: float) -> void:
	var p: AudioStreamPlayer = _pool[_pool_index]
	_pool_index = (_pool_index + 1) % POOL_SIZE
	p.stream = stream
	p.volume_db = vol
	p.pitch_scale = pit
	p.play()


func _setup_buses() -> void:
	_music_bus = AudioServer.get_bus_index("Music")
	if _music_bus == -1:
		AudioServer.add_bus()
		_music_bus = AudioServer.bus_count - 1
		AudioServer.set_bus_name(_music_bus, "Music")
		AudioServer.set_bus_send(_music_bus, "Master")
		_lowpass = AudioEffectLowPassFilter.new()
		_lowpass.cutoff_hz = LOWPASS_OPEN
		_distortion = AudioEffectDistortion.new()
		_distortion.mode = AudioEffectDistortion.MODE_OVERDRIVE
		_distortion.drive = 0.35
		_distortion.post_gain = -4.0
		_highpass = AudioEffectHighPassFilter.new()
		_highpass.cutoff_hz = 220.0
		AudioServer.add_bus_effect(_music_bus, _lowpass, 0)
		AudioServer.add_bus_effect(_music_bus, _distortion, 1)
		AudioServer.add_bus_effect(_music_bus, _highpass, 2)
		AudioServer.set_bus_effect_enabled(_music_bus, 1, false)
		AudioServer.set_bus_effect_enabled(_music_bus, 2, false)
	_sfx_bus = AudioServer.get_bus_index("SFX")
	if _sfx_bus == -1:
		AudioServer.add_bus()
		_sfx_bus = AudioServer.bus_count - 1
		AudioServer.set_bus_name(_sfx_bus, "SFX")
		AudioServer.set_bus_send(_sfx_bus, "Master")
	_radio_bus = AudioServer.get_bus_index("Radio")
	if _radio_bus == -1:
		AudioServer.add_bus()
		_radio_bus = AudioServer.bus_count - 1
		AudioServer.set_bus_name(_radio_bus, "Radio")
		AudioServer.set_bus_send(_radio_bus, "Master")
		var hp := AudioEffectHighPassFilter.new()
		hp.cutoff_hz = 340.0
		var lp := AudioEffectLowPassFilter.new()
		lp.cutoff_hz = 3100.0
		var drive := AudioEffectDistortion.new()
		drive.mode = AudioEffectDistortion.MODE_OVERDRIVE
		drive.drive = 0.28
		drive.post_gain = -2.0
		var comp := AudioEffectCompressor.new()
		comp.threshold = -18.0
		comp.ratio = 4.0
		comp.gain = 5.0
		AudioServer.add_bus_effect(_radio_bus, hp, 0)
		AudioServer.add_bus_effect(_radio_bus, lp, 1)
		AudioServer.add_bus_effect(_radio_bus, drive, 2)
		AudioServer.add_bus_effect(_radio_bus, comp, 3)
	_echo_bus = AudioServer.get_bus_index("Echo")
	if _echo_bus == -1:
		AudioServer.add_bus()
		_echo_bus = AudioServer.bus_count - 1
		AudioServer.set_bus_name(_echo_bus, "Echo")
		AudioServer.set_bus_send(_echo_bus, "Master")
		var shift := AudioEffectPitchShift.new()
		shift.pitch_scale = 0.84
		var lofi := AudioEffectDistortion.new()
		lofi.mode = AudioEffectDistortion.MODE_LOFI
		lofi.drive = 0.2
		var room := AudioEffectReverb.new()
		room.room_size = 0.4
		room.wet = 0.25
		AudioServer.add_bus_effect(_echo_bus, shift, 0)
		AudioServer.add_bus_effect(_echo_bus, lofi, 1)
		AudioServer.add_bus_effect(_echo_bus, room, 2)


func _cutoff_for_tier(t: int) -> float:
	return 7000.0 if t == GameState.Tier.DEGRADED else LOWPASS_OPEN


func _on_tier_changed(t: int) -> void:
	_tier_cutoff = _cutoff_for_tier(t)
	var berserk: bool = t == GameState.Tier.BERSERK
	AudioServer.set_bus_effect_enabled(_music_bus, 1, berserk)
	AudioServer.set_bus_effect_enabled(_music_bus, 2, berserk)
	_apply_filters(0.3)


func _apply_filters(time: float) -> void:
	if _lowpass == null:
		return
	var target: float = LOWPASS_BLACKOUT if _blackout else _tier_cutoff
	var tw := create_tween()
	tw.set_ignore_time_scale(true)
	tw.tween_property(_lowpass, "cutoff_hz", target, time)
