extends Node
## 8-voice SFX pool, music player, and the Music-bus filter chain
## (low-pass for Blackout, distortion + high-pass for Berserk Overdrive).
## Every sound is a recorded sample from a human-made pack: Warped City (Ansimuz, CC0) and the
## Kenney Sci-Fi, Impact, Interface, Digital Audio and UI Audio packs (CC0). Nothing is synthesized.
## A cue is a list of layers; each layer picks a random variant of its sample, so repeats differ.

const POOL_SIZE: int = 10
const LOWPASS_OPEN: float = 20500.0
const LOWPASS_BLACKOUT: float = 650.0
const K: String = "res://assets/audio/sfx/kenney/"

const MUSIC: Dictionary = {
	"stage": "res://assets/audio/bgm/cyber_runner.ogg",
	"boss": "res://assets/audio/bgm/sci_fi_platformer02.ogg",
}

## sample id -> variant files (one is picked at random per play)
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
}

## key -> list of layers [sample_id, volume_db, pitch_multiplier, delay_seconds (optional)]
const CUES: Dictionary = {
	"parry_hit": [["metal", -4.0, 1.15], ["laser_small", -13.0, 1.4]],
	"rally_ping": [["bell", -6.0, 1.0], ["glass", -10.0, 1.0]],
	"z_lane_whoosh": [["phase_jump", -6.0, 1.0], ["thruster", -12.0, 1.1]],
	"blackout_heartbeat": [["thump", -1.0, 0.7], ["thump", -4.0, 0.62, 0.2]],
	"blackout_rebound": [["low_boom", -6.0, 1.0], ["force_field", -7.0, 0.8], ["explosion", -11.0, 0.7]],
	"vhs_rewind": [["scratch", -3.0, 0.8], ["scratch", -5.0, 0.7, 0.09], ["phaser_down", -10.0, 1.3]],
	"sara_comms": [["bong", -9.0, 1.2]],
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

var _streams: Dictionary = {}  ## sample id -> Array of AudioStream
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


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.seed = 909
	_setup_buses()
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
	## Blackout bed: a recorded low engine hum, looped and pitched down, under the heartbeat.
	_whine = AudioStreamPlayer.new()
	_whine.bus = "SFX"
	var drone: AudioStreamOggVorbis = (_streams["drone"][0] as AudioStreamOggVorbis).duplicate()
	drone.loop = true
	_whine.stream = drone
	_whine.volume_db = -14.0
	_whine.pitch_scale = 0.8
	add_child(_whine)
	GameState.tier_changed.connect(_on_tier_changed)


# ---------------------------------------------------------------- public API

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
			## Real-time delay so hit-stop or the Blackout slow-down does not stretch the rhythm.
			get_tree().create_timer(delay, true, false, true).timeout.connect(func() -> void: _voice(stream, vol, pit))


## True when every sample listed in SAMPLES loaded. Used by tests.
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


# ---------------------------------------------------------------- private

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
