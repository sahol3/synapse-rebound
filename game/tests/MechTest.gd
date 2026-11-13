extends Node
## Headless end-to-end mechanics test. Drives the real input actions with an auto-parry bot.
## Run: tools\bin\godot.cmd --headless --path game res://tests/MechTest.tscn
## Prints PASS/FAIL per check and "MECHTEST passed=N failed=M"; exit code 1 on any failure.

var main: Node
var passed: int = 0
var failed: int = 0
var bot_on: bool = false
var bot_target: Node2D
var _release_next: bool = false


func _ready() -> void:
	## These checks pin the fixed mechanics, so the adaptive director is off and never saves.
	Director.enabled = false
	Director.persist = false
	main = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	_run.call_deferred()


func _physics_process(_delta: float) -> void:
	if _release_next:
		_unact("parry")
		_release_next = false
	var p: Player = _p()
	if not bot_on or p == null or p.dead:
		return
	for node: Node in get_tree().get_nodes_in_group("projectiles"):
		var pr: Projectile = node as Projectile
		if pr == null or pr.team != Projectile.Team.ENEMY or pr.lane != p.lane:
			continue
		if pr.global_position.distance_to(p.chest()) < 38.0 and p.parry_ready() >= 1.0:
			var aim := Vector2.RIGHT
			if bot_target != null and is_instance_valid(bot_target):
				aim = bot_target.global_position - p.chest()
			p.aim_override = aim
			_act("parry")
			_release_next = true
			return


func _act(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)


func _unact(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = false
	Input.parse_input_event(ev)


func _p() -> Player:
	if main == null:
		return null
	var pl: Variant = main.get("player")
	return pl as Player if pl != null and is_instance_valid(pl) else null


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec, true, false, true).timeout


func _check(name: String, ok: bool, detail: String = "") -> void:
	if ok:
		passed += 1
		print("PASS  ", name, "  ", detail)
	else:
		failed += 1
		print("FAIL  ", name, "  ", detail)


func _shoot_at_player(dx: float, speed: float = 150.0) -> Projectile:
	var p: Player = _p()
	var from: Vector2 = p.chest() + Vector2(dx, 0)
	var pr := Projectile.make(from, Vector2(-signf(dx) * speed, 0), Projectile.Team.ENEMY, p.lane)
	StageBase.spawn(pr)
	return pr


func _freeze_enemies() -> void:
	for e: Node in get_tree().get_nodes_in_group("enemies"):
		if e is EnemyBase:
			(e as EnemyBase).active = false
			if (e as EnemyBase).kind == EnemyBase.Kind.SNIPER:
				(e as EnemyBase).set_physics_process(false)


