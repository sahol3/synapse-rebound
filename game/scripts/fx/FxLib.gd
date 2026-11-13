class_name FxLib
extends RefCounted
## Builds SpriteFrames from the human-made sheets (BDragon1727 16x16 effects, Ansimuz Warped City)
## and spawns one-shot effect sprites. Frames are cached per (anim, color).

const SHEETS: Dictionary = {
	"cyan": "res://assets/vfx/water.png",
	"magenta": "res://assets/vfx/purple.png",
	"gold": "res://assets/vfx/fire.png",
	"green": "res://assets/vfx/green.png",
}

## BDragon1727 cells, 16x16 each, (column, row).
const ANIMS: Dictionary = {
	"slash": {"cells": [Vector2i(10, 3), Vector2i(11, 3), Vector2i(12, 3)], "fps": 26.0, "loop": false},
	"spark": {"cells": [Vector2i(10, 5), Vector2i(11, 5), Vector2i(12, 5)], "fps": 22.0, "loop": false},
	"ring": {"cells": [Vector2i(14, 5), Vector2i(15, 5), Vector2i(16, 5), Vector2i(17, 5)], "fps": 22.0, "loop": false},
	"ring2": {"cells": [Vector2i(14, 6), Vector2i(15, 6), Vector2i(16, 6), Vector2i(17, 6)], "fps": 18.0, "loop": false},
	"puff": {"cells": [Vector2i(10, 1), Vector2i(11, 1), Vector2i(12, 1)], "fps": 16.0, "loop": false},
	"star": {"cells": [Vector2i(7, 4), Vector2i(8, 4)], "fps": 16.0, "loop": false},
	"bullet": {"cells": [Vector2i(24, 0), Vector2i(25, 0), Vector2i(26, 0), Vector2i(27, 0)], "fps": 14.0, "loop": true},
	"orb": {"cells": [Vector2i(14, 7), Vector2i(15, 7), Vector2i(16, 7), Vector2i(15, 7)], "fps": 12.0, "loop": true},
	"heavy": {"cells": [Vector2i(19, 9), Vector2i(20, 9), Vector2i(21, 9), Vector2i(22, 9)], "fps": 12.0, "loop": true},
	"core": {"cells": [Vector2i(30, 5), Vector2i(31, 5), Vector2i(32, 5), Vector2i(33, 5), Vector2i(34, 5)], "fps": 12.0, "loop": true},
	"shard": {"cells": [Vector2i(24, 1), Vector2i(25, 1), Vector2i(26, 1), Vector2i(27, 1)], "fps": 18.0, "loop": true},
	"burst": {"cells": [Vector2i(30, 0), Vector2i(31, 0), Vector2i(32, 0), Vector2i(33, 0), Vector2i(34, 0), Vector2i(35, 0)], "fps": 18.0, "loop": false},
	"debris": {"cells": [Vector2i(30, 10), Vector2i(31, 10), Vector2i(32, 10), Vector2i(33, 10), Vector2i(34, 10), Vector2i(35, 10)], "fps": 16.0, "loop": false},
	"zring": {"cells": [Vector2i(28, 8), Vector2i(27, 8), Vector2i(26, 8), Vector2i(25, 8), Vector2i(24, 8)], "fps": 9.0, "loop": true},
	"pickup": {"cells": [Vector2i(30, 3), Vector2i(31, 3), Vector2i(32, 3), Vector2i(33, 3), Vector2i(34, 3)], "fps": 10.0, "loop": true},
	"rain_splash": {"cells": [Vector2i(30, 6), Vector2i(31, 6), Vector2i(32, 6)], "fps": 18.0, "loop": false},
}

## Warped City strips: folder, frame count, fps, loop.
const STRIPS: Dictionary = {
	"explosion": {"path": "res://assets/warped_city/misc/enemy-explosion/enemy-explosion-%d.png", "count": 6, "fps": 16.0, "loop": false},
	"drone": {"path": "res://assets/warped_city/misc/drone/drone-%d.png", "count": 4, "fps": 10.0, "loop": true},
	"turret": {"path": "res://assets/warped_city/misc/turret/turret-%d.png", "count": 6, "fps": 10.0, "loop": true},
	"shot": {"path": "res://assets/warped_city/misc/shot/shot-%d.png", "count": 3, "fps": 14.0, "loop": true},
	"shot_hit": {"path": "res://assets/warped_city/misc/shot-hit/shot-hit-%d.png", "count": 3, "fps": 18.0, "loop": false},
}

static var _cache: Dictionary = {}


static func frames(anim: String, color: String = "cyan") -> SpriteFrames:
	var key: String = anim + ":" + color
	if _cache.has(key):
		return _cache[key]
	var sf := SpriteFrames.new()
	if STRIPS.has(anim):
		var strip: Dictionary = STRIPS[anim]
		sf.set_animation_speed("default", strip["fps"])
		sf.set_animation_loop("default", strip["loop"])
		for i: int in int(strip["count"]):
			var tex: Texture2D = load(String(strip["path"]) % (i + 1))
			sf.add_frame("default", tex)
	else:
		var def: Dictionary = ANIMS[anim]
		var sheet: Texture2D = load(SHEETS.get(color, SHEETS["cyan"]))
		sf.set_animation_speed("default", def["fps"])
		sf.set_animation_loop("default", def["loop"])
		for cell: Vector2i in def["cells"]:
			var at := AtlasTexture.new()
			at.atlas = sheet
			at.region = Rect2(cell.x * 16, cell.y * 16, 16, 16)
			sf.add_frame("default", at)
	_cache[key] = sf
	return sf


static func strip_frames(paths: Array, fps: float, loop: bool) -> SpriteFrames:
	var key: String = "strip:" + str(paths[0]) + str(paths.size())
	if _cache.has(key):
		return _cache[key]
	var sf := SpriteFrames.new()
	sf.set_animation_speed("default", fps)
	sf.set_animation_loop("default", loop)
	for p: String in paths:
		sf.add_frame("default", load(p))
	_cache[key] = sf
	return sf


static func sprite(anim: String, color: String = "cyan") -> AnimatedSprite2D:
	var s := AnimatedSprite2D.new()
	s.sprite_frames = frames(anim, color)
	s.play("default")
	return s


static func spawn(parent: Node, anim: String, color: String, pos: Vector2, rot: float = 0.0,
		scl: float = 1.0, tint: Color = Color.WHITE, z: int = 20) -> AnimatedSprite2D:
	if parent == null or not is_instance_valid(parent):
		return null
	var s := sprite(anim, color)
	s.global_position = pos
	s.rotation = rot
	s.scale = Vector2(scl, scl)
	s.modulate = tint
	s.z_index = z
	s.animation_finished.connect(s.queue_free)
	parent.add_child(s)
	s.global_position = pos
	return s
