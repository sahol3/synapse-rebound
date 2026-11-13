# Haven Dhaka project ledger

Newest entry on top. Every session appends one entry before it stops: date, who (session or agent), what changed,
what was verified and how, and what is next. Facts only; anything unverified is marked "(unverified)".
Machine-wide mirror: `py ~/.claude/automation/ledger/ledger.py status haven-dhaka`.

## Open items

| # | Item | Owner | Status |
|---|---|---|---|
| 1 | Game concept and scope: SYNAPSE // REBOUND, spec in `docs/DESIGN.md` | operator | done 2026-11-13 |
| 2 | Track: Godot game (Ren'Py not started) | operator | done 2026-11-13 |
| 3 | `butler login` once on this machine (opens a browser; operator only) | operator | open |
| 4 | Create itch.io project page and note its `<user>/<game>` slug here | operator | open |
| 6 | Click the itch shortcut once to confirm the app starts from D: (not verifiable from Claude's tools) | operator | open |
| 7 | Uninstall Tiled from Settings > Apps (the 66 MB C: copy; the project uses `tools\tiled`) | operator | open |
| 8 | Hand playtest of all four stages in a visible browser and on Windows (feel, difficulty, frame rate, audio). First playtest 2026-11-13 led to the adaptive director, Stage 3 fix, saving and new enemy art; play again and press F3 to see what the director thinks | operator | open |
| 9 | Public GitHub repo: https://github.com/sahol3/synapse-rebound (created and pushed 2026-11-13 on the operator's yes) | agent | done 2026-11-13 |
| 10 | Upload `exports/web` and `exports/windows` to itch.io with butler (needs items 3 and 4) | operator, then agent | open |
| 11 | Push the 2026-11-13 playtest-fix commits to GitHub | operator says yes, then agent | open |
| 12 | Bot runs from start to exit for Stages 1, 2 and 4 (only Stage 3 has one) | agent | open |
| 13 | After the next real session, check that `user://director.json` shows `runs` above 0 and samples (`hit_n`); on 2026-11-13 it stayed untouched through one session | agent | open |
| 5 | Inkscape 1.4.4 not installed: Windows Installer needs 171,620 KB free on C: and only 109,488 KB was free (log `tools\_ink\admin.log`). Free ~300 MB on C:, then run `scripts\install_inkscape_portable.ps1` (MSI already downloaded) | operator, then agent | blocked on C: space |

## Entries

### 2026-11-13 · Director models 4 to 8 (Claude Code, Fable 5.2)
- Operator: "mind adding more prediction and modulating models so that it goes very well?"
- Added to `Director.gd`: timing model (how early the player swings, P(on time), personal deflect window up to +0.08 s,
  longer telegraph for hits taken with no swing), room model (Elo-style rating per room and for the player,
  P(clear this attempt), up to 0.18 challenge taken off in a room that beat the player before), lever bandit (UCB1 over
  timing / pace / density help, boosted for one life on a death streak, scored by whether that life went better),
  pacing wave (intensity meter, five-second release after a peak, slight pressure in a long calm), skill tracing
  (BKT per mechanic, drives every second stuck hint through `DialogueData.SKILL_HINTS`).
- Hooks: `Player._start_parry` -> `parry_pressed`, `_start_dash` and `_rebound` -> `skill_used`, `StageBase._enter_room`
  and `resume_at` -> `room_entered`. All knobs now read `Director.level(lever)`. F3 shows four more lines.
- Profile file keeps version 1: the new keys are optional, an older profile loads and starts these models fresh.
- Verified: see the test line in the commit. All of it is on simulated players and scripted bots.
- Not verified: whether the new models feel better to a person. Constants (caps, learning rates) are first guesses.

### 2026-11-13 · Second playtest round: freeze, shoved enemies, saving (Claude Code, Fable 5.2)
- Operator, playing the new Windows build: "the character sometimes just freezes, in level 3 especially", "it has no
  permanent saving options", and a screenshot of the Stage 1 Enforcer standing inside the building under the walkway
  ("characters or items go out of the total area I could even hit").
- Causes, each reproduced by a test before the fix:
  1. Freeze: `Main._on_player_died` dropped a death that arrived while a rewind was still running, so the player stayed
     dead for good. Stage 3 triggered it often: `kill_y` follows the highest point reached, and after a respawn it was
     updated one frame late, so a player who had climbed more than 230 px above the checkpoint was killed again by the
     stale line. ClimbTest F1/F2 failed with `dead=true busy=false kill_y=79 player_y=240`.
  2. Enemies out of reach: `EnemyBase.shove` moved enemies freely, and they are not physics bodies. A rebound from
     above pushed walkers into the floor and turrets off their mounts, with the module the walker carried. MechTest T3
     (new check) failed with `walker moved (-71, 4.4), turret moved (-40, 10.5)`.
  3. Saving worked (his session wrote `save.json` at 23:13: stage 1, checkpoint 3) but nothing on screen said so, and
     quitting to the title or closing the window did not save the clock and stats of the current life.
- Fixes: a death during a rewind is replayed when the rewind ends; Stage 3 moves its kill line in `on_rewind`; walkers
  slide only along their platform inside their patrol range, turrets and snipers do not move, flyers drift and return;
  "saved" shows under the sync meter at each checkpoint; quitting to the title and closing the window save; the pause
  screen says progress is saved; afterimages no longer stack on a standing player and recolour the sprite; the
  difficulty profile is also written every 20 s of play and at each stage start.
- Verified: see the test line below. The exported exe wrote a save file and a profile file on a real run
  (`-- --save-file=` / `--profile-file=` dev arguments).
- Open question: during his 23:11 session `director.json` was not rewritten although `save.json` was. A plain launch of
  the same exe at 23:14 did rewrite it. Not explained. The timed save and the exe check narrow it; item 13 tracks it.
- Not verified: feel. No person has played the build with these fixes.

### 2026-11-13 · Playtest fixes: adaptive difficulty, any window size, Stage 3, saving, enemy art (Claude Code, Fable 5.2)
- Operator played the build: could not clear Stage 1 at first, then could not pass Stage 3 "in any way"; "some mechanics
  are not clear enough and sometimes don't act as they should"; the game "does not adapt to different screen sizes and
  aspect ratios"; "there is no progress saving"; "the villains are all the same, go for a similar pack". He asked for
  two or three lightweight prediction models that make the game easier or harder per player and keep people from quitting.
- Found by reading and testing, not known before:
  1. Stage 3 could not be climbed with the keyboard. Steps are 64 to 80 px, a jump is 55 px, so each of the 25 platforms
     needed a dash aimed above the head with the mouse, and a 230 px fall kills. `ClimbTest` C0 (plain jumps) never
     leaves the floor. MechTest never climbed; it teleports.
  2. Blackout was survivable by luck only. It runs at quarter speed, so in the 1.5 s window a 140 px/s shot travels
     about 52 px. Rebounds in play and in MechTest T3 came from a bug: the shot that had just hit stayed deflectable for
     0.05 s of game time (0.2 s real).
  3. In a window, a click outside the game took focus away and every key stopped working.
  4. The parry recharge ran four times slower during Blackout (it used game time).
  5. Enforcer and Heavy were the player's own sprite with a tint; the firing pose showed for one tick.
- Built:
  - `scripts/autoload/Director.gd`: hit model and quit model (online logistic regression), move model (n-gram, 3 steps,
    back-off), one `challenge` value 0..1 that every difficulty knob reads; new players start at 0.25; profile in
    `user://director.json`; F3 shows the numbers; the pause screen shows the level. Mercy shot in Blackout (homing, all
    levels), fall assist after two fall deaths, stage hint again when stuck.
  - `scripts/autoload/Display.gd`: Godot stretch off; whole-number art and interface scales from the real window; HUD,
    menu, camera limits, parallax, rain and the three screen shaders follow it; F11 fullscreen; desktop opens maximized.
  - Space again in mid-air = upward dash steered by A/D. Spent shots are not deflectable. Parry recharge on real time in
    Blackout, parry input buffer 0.10 -> 0.14 s. Mouse confined to the window while playing (desktop).
  - Save and Continue: `user://save.json` (stage, checkpoint, modules, clock, loops, stats), written at stage start,
    checkpoint and death, cleared at the ending.
  - Enemy characters from "Sideview Sci-Fi - Patreon Collection" by Ansimuz (CC0, OpenGameArt, 2.47 MB zip in
    `assets/raw/sideview_scifi`, 14 sheets copied unchanged by `scripts/import_sprites.py`): marine = Enforcer, bipedal
    unit = Stage 3 Command Enforcer, mech = Heavy, tank = sniper, flying enemy = Deflector.
- Verified (final runs, 23:00): MECHTEST 27/27 (director off; T3 now uses a shot fast enough to be a real rebound),
  DIRECTORTEST 27/27 (three simulated players, save file logic, 1,317 window sizes), CLIMBTEST 9/9 (Continue resumes
  at the checkpoint; keyboard-only climb of Stage 3 in two timings, 26 jumps and 26 air-dashes, 0 deaths; the
  plain-jump control never leaves the floor), DIRECTORLIVE 7/7 (weak bot: challenge 0.25 -> 0.00, 6 mercy shots, 6
  rebounds, 0 deaths; strong bot: 0.25 -> 0.93, 0 deaths). `check_sizes.py sizes2`: 18 of 18 screenshots from a real
  window at 1152x648, 1366x768, 1600x900, 1024x768, 960x540 and 1800x720 have the asked size, no empty bar and no
  script error; the bar check fails on a letterboxed control frame. Enemy gallery frame read: all seven kinds stand
  on the roof with their own art. Exports rebuilt (Web 22:59, Windows 23:00); the exported exe took Stage 2 and
  Stage 3 screenshots at 1600x900 and 1366x768 and ran headless with no script error; the web build booted in the
  Browser pane at 1280x800 with a 1280x800 canvas and no console error.
- Two test tools were wrong and are fixed: the movie writer records 1152x648 whatever `--resolution` says, so the
  first size captures proved nothing (check_sizes caught it, 15 of 18 SIZE-WRONG); engine arguments are not visible
  to scripts in an exported build, so dev runs are now detected by feature tag and user arguments.
- Not verified: how any of it feels to a person. The three models have met simulated players and two bots only; no
  recorded human play exists. Stages 1, 2 and 4 have no start-to-exit bot run (only Stage 3 has). The web build was not
  opened in a browser after these changes. Fullscreen on a second monitor and windows larger than this screen were not
  captured.
- Next: operator plays again (item 8) and says where it still feels unfair; F3 shows what the director thinks.
  Then commit and push on his yes, and itch.io (items 3, 4, 10).

### 2026-11-13 · Recorded SFX replace synthesized sound (Claude Code, Opus 5.5)
- Operator: synthesized sound is not allowed; SFX must come from downloaded asset packs. The first build synthesized
  18 cues and RULES/CREDITS wrongly said that was allowed. Corrected in RULES section 6, CREDITS, the menu credits,
  DECISIONS and memory `feedback_no_synthesized_audio`.
- The spec's itch.io packs (Hove Audio, Helton Yan, Shapeforms) could not be fetched: itch.io answered 522 (main
  site, Ansimuz page) and 429 (BDragon page) from this machine, in curl and in the browser pane. Used Kenney CC0 packs
  instead (Sci-Fi Sounds, named in the spec, plus Impact Sounds, Interface Sounds, Digital Audio, UI Audio).
  Raw packs in `assets/raw/sfx/kenney_*` (gitignored); `scripts/import_sfx.py` copies 103 samples and trims 3 into
  `game/assets/audio/sfx/kenney/` with the CC0 licence file.
- `AudioManager.gd`: all synthesis removed; cues are layers of recorded samples with random variants and real-time
  delays (heartbeat = two recorded thumps 0.2 s apart; Blackout bed = looped engine hum).
- Verified: `tests/SfxProbe.tscn` recorded with the movie writer and measured by `scripts/sfx_probe_check.py`:
  24 of 24 slots as expected (every cue audible, silent control at -120 dBFS, no clipping); MechTest 27/27 with the
  new T9 "every recorded SFX sample loaded". Web export rebuilt.
- Not verified: how the new sounds feel in play. Windows export waits until the running SynapseRebound.exe closes.
- Next: swap Hove/Helton Yan samples in per cue when itch.io is reachable, if the operator wants the spec's packs.

### 2026-11-13 · UI de-AI pass (Claude Code, Opus 5.5), approved
- Operator: "many things look and feel ai". Pass 1 (pixel font at 3x, boxed panels, tag blocks, bold display type,
  landing-page menu) was rejected mid-turn: "It looks more AI now". Logged in the design-orchestrator taste ledger.
- Pass 2 (current files): `scripts/ui/PixelFont.gd` hand-drawn 5x7 bitmap face built in memory; HUD and menu at 2x with
  outlined text and no panels; clock, loops and modules moved to the pause screen; 4-segment sync bar; one boss bar
  with a segment per hit point; one comms channel so Sara and The Echo never overlap; hints wait for the stage name;
  tutorial hints in sentence case; Echo's burned text plays " // " segments as one-line beats; CRT pass samples nearest,
  scanlines on the 3 px grid, no constant colour split or edge glow; VHS and Blackout shaders move in whole art pixels;
  Z-rings cyan at 2x with a hard blink; pickup sprite at 2x.
- Verified: MechTest 26/26 after each step; rendered frames in `tools/_frames/after4` and
  `tools/_frames/compare_before_after4.jpg`; fx frames for VHS and Blackout show no shader errors; Web and Windows
  re-exported, exe exits 0 headless.
- Not verified: feel in a visible window; the web build in a browser after this pass.
- Verdict on pass 2: "THIS CURRENT VERSION IS MUCH MUCH BETTER AND NICE". Committed. Keep this direction.

### 2026-11-13 · SYNAPSE // REBOUND build (Claude Code, Opus 5.5)
- Built the game from the operator's spec (now `docs/DESIGN.md`) with the Warped City assets: four stages (Alley, Highway
  with two depth lanes, vertical Shaft, Rooftop boss), 360 degree deflection with hit-stop, air recoil and dash refill,
  ping-pong rallies (x1.32 speed, x1.15 scale, rail on the third bounce), Z-lane switching, wall-slam, 1.5 s Blackout
  Rebound, 0.3 s VHS rewind on death, Neural Sync 0 to 400% with tiers, three Q/E module choices, a three-phase gunship
  boss and three endings. Sara and Echo dialogue, shader stack (CRT, Blackout, VHS, shockwave, hit flash, glitch text),
  and runtime-synthesized SFX.
- Verified: `MECHTEST passed=26 failed=0` (headless, real input actions); all four stages load headless with no SCRIPT
  ERROR; movie-writer frames of menu, every stage, parry, rally, Blackout and rewind were inspected; Web export served
  locally booted on WebGL 2 with no console errors, and the title screen and Stage 1 rendered and took input.
- Not verified: game feel, difficulty and frame rate in a visible browser or on Windows (the Browser pane was hidden and
  throttled); the Windows exe was exported but not launched; runs on Godot 4.3 (spec version) untested.
- Licence: BDragon1727 sheets gitignored (no redistribution). README and CREDITS written for the public repo.
- Next: operator playtest (item 8), then GitHub repo (item 9) and itch.io upload (item 10) on the operator's go-ahead.

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