func _run() -> void:
	await _wait(0.3)
	main._begin_run(1)
	await _wait(1.6)
	_freeze_enemies()
	var p: Player = _p()
	_check("stage1 loaded", main.stage != null and main.stage.stage_index == 1)
	_check("player landed", p != null and p.is_on_floor(), "pos=%s" % str(p.global_position if p else Vector2.ZERO))

	# T1: basic deflect
	bot_on = true
	bot_target = null
	var shot: Projectile = _shoot_at_player(80.0)
	await _wait(1.0)
	_check("T1 deflect turns shot to player team", is_instance_valid(shot) == false or shot.team == Projectile.Team.PLAYER, "parries=%d" % GameState.parries)
	_check("T1 parry counted + sync gained", GameState.parries >= 1 and GameState.sync_rate >= 10.0, "sync=%.1f" % GameState.sync_rate)

	# T2: Enforcer rally -> railgun -> kill
	var feet: Vector2 = p.global_position + Vector2(130, Player.FEET_Y)
	var enf := EnemyBase.create(EnemyBase.Kind.ENFORCER, feet - Vector2(0, 20), 0, {"interval": 1.0})
	main.stage.enemies_node.add_child(enf)
	bot_target = enf
	var t: float = 0.0
	while t < 12.0 and is_instance_valid(enf) and enf.alive:
		await _wait(0.25)
		t += 0.25
	_check("T2 enforcer killed by rally", not is_instance_valid(enf) or not enf.alive, "t=%.2fs best_rally=%d" % [t, GameState.best_rally])
	_check("T2 rally reached railgun (bounce>=3)", GameState.best_rally >= 3, "best_rally=%d" % GameState.best_rally)

	# T3: blackout -> rebound
	bot_on = false
	## Bystanders for the rebound shockwave: a walker and a turret to the player's left.
	var walker := EnemyBase.create(EnemyBase.Kind.ENFORCER, p.global_position + Vector2(-70, 0), 0, {"patrol": 30.0})
	walker.active = false
	main.stage.enemies_node.add_child(walker)
	var bolted := EnemyBase.create(EnemyBase.Kind.TURRET, p.global_position + Vector2(-115, Player.FEET_Y), 0, {})
	bolted.active = false
	main.stage.enemies_node.add_child(bolted)
	var walker_at: Vector2 = walker.position
	var bolted_at: Vector2 = bolted.position
	await _wait(1.2)
	_shoot_at_player(60.0)
	await _wait(0.35)
	_check("T3 lethal hit enters Blackout", p.in_blackout, "time_scale=%.2f" % Engine.time_scale)
	_check("T3 world slowed to 0.25", is_equal_approx(JuiceManager.base_time_scale, 0.25))
	bot_on = true
	bot_target = null
	## Fast enough to catch the player, who is still sliding away from the first hit. (Until 2026-11-13
	## this check passed by deflecting the shot that had already hit; that is no longer possible.)
	_shoot_at_player(50.0, 600.0)
	await _wait(0.9)
	_check("T3 deflect during Blackout = Rebound", not p.in_blackout and GameState.rebounds == 1, "rebounds=%d" % GameState.rebounds)
	_check("T3 time restored", is_equal_approx(JuiceManager.base_time_scale, 1.0))
	await _wait(0.6)
	_check("T3 the rebound shockwave leaves a walker on its platform and a turret where it was",
			is_instance_valid(walker) and is_instance_valid(bolted) and absf(walker.position.y - walker_at.y) < 0.5
			and absf(walker.position.x - walker_at.x) <= 30.5 and bolted.position.distance_to(bolted_at) < 0.5,
			"walker moved %s, turret moved %s" % [str(walker.position - walker_at), str(bolted.position - bolted_at)])
	walker.queue_free()
	bolted.queue_free()

	# T4: blackout -> second hit -> death -> VHS rewind
	bot_on = false
	await _wait(1.3)
	var deaths_before: int = GameState.loop_deaths
	_shoot_at_player(50.0)
	await _wait(0.3)
	_shoot_at_player(-40.0, 200.0)
	_shoot_at_player(40.0, 200.0)
	await _wait(2.4)
	_check("T4 death registered", GameState.loop_deaths == deaths_before + 1, "loops=%d" % GameState.loop_deaths)
	_check("T4 player respawned alive", not p.dead and not p.in_blackout)

	# T5: module carrier -> pickup -> Overclock choice -> stage 2
	var carrier: EnemyBase = null
	for e: Node in get_tree().get_nodes_in_group("enemies"):
		if e is EnemyBase and (e as EnemyBase).carries_module:
			carrier = e
	_check("T5 stage has a module carrier", carrier != null)
	if carrier:
		var cpos: Vector2 = carrier.global_position
		carrier.die()
		await _wait(0.4)
		p.global_position = cpos + Vector2(0, -6)
		p.velocity = Vector2.ZERO
		await _wait(0.6)
		_check("T5 module modal opened", main.hud._module_open)
		_act("choose_overclock")
		await get_tree().process_frame
		_unact("choose_overclock")
		await _wait(3.6)
		_check("T5 choice recorded as Overclock", GameState.choices == ["E"] and GameState.sync_floor() >= 100.0, "choices=%s floor=%.0f" % [str(GameState.choices), GameState.sync_floor()])
		_check("T5 advanced to stage 2", main.stage != null and main.stage.stage_index == 2)

	# T6: lane switch lands on the overpass
	await _wait(0.2)
	_freeze_enemies()
	await _wait(1.4)
	p = _p()
	# Refusal: at x=48 there is no overpass behind the road.
	bot_on = true
	bot_target = null
	_shoot_at_player(70.0)
	await _wait(0.3)
	_act("lane_back")
	await get_tree().physics_frame
	await get_tree().physics_frame
	_unact("lane_back")
	await _wait(0.4)
	_check("T6 lane switch refused where no depth surface exists", p.lane == 0 and not p.dead and GameState.loop_deaths == 1, "lane=%d loops=%d" % [p.lane, GameState.loop_deaths])
	p.global_position = Vector2(12 * 16, p.global_position.y)
	await _wait(0.8)
	bot_on = true
	bot_target = null
	_shoot_at_player(70.0)
	await _wait(0.3)
	_act("lane_back")
	await get_tree().physics_frame
	await get_tree().physics_frame
	_unact("lane_back")
	await _wait(0.2)
	_check("T6 W after deflect switches to BG lane", p.lane == 1 and p.collision_mask == GameState.BIT_WORLD_BG, "lane=%d" % p.lane)
	await _wait(1.4)
	_check("T6 landed on the overpass deck (alive, on floor, BG lane)", not p.dead and p.lane == 1 and p.is_on_floor(), "pos=%s" % str(p.global_position))

	# T7: boss phases + 5-bounce execution rally
	bot_on = false
	main.load_stage(4)
	await _wait(2.6)
	p = _p()
	var boss: BossGunship = main.stage.boss
	_check("T7 boss spawned in phase 1", boss != null and boss.phase == 1)
	for w: EnemyBase in boss._wings:
		if is_instance_valid(w):
			w.die()
	await _wait(1.2)
	_check("T7 wings down -> phase 2 depth retreat (BG lane)", boss.phase == 2 and boss.lane == 1)
	# Cross-plane parry: deflect one of her rail-missiles back into the hull.
	bot_on = true
	bot_target = boss
	var hp_before: int = boss.hp
	t = 0.0
	while t < 10.0 and boss.hp == hp_before:
		await _wait(0.25)
		t += 0.25
	_check("T7 cross-plane parry damages hull", boss.hp < hp_before, "hp %d -> %d in %.1fs" % [hp_before, boss.hp, t])
	while boss.phase == 2:
		boss.take_damage(3)
		await _wait(0.05)
	await _wait(1.2)
	_check("T7 15%% HP -> phase 3 execution rally", boss.phase == 3)
	var rally_before: int = GameState.best_rally
	t = 0.0
	while t < 40.0 and main._state == "play":
		await _wait(0.25)
		t += 0.25
	_check("T7 5-bounce rally shatters the gunship", main._state == "ending", "t=%.1fs best_rally=%d (was %d) loops=%d" % [t, GameState.best_rally, rally_before, GameState.loop_deaths])
	_check("T7 rally reached bounce 5", GameState.best_rally >= 5)
	await _wait(3.5)
	_check("T8 ending screen shown", main.hud._ending_open, "ending=%s" % GameState.ending_id())
	_check("T9 every recorded SFX sample loaded", AudioManager.all_samples_loaded(), "%d sample ids" % AudioManager.SAMPLES.size())

	print("MECHTEST passed=%d failed=%d" % [passed, failed])
	get_tree().quit(1 if failed > 0 else 0)
