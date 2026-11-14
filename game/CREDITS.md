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

Every sound effect is a downloaded file made by a person. This project synthesizes nothing and no AI audio tools were used.

**Sci-Fi Sounds, Impact Sounds, Interface Sounds, Digital Audio and UI Audio** by Kenney, https://kenney.nl

The deflection clangs, rally bells, lasers, force fields, explosions, the Blackout heartbeat and engine hum, the tape
scratches of the rewind, The Echo's glitches, Saif's comms tone, footsteps, power-ups and menu sounds come from these
packs, which are released under Creative Commons Zero (CC0). The licence is in `assets/audio/sfx/kenney/License.txt`.
Two long recordings (a thruster and a computer hum) were trimmed to short clips with ffmpeg.

Two more recordings come from Freesound, both released by their uploaders under Creative Commons Zero (CC0), and are
in `assets/audio/sfx/meme/`.

- "S38-01 Man eaten by alligator; screams [Wilhelm screams]" by craigsmith, https://freesound.org/s/675810/ . Three
  one-second takes were cut from the preview file with ffmpeg (`scream_1.ogg` to `scream_3.ogg`).
- "Censor Beep" by mattskydoodle, https://freesound.org/people/mattskydoodle/sounds/195116/ , shortened to 0.32
  seconds (`censor_beep.ogg`). It is a broadcast test tone as its uploader published it.

The low thud that plays on a very fast death is a layer of three Kenney samples at a lower pitch.

## Voice

Saif's 34 lines are one recording made by the game's author for this game, cut into lines and played through a
radio filter built from Godot's audio effects. The Echo's lines have no recording yet and stay text. The static under the voice is `computerNoise_002` from the Kenney Sci-Fi Sounds pack (CC0). No voice in
the game is generated.

## Icon

`icon.png` is a layout of art that already ships with the game: the Warped City skyline, the player's sprite, one
shot sprite and the title set in m5x7. `tests/IconCard.gd` places them and captures the result. Nothing in it is
drawn by code or generated.

## Typeface

The interface typeface is m5x7 by Daniel Linssen, from https://managore.itch.io/m5x7, released under Creative
Commons Zero (CC0). The file is `assets/fonts/m5x7.ttf`, unchanged from the download.

## Editor plugin

`addons/godot_mcp` is the Godot MCP editor plugin from https://github.com/ee0pdt/Godot-MCP, used during development and
excluded from exported builds. It is MIT licensed; the licence is in `addons/godot_mcp/LICENSE`.

## Engine

Godot Engine 4.7.2, MIT licence, https://godotengine.org

## AI use

No AI-generated images, sprites, music or voice are used anywhere in the game. The GDScript code, the shaders and the
dialogue were written with an AI coding agent, which the event's rules allow.
