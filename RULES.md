# Haven Dhaka global rules

Every agent and session working in `D:\CLAUDE-CODE\haven-dhaka` reads this file first, then `LEDGER.md`.
It names every tool, its exact version and path, and the rules that keep work identical across sessions.
If you change a tool, a path or a version, update this file and add a ledger line in the same turn.

## 1. Folder map

| Path | What lives there | In git |
|---|---|---|
| `README.md` | Public, player-facing readme for the GitHub repo | yes |
| `game/` | The Godot 4.7.2 project (`project.godot`, `scenes/`, `scripts/`, `assets/`, `addons/godot_mcp`) | yes |
| `assets/source/` | Editable source files (`.ase`, `.svg`, `.tmx`, `.aup3`) | yes |
| `assets/raw/` | Downloaded packs before import (itch.io, Kenney, OpenGameArt) | no |
| `assets/licenses/` | One `.txt` per third-party asset pack: source URL, author, license, date | yes |
| `vn/` | Ren'Py project, if the visual-novel track starts (create with the Ren'Py launcher) | yes |
| `tools/` | Every tool install: godot (self-contained), godot-mcp, ee0pdt-godot-mcp, butler, renpy, libresprite, tiled, itch-app, pyenv, `bin/` shims, `_uvcache`/`_npmcache` | no |
| `refs/` | Offline references: `godot-docs/` (4.7 branch, .rst only), `gdquest-gdscript-guidelines.md` | no (third-party copies stay local) |
| `exports/` | Build output for itch.io (`web/`, `windows/`) | no |
| `scripts/` | Install scripts, `mcp_probe.mjs`, `verify_toolchain.ps1` | yes |
| `docs/` | Design docs, story bible, decisions | yes |

## 2. Toolchain (verified 2026-11-13)

| Tool | Version | How to call it |
|---|---|---|
| Godot (standard, GDScript, no .NET) | 4.7.2.stable.official.ed1daf0bf | `tools\bin\godot.cmd` (console) · `tools\bin\godot-editor.cmd` (GUI) |
| Godot exe (real path) | 4.7.2, self-contained (`._sc_`) | `tools\godot\Godot_v4.7.2-stable_win64_console.exe` / `Godot_v4.7.2-stable_win64.exe`. Editor settings, caches and templates live in `tools\godot\editor_data\`, never in AppData |
| Godot export templates | 4.7.2.stable (35 files) | `tools\godot\editor_data\export_templates\4.7.2.stable\`, referenced by absolute path in `game/export_presets.cfg` |
| Ren'Py SDK | 8.5.3.26051504 | `tools\renpy\renpy.exe` (launcher) · lint: `tools\renpy\renpy.exe <project> lint <report.txt>` |
| itch.io butler | v15.32.0 | `tools\bin\butler.exe` |
| itch.io desktop app | 26.22.0 | Files on D: in `tools\itch-app\local` and `tools\itch-app\roaming`; `%LOCALAPPDATA%\itch` and `%APPDATA%\itch` are junctions to them. Start-menu and desktop shortcuts point at `tools\itch-app\local\itch-setup.exe` |
| gdtoolkit (gdformat, gdlint) | 4.5.0 | `tools\bin\gdlint.cmd`, `tools\bin\gdformat.cmd` (venv `tools\pyenv`; the shims clear `PYTHONPATH`) |
| Project Python venv | 3.13 base | `tools\pyenv` holds gdtoolkit + mcp-server-git. Install into it with `UV_CACHE_DIR=tools\_uvcache` so nothing lands in the C: uv cache |
| LibreSprite (pixel art) | v1.3 portable | `tools\libresprite\libresprite.exe` |
| Tiled (tilemaps) | 1.12.2 portable | `tools\tiled\...\tiled.exe` (MSI admin-extract; `scripts\install_tiled_portable.ps1`) |
| Inkscape (vector, UI) | 1.4.4, NOT YET INSTALLED (C: full, see LEDGER open item 5) | after install: `tools\inkscape\...\bin\inkscape.com` (CLI) / `inkscape.exe` (GUI); `scripts\install_inkscape_portable.ps1` |
| Audacity | 3.7.7 | Start menu |
| FFmpeg | 9.0.2 | `ffmpeg` on PATH |
| Node | 25.9.0 | `node`, `npm`, `npx` (newer than LTS; do not install NodeJS.LTS on top) |
| uv | on PATH | `C:\Users\Sahol\.local\bin\uv.exe` |
| Git | 2.53 | `git` |
| Python | 3.13 | `py` (bare `python` is the Store stub) |

Everything for this project lives on D:. Only Audacity, FFmpeg, Node, Git, uv and Python (all present before this project) sit on C:.
Never install this project's tools with winget or an MSI into C:. Use portable builds or admin extracts into `tools\`.
`scripts\install_winget.ps1` is kept only as a record of the first attempt; do not re-run it.
Check everything in one go: `powershell -ExecutionPolicy Bypass -File scripts\verify_toolchain.ps1`.

## 3. MCP servers (`.mcp.json` in this folder)

| Name | Source | What it does | Needs |
|---|---|---|---|
| `godot` | `tools/godot-mcp` (Coding-Solo, commit 1209744, built `npm run build`) | Launch editor, run project, read debug output, create scenes, add nodes, load sprites, UID updates | `GODOT_PATH` (set in `.mcp.json`) |
| `godot-editor` | `tools/ee0pdt-godot-mcp/server` (ee0pdt, commit b7d08eb, built `npm run build`) | Live editor control: create/delete nodes, edit properties, scripts, scenes, run editor scripts | The editor open on `game/` with the "Godot MCP" plugin enabled; WebSocket `ws://localhost:9080` |
| `filesystem` | `@modelcontextprotocol/server-filesystem@2.3.0` via npx | File access scoped to this folder | npm cache pinned to `tools\_npmcache` |
| `git` | `tools\pyenv\Scripts\mcp-server-git.exe` | Git operations on this repo | `PYTHONPATH` cleared in `.mcp.json` (the machine-wide value `D:\Stuff_not_dl\Packages` breaks its imports) |

