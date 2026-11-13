class_name WorldGlitchText
extends Node2D
## The Echo's words burned onto the buildings between the depth lane and the foreground.
## Pixel face at 2x world pixels. A " // " in the line splits it into beats that play one after
## another in the same spot ("00:00:00", then "IMPACT AVOIDED", then "BOUNCING BACK -60.0s");
## a long beat wraps to two lines at most. Each beat types on in hard steps, holds with the odd
## corrupted glyph, and the last one flickers out. Runs on real time.

const MAX_CHARS: int = 22
const TYPE_TIME: float = 0.2
const GLITCH: String = "#%&@!?<>=+*01"

var text: String = ""
var intensity: float = 1.0
var hold: float = 2.4

var _label: Label
var _beats: PackedStringArray = []
var _beat: int = -1
var _beat_len: float = 1.0
var _t: float = 0.0
var _last_ms: int = 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	for seg: String in PixelFont.clean(text).split(" // "):
		_beats.append("\n".join(_wrap(seg)))
	_beat_len = maxf(hold / float(_beats.size()), 0.85)
	_label = PixelFont.label("", 2, Color(1.0, 0.08, 0.22), false, Color(0.16, 0.0, 0.05, 1.0))
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_label)
	modulate.a = 0.75 * intensity + 0.2
	_last_ms = Time.get_ticks_msec()
	_show(0)


func _wrap(seg: String) -> PackedStringArray:
	var out: PackedStringArray = []
	var line: String = ""
	for word: String in seg.split(" ", false):
		if line != "" and line.length() + 1 + word.length() > MAX_CHARS:
			out.append(line)
			line = word
		else:
			line = word if line == "" else line + " " + word
	if line != "":
		out.append(line)
	return out


func _show(i: int) -> void:
	_beat = i
	_label.text = _beats[i]
	_label.visible_characters = 0
	## Size from the glyph table, not from the Label (it reports 0 before its first draw).
	var lines: PackedStringArray = _beats[i].split("\n")
	var w: float = 0.0
	for ln: String in lines:
		w = maxf(w, PixelFont.width(ln, 2))
	var h: float = lines.size() * (PixelFont.SIZE * 2 + 4) - 4
	_label.size = Vector2(w, h)
	_label.position = (-Vector2(w, h) * 0.5).round()


func _process(_delta: float) -> void:
	var now: int = Time.get_ticks_msec()
	_t += minf(float(now - _last_ms) / 1000.0, 0.1)
	_last_ms = now
	var idx: int = mini(int(_t / _beat_len), _beats.size() - 1)
	if idx != _beat:
		_show(idx)
	var local: float = _t - float(idx) * _beat_len
	var full: String = _beats[idx]
	if local < TYPE_TIME:
		_label.visible_characters = int(float(full.length()) * local / TYPE_TIME) + 1
		return
	_label.visible_characters = -1
	var last: bool = idx == _beats.size() - 1
	if not last or local < _beat_len:
		if _rng.randf() < 0.06 * intensity:
			var k: int = _rng.randi_range(0, full.length() - 1)
			if full[k] != " " and full[k] != "\n":
				_label.text = full.substr(0, k) + GLITCH[_rng.randi() % GLITCH.length()] + full.substr(k + 1)
		else:
			_label.text = full
		return
	var out_t: float = local - _beat_len
	visible = int(out_t * 24.0) % 3 != 0
	modulate.a = (0.75 * intensity + 0.2) * (1.0 - out_t / 0.5)
	if out_t > 0.5:
		queue_free()
