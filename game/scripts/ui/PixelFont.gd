class_name PixelFont
extends RefCounted
## The game's interface typeface: m5x7 by Daniel Linssen (CC0), loaded from
## `res://assets/fonts/m5x7.ttf`. It is a 5x7 pixel face: capitals are 7 px tall, lowercase is 5,
## descenders go 2 px below the baseline. The file is drawn at 16 px per pixel-grid unit, so only
## whole multiples are used (16 = 1x, 32 = 2x, 48 = 3x) and text lands on the same pixel grid as
## the 16 px Warped City art.
##
## SIZE, ASCENT and DESCENT describe the line box the layout code works with (cap height plus
## descenders), which is smaller than the metrics stored in the font file. `font()` writes them
## into the font's size caches so Labels lay out on that box too.

const PATH: String = "res://assets/fonts/m5x7.ttf"
## Font size that gives one screen pixel per font pixel.
const PX: int = 16
const SIZE: int = 9
const ASCENT: int = 7
const DESCENT: int = 2

static var _font: FontFile
static var _widths: Dictionary = {}


static func font() -> FontFile:
	if _font != null:
		return _font
	var f: FontFile = (load(PATH) as FontFile).duplicate()
	f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	f.generate_mipmaps = false
	f.hinting = TextServer.HINTING_NONE
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	f.allow_system_fallback = false
	f.force_autohinter = false
	for scale: int in [1, 2, 3, 4]:
		f.set_cache_ascent(0, PX * scale, ASCENT * scale)
		f.set_cache_descent(0, PX * scale, DESCENT * scale)
	_font = f
	return f


## Replaces characters the layout should not meet (curly quotes, dashes, ellipsis) with ASCII.
static func clean(text: String) -> String:
	var t: String = text.replace("…", "...").replace("—", "-").replace("–", "-")
	t = t.replace("‘", "'").replace("’", "'").replace("“", "\"").replace("”", "\"")
	t = t.replace("×", "x").replace("·", "-")
	return t


## Advance of one character in font pixels, including its 1 px letter gap.
static func _advance(ch: String) -> int:
	if _widths.has(ch):
		return _widths[ch]
	var w: int = int(roundf(font().get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, PX).x))
	_widths[ch] = w
	return w


## Pixel width of `text` at `scale` (1 = 16 px). Trailing letter gap is excluded.
static func width(text: String, scale: int = 1) -> int:
	var w: int = 0
	for i: int in text.length():
		w += _advance(text[i])
	return maxi(w - 1, 0) * scale


## A Label in the pixel face with a hard 1 px drop shadow, the only outline style bitmap glyphs allow.
static func label(text: String, scale: int, color: Color, _unused: bool = false, shadow: Color = Color(0.02, 0.01, 0.06, 1.0)) -> Label:
	var l := Label.new()
	l.text = clean(text)
	l.add_theme_font_override("font", font())
	l.add_theme_font_size_override("font_size", PX * scale)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", shadow)
	l.add_theme_constant_override("shadow_offset_x", scale)
	l.add_theme_constant_override("shadow_offset_y", scale)
	l.add_theme_constant_override("line_spacing", 2 * scale)
	l.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Greedy word wrap to `max_w` pixels at `scale`. Keeps explicit newlines.
static func wrap(text: String, max_w: int, scale: int = 1) -> PackedStringArray:
	var out: PackedStringArray = []
	for para: String in clean(text).split("\n"):
		var line: String = ""
		for word: String in para.split(" ", false):
			var test: String = word if line == "" else line + " " + word
			if line != "" and width(test, scale) > max_w:
				out.append(line)
				line = word
			else:
				line = test
		out.append(line)
	return out


## Draws `text` with a 1-pixel outline on all eight sides, the way pixel games keep type readable
## over busy art without a box. `pos` is the top-left (align 0), right edge (1) or centre (2).
static func draw(ci: CanvasItem, pos: Vector2, text: String, scale: int, col: Color,
		align: int = 0, outline: Color = Color("#05040B")) -> void:
	var f: FontFile = font()
	var w: float = width(text, scale)
	var x: float = pos.x - (w if align == 1 else (floorf(w * 0.5) if align == 2 else 0.0))
	var base := Vector2(roundf(x), roundf(pos.y) + ASCENT * scale)
	var fs: int = PX * scale
	if outline.a > 0.0:
		var oc := Color(outline.r, outline.g, outline.b, outline.a * col.a)
		for d: Vector2 in [Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1), Vector2(-1, 0), Vector2(1, 0),
				Vector2(-1, 1), Vector2(0, 1), Vector2(1, 1)]:
			ci.draw_string(f, base + d * scale, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, oc)
	ci.draw_string(f, base, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
