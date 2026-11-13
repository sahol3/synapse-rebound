# Credits

## Art and audio

**Warped City** by Luis Zuno (Ansimuz), https://ansimuz.itch.io/warped-city

The player sprites, the turret and drone, explosions, the tileset, the parallax backgrounds, the animated
signs and props, and the vehicles all come from this pack. The two music tracks (`cyber_runner.ogg` and
`sci_fi_platformer02.ogg`) and the beam, explosion and hurt sounds are also included in the pack, which states:
"All assets included in this package are licensed under the Creative Commons Zero (CC0) license". The full licence is
in `assets/licenses/warped-city-public-license.pdf` at the repository root.

**Sideview Sci-Fi - Patreon Collection** by Luis Zuno (Ansimuz),
https://opengameart.org/content/sideview-sci-fi-patreon-collection

The Enforcer (space marine), the Stage 3 Command Enforcer (bipedal unit), the Highway Heavy (mech unit), the sniper
(tank unit) and the Deflector (flying enemy) use sheets from this pack, copied unchanged into
`assets/sideview_scifi/`. OpenGameArt lists the pack as CC0, and its licence file, kept beside the sheets as
`public-license.txt`, reads: "Public domain and free to use on whatever you want, personal or commercial. Credit is
not required but appreciated."

**Free Effect and Bullet 16x16** by BDragon1727, https://bdragon1727.itch.io/free-effect-and-bullet-16x16

The bullets, parry slashes, sparks, impact rings, Z-rings, the boss core and the module pickup use these sheets. The
author allows free use in non-commercial games and modification, and does not allow the asset to be resold or
redistributed. For that reason the sheets are not committed to this repository; the README explains how to add them.

## Sound effects

Every sound effect is a recorded sample from a human-made pack. Nothing is synthesized and no AI audio tools were used.

**Sci-Fi Sounds, Impact Sounds, Interface Sounds, Digital Audio and UI Audio** by Kenney, https://kenney.nl

The deflection clangs, rally bells, lasers, force fields, explosions, the Blackout heartbeat and engine hum, the tape
scratches of the rewind, The Echo's glitches, Sara's comms tone, footsteps, power-ups and menu sounds come from these
packs, which are released under Creative Commons Zero (CC0). The licence is in `assets/audio/sfx/kenney/License.txt`.
Two long recordings (a thruster and a computer hum) were trimmed to short clips with ffmpeg.

## Typeface

The interface typeface is a 5x7 pixel font drawn for this game. Its glyphs are written out in
`scripts/ui/PixelFont.gd` and built into a font in memory when the game starts, so the game ships no font files.

## Editor plugin

`addons/godot_mcp` is the Godot MCP editor plugin from https://github.com/ee0pdt/Godot-MCP, used during development and
excluded from exported builds. It is MIT licensed; the licence is in `addons/godot_mcp/LICENSE`.

## Engine

Godot Engine 4.7.2, MIT licence, https://godotengine.org

## AI use

No AI-generated images, sprites, music or voice are used anywhere in the game. The GDScript code, the shaders and the
dialogue were written with an AI coding agent, which the event's rules allow.
