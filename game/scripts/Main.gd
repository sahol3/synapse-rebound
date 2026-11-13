extends Node
## Scene manager: title menu -> Stages 1-4 -> ending. Owns the camera, post-processing,
## HUD, the 0.3s VHS rewind on death, the slow-motion module choice and pause.
## Debug: `-- --stage=N` on the command line skips the menu and starts at stage N.

const STAGE_SCENES: PackedStringArray = [
	"res://scenes/levels/Stage01_Alley.tscn",
	"res://scenes/levels/Stage02_Highway.tscn",
	"res://scenes/levels/Stage03_Shaft.tscn",
	"res://scenes/levels/Stage04_RooftopBoss.tscn",
]
const PLAYER_SCENE: String = "res://scenes/entities/Player.tscn"
const MENU_SCENE: String = "res://scenes/ui/MainMenu.tscn"
const HUD_SCENE: String = "res://scenes/ui/HUD.tscn"

var world: Node2D
var camera: GameCamera
var post: PostFX
var hud: HudController
var stage: StageBase
var player: Player
var menu: Node

var _state: String = "menu"
var _busy: bool = false
var _death_pending: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	world = Node2D.new()
	world.name = "World"
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	camera = GameCamera.new()
	camera.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(camera)
	post = PostFX.new()
	add_child(post)
	hud = load(HUD_SCENE).instantiate()
	add_child(hud)
	JuiceManager.post_fx = post
	hud.module_choice.connect(func(_c: String) -> void: pass)
	hud.pause_action.connect(_on_pause_action)
	hud.ending_closed.connect(show_menu)
	Director.stuck.connect(func() -> void:
		if _state == "play" and not _busy:
			var skill: String = Director.hint_skill()
			hud.system(DialogueData.SKILL_HINTS[skill] if DialogueData.SKILL_HINTS.has(skill)
					else DialogueData.STUCK_HINTS[GameState.current_stage - 1], 7.0))
	Director.assist_changed.connect(func(kind: String) -> void:
		if _state == "play":
			hud.say("assist_" + kind))
	var start_stage: int = 0
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--stage="):
			start_stage = int(arg.get_slice("=", 1))
	if start_stage > 0:
		_begin_run(start_stage)
	else:
		show_menu()


# ================================================================= menu / run

func show_menu() -> void:
	_state = "menu"
	get_tree().paused = false
	hud.set_paused_panel(false)
	hud.show_gameplay = false
	hud.boss = null
	hud.clear_dialogue()
	_clear_stage()
	JuiceManager.reset_time()
	Director.run_ended()
	menu = load(MENU_SCENE).instantiate()
	world.add_child(menu)
	menu.start_requested.connect(func() -> void: _begin_run(1))
	menu.continue_requested.connect(_continue_run)


func _begin_run(first_stage: int) -> void:
	if menu and is_instance_valid(menu):
		menu.queue_free()
		menu = null
	GameState.reset_run()
	Director.run_started()
	for i: int in first_stage - 1:
		GameState.choose_module(i + 1, "Q" if i % 2 == 0 else "E")
	GameState.timer_running = true
	AudioManager.set_menu_muffle(false)
	load_stage(first_stage)


func _continue_run() -> void:
	## Resume the saved run: same stage and checkpoint, same modules, clock and loop count.
	var d: Dictionary = GameState.saved_run()
	if d.is_empty():
		_begin_run(1)
		return
	if menu and is_instance_valid(menu):
		menu.queue_free()
		menu = null
	GameState.reset_run()
	GameState.apply_save(d)
	Director.run_started()
	GameState.timer_running = true
	AudioManager.set_menu_muffle(false)
	load_stage(int(d["stage"]), int(d.get("room", 0)))


func _clear_stage() -> void:
	if stage and is_instance_valid(stage):
		stage.queue_free()
	stage = null
	player = null


func load_stage(index: int, room: int = 0) -> void:
	_clear_stage()
	JuiceManager.reset_time()
	_busy = false
	_state = "play"
	GameState.current_stage = index
	Director.stage_loaded(index)
	stage = load(STAGE_SCENES[index - 1]).instantiate()
	world.add_child(stage)
	JuiceManager.fx_root = stage.fx
	JuiceManager.camera = camera
	player = load(PLAYER_SCENE).instantiate()
	stage.add_child(player)
	player.respawn(stage.spawn_point, stage.spawn_lane)
	player.died.connect(_on_player_died)
	player.blackout_started.connect(_on_blackout_started)
	player.blackout_ended.connect(_on_blackout_ended)
	player.deflected.connect(func(p: Projectile) -> void:
		if stage and stage.has_method("on_player_deflect"):
			stage.on_player_deflect(p))
	player.lane_switched.connect(func(l: int) -> void:
		if stage and stage.has_method("on_lane_switched"):
			stage.on_lane_switched(l))
	camera.target = player
	camera.use_fixed = false
	camera.lock_y = 7.0 * StageBase.T if stage.camera_mode == "arena" else NAN
	camera.make_current()
	camera.set_limits(Rect2(stage.bounds.position * StageBase.T, stage.bounds.size * StageBase.T))
	camera.snap_to_target()
	stage.dialogue.connect(hud.say)
	stage.module_collected.connect(_on_module_collected)
	stage.checkpoint_reached.connect(func() -> void:
		if GameState.persist:
			hud.saved_flash())
	if stage.has_signal("boss_defeated"):
		stage.connect("boss_defeated", _on_boss_defeated)
	hud.player = player
	hud.show_gameplay = true
	hud.clear_dialogue()
	hud.stage_card(index)
	AudioManager.play_music(stage.music)
	AudioManager.play_sfx("vhs_rewind")
	post.vhs(0.6)
	stage.start()
	if room > 0:
		stage.resume_at(room)
		player.respawn(stage.checkpoint_pos, stage.checkpoint_lane)
		camera.snap_to_target()
	GameState.save_run(stage.current_room)
	if stage.get("boss") != null:
		hud.boss = stage.get("boss")
	else:
		hud.boss = null


