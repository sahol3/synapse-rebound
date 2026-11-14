# SYNAPSE // REBOUND

A 2D cyberpunk action platformer made for Hack Club Haven Dhaka 2026. The theme is "Bounce Back", and each of the
four stages is built on one meaning of it: you bounce bullets back, you bounce between depth lanes, you bounce back up
the tower you fell from, and on the roof you bounce back from the fall itself.

You play VINCENT-09, a courier who was shot off Tower 09 at midnight. A Lazarus implant snaps you back sixty seconds
before your execution with no gun, only a kinetic wrist deflector. Two voices talk to you as you climb back to the roof:
Sara, your handler, and The Echo, a recording you left for yourself before your memory was wiped. They disagree about
who pulled the trigger.

## Story and theme

The story is told while you play. Each stage card names the meaning of Bounce Back that the stage is built on. Every
death is a Lazarus rewind in the fiction, shown as a loop count, and Sara and The Echo keep count with you: they speak
at the third, fifth, eighth and twelfth loop, and what Sara says changes once she has dropped the handler act in
Stage 3. Coming back from Blackout flashes BOUNCED BACK, and The Echo marks the first, third and seventh time and your
first three-bounce rally. The ending screen counts the shots you sent back and the times you got up.

## Play

To run from source, open the `game/` folder in Godot 4.7 (standard edition, GDScript) and press Play. The Web export
below produces the build for itch.io.

| Input | Action |
|---|---|
| A / D | Move |
| Space | Jump (hold for height). Press again in mid-air to dash upward, steered with A / D |
| Mouse | Aim |
| Left or right click | Deflect toward the cursor |
| Shift | Air-dash toward the cursor |
| W / S, middle click | Switch depth lane right after a deflection |
| Q / E | Stabilize or Overclock a recovered module |
| R | Rewind to the last checkpoint |
| Esc | Pause |
| F11, Alt+Enter | Fullscreen |
| F3 | Show the adaptive difficulty numbers |

## How it plays

- **Deflection.** Every shot can be sent back at the cursor during a short parry window. A deflection in mid-air also
  recoils you away from the shot and refills your air-dash, so a good chain keeps you off the ground.
- **Ping-pong rallies.** Shielded enemies throw your deflection back. Each bounce makes the shot faster and larger and
  shifts its colour from magenta to cyan to gold. On the third bounce it turns into a crimson railgun that pierces shields.
- **Depth lanes.** Stage 2 and the boss use a foreground lane and a background lane. Snipers fire across them, and you
  can parry a sniper shot back into the depth.
- **Blackout Rebound.** A hit does not kill you. Time drops to a quarter speed for 1.5 seconds or more, and if you
  deflect any shot in that window you rebound with a shockwave. A second hit, or the timer running out, rewinds you
  0.3 seconds to the start of the room.
- **Climbing.** A plain jump rises 55 pixels. Pressing Space again in the air spends the air-dash straight up, which
  is how the Ascent Shaft is climbed. A deflection in mid-air gives the dash back.
- **Neural Sync.** Deflections raise a sync meter from 0% to 400%. Higher tiers add speed, afterimage trails, a wider
  parry arc, memory fragments burned onto the buildings, and finally Berserk Overdrive.
- **Modules.** Each of the first three stages ends with a stolen module. Stabilizing it follows Sara and gives a
  defensive upgrade. Overclocking it follows The Echo and gives an offensive one. The three choices decide which of the
  three endings you see.

## Adaptive difficulty

The game adjusts itself to the person playing. Eight small models run on the player's own machine and learn only from
that player. Nothing is uploaded. The profile is one JSON file in Godot's user data folder (`user://director.json`), and
deleting it returns the game to its starting difficulty.

| Model | Type | Predicts | Learns from |
|---|---|---|---|
| Hit model | Online logistic regression, five weights | The chance that an incoming shot hits you, given its speed, how many shots are in the air, whether you are airborne and how close the shooter is | Every shot you deflect, dodge or take |
| Quit model | Online logistic regression, six weights, starting from hand-set values | The chance that you stop playing before the next checkpoint, estimated at each death from the death streak, the time stuck, deaths in the last minute, how short the last life was and your recent deflect rate | What happened next: you reached the checkpoint, quit to the menu, closed the window or went idle for 30 seconds |
| Move model | N-gram over six movement states, five samples a second, three steps of context with back-off to two and one | Where you will be when a shot arrives | Your movement |
| Timing model | Running mean and spread of how early you swing, with a normal distribution over it | The chance that your next swing is still active when the shot arrives | The time between each click and the nearest incoming shot reaching you, and how often a hit lands with no swing at all |
| Room model | One rating for you and one for every room, updated like chess Elo | The chance that you clear the room you are in on this attempt | Every death in a room and every room cleared |
| Lever bandit | UCB1 over three kinds of help: timing, pace and density | Which kind of help makes your next life go better | Whether the life after a boost was longer than your usual one or reached a checkpoint |
| Pacing wave | Intensity meter with a six-second half-life | When a fight has peaked and needs a release | Hits, deflects and near misses |
| Skill tracing | Bayesian knowledge tracing, one value per mechanic (deflect, dash, air dash, rebound, lane change) | The chance that you know each mechanic | Once per life, whether you used a mechanic you had the chance to use |