Probed on 2026-11-13 after the move to D:: `godot` returned `get_godot_version` = 4.7.2, `godot-editor` returned
`get_project_info` for Haven Dhaka with a headless editor running, and `git` returned `git_status` for this repo.
Re-probe with `node scripts/mcp_probe.mjs <server.js|server.exe> <tool> '<json args>'` (`PROBE_ARGS` env passes server arguments).

Rules for MCP use:
- Scene and node changes go through `godot-editor` (or the `godot` scene tools) when the editor is running. Hand-editing
  `.tscn`/`.tres` text is allowed only for trivial edits, and never for `uid://` values.
- After moving or renaming resources, run the `godot` tool `update_project_uids` or reopen the editor so UIDs regenerate.
- `get_debug_output` after every `run_project`. An empty error list is the done-condition, not "it launched".
- The `godot_mcp` addon inside `game/addons/` is a copy of `tools/ee0pdt-godot-mcp/addons/godot_mcp`. Update both together.

## 4. GDScript rules (Godot 4.x only)

Sources: `refs/godot-docs/tutorials/scripting/gdscript/gdscript_styleguide.rst`,
`refs/godot-docs/tutorials/scripting/gdscript/static_typing.rst`, `refs/gdquest-gdscript-guidelines.md`.
Look up a class with `grep -rl "ClassName" refs/godot-docs/classes/` before guessing a method.

- Static typing everywhere: `var speed: float = 200.0`, typed parameters, typed returns (`-> void`), typed arrays
  (`Array[Enemy]`). The project raises warnings on untyped declarations and unsafe access; keep the warning count at zero.
- Godot 3 names are banned. Use the 4.x name.

| Godot 3 (banned) | Godot 4 (use) |
|---|---|
| `KinematicBody2D` / `KinematicBody` | `CharacterBody2D` / `CharacterBody3D` |
| `move_and_slide(velocity, Vector2.UP)` | set `velocity`, call `move_and_slide()` |
| `yield(obj, "signal")` | `await obj.signal` |
| `connect("pressed", self, "_on_pressed")` | `pressed.connect(_on_pressed)` |
| `emit_signal("hit", dmg)` | `hit.emit(dmg)` |
| `export var x = 1` / `onready var` | `@export var x: int = 1` / `@onready var` |
| `tool` | `@tool` |
| `Spatial`, `Position2D`, `YSort` | `Node3D`, `Marker2D`, `y_sort_enabled` on `Node2D` |
| `instance()` | `instantiate()` |
| `File`, `Directory` | `FileAccess`, `DirAccess` |
| `rand_range()` | `randf_range()` |
| `get_tree().change_scene("...")` | `get_tree().change_scene_to_file("...")` |
| `PoolStringArray` etc. | `PackedStringArray` etc. |
| `setget` | property `set(value):` / `get:` blocks |

