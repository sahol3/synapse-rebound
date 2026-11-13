# SYNAPSE // REBOUND

A 2D cyberpunk action platformer made for Hack Club Haven Dhaka 2026. The theme is "Bounce Back", and the game uses it
three ways: you bounce bullets back, you bounce between depth lanes, and you bounce back from the edge of death.

You play VINCENT-09, a courier who was shot off Tower 09 at midnight. A Lazarus implant snaps you back sixty seconds
before your execution with no gun, only a kinetic wrist deflector. Two voices talk to you as you climb back to the roof:
Sara, your handler, and The Echo, a recording you left for yourself before your memory was wiped. They disagree about
who pulled the trigger.

## Play

To run from source, open the `game/` folder in Godot 4.7 (standard edition, GDScript) and press Play. The Web export
below produces the build for itch.io.

| Input | Action |
|---|---|
| A / D | Move |
| Space | Jump (hold for height) |
| Mouse | Aim |
| Left or right click | Deflect toward the cursor |
| Shift | Air-dash toward the cursor |
| W / S, middle click | Switch depth lane right after a deflection |
| Q / E | Stabilize or Overclock a recovered module |
| R | Rewind to the last checkpoint |
| Esc | Pause |

## How it plays

- **Deflection.** Every shot can be sent back at the cursor during a short parry window. A deflection in mid-air also
  recoils you away from the shot and refills your air-dash, so a good chain keeps you off the ground.
- **Ping-pong rallies.** Shielded enemies throw your deflection back. Each bounce makes the shot faster and larger and
  shifts its colour from magenta to cyan to gold. On the third bounce it turns into a crimson railgun that pierces shields.
- **Depth lanes.** Stage 2 and the boss use a foreground lane and a background lane. Snipers fire across them, and you
  can parry a sniper shot back into the depth.
- **Blackout Rebound.** A hit does not kill you. Time drops to a quarter speed for 1.5 seconds, and if you deflect any
  shot in that window you rebound with a shockwave. A second hit, or the timer running out, rewinds you 0.3 seconds
  to the start of the room.
- **Neural Sync.** Deflections raise a sync meter from 0% to 400%. Higher tiers add speed, afterimage trails, a wider
  parry arc, memory fragments burned onto the buildings, and finally Berserk Overdrive.
- **Modules.** Each of the first three stages ends with a stolen module. Stabilizing it follows Sara and gives a
  defensive upgrade. Overclocking it follows The Echo and gives an offensive one. The three choices decide which of the
  three endings you see.

## Stages

1. The Awakening Alley
2. The Dual-Highway Overpass
3. The Ascent Shaft
4. Rooftop 09, against Sara's Valkyrie gunship in three phases

## Building from source

The BDragon1727 effect sheets are not in this repository, because their licence does not allow redistribution. Download
"Free Effect and Bullet 16x16" from https://bdragon1727.itch.io/free-effect-and-bullet-16x16 and copy the four sheets
into `game/assets/vfx/` as `fire.png`, `green.png`, `purple.png` and `water.png`. Every other asset is included.

Web export (Compatibility renderer, single-threaded, so itch.io needs no SharedArrayBuffer setting):

```
godot --headless --path game --export-release "Web" ../exports/web/index.html
```

## Tests

`res://tests/MechTest.tscn` drives the real input actions with an auto-parry bot and checks deflection, the Enforcer
rally and railgun kill, Blackout and Rebound, death and rewind, the module choice, lane switching, all three boss phases
and the ending screen.

```
godot --headless --path game res://tests/MechTest.tscn
```

## Project layout

| Path | Contents |
|---|---|
| `game/scripts/autoload/` | GameState (sync, modules, stats, input map), AudioManager, JuiceManager, DialogueData |
| `game/scripts/entities/` | Player, Projectile, EnemyBase, BossGunship |
| `game/scripts/world/` | StageBase (stage builder), camera, rain, Z-rings, module pickup |
| `game/scripts/levels/` | The four stages |
| `game/scripts/ui/` | HUD, pixel font, post-processing stack, main menu, Echo world text |
| `game/shaders/` | CRT, Blackout crimson, VHS rewind, shockwave, hit flash, glitch text |
| `game/scenes/` | Scene files, generated with `scripts/build_scenes.gd` |
| `docs/` | The design document, decisions log |

Credits and licences are in [game/CREDITS.md](game/CREDITS.md).