A director turns those predictions into one number from 0 to 1, the challenge level. It solves the hit model for the
level at which about 26% of threatening shots would hit you, lowers that target toward 10% as the quit risk rises, and
moves toward the answer faster downward than upward. The level sets shot speed (70% to 115%), fire rate, the warning
time before a shot, how many shots may be in the air at once, the size and length of the parry window, the length of
Blackout, aim lines on enemies, and whether enemies lead their shots with the move model. A new player starts at 25%.

The other five models decide how that level is applied. The timing model widens the deflect window by up to 0.08
seconds, only as far as needed to bring your swings to 75% on time, and lengthens the warning before a shot if you
often take a hit without swinging. The room model lowers the level by up to 0.18 in a room that has beaten you before,
from the moment you enter it. On a death streak the lever bandit gives one kind of help an extra boost for the next
life and keeps score of which kind works for you. The pacing wave makes enemies fire slower for five seconds after a
peak and slightly faster in a long calm at a high level. When the game sees you stuck, every second hint is about the
mechanic the skill model says you have not shown yet.

During Blackout one enemy that can see you fires a fast tracking shot, at every challenge level, because at quarter
speed an ordinary shot does not arrive before the timer ends. That shot is the one to rebound off. After two deaths
by falling in the same room, the player has a second air-dash and a longer ledge grace until the next checkpoint. Repeated deaths, or 50 seconds without
progress, bring the stage's one-line hint back on screen.

The pause screen shows the current level, and F3 shows the models' numbers during play.

## Saving

The run is saved at every stage start, checkpoint and death, and when you quit to the title screen or close the
window: the stage, the checkpoint, the module choices, the clock, the loop count and the stats. A small "saved"
appears under the sync meter at each checkpoint. When a save exists the title screen shows Continue with the stage name, and New
game starts over. Finishing the game clears the save. The file is `user://save.json` in Godot's user data folder.

## Enemies

| Enemy | Look | Pack |
|---|---|---|
| Turret, wing turret | Fixed gun | Warped City |
| Drone | Hovering drone | Warped City |
| Enforcer | Rifle soldier with a kinetic shield | Sideview Sci-Fi |
| Command Enforcer (Stage 3) | Two-legged walker | Sideview Sci-Fi |
| Highway Heavy | Mech | Sideview Sci-Fi |
| Sniper | Tank on the far overpass | Sideview Sci-Fi |
| Deflector | Winged drone with a gold shield | Sideview Sci-Fi |

## Window sizes

The game fills any window. It picks a whole-number scale for the art and another for the interface from the real window
size, so pixels stay even at every resolution. The design view is 384x216 art pixels (3x at 1152x648, 5x at 1920x1080).
A window with a different shape shows more of the world in place of black bars. F11 or Alt+Enter toggles fullscreen,
and the desktop build opens maximized.

## Stages

1. The Awakening Alley
2. The Dual-Highway Overpass
3. The Ascent Shaft
4. Rooftop 09, against Sara's Valkyrie gunship in three phases

## Building from source

The enemy character sheets in `game/assets/sideview_scifi/` are copied unchanged from the CC0 pack by
`scripts/import_sprites.py`. The BDragon1727 effect sheets are not in this repository, because their licence does not allow redistribution. Download
"Free Effect and Bullet 16x16" from https://bdragon1727.itch.io/free-effect-and-bullet-16x16 and copy the four sheets
into `game/assets/vfx/` as `fire.png`, `green.png`, `purple.png` and `water.png`. Every other asset is included.

Web export (Compatibility renderer, single-threaded, so itch.io needs no SharedArrayBuffer setting):

```
godot --headless --path game --export-release "Web" ../exports/web/index.html
```

## Tests

Four headless tests drive the real game.

| Scene | Checks |
|---|---|
| `res://tests/MechTest.tscn` | The fixed mechanics with the director off: deflection, the Enforcer rally and railgun kill, Blackout and Rebound, death and rewind, the module choice, lane switching, all three boss phases and the ending screen |
| `res://tests/DirectorTest.tscn` | The eight models against simulated players (struggling, middling, expert), the profile save and load, the display scale rule across 1,317 window sizes, and the progress save file |
| `res://tests/DirectorLive.tscn` | The director inside Stage 1 with a weak bot and a strong bot in front of a real turret |
| `res://tests/ClimbTest.tscn` | Continue resumes a saved run at its checkpoint. A keyboard-only bot climbs the Ascent Shaft from the floor to the roof deck, and a control run with plain jumps shows that it cannot |

```
godot --headless --path game res://tests/MechTest.tscn
```

The models have been tested on simulated players only. No recorded human play exists yet to check them against.

## Project layout

| Path | Contents |
|---|---|
| `game/scripts/autoload/` | Display (window scaling), GameState (sync, modules, stats, input map), AudioManager, JuiceManager, DialogueData, Director (adaptive difficulty) |
| `game/scripts/entities/` | Player, Projectile, EnemyBase, BossGunship |
| `game/scripts/world/` | StageBase (stage builder), camera, rain, Z-rings, module pickup |
| `game/scripts/levels/` | The four stages |
| `game/scripts/ui/` | HUD, typeface loader (m5x7), post-processing stack, main menu, Echo world text |
| `game/shaders/` | CRT, Blackout crimson, VHS rewind, shockwave, hit flash, glitch text |
| `game/scenes/` | Scene files, generated with `scripts/build_scenes.gd` |
| `docs/` | The design document, decisions log |

Credits and licences are in [game/CREDITS.md](game/CREDITS.md).
