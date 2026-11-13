class_name PixelFont
extends RefCounted
## The game's own bitmap typeface, drawn by hand as 5x7 glyphs (descenders go 2 rows lower) and
## built into a FontFile in memory at startup. Nothing is loaded from disk and nothing is written
## to disk. Fixed size 9 with integer-only scaling, so text always lands on the same pixel grid as
## the 16 px Warped City art: size 9 = 1x, 18 = 2x, 27 = 3x.
##
## Glyph format: rows separated by spaces, '#' = ink, '.' = empty. Row 0 is the top of a capital,
## row 6 sits on the baseline, rows 7-8 are descenders.

const SIZE: int = 9
const ASCENT: int = 7
const DESCENT: int = 2

const GLYPHS: Dictionary = {
	" ": "... ... ... ... ... ... ...",
	"A": ".###. #...# #...# ##### #...# #...# #...#",
	"B": "####. #...# #...# ####. #...# #...# ####.",
	"C": ".#### #.... #.... #.... #.... #.... .####",
	"D": "####. #...# #...# #...# #...# #...# ####.",
	"E": "##### #.... #.... ####. #.... #.... #####",
	"F": "##### #.... #.... ####. #.... #.... #....",
	"G": ".#### #.... #.... #.### #...# #...# .####",
	"H": "#...# #...# #...# ##### #...# #...# #...#",
	"I": "### .#. .#. .#. .#. .#. ###",
	"J": "....# ....# ....# ....# #...# #...# .###.",
	"K": "#...# #..#. #.#.. ##... #.#.. #..#. #...#",
	"L": "#.... #.... #.... #.... #.... #.... #####",
	"M": "#...# ##.## #.#.# #.#.# #...# #...# #...#",
	"N": "#...# ##..# #.#.# #..## #...# #...# #...#",
	"O": ".###. #...# #...# #...# #...# #...# .###.",
	"P": "####. #...# #...# ####. #.... #.... #....",
	"Q": ".###. #...# #...# #...# #.#.# #..#. .##.#",
	"R": "####. #...# #...# ####. #.#.. #..#. #...#",
	"S": ".#### #.... #.... .###. ....# ....# ####.",
	"T": "##### ..#.. ..#.. ..#.. ..#.. ..#.. ..#..",
	"U": "#...# #...# #...# #...# #...# #...# .###.",
	"V": "#...# #...# #...# #...# .#.#. .#.#. ..#..",
	"W": "#...# #...# #...# #.#.# #.#.# ##.## #...#",
	"X": "#...# #...# .#.#. ..#.. .#.#. #...# #...#",
	"Y": "#...# #...# .#.#. ..#.. ..#.. ..#.. ..#..",
	"Z": "##### ....# ...#. ..#.. .#... #.... #####",
	"a": "..... ..... .###. ....# .#### #...# .####",
	"b": "#.... #.... ####. #...# #...# #...# ####.",
	"c": "..... ..... .#### #.... #.... #.... .####",
	"d": "....# ....# .#### #...# #...# #...# .####",
	"e": "..... ..... .###. #...# ##### #.... .####",
	"f": "..## .#.. #### .#.. .#.. .#.. .#..",
	"g": "..... ..... .#### #...# #...# #...# .#### ....# ####.",
	"h": "#.... #.... ####. #...# #...# #...# #...#",
	"i": "# . # # # # #",
	"j": "..# ... ..# ..# ..# ..# ..# ..# ##.",
	"k": "#... #... #..# #.#. ##.. #.#. #..#",
	"l": "#. #. #. #. #. #. .#",
	"m": "..... ..... ##.#. #.#.# #.#.# #.#.# #...#",
	"n": "..... ..... ####. #...# #...# #...# #...#",
	"o": "..... ..... .###. #...# #...# #...# .###.",
	"p": "..... ..... ####. #...# #...# #...# ####. #.... #....",
	"q": "..... ..... .#### #...# #...# #...# .#### ....# ....#",
	"r": ".... .... #.## ##.. #... #... #...",
	"s": "..... ..... .#### #.... .###. ....# ####.",
	"t": ".#.. .#.. #### .#.. .#.. .#.. ..##",
	"u": "..... ..... #...# #...# #...# #...# .####",
	"v": "..... ..... #...# #...# .#.#. .#.#. ..#..",
	"w": "..... ..... #...# #.#.# #.#.# #.#.# .#.#.",
	"x": "..... ..... #...# .#.#. ..#.. .#.#. #...#",
	"y": "..... ..... #...# #...# #...# #...# .#### ....# ####.",
	"z": "..... ..... ##### ...#. ..#.. .#... #####",
	"0": ".###. #...# #..## #.#.# ##..# #...# .###.",
	"1": "..#.. .##.. #.#.. ..#.. ..#.. ..#.. #####",
	"2": ".###. #...# ....# ...#. ..#.. .#... #####",
	"3": "####. ....# ....# .###. ....# ....# ####.",
	"4": "...#. ..##. .#.#. #..#. ##### ...#. ...#.",
	"5": "##### #.... ####. ....# ....# #...# .###.",
	"6": ".###. #.... #.... ####. #...# #...# .###.",
	"7": "##### ....# ...#. ..#.. ..#.. ..#.. ..#..",
	"8": ".###. #...# #...# .###. #...# #...# .###.",
	"9": ".###. #...# #...# .#### ....# ....# .###.",
	".": ". . . . . . #",
	",": ".. .. .. .. .. .. .# #.",
	"!": "# # # # # . #",
	"?": ".###. #...# ....# ...#. ..#.. ..... ..#..",
	"'": "# # . . . . .",
	"\"": "#.# #.# ... ... ... ... ...",
	":": ". . # . . # .",
	";": ".. .. .# .. .. .# #.",
	"-": ".... .... .... #### .... .... ....",
	"_": ".... .... .... .... .... .... ####",
	"+": "..... ..... ..#.. .###. ..#.. ..... .....",
	"=": "..... ..... ##### ..... ##### ..... .....",
	"*": "..... #.#.# .###. ##### .###. #.#.# .....",
	"/": "....# ....# ...#. ..#.. .#... #.... #....",
	"\\": "#.... #.... .#... ..#.. ...#. ....# ....#",
	"(": ".# #. #. #. #. #. .#",
	")": "#. .# .# .# .# .# #.",
	"[": "## #. #. #. #. #. ##",
	"]": "## .# .# .# .# .# ##",
	"<": "...# ..#. .#.. #... .#.. ..#. ...#",
	">": "#... .#.. ..#. ...# ..#. .#.. #...",
	"%": "##..# ##..# ...#. ..#.. .#... #..## #..##",
	"#": ".#.#. .#.#. ##### .#.#. ##### .#.#. .#.#.",
	"&": ".##.. #..#. #.#.. .#... #.#.# #..#. .##.#",
	"@": ".###. #...# #.### #.#.# #.### #.... .####",
	"$": "..#.. .#### #.#.. .###. ..#.# ####. ..#..",
	"^": "..#.. .#.#. #...# ..... ..... ..... .....",
	"|": "# # # # # # #",
	"~": "..... ..... .#..# #.##. ..... ..... .....",
	"`": "#. .# .. .. .. .. ..",
}

