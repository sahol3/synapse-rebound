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
| 5 | Inkscape 1.4.4 not installed: Windows Installer needs 171,620 KB free on C: and only 109,488 KB was free (log `tools\_ink\admin.log`). Free ~300 MB on C:, then run `scripts\install_inkscape_portable.ps1` (MSI already downloaded) | operator, then agent | blocked on C: space |

## Entries

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
