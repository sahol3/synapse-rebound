# Haven Dhaka project ledger

Newest entry on top. Every session appends one entry before it stops: date, who (session or agent), what changed,
what was verified and how, and what is next. Facts only; anything unverified is marked "(unverified)".
Machine-wide mirror: `py ~/.claude/automation/ledger/ledger.py status haven-dhaka`.

## Open items

| # | Item | Owner | Status |
|---|---|---|---|
| 1 | Game concept, genre and scope for Haven Dhaka (`docs/DESIGN.md`) | operator | open |
| 2 | Choose track: Godot game, Ren'Py visual novel, or both | operator | open |
| 3 | `butler login` once on this machine (opens a browser; operator only) | operator | open |
| 4 | Create itch.io project page and note its `<user>/<game>` slug here | operator | open |
| 6 | Click the itch shortcut once to confirm the app starts from D: (not verifiable from Claude's tools) | operator | open |
| 7 | Uninstall Tiled from Settings > Apps (the 66 MB C: copy; the project uses `tools\tiled`) | operator | open |
| 5 | Inkscape 1.4.4 not installed: Windows Installer needs 171,620 KB free on C: and only 109,488 KB was free (log `tools\_ink\admin.log`). Free ~300 MB on C:, then run `scripts\install_inkscape_portable.ps1` (MSI already downloaded) | operator, then agent | blocked on C: space |

## Entries

### 2026-11-13 · move to D: (Claude Code, Opus 5.5)
- Operator asked for everything off C:. C: went from 1,523 MB free (start of this pass) to 2,689 MB.
- Godot 4.7.2 now runs self-contained from `tools\godot` (with `._sc_`; editor data and export templates in `tools\godot\editor_data`).
  The winget Godot was uninstalled, and `%APPDATA%\Godot` and `%LOCALAPPDATA%\Godot` were deleted.
- Uninstalled the unused winget Ren'Py 8.3.7 (302 MB) and a duplicate winget uv (32 MB); the original `~\.local\bin\uv.exe` remains.
- gdtoolkit moved from `uv tool` (C:) into the venv `tools\pyenv`, along with mcp-server-git (was uvx, C: cache). Deleted today's gdtoolkit
  wheels from the C: uv cache. The `mcp-server-git` wheel folder there stayed locked and was left (small).
- itch app (448 MB) moved to `tools\itch-app` with junctions back; shortcuts now point at the D: launcher.
  Not verified: the app did not start from inside Claude's process tree (junction access is blocked there). Check: click the itch
  shortcut once. If it fails, reinstall itch from itch.io.
- Deleted the winget download cache `%LOCALAPPDATA%\Temp\WinGet` (202 MB).
- Fixed: the machine-wide `PYTHONPATH=D:\Stuff_not_dl\Packages` broke mcp-server-git imports; `.mcp.json` and the shims now clear it.
- Turned off Godot file logging so game runs stop writing logs to AppData.
- Verified: `verify_toolchain.ps1` 21 of 22 PASS (inkscape still blocked); MCP probes `godot`, `godot-editor`, `git` all answered.
- Left on C: for the operator: `C:\Program Files\Tiled` (66 MB, needs admin to uninstall).

### 2026-11-13 · setup session (Claude Code, Opus 5.5)
- Created `D:\CLAUDE-CODE\haven-dhaka` (folder named without the space so Godot CLI and MCP paths stay unquoted).
- Installed: Godot 4.7.2 standard (winget), export templates 4.7.2, Ren'Py SDK 8.5.3 (renpy.org, `tools\renpy`),
  itch app 26.22.0 (winget), butler v15.32.0 (`tools\butler`), gdtoolkit 4.5.0 (`uv tool`), LibreSprite v1.3 portable,
  Tiled 1.12.2 portable (`tools\tiled\PFiles\Tiled\tiled.exe`). Already present: Node 25.9.0, uv, Git 2.53, FFmpeg 9.0.2,
  Audacity 3.7.7, Python 3.13. Inkscape failed (C: full, open item 5).
- C: had 0 GB free; export templates moved to `tools\export_templates` on D: with a junction from `%APPDATA%\Godot\export_templates`.
- Export presets "Web" and "Windows Desktop" added; both exports built, and `exports\windows\HavenDhaka.exe` printed "Haven Dhaka boot OK".
- `scripts\verify_toolchain.ps1`: 19 of 20 PASS (inkscape FAIL).
- Cloned and built `Coding-Solo/godot-mcp` (1209744) and `ee0pdt/Godot-MCP` (b7d08eb); copied the editor addon into `game/addons/godot_mcp`.
- Offline refs: `refs/godot-docs` (4.7 branch, 1,517 .rst files, 40 MB), `refs/gdquest-gdscript-guidelines.md`.
- Godot project `game/` boots headless and prints "Haven Dhaka boot OK"; editor import shows no script errors.
- Verified MCP: `godot` → `get_godot_version` = 4.7.2.stable.official.ed1daf0bf; `godot-editor` → `get_project_info` returned the project with a headless editor running.
- Source notes corrected: `GDQuest/GDScript-guidelines` repo does not exist (guide saved from GitBook);
  `awesome-cursorrules` has no Godot rules file, so the Godot 3→4 ban list is written into RULES.md section 4.
- Next: open items 1–4.