- Naming: `snake_case` files, functions, variables; `PascalCase` classes and nodes; `CONSTANT_CASE` constants;
  signals in past tense (`health_changed`). One `class_name` per reusable script.
- Order inside a script follows the style guide: `@tool`, `class_name`, `extends`, docstring, signals, enums,
  constants, `@export`, public vars, private vars (`_prefix`), `@onready`, built-in callbacks, public methods, private methods.
- Prefer signals up, calls down. A child never reaches into its parent with `get_parent()` chains.
- Every script passes `gdlint` and `gdformat --check` before it is reported done.

## 5. Project settings that stay fixed

- Renderer: GL Compatibility (desktop and mobile). It is the only renderer that exports to the web for itch.io.
- Design size 1152x648 (art scale 3, so the world view is 384x216 with 16 px tiles). Godot's stretch is OFF; the
  `Display` autoload picks whole-number art and interface scales from the real window size (section 11). Default
  texture filter Nearest (pixel art). Physics runs at 120 ticks per second.
- Main scene `res://scenes/Main.tscn` (capital M; the old `main.tscn`/`main.gd` were removed).
- Autoloads, in this order: Display, GameState, AudioManager, JuiceManager, DialogueData, Director.
- Changing any of these is a decision: write it in `docs/DECISIONS.md` and the ledger.

## 6. Assets

- Every third-party asset gets a license file in `assets/licenses/<pack>.txt` before it is imported into `game/`.
  Allowed without asking: CC0 and CC-BY (credit goes in `docs/CREDITS.md`). Anything else (NC, ND, "personal use",
  unclear) stays in `assets/raw/` and is flagged in the ledger.
- One recorded exception, for SYNAPSE // REBOUND: the BDragon1727 "Free Effect and Bullet 16x16" sheets
  (`game/assets/vfx/*.png`) are free for non-commercial games but may not be redistributed. They are used in the
  build and are gitignored, so they never reach the public repo. A fresh clone must re-download them (see `game/README.md`).
  Never commit them and never sell a build that contains them.
- The game's credits file is `game/CREDITS.md` (it ships with the repo), not `docs/CREDITS.md`.
- Jam rule: no AI-generated images, sprites, music or voice, and no script that writes PNG or SVG files.
  Sound must be recorded samples from a downloaded asset pack: synthesizing sound in code is NOT allowed
  (operator, 2026-11-13). Raw packs go in `assets/raw/sfx/<pack>/` (gitignored); `scripts/import_sfx.py` copies
  the chosen files into `game/assets/audio/sfx/kenney/`. Trimming or pitch-shifting a recorded sample is fine.
- Free sources: kenney.nl (CC0), opengameart.org (check each), itch.io game assets (check each page),
  Google Fonts (OFL). Paid itch.io packs need the operator's purchase; never buy.
- Pixel art: LibreSprite, export PNG sheets to `game/assets/sprites/`. Keep `.ase` sources in `assets/source/`.
- Tilemaps: Tiled `.tmx`/`.tsx` sources in `assets/source/maps/`; import into Godot TileMapLayer (TileMap node is deprecated in 4.3+).
- Vector UI: Inkscape SVG in `assets/source/ui/`, export PNG at 1x and 2x.
- Audio: Audacity for edits, FFmpeg for conversion. Music and ambience `.ogg`, short SFX `.wav`.
  Normalise with `ffmpeg -i in.wav -af loudnorm=I=-16:TP=-1.5:LRA=11 out.wav`; convert with `ffmpeg -i in.wav -c:a libvorbis -q:a 5 out.ogg`.

## 7. Ren'Py track (visual novel)

