# Credits

## Art and audio

**Warped City** by Luis Zuno (Ansimuz), https://ansimuz.itch.io/warped-city

The player and enemy sprites, the turret and drone, explosions, the tileset, the parallax backgrounds, the animated
signs and props, and the vehicles all come from this pack. The two music tracks (`cyber_runner.ogg` and
`sci_fi_platformer02.ogg`) and the beam, explosion and hurt sounds are also included in the pack, which states:
"All assets included in this package are licensed under the Creative Commons Zero (CC0) license". The full licence is
in `assets/licenses/warped-city-public-license.pdf` at the repository root.

**Free Effect and Bullet 16x16** by BDragon1727, https://bdragon1727.itch.io/free-effect-and-bullet-16x16

The bullets, parry slashes, sparks, impact rings, Z-rings, the boss core and the module pickup use these sheets. The
author allows free use in non-commercial games and modification, and does not allow the asset to be resold or
redistributed. For that reason the sheets are not committed to this repository; the README explains how to add them.

## Sound synthesized in code

The comms beeps, rally pings, heartbeat, flatline whine, tape rewind, glitch bursts, whooshes and alarm are generated
at startup in `scripts/autoload/AudioManager.gd` from sine waves and noise. No recorded samples and no AI audio tools
were used for them.

## Text and fonts

The interface uses the system monospace font when one is available and falls back to Godot's built-in font. The game
ships no font files.

## Engine

Godot Engine 4.7.2, MIT licence, https://godotengine.org

## AI use

No AI-generated images, sprites, music or voice are used anywhere in the game. The GDScript code, the shaders and the
dialogue were written with an AI coding agent, which the event's rules allow.