# ================================================================= death / rewind

func _on_player_died() -> void:
	if _state != "play":
		return
	if _busy:
		## A death that lands while a rewind is still running must not be dropped: the player
		## would stay dead with nothing left to bring them back (the Stage 3 freeze).
		_death_pending = true
		return
	_busy = true
	_death_pending = false
	GameState.register_death()
	Director.player_died(player.death_cause, player.global_position)
	GameState.save_run(stage.current_room)
	AudioManager.play_sfx("vhs_rewind")
	post.set_blackout(false)
	post.vhs_hold(true)
	await get_tree().create_timer(0.15, true, false, true).timeout
	if stage == null or not is_instance_valid(stage):
		_busy = false
		return
	stage.reset_room()
	player.respawn(stage.checkpoint_pos, stage.checkpoint_lane)
	camera.snap_to_target()
	GameState.set_sync(maxf(GameState.sync_floor(), GameState.sync_rate * 0.5))
	if stage.has_method("on_rewind"):
		stage.on_rewind()
	await get_tree().create_timer(0.15, true, false, true).timeout
	post.vhs_hold(false)
	post.vhs(0.15)
	hud.loop_flash(GameState.loop_deaths)
	if GameState.current_stage != 1 and GameState.once("first_death"):
		hud.say("first_death")
	_busy = false
	if _state == "play" and player != null and is_instance_valid(player) and player.dead:
		_on_player_died.call_deferred()


func _on_blackout_started() -> void:
	post.set_blackout(true)
	if GameState.once("first_blackout"):
		hud.say("first_blackout")


func _on_blackout_ended(rebounded: bool) -> void:
	post.set_blackout(false)
	if rebounded and GameState.once("first_rebound"):
		hud.say("first_rebound")


# ================================================================= module choice

func _on_module_collected(stage_index: int) -> void:
	if _state != "play":
		return
	_state = "choice"
	Director.progress("module")
	player.input_enabled = false
	JuiceManager.set_base_time_scale(0.12)
	hud.say("s%d_module" % stage_index)
	hud.open_module_choice(stage_index)
	var choice: String = await hud.module_choice
	GameState.choose_module(stage_index, choice)
	JuiceManager.set_base_time_scale(1.0)
	if choice == "E":
		JuiceManager.flash(Color(1.0, 0.0, 0.25, 0.6), 0.3)
		stage.burn_text("OVERCLOCKED // MEMORY BLOCK %02d BROKEN" % stage_index)
		AudioManager.play_sfx("echo_glitch", 0.6)
	else:
		JuiceManager.flash(Color(0.0, 0.9, 1.0, 0.5), 0.3)
		stage.burn_text("STABILIZED", 0.3)
	AudioManager.play_sfx("module")
	await get_tree().create_timer(2.4, true, false, true).timeout
	if _state != "choice":
		return
	post.vhs(0.5)
	AudioManager.play_sfx("vhs_rewind")
	load_stage(stage_index + 1)


# ================================================================= ending

func _on_boss_defeated() -> void:
	if _state != "play":
		return
	_state = "ending"
	Director.progress("boss")
	GameState.clear_save()
	player.input_enabled = false
	GameState.timer_running = false
	hud.say("s4_win")
	var id: String = GameState.ending_id()
	var e: Dictionary = DialogueData.ENDINGS[id]
	stage.burn_text(String(e["title"]).split(" // ")[0])
	await get_tree().create_timer(2.5, true, false, true).timeout
	AudioManager.stop_music(3.0)
	hud.show_gameplay = false
	hud.show_ending(id)


# ================================================================= pause / restart

func _unhandled_input(event: InputEvent) -> void:
	if _state != "play":
		return
	if event.is_action_pressed("pause"):
		_set_paused(not get_tree().paused)
	elif event.is_action_pressed("restart") and not get_tree().paused and player and not player.dead:
		player.die("restart")


func _notification(what: int) -> void:
	## Closing the window mid-run keeps the clock and stats up to the last moment.
	if what == NOTIFICATION_WM_CLOSE_REQUEST and _state == "play" and stage != null and is_instance_valid(stage):
		GameState.save_run(stage.current_room)


func _set_paused(on: bool) -> void:
	get_tree().paused = on
	hud.set_paused_panel(on)
	AudioManager.set_menu_muffle(on)


func _on_pause_action(action: String) -> void:
	match action:
		"resume":
			_set_paused(false)
		"restart":
			_set_paused(false)
			if player and not player.dead:
				player.die("restart")
		"menu":
			_set_paused(false)
			Director.quit("menu")
			if stage != null and is_instance_valid(stage):
				GameState.save_run(stage.current_room)
			show_menu()
