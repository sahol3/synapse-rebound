extends SceneTree
## Lays out the game's icon from art that already ships: the Warped City skyline, the player's
## deflect pose, one enemy shot and the title in m5x7. Nothing is drawn here; every pixel comes
## from a pack file or the font. The 64x64 layout is captured and scaled 4x without smoothing.
##
## Run with a window (not --headless):
##   godot --path game --script res://tests/IconCard.gd -- --out=<absolute path>.png

const ART: int = 64
const SCALE: int = 4
const INK: Color = Color("#05040B")

var _vp: SubViewport
var _out: String = ""


class Card extends Node2D:
	var sky: Texture2D = load("res://assets/warped_city/background/skyline-a.png")
	var hero: Texture2D = load("res://assets/warped_city/player/shoot.png")
	var shot: Texture2D = load("res://assets/warped_city/misc/shot/shot-1.png")
	var spark: Texture2D = load("res://assets/warped_city/misc/shot-hit/shot-hit-2.png")

	func _draw() -> void:
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		# Skyline: the sunset band sits behind the legs, open night sky behind the head and the title.
		draw_texture_rect_region(sky, Rect2(0, 0, 64, 64), Rect2(32, 118, 64, 64))
		# Player, feet on the bottom edge, with the same 1 px dark outline the interface text uses.
		var at := Vector2(-11, -3)
		for d: Vector2 in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
			draw_texture(hero, at + d, INK)
		draw_texture(hero, at)
		# The shot he has just sent back, leaving the wrist-guard.
		draw_texture(spark, Vector2(40, 22))
		draw_texture(shot, Vector2(49, 22), Color("#00F0FF"))
		# Title.
		PixelFont.draw(self, Vector2(32, 3), "REBOUND", 1, Color("#F2F4FF"), 2)


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.get_slice("=", 1)
	_vp = SubViewport.new()
	_vp.size = Vector2i(ART, ART)
	_vp.transparent_bg = false
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	_vp.add_child(Card.new())
	root.add_child(_vp)
	_capture()


func _capture() -> void:
	for i: int in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	var img: Image = _vp.get_texture().get_image()
	img.resize(ART * SCALE, ART * SCALE, Image.INTERPOLATE_NEAREST)
	if _out == "":
		push_error("IconCard: pass -- --out=<absolute path>.png")
	else:
		var err: Error = img.save_png(_out)
		print("ICONCARD saved=", _out, " err=", err, " size=", img.get_size())
	quit()
