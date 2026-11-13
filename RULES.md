# Haven Dhaka global rules

Every agent and session working in `D:\CLAUDE-CODE\haven-dhaka` reads this file first, then `LEDGER.md`.
It names every tool, its exact version and path, and the rules that keep work identical across sessions.
If you change a tool, a path or a version, update this file and add a ledger line in the same turn.

## 1. Folder map

| Path | What lives there | In git |
|---|---|---|
| `game/` | The Godot 4.7.2 project (`project.godot`, `scenes/`, `scripts/`, `assets/`, `addons/godot_mcp`) | yes |
| `assets/source/` | Editable source files (`.ase`, `.svg`, `.tmx`, `.aup3`) | yes |
| `assets/raw/` | Downloaded packs before import (itch.io, Kenney, OpenGameArt) | no |
| `assets/licenses/` | One `.txt` per third-party asset pack: source URL, author, license, date | yes |
| `vn/` | Ren'Py project, if the visual-novel track starts (create with the Ren'Py launcher) | yes |
| `tools/` | Local tool installs: godot-mcp, ee0pdt-godot-mcp, butler, libresprite, renpy, `bin/` shims | no |
| `refs/` | Offline references: `godot-docs/` (4.7 branch, .rst only), `gdquest-gdscript-guidelines.md` | docs no, guide yes |
| `exports/` | Build output for itch.io (`web/`, `windows/`) | no |
| `scripts/` | Install scripts, `mcp_probe.mjs`, `verify_toolchain.ps1` | yes |
| `docs/` | Design docs, story bible, decisions | yes |

## 2. Toolchain (verified 2026-11-13)

| Tool | Version | How to call it |
|---|---|---|
| Godot (standard, GDScript, no .NET) | 4.7.2.stable.official.ed1daf0bf | `tools\bin\godot.cmd` (console) · `tools\bin\godot-editor.cmd` (GUI) |
| Godot exe (real path) | 4.7.2 | `C:\Users\Sahol\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe` |
| Godot export templates | 4.7.2.stable (35 files) | `tools\export_templates\4.7.2.stable\` on D:, referenced by path in `game/export_presets.cfg`; `%APPDATA%\Godot\export_templates` is a junction to it |
| Ren'Py SDK | 8.5.3.26051504 | `tools\renpy\renpy.exe` (launcher) · lint: `tools\renpy\renpy.exe <project> lint <report.txt>` |
| itch.io butler | v15.32.0 | `tools\bin\butler.exe` |
| itch.io desktop app | 26.22.0 | Start menu "itch" |
| gdtoolkit (gdformat, gdlint) | 4.5.0 | `gdformat`, `gdlint` on PATH (installed with `uv tool`) |
| LibreSprite (pixel art) | v1.3 portable | `tools\libresprite\libresprite.exe` |
| Tiled (tilemaps) | 1.12.2 portable | `tools\tiled\...\tiled.exe` (MSI admin-extract; `scripts\install_tiled_portable.ps1`) |
| Inkscape (vector, UI) | 1.4.4 portable | `tools\inkscape\...\bin\inkscape.com` (CLI) / `inkscape.exe` (GUI); `scripts\install_inkscape_portable.ps1` |
| Audacity | 3.7.7 | Start menu |
| FFmpeg | 9.0.2 | `ffmpeg` on PATH |
| Node | 25.9.0 | `node`, `npm`, `npx` (newer than LTS; do not install NodeJS.LTS on top) |
| uv | on PATH | `C:\Users\Sahol\.local\bin\uv.exe` |
| Git | 2.53 | `git` |
| Python | 3.13 | `py` (bare `python` is the Store stub) |

Re-install from scratch: `scripts\install_winget.ps1`, then `scripts\install_export_templates.sh`, then rebuild the MCP servers (section 3).
Check everything in one go: `powershell -ExecutionPolicy Bypass -File scripts\verify_toolchain.ps1`.

## 3. MCP servers (`.mcp.json` in this folder)

| Name | Source | What it does | Needs |
|---|---|---|---|
| `godot` | `tools/godot-mcp` (Coding-Solo, commit 1209744, built `npm run build`) | Launch editor, run project, read debug output, create scenes, add nodes, load sprites, UID updates | `GODOT_PATH` (set in `.mcp.json`) |
| `godot-editor` | `tools/ee0pdt-godot-mcp/server` (ee0pdt, commit b7d08eb, built `npm run build`) | Live editor control: create/delete nodes, edit properties, scripts, scenes, run editor scripts | The editor open on `game/` with the "Godot MCP" plugin enabled; WebSocket `ws://localhost:9080` |
| `filesystem` | `@modelcontextprotocol/server-filesystem@2.3.0` via npx | File access scoped to this folder | none |
| `git` | `mcp-server-git` via uvx | Git operations on this repo | none |

Both Godot servers were probed on 2026-11-13: `godot` returned `get_godot_version` = 4.7.2, and `godot-editor`
returned `get_project_info` for Haven Dhaka with a headless editor running. Re-probe with
`node scripts/mcp_probe.mjs <server.js> <tool> '{}'`.

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
- Base viewport 1280x720, stretch mode `canvas_items`, default texture filter Nearest (pixel art).
- Main scene `res://scenes/main.tscn`.
- Changing any of these is a decision: write it in `docs/DECISIONS.md` and the ledger.

## 6. Assets

- Every third-party asset gets a license file in `assets/licenses/<pack>.txt` before it is imported into `game/`.
  Allowed without asking: CC0 and CC-BY (credit goes in `docs/CREDITS.md`). Anything else (NC, ND, "personal use",
  unclear) stays in `assets/raw/` and is flagged in the ledger.
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
  Both exports were built and the Windows exe printed "Haven Dhaka boot OK" on 2026-11-13.
- Web export: `tools\bin\godot.cmd --headless --path game --export-release "Web" ..\exports\web\index.html`.
  Windows export: `--export-release "Windows Desktop" ..\exports\windows\HavenDhaka.exe`.
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

- C: is full (0 GB free on 2026-11-13). Nothing large goes on C:. Downloads, templates, builds and caches stay under this folder on D:.
- Agent shells cannot read through the `%APPDATA%\Godot\export_templates` junction (sandbox error "mount point ... not attached").
  Godot itself does not need it, because the presets use absolute D: paths.

- The Bash tool sandbox blocks loopback, so the `godot-editor` WebSocket (`localhost:9080`) is reachable only from PowerShell or the MCP client.
- `godot.cmd` is the console build: use it for `--headless`, exports and CI. The GUI build gives no stdout.
- winget has no LibreSprite package; it is the portable GitHub build in `tools\libresprite`.
- Tiled and Inkscape are admin-extracted MSIs on D:, not installed. A normal MSI install fails while C: is full (Inkscape: 1603)
  or stalls on an elevation prompt (Tiled). `msiexec /a` exits 1618 while another installer session holds the lock; the scripts retry.
- winget's Ren'Py is 8.3.7 (old). The project uses `tools\renpy` 8.5.3; ignore any other copy.
- The original setup notes named `PatrickJS/awesome-cursorrules` and `GDQuest/GDScript-guidelines`. The first has no
  Godot rules file, and the second does not exist; the GDQuest guide is the GitBook page saved in `refs/`. Section 4 replaces both.
