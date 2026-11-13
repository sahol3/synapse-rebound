extends Node
## 8-voice SFX pool, music player, and the Music-bus filter chain
## (low-pass for Blackout, distortion + high-pass for Berserk Overdrive).
## Samples come from the Ansimuz Warped City pack. Every other cue is synthesized
## here from oscillators and noise at startup (deterministic code, no samples, no AI).

const MIX_RATE: int = 22050
const POOL_SIZE: int = 8
const LOWPASS_OPEN: float = 20500.0
const LOWPASS_BLACKOUT: float = 650.0

const MUSIC: Dictionary = {
	"stage": "res://assets/audio/bgm/cyber_runner.ogg",
	"boss": "res://assets/audio/bgm/sci_fi_platformer02.ogg",
}
const SAMPLES: Dictionary = {
	"beam": "res://assets/audio/sfx/beam.ogg",
	"explosion": "res://assets/audio/sfx/explosion.ogg",
	"hurt": "res://assets/audio/sfx/hurt.ogg",
}

## key -> list of layers [stream_id, volume_db, pitch_multiplier]
const CUES: Dictionary = {
	"parry_hit": [["ting", -4.0, 1.0], ["beam", -12.0, 1.8]],
	"rally_ping": [["bell", -3.0, 1.0], ["ting", -10.0, 1.0]],
	"z_lane_whoosh": [["whoosh", -4.0, 1.0]],
	"blackout_heartbeat": [["heartbeat", 0.0, 1.0]],
	"blackout_rebound": [["impact", -1.0, 1.0], ["explosion", -6.0, 0.7]],
	"vhs_rewind": [["rewind", -2.0, 1.0]],
	"sara_comms": [["beep2", -9.0, 1.2]],
	"echo_glitch": [["glitch", -6.0, 0.75]],
	"shot": [["beam", -11.0, 1.0]],
	"heavy_shot": [["beam", -6.0, 0.55]],
	"explosion": [["explosion", -3.0, 1.0]],
	"hurt": [["hurt", -2.0, 1.0]],
	"dash": [["whoosh_short", -6.0, 1.0]],
	"jump": [["blip", -14.0, 1.0]],
	"land": [["thud", -10.0, 1.0]],
	"shield": [["bell", -6.0, 0.62], ["glitch", -14.0, 1.3]],
	"rail": [["rail", -2.0, 1.0], ["beam", -6.0, 0.45]],
	"ui_move": [["beep1", -14.0, 1.0]],
	"ui_select": [["beep2", -8.0, 0.9]],
	"module": [["arp", -4.0, 1.0]],
	"laser_lock": [["lock", -10.0, 1.0]],
	"boss_alarm": [["alarm", -8.0, 1.0]],
	"swing": [["swish", -12.0, 1.0]],
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


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.seed = 909
	_setup_buses()
	for k: String in SAMPLES:
		_streams[k] = load(SAMPLES[k])
	_synthesize_all()
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
	_whine.stream = _streams["whine"]
	_whine.volume_db = -22.0
	add_child(_whine)
	GameState.tier_changed.connect(_on_tier_changed)


# ---------------------------------------------------------------- public API

func play_sfx(key: String, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if not CUES.has(key):
		return
	for layer: Array in CUES[key]:
		var stream: AudioStream = _streams.get(layer[0])
		if stream == null:
			continue
		var p: AudioStreamPlayer = _pool[_pool_index]
		_pool_index = (_pool_index + 1) % POOL_SIZE
		p.stream = stream
		p.volume_db = float(layer[1]) + volume_db
		p.pitch_scale = clampf(pitch * float(layer[2]), 0.05, 4.0)
		p.play()


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


# ---------------------------------------------------------------- filters

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


# ---------------------------------------------------------------- synthesis

func _synthesize_all() -> void:
	_streams["ting"] = _make(0.22, func(t: float) -> float:
		var e: float = exp(-t * 22.0)
		var n: float = _noise() * exp(-t * 400.0) * 0.6
		return (sin(TAU * 1760.0 * t) * 0.5 + sin(TAU * 2637.0 * t) * 0.3 + sin(TAU * 3951.0 * t) * 0.2) * e + n)
	_streams["bell"] = _make(0.5, func(t: float) -> float:
		var e: float = exp(-t * 7.0)
		var fm: float = sin(TAU * 3.0 * 880.0 * t) * 0.8 * exp(-t * 12.0)
		return (sin(TAU * 880.0 * t + fm) * 0.55 + sin(TAU * 1760.0 * t) * 0.25 + sin(TAU * 2640.0 * t) * 0.12) * e)
	_streams["whoosh"] = _make_noise_sweep(0.3, 300.0, 4200.0, 0.55)
	_streams["whoosh_short"] = _make_noise_sweep(0.16, 900.0, 5200.0, 0.45)
	_streams["swish"] = _make_noise_sweep(0.09, 1800.0, 7000.0, 0.35)
	_streams["heartbeat"] = _make(0.62, func(t: float) -> float:
		var a: float = _thump(t, 0.0)
		var b: float = _thump(t, 0.2) * 0.75
		return a + b)
	var whine_fn: Callable = func(t: float) -> float:
		return sin(TAU * 987.0 * t) * 0.18
	_streams["whine"] = _make(1.0, whine_fn, true)
	_streams["impact"] = _make(0.75, func(t: float) -> float:
		var sub_f: float = lerpf(90.0, 28.0, minf(t / 0.6, 1.0))
		var sub: float = sin(TAU * sub_f * t) * exp(-t * 4.0) * 0.9
		var n: float = _noise() * exp(-t * 18.0) * 0.5
		var chord: float = (sin(TAU * 440.0 * t) + sin(TAU * 554.4 * t) + sin(TAU * 659.3 * t)) * 0.12 * exp(-t * 5.0)
		return sub + n + chord)
	_streams["rewind"] = _make(0.38, func(t: float) -> float:
		var f: float = 300.0 + 900.0 * absf(sin(t * 22.0)) + 400.0 * sin(t * 140.0)
		var chop: float = 1.0 if fmod(t * 38.0, 1.0) > 0.25 else 0.25
		return (sin(TAU * f * t) * 0.45 + _noise() * 0.35) * chop * (1.0 - t / 0.38))
	_streams["beep1"] = _make_beeps([1320.0], 0.05, 0.0)
	_streams["beep2"] = _make_beeps([1320.0, 1760.0], 0.05, 0.035)
	_streams["glitch"] = _make_glitch(0.3)
	_streams["blip"] = _make(0.07, func(t: float) -> float:
		var f: float = lerpf(520.0, 980.0, t / 0.07)
		return signf(sin(TAU * f * t)) * 0.25 * (1.0 - t / 0.07))
	_streams["thud"] = _make(0.08, func(t: float) -> float:
		return sin(TAU * lerpf(120.0, 50.0, t / 0.08) * t) * (1.0 - t / 0.08) * 0.7)
	_streams["rail"] = _make(0.55, func(t: float) -> float:
		var crackle: float = _noise() * (0.5 + 0.5 * sin(t * 900.0)) * exp(-t * 5.0)
		var tone: float = sin(TAU * lerpf(1600.0, 200.0, t / 0.55) * t) * 0.35 * exp(-t * 3.0)
		return crackle * 0.6 + tone)
	_streams["arp"] = _make(0.7, func(t: float) -> float:
		var notes: Array[float] = [523.25, 659.25, 783.99, 1046.5]
		var idx: int = mini(int(t / 0.09), 3)
		var lt: float = t - float(idx) * 0.09
		return sin(TAU * notes[idx] * t) * exp(-lt * 6.0) * 0.4)
	_streams["lock"] = _make(0.9, func(t: float) -> float:
		var f: float = lerpf(400.0, 1400.0, t / 0.9)
		var gate: float = 1.0 if fmod(t * 14.0, 1.0) < 0.6 else 0.0
		return sin(TAU * f * t) * 0.3 * gate)
	_streams["alarm"] = _make(0.9, func(t: float) -> float:
		var f: float = 880.0 if fmod(t, 0.3) < 0.15 else 660.0
		return signf(sin(TAU * f * t)) * 0.18 * (1.0 - t / 0.9))


func _make(length: float, fn: Callable, loop: bool = false) -> AudioStreamWAV:
	var n: int = int(length * MIX_RATE)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i: int in n:
		var t: float = float(i) / MIX_RATE
		var v: float = clampf(float(fn.call(t)), -1.0, 1.0)
		var fade: float = minf(1.0, float(n - i) / 64.0) if not loop else 1.0
		data.encode_s16(i * 2, int(v * fade * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = MIX_RATE
	w.stereo = false
	w.data = data
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = n
	return w


func _make_noise_sweep(length: float, f0: float, f1: float, gain: float) -> AudioStreamWAV:
	var state: Array[float] = [0.0]
	return _make(length, func(t: float) -> float:
		var k: float = t / length
		var cutoff: float = lerpf(f0, f1, sin(k * PI))
		var alpha: float = clampf(TAU * cutoff / MIX_RATE, 0.0, 1.0)
		state[0] += alpha * (_noise() - state[0])
		return state[0] * gain * 2.2 * sin(k * PI))


func _make_beeps(freqs: Array, each: float, gap: float) -> AudioStreamWAV:
	var total: float = (each + gap) * freqs.size()
	return _make(total, func(t: float) -> float:
		var idx: int = int(t / (each + gap))
		var lt: float = t - float(idx) * (each + gap)
		if idx >= freqs.size() or lt > each:
			return 0.0
		var env: float = minf(1.0, lt * 400.0) * minf(1.0, (each - lt) * 400.0)
		return (sin(TAU * float(freqs[idx]) * t) * 0.6 + signf(sin(TAU * float(freqs[idx]) * t)) * 0.08) * env)


func _make_glitch(length: float) -> AudioStreamWAV:
	var held: Array[float] = [0.0, 0.0]
	return _make(length, func(t: float) -> float:
		held[1] -= 1.0
		if held[1] <= 0.0:
			held[0] = _noise()
			held[1] = float(_rng.randi_range(2, 40))
		var sq: float = signf(sin(TAU * 70.0 * t)) * 0.3 if fmod(t * 9.0, 1.0) < 0.4 else 0.0
		return (held[0] * 0.5 + sq) * (1.0 - t / length))


func _thump(t: float, at: float) -> float:
	var lt: float = t - at
	if lt < 0.0 or lt > 0.18:
		return 0.0
	return sin(TAU * lerpf(62.0, 38.0, lt / 0.18) * lt) * exp(-lt * 16.0) * 0.95


func _noise() -> float:
	return _rng.randf_range(-1.0, 1.0)
