extends StageBase
## STAGE 4: ROOFTOP 09. The rain-drenched helipad where it started. Saif's Valkyrie Gunship.

signal boss_defeated

const K := EnemyBase.Kind

var boss: BossGunship


func _init() -> void:
	stage_index = 4
	has_lanes = true
	bottom_row = 32
	kill_y = 330.0
	bounds = Rect2i(-4, -12, 40, 26)
	spawn_point = Vector2(4 * T, 9 * T)
	music = "boss"
	camera_mode = "arena"


func build() -> void:
	wall(-4, -1, -12, 11)
	building(0, 31, 11)
	# Depth-lane floating decks + Z-rings for Phase 2.
	catwalk(2, 8, 6, 1)
	catwalk(13, 19, 5, 1)
	catwalk(24, 30, 6, 1)
	zring(10.5, 8.5)
	zring(21.5, 8.5)
	zring(5, 3.5, Vector2(0, -200))
	zring(27, 3.5, Vector2(0, -200))
	# Helipad dressing.
	prop("control-box-3", 3, 10.05)
	prop("control-box-1", 28, 10.05)
	prop("antenna", 1, 8.0)
	prop("banner-floor", 15, 10.7)
	prop("banner-floor", 17, 10.7)
	building(33, 40, 2, 1)
	building(-12, -6, 4, 1)
	_broken_glass()
	add_traffic(8, -50.0, 60.0, 90.0)


func _broken_glass() -> void:
	## Glass from where you fell at 00:00, using the effect sheet's debris frames (cyan).
	for i: int in 9:
		var s := FxLib.sprite("debris", "cyan")
		s.stop()
		s.frame = 2 + i % 3
		s.position = Vector2((28.0 + float(i) * 0.4) * T, 11.0 * T - 3.0 - float(i % 2) * 2.0)
		s.rotation = float(i) * 0.7
		s.modulate = Color(0.7, 1.0, 1.0, 0.8)
		props.add_child(s)


func start() -> void:
	dialogue.emit("s4_intro")
	boss = BossGunship.new()
	boss.arena = Rect2(5 * T, 3 * T, 22 * T, 2 * T)
	boss.position = Vector2(16 * T, -3 * T)
	boss.phase_changed.connect(_on_phase)
	boss.defeated.connect(func() -> void: boss_defeated.emit())
	enemies_node.add_child(boss)
	var tw := create_tween()
	tw.tween_property(boss, "position:y", 3.0 * T, 1.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_callback(boss.start)


func _on_phase(phase: int) -> void:
	match phase:
		2:
			dialogue.emit("s4_phase2")
		3:
			dialogue.emit("s4_phase3")


func reset_room() -> void:
	## The boss keeps its progress through rewinds (Katana ZERO style mercy); only bullets clear.
	for p: Node in projectiles_node.get_children():
		p.queue_free()