- SDK `tools\renpy\` 8.5.3. Create projects from the launcher into `vn/`. Lint with
  `Start-Process tools\renpy\renpy.exe -ArgumentList 'vn\<project>','lint','lint.txt' -Wait` (PowerShell; renpy.exe is a GUI
  binary, so the report goes to the file, not stdout) and treat any lint error as a blocker.
- Ren'Py scripts are `.rpy` (Python-like). Images go in `game/images/`, audio in `game/audio/` inside the Ren'Py project.
- Distribute builds with the launcher's "Build Distributions"; the web build needs the launcher's Web download step.

## 8. Builds and itch.io

- Export presets live in `game/export_presets.cfg` (in git): "Web" (no threads, so itch.io needs no SharedArrayBuffer) and
  "Windows Desktop" (x86_64, embedded pck). Both use `custom_template/*` paths into `tools\export_templates`, and both
  exclude `addons/godot_mcp/*` so the editor-only MCP addon never ships. Credentials never go there; `export_credentials.cfg` is ignored.
  Both exports were rebuilt for SYNAPSE // REBOUND on 2026-11-13; the Windows exe exits 0 on `--headless --quit-after 240`.
- Web export: `tools\bin\godot.cmd --headless --path game --export-release "Web" ..\exports\web\index.html`.
  Windows export: `--export-release "Windows Desktop" ..\exports\windows\SynapseRebound.exe`.
  Both presets also exclude `tests/*`.
- itch.io upload with butler: `tools\bin\butler.exe push exports\web <user>/<game>:html5` and `...:windows`.
  `butler login` is done by the operator once (it opens a browser). Agents never type the itch.io password or API key.
  If `BUTLER_API_KEY` is needed it comes from an environment variable, never from a file in this repo.
- On the itch.io page, tick "This file will be played in the browser" for the html5 channel; leave "SharedArrayBuffer support" off (the Web preset has threads off).
- A push to itch.io is outward-facing: it happens only when the operator asks for it in the session.

## 9. Session protocol

1. Read `RULES.md`, then the top of `LEDGER.md`, then `git status`.
2. Run `scripts\verify_toolchain.ps1` if the last ledger entry is more than 7 days old or a tool looks missing.
3. Work. Run the project headless (`tools\bin\godot.cmd --headless --path game --quit-after 5`) and check the output
   for `SCRIPT ERROR` before reporting done.
4. Append to `LEDGER.md` (what changed, what was verified, what is next), then
   `py ~/.claude/automation/ledger/ledger.py log "haven-dhaka: <what>" -k did`.
5. Commit with a message file (PowerShell mangles `-m` strings). Stop any editor or game process you started.

## 10. Known quirks

- C: is nearly full (0 GB free on 2026-11-13, about 2.7 GB after this project's files moved to D:). Nothing from this project goes on C:.
  Downloads, templates, builds, venvs and caches stay under this folder on D:.
- Processes started from Claude's tools cannot read or launch through C:→D: junctions ("mount point ... not attached"),
  even with the sandbox off. Always call tools by their D: path, never through the itch junctions.
- Running the game (not the editor) still creates empty `%APPDATA%\Godot\app_userdata\Haven Dhaka` folders, because self-contained
  mode covers only the editor. File logging is off, so they stay empty until the game writes `user://` saves.
- The machine-wide `PYTHONPATH=D:\Stuff_not_dl\Packages` shadows packages in every venv. Clear it for any Python tool in this project.

- The Bash tool sandbox blocks loopback, so the `godot-editor` WebSocket (`localhost:9080`) is reachable only from PowerShell or the MCP client.
- `godot.cmd` is the console build: use it for `--headless`, exports and CI. The GUI build gives no stdout.
- winget has no LibreSprite package; it is the portable GitHub build in `tools\libresprite`.
- Tiled and Inkscape are admin-extracted MSIs on D:, not installed. A normal MSI install fails while C: is full (Inkscape: 1603)
  or stalls on an elevation prompt (Tiled). `msiexec /a` exits 1618 while another installer session holds the lock; the scripts retry.
- The winget copies of Godot, Ren'Py 8.3.7 and uv were uninstalled on 2026-11-13. `tools\` holds the only copies this project uses.
- A full Tiled install also landed in `C:\Program Files\Tiled` (66 MB) from the first winget attempt. Removing it needs admin
  (silent uninstall returned 1603), so it is the operator's to remove from Settings > Apps. Nothing here uses it.
- The original setup notes named `PatrickJS/awesome-cursorrules` and `GDQuest/GDScript-guidelines`. The first has no
  Godot rules file, and the second does not exist; the GDQuest guide is the GitBook page saved in `refs/`. Section 4 replaces both.

## 11. SYNAPSE // REBOUND (the game in `game/`)

- Spec: `docs/DESIGN.md` (operator's master spec and game design document). Player-facing summary: `game/README.md`.
- Scenes are generated, never hand-edited: `tools\bin\godot.cmd --headless --path game --script ..\scripts\build_scenes.gd`
  rewrites Main, ui/MainMenu, ui/HUD, entities/*, levels/Stage01..04 and tests/MechTest. Behaviour lives in scripts;
  a scene is a root node plus its script. In `--script` mode autoloads do not exist, so the builder attaches a stub
  script that `take_over_path`s the real path; the saved `.tscn` points at the real script.
- Code layout: `scripts/autoload/` (GameState: sync, tiers, modules, endings, input map registered at runtime;
  AudioManager: buses, cue map of recorded samples; JuiceManager: hit-stop, shake, flash, ghosts; DialogueData: every line),
  `scripts/entities/` (Player, Projectile, EnemyBase, BossGunship), `scripts/world/` (StageBase builds stages in code
  from `tileset.png`), `scripts/levels/`, `scripts/ui/` (HudController, PostFX shader chain, MainMenu), `shaders/`.
- Time: `Engine.time_scale` belongs to JuiceManager only (`set_base_time_scale`, `hitstop`, `reset_time`). Anything that
  must run during hit-stop or Blackout uses real time: `create_timer(t, true, false, true)` and `Tween.set_ignore_time_scale(true)`.
- Physics layers: 1 world_fg, 2 world_bg, 4 player_hurt, 8 enemy_hurt, 32 triggers. Lane 1 (background) uses layer 2.
- Test gate: `tools\bin\godot.cmd --headless --path game res://tests/MechTest.tscn` must print `MECHTEST passed=28 failed=0`
  (or more passes, never a failure) before any commit that touches gameplay. Input in tests goes through
  `Input.parse_input_event(InputEventAction)` for taps (MechTest, DirectorLive); held keys in ClimbTest use
  `Input.action_press` / `action_release` with one released physics frame between two presses.
  The first run right after an import of new assets can fail the landing check on a cold cache; run it again.
- Sound gate (any change to `AudioManager.gd` or the samples): record `res://tests/SfxProbe.tscn` with
  `--write-movie <ABS>\f.png --fixed-fps 30 --quit-after 640`, then `py -I scripts\sfx_probe_check.py <f.wav> <slots>`
  (slots = the `SFXPROBE slots=` line it prints) must end `VERDICT: N of N`.
- Display: never write 1152, 648, 576, 324 or a zoom of 3 into game code. Read `Display.art` (camera zoom),
  `Display.ui` (HUD/menu layer scale), `Display.view` (world pixels on screen), `Display.ui_size` (interface pixels) and
  connect to `Display.changed`. HUD blocks anchor to the real edges or use `_oy()` / `_ox()`; the screen shaders take
  `screen_size` and `art_px` from PostFX. Check: `powershell -File scripts\capture_sizes.ps1` then
  `py scripts\check_sizes.py sizes` (frame size, empty bars, script errors at six window sizes).
- Difficulty: every number the difficulty changes is read through `Director` (shot speed, fire interval, charge time,
  shot cap, parry window/radius/arc, Blackout length, mercy shot, aim lead, fall assist). `Director.enabled = false`
  returns the original fixed values; MechTest and ClimbTest run that way, and no test may save the profile
  (`Director.persist = false`). The nine models and what they learn from are described in `README.md`.
  Every knob reads `Director.level(lever)`, never `challenge` directly, so the room model and the lever bandit apply
  everywhere. New saved model state gets an optional key in `from_dict`; an older profile must still load.
  Blackout runs at quarter speed, so an ordinary shot cannot arrive inside the window: the mercy shot is what makes a
  rebound possible, do not remove it without replacing it.
- Enemies are plain Node2D, not physics bodies: anything that moves one (shove, knock-back) must keep walkers on
  their platform inside the patrol range and leave turrets where they are. A death signal must never be dropped:
  `Main._on_player_died` replays one that arrives during a rewind. A stage that moves `kill_y` updates it in
  `on_rewind`, in the same frame as the respawn.
- Climb rule: a plain jump is 55 px. Any step taller than 48 px needs the air-dash (Space again in mid-air), and a
  stage that needs it must say so on screen. A new or changed climb gets a bot run like `tests/ClimbTest.gd`.
- More test gates: `DirectorTest.tscn` (`DIRECTORTEST passed=63 failed=0`), `ClimbTest.tscn` (`CLIMBTEST passed=17
  failed=0`, about 90 s) and `DirectorLive.tscn` (`DIRECTORLIVE passed=8 failed=0`, about 100 s) after any change to
  the director, the player's movement or a stage layout.
- Enemy art: `EnemyBase.SKINS` holds each character's sheet layout, feet offset, hurtbox, shield and muzzle. Look at
  `res://tests/EnemyGallery.tscn` (every kind on one roof) after changing it:
  `godot --path game --windowed --resolution 1280x400 res://tests/EnemyGallery.tscn -- --shot=<ABS>.png --shot-frame=110`.
- Dev runs (headless, movie writer, `--stage=`, `--shot=`) never read or write `user://director.json` or
  `user://save.json` (`GameState.is_dev_run()`). Engine arguments such as `--resolution` are not visible to scripts in
  an exported build; do not branch on them.
- Debug start: `godot.cmd --path game -- --stage=N` skips the menu (modules for earlier stages are auto-picked).
- Visual checks without a window: `--write-movie <ABSOLUTE dir>\f.png --fixed-fps 30 --quit-after N` (a relative path
  fails silently), then read the PNGs. `scripts\capture_frames.ps1 -Tag <name>` records menu, stages 1-4 and the MechTest
  run into `tools\_frames\<name>\`; `py -I scripts\contact_sheet.py <name>` builds `sheet_shots.jpg` and `sheet_mech.jpg`.
- Icon and boot image: `game/icon.png` (256 px, a 64 px layout scaled 4x). Rebuild it with
  `godot.cmd --path game --script res://tests/IconCard.gd -- --out=<abs>\game\icon.png` (needs a window).
  It may only place existing pack art and the font; the operator asked for this composite on 2026-11-14, which
  is the one allowed case of a script saving a PNG that ships. No Godot logo anywhere a player sees: project icon,
  boot splash and exe details are ours. The Godot licence notice in `game/CREDITS.md` stays (MIT requires it).
- Lifetime progress (Lore entries, endings seen, best time, longest rally) is `GameState.meta()`, stored in
  `meta_path()`, which is derived from `save_path`. A test or dev run that redirects the save redirects it too, and
  with `persist` off nothing is read or written. Lore entries are `DialogueData.MEMORIES`; unlock with
  `GameState.unlock_memory(id)`. Engagement features must tell the player something true about their own play
  (progress, personal bests); no timers, no fake scarcity, no punishment for leaving.
- Voice: a spoken line's recording is `game/assets/audio/voice/<sara|echo>/<id>_<n>.ogg`, where `<id>_<n>` is the
  line's key in `DialogueData.LINES` (n counts from 1). Recordings come from a person; never generate a voice.
  After changing any spoken line, regenerate the sheet:
  `godot.cmd --headless --path game --script res://tests/VoiceSheet.gd -- --out=<abs>\docs\VOICE_SCRIPT.md`.
  Import takes with `py -I scripts\import_voice.py <folder>`, then run `--import`. On start the game prints
  `voice: N of M spoken lines have a recording` when N is above zero. The radio and Echo buses are built in
  `AudioManager._setup_buses`; the static bed and key click must stay pack samples.
- Endings: the after-story must play without input and must show something moving in every scene; text alone was
  rejected (operator, 2026-11-14). Its scenes use only shipped art (`scripts/world/Epilogue.gd`).
- Story lines that react to play live in `DialogueData.LINES` and are triggered from `Main.gd` (loops, rebounds,
  rallies). A reactive line only plays when `hud.comms_idle()` and once per run (`GameState.once`).
- UI type is m5x7 by Daniel Linssen (CC0), `game/assets/fonts/m5x7.ttf`, loaded by `scripts/ui/PixelFont.gd`.
  Use it only at multiples of 16 px (`PixelFont.PX`): 16 is one screen pixel per font pixel. Never draw glyphs
  in code or generate a font; a typeface is a downloaded file with its licence in `game/CREDITS.md`
  (operator, 2026-11-14). HUD and menu layers are scaled by `Display.ui` (2x and 576x324 interface pixels at the design size);
  world text uses it at 2x world pixels.
  The operator rejected boxed panels, tag blocks, bold display type and explanatory sub-labels (2026-11-13, "It looks
  more AI now") and approved the minimal pass ("much much better"); keep the HUD to outlined text and thin bars.
- Web check: launch config `synapse-web` in `D:\CLAUDE-CODE\.claude\launch.json` serves `exports/web` on port 4180.
  A hidden Browser pane throttles the page, so judge feel and frame rate in a visible browser, not from the pane.
