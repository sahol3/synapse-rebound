extends SceneTree
## Renders a specimen of PixelFont at 1x/2x/3x inside a 3x canvas, for movie-writer review.
## tools\godot\Godot_v4.7.2-stable_win64_console.exe --path game --script res://tests/FontProbe.gd --write-movie <dir>\f.png --fixed-fps 10 --quit-after 3


func _initialize() -> void:
	var layer := CanvasLayer.new()
	layer.transform = Transform2D.IDENTITY.scaled(Vector2(3, 3))
	root.add_child(layer)
	var bg := ColorRect.new()
	bg.color = Color("#0b0a1a")
	bg.size = Vector2(384, 216)
	layer.add_child(bg)
	var lines: Array = [
		["ABCDEFGHIJKLMNOPQRSTUVWXYZ 0123456789", 1],
		["abcdefghijklmnopqrstuvwxyz .,!?'\":;-+=*/()[]<>%#&@$_", 1],
		["Vincent?! Holy hell, your Lazarus implant actually fired!", 1],
		["SYNC 109%  LOOP 02  00:43.71", 2],
		["REBOUND", 3],
	]
	var y: int = 6
	for ln: Array in lines:
		var l := PixelFont.label(ln[0], ln[1], Color("#e6f1ff"))
		l.position = Vector2(6, y)
		layer.add_child(l)
		y += 12 * int(ln[1]) + 4
	print("font width REBOUND x3 = ", PixelFont.width("REBOUND", 3))