static var _font: FontFile
static var _bold: FontFile


## bold = every ink pixel also inks its right neighbour (a 2 px stroke for display sizes).
static func font(bold: bool = false) -> FontFile:
	if bold and _bold != null:
		return _bold
	if not bold and _font != null:
		return _font
	var extra: int = 1 if bold else 0
	var keys: Array = GLYPHS.keys()
	var total_w: int = 0
	for k: String in keys:
		total_w += _rows(k)[0].length() + 1 + extra
	var img := Image.create_empty(maxi(total_w, 1), SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 0))
	var f := FontFile.new()
	f.fixed_size = SIZE
	f.fixed_size_scale_mode = TextServer.FIXED_SIZE_SCALE_INTEGER_ONLY
	f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	f.generate_mipmaps = false
	f.hinting = TextServer.HINTING_NONE
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	f.allow_system_fallback = false
	var sz := Vector2i(SIZE, 0)
	var x: int = 0
	for k: String in keys:
		var rows: PackedStringArray = _rows(k)
		var w: int = rows[0].length() + (extra if k != " " else 0)
		for r: int in rows.size():
			for c: int in rows[r].length():
				if rows[r].unicode_at(c) == 35:  # '#'
					img.set_pixel(x + c, r, Color.WHITE)
					if bold:
						img.set_pixel(x + c + 1, r, Color.WHITE)
		var code: int = k.unicode_at(0)
		f.set_glyph_advance(0, SIZE, code, Vector2(w + 1, 0))
		f.set_glyph_offset(0, sz, code, Vector2(0, -ASCENT))
		f.set_glyph_size(0, sz, code, Vector2(w, SIZE))
		f.set_glyph_uv_rect(0, sz, code, Rect2(x, 0, w, SIZE))
		f.set_glyph_texture_idx(0, sz, code, 0)
		x += w + 1
	f.set_texture_image(0, sz, 0, img)
	f.set_cache_ascent(0, SIZE, ASCENT)
	f.set_cache_descent(0, SIZE, DESCENT)
	if bold:
		_bold = f
	else:
		_font = f
	return f


static func _rows(k: String) -> PackedStringArray:
	var rows: PackedStringArray = String(GLYPHS[k]).split(" ")
	var w: int = rows[0].length()
	while rows.size() < SIZE:
		rows.append(".".repeat(w))
	return rows


## Replaces characters the font does not draw (curly quotes, dashes, ellipsis) with ASCII.
static func clean(text: String) -> String:
	var t: String = text.replace("…", "...").replace("—", "-").replace("–", "-")
	t = t.replace("‘", "'").replace("’", "'").replace("“", "\"").replace("”", "\"")
	t = t.replace("×", "x").replace("·", "-")
	return t


## Pixel width of `text` at `scale` (1 = size 9). Trailing letter gap is excluded.
static func width(text: String, scale: int = 1, bold: bool = false) -> int:
	var w: int = 0
	for i: int in text.length():
		var ch: String = text[i]
		if GLYPHS.has(ch):
			w += _rows(ch)[0].length() + 1 + (1 if bold and ch != " " else 0)
	return maxi(w - 1, 0) * scale


## A Label in the pixel face with a hard 1 px drop shadow, the only outline style bitmap glyphs allow.
static func label(text: String, scale: int, color: Color, bold: bool = false, shadow: Color = Color(0.02, 0.01, 0.06, 1.0)) -> Label:
	var l := Label.new()
	l.text = clean(text)
	l.add_theme_font_override("font", font(bold))
	l.add_theme_font_size_override("font_size", SIZE * scale)
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
	var fs: int = SIZE * scale
	if outline.a > 0.0:
		var oc := Color(outline.r, outline.g, outline.b, outline.a * col.a)
		for d: Vector2 in [Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1), Vector2(-1, 0), Vector2(1, 0),
				Vector2(-1, 1), Vector2(0, 1), Vector2(1, 1)]:
			ci.draw_string(f, base + d * scale, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, oc)
	ci.draw_string(f, base, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
