# Decisions

One entry per decision: date, decision, reason, who decided.

- 2026-11-13: Renderer GL Compatibility, 1280x720 canvas_items, Nearest filter. Reason: only renderer with web export for itch.io; pixel-art default. Decided by: setup session (change freely before the first playable).
- 2026-11-13: The game is SYNAPSE // REBOUND, built from the operator's spec `docs/DESIGN.md` (Hack Club Haven Dhaka 2026, theme "Bounce Back"). Godot track only; the Ren'Py track is not started. Decided by: operator.
- 2026-11-13: Viewport changed to 1152x648 with camera zoom 3 (384x216 world view, 16 px tiles), physics 120 ticks. Reason: the Warped City tiles and sprites are 16 px and read best at an integer 3x zoom. Decided by: build session.
- 2026-11-13: Built on Godot 4.7.2, although the spec names 4.3. Reason: 4.7.2 is the installed toolchain and the code uses only 4.x APIs that 4.3 also has (unverified on 4.3). Decided by: build session.
- 2026-11-13: BDragon1727 effect sheets are used but gitignored (no-redistribution licence); every other asset is CC0 Warped City. Decided by: build session.
- 2026-11-13: Synthesized sound is not allowed (operator). All SFX are recorded Kenney CC0 samples. The spec's itch.io packs (Hove Audio, Helton Yan, Shapeforms) could not be downloaded because itch.io returned 522/429 from this machine; they can replace Kenney samples cue by cue later. Decided by: operator, applied by build session.
