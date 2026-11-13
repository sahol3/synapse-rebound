# SYNAPSE // REBOUND — MASTER AGENT ARCHITECTURE & GAME DESIGN SPEC

**Event:** Hack Club Haven Dhaka 2026
**Theme:** "Bounce Back" (Literal Physics + Time-Loop Recovery + Psychological Comeback)
**Engine:** Godot 4.3 (Renderer: `Compatibility` ONLY for WebGL2 / Itch.io HTML5 Export)
**Target Deliverables:** Public GitHub Repository + Web-Playable Itch.io Build (`index.html`)

## 1. COMPETITION COMPLIANCE & ENGINE GUARDRAILS

### 1.1 AI & Asset Rules

1. **100% Allowed (Agent Domain):**

   * All `.gd` (GDScript 2.0) gameplay systems, physics, state machines, AI controllers, and procedural camera/tween animations.

   * All `.gdshader` visual effects (CRT scanlines, chromatic aberration, VHS rewind distortion, shockwave rings, hit-flashes, neon bloom).

   * All narrative scripts, branching dialogue data, character logs, and world-space typography triggers.

2. **Strictly Prohibited:**

   * Do NOT use AI-generated raster images/bitmaps or AI-generated music/voiceovers (no Suno/Udio/ElevenLabs).

   * Do NOT write Python/GDScript/SVG generator scripts to output `.png` or `.svg` files.

3. **Locked Human Asset Stack (`res://assets/`):**

   * **World, Tiles, Parallax & Characters:** Ansimuz *Warped City* (`https://ansimuz.itch.io/warped-city` — Side-view Cyberpunk Neo-Tokyo environment, human cyber-operative sprites, drones, turrets, vehicles).

   * **Projectiles, Slashes & Impact VFX:** BDragon1727 *Free Effect and Bullet 16x16* (`https://bdragon1727.itch.io/free-effect-and-bullet-16x16`) + *Retro Impact Effect Pack 3* (`https://bdragon1727.itch.io/retro-impact-effect-pack-3`).

   * **Audio Stack (100% Human-Made & Royalty-Free — Log in `CREDITS.md`):**
     * **BGM Pack 1 (High-Tempo Darksynth Combat Loops):** White Bat Audio *Free Cyberpunk Music Loop Pack* (`https://whitebataudio.itch.io/free-cyberpunk-loop-pack`) OR Blackvoid6 *Cyberpunk Action Music Pack* (`https://itch.io/game-assets/free/tag-cyberpunk/tag-music`).
     * **BGM Pack 2 (Synthwave & Boss Loops in `.ogg`):** TomMusic *Fluorescent Horizons Free Cyberpunk & Synthwave Pack* (`https://tommusic.itch.io/free-cyberpunk-and-synthwave-music-pack-fluorescent-horizons` — explicitly verified "No generative AI used").
     * **SFX Pack 1 (Evangelion / 90s Anime Deflections, Mecha & VHS Rewind):** Helton Yan *FREE Retro Anime Sound Effects* (`https://heltonyan.itch.io/`) + *Shapeforms Audio Free Sound Effects* (180 high-impact sci-fi & cyber combat `.wav` files).
     * **SFX Pack 2 (NERV Terminal Alerts, Glitches & Comms Beeps):** Hove Audio *Free SCI-FI UI Sound Effects Pack* (`https://hoveaudio.itch.io/free-sci-fi-ui-sound-effects-pack` — 100+ bleeps, 31 glitches, 12 rings; explicitly verified "No generative AI used").
     * **SFX Pack 3 (Lasers, Impacts & Switches):** Kenney.nl *Sci-Fi Sounds* (`https://kenney.nl/assets/sci-fi-sounds` — CC0 Public Domain).

### 1.2 Godot 4.3 Strict Syntax Rules (Zero Godot 3 Hallucinations)

* **Scene Safety:** Agents write `.gd` and `.gdshader` files. Only modify `.tscn` files via Godot-MCP tool calls or instruct the developer on exact node hierarchies.

* **GDScript 2.0 Mandates:**

  * Use `CharacterBody2D` (never `KinematicBody2D`).

  * Use built-in `velocity` property and call `move_and_slide()` with zero arguments.

  * Use `@export` and `@onready` annotations.

  * Use `await` (never `yield`).

  * Use `signal_name.connect(_on_callable)` (never string-based `.connect()`).

  * Use `velocity = velocity.bounce(collision.get_normal())` for vector reflection.

  * Enforce static typing everywhere (`var sync_rate: float = 100.0`, `func parry() -> void:`).

## 2. PSYCHOLOGICAL RETENTION & DOPAMINE ENGINEERING

*(Synthesized from Katana ZERO, SANABI, Celeste, Dead Cells, VINCIT, and Evangelion/Edgerunners)*

### 2.1 The Micro-Loop (Every 2–4 Seconds of Combat)

1. **Katana ZERO "Bullet-Time Deflection" & Hit-Stop:**

   * Parrying a projectile within the 0.18s active window freezes `Engine.time_scale = 0.04` for `80ms` (scaling up to `140ms` on multi-bounces) using `await get_tree().create_timer(duration, true, false, true).timeout`.

   * Spawns a directional BDragon1727 slash spark + white-cyan invert flash on the deflected projectile.

2. **SANABI "Kinetic Air-Momentum" (The Floor is Lava):**

   * Deflecting any projectile while airborne applies an opposite kinetic impulse (`velocity = -aim_direction * recoil_force`) and **instantly resets the player's Air-Dash charge**.

   * Skilled players can bounce from projectile to drone across entire skyscrapers without touching the ground.

3. **Celeste "Zero-Friction Forgiveness" Physics:**

   * **Coyote Time (`0.12s`):** Player can still jump for $0.12\text{ s}$ after walking off a ledge.

   * **Jump & Parry Buffering (`0.10s`):** Pressing jump or parry $0.10\text{ s}$ before landing/cooldown expiry queues the action immediately on the first available frame.

   * **Corner Correction:** If the player's head clips the outer 4 pixels of a platform during an upward recoil bounce, nudge `position.x` smoothly so momentum is never killed by a pixel snag.

4. **Edgerunners "Sandevistan" Afterimage Trail:**

   * Whenever dashing or operating above $200\%$ Neural Sync, spawn a fading `Sprite2D` duplicate of the player's current frame every `0.035s`. Tint ghosts along a gradient (`Cyan #00F0FF` $\rightarrow$ `Magenta #FF0055` $\rightarrow$ `Deep Violet #4A00E0`) and tween `modulate.a` to `0.0` over `0.25s`.

### 2.2 The Macro-Loop (Attention, Escalation & Recovery)

1. **0.3-Second VHS Rewind Respawn (Zero Game-Over Friction):**

   * Never show a static "Game Over" screen. When the player fails a room, trigger a loud tape-rewind scratch, activate `vhs_rewind.gdshader` for `0.3s`, increment `GameState.loop_deaths += 1`, and snap the player back to the room entrance with music uninterrupted.

2. **Evangelion "Neural Sync Rate" (`0%` to `400%` Berserk Overdrive):**

   * Every successful deflection increases `sync_rate` by $+15\%$ (consecutive airborne bounces grant $+25\%$).

   * $< 100\%$ **(Degraded):** Standard movement, clean cyan HUD.

   * $100\% - 199\%$ **(Synchronized):** $+15\%$ movement speed, synth bassline layer unmutes.

   * $200\% - 299\%$ **(Overclocked):** Sandevistan trails permanently active, parry arc widens by $+25\%$, suppressed **Echo Memories** burn onto the background buildings.

   * $300\% - 400\%$ **(BERSERK OVERDRIVE):** HUD borders flash NERV crimson/amber (`#FF9900` / `#FF0033`), projectiles deflected by the player explode on impact, and high-pass/distortion audio filters kick in.

## 3. THE TRIPLE-STACK "BOUNCE BACK" CORE MECHANICS

### Mechanic 1: 360-Degree Deflection & The "Ping-Pong Death Rally"

* **The Base Parry:** The player has **zero guns**. Left-Click or Right-Click triggers a $360^\circ$ kinetic wrist-deflector aimed at `get_global_mouse_position()`.

* **The Rally Escalation:** Standard turrets die in 1 deflected shot. However, **Syndicate Enforcers and Bosses have kinetic shields that bounce your parried shot BACK at you.**

* Every time a projectile bounces back and forth in a rally:

  * `bounce_count += 1`

  * Speed scales: `speed *= 1.32`

  * Size scales: `scale *= 1.15`

  * Color shifts: `Magenta (Enemy)` $\rightarrow$ `Cyan (Bounce 1)` $\rightarrow$ `Electric Gold (Bounce 2)` $\rightarrow$ `Crimson Supernova (Bounce 3+)`

  * Audio pitch steps up a musical semitone (`pitch_scale = 1.0 + (bounce_count * 0.12)`).

  * At `bounce_count >= 3`, the projectile becomes an unstoppable railgun beam that pierces shields and shatters every enemy in its line of fire.

### Mechanic 2: 2.5D Z-Lane Depth Switching & Pinball Wall-Slam

* **Dual-Plane 2.5D Gameplay:** Levels feature two parallel combat planes using *Warped City* assets:

  * **Foreground Lane (`z_lane = 0`):** Scale `Vector2(1.0, 1.0)`, `z_index = 0`, `modulate = Color(1, 1, 1)`, Collision Layer/Mask `1`.

  * **Background Catwalk/Highway Lane (`z_lane = 1`):** Scale `Vector2(0.78, 0.78)`, `z_index = -5`, `modulate = Color(0.65, 0.75, 0.95)`, Collision Layer/Mask `2`.

* **How You Bounce Between Lanes:** Pressing `W` / `S` (or `Middle-Click`) while parrying a heavy plasma shot—or hitting a kinetic Z-Ring—launches the player through the air from the Foreground into the Background lane (or vice versa) over `0.18s` via a cubic `Tween`, complete with a shockwave ring.

* **Cross-Lane Sniping:** Snipers in the Background Lane can lock a red laser onto you in the Foreground. If you parry their shot at the exact frame it crosses planes, you bounce the bullet *back into the background depth* to take them out.

* **Kinetic Wall-Slam:** Getting knocked back into a wall and pressing `Parry` within `0.1s` of impact ricochets the player's entire body off the wall at high speed, turning the player into a human projectile that slices through drones.

### Mechanic 3: The 1.5-Second "Blackout Rebound" (Clutch Comeback)

* Taking a direct hit does **not** kill the player instantly (unless already in Blackout).

* Instead, a lethal hit triggers **BLACKOUT STATE**:

  * `Engine.time_scale` drops to `0.25` for `1.5` real-time seconds.

  * Screen shader drains to monochrome black-and-white with neon crimson highlights.

  * The player's body is launched backward in slow motion while a frantic heartbeat + flatline whine plays.

* **The Comeback:** If the player aims and deflects **any** incoming projectile in mid-air before the `1.5s` timer hits zero (or before hitting a death pit), they trigger a **BLACKOUT REBOUND**:

  * Time snaps back to `1.0x` with a massive radial shockwave that pushes nearby enemies back.

  * Health stabilizes, and `sync_rate` spikes by $+50\%$.

  * You literally *bounce back from the edge of death*.

## 4. FULL MULTI-NARRATIVE STORY, MODULE RECOVERY & SCRIPT

### 4.1 Narrative Premise & The Two Competing Voices

* **The Setup:** You are **VINCENT-09**, an elite cybernetic courier in Neo-Dhaka (*Warped City*). At 00:00, on the roof of Tower 09, someone stripped your three core neural modules, locked your weapons, wiped your memory, and shot you off the roof into the acid rain.

* **The "Bounce Back" Hook:** One millisecond before your skull hits the street below, your experimental **Lazarus Loop** implant triggers a quantum temporal rebound—snapping your body back onto the lower neon scaffolding **60 seconds before your execution**.

* **The Dual-Voice Psychological System (Delivered Live During Gameplay):**

  1. **CHANNEL A — "SARA" (Your Handler / Top-Left Cyan HUD Comms):**

     * Speaks in calm, urgent tactical transmissions. She tells you that the **Valkyrie Syndicate** ambushed you on the roof, stole your neural cores, and is trying to finish you off. She begs you to keep your Sync Rate low and **STABILIZE** your recovered hardware so your brain doesn't fry.

  2. **CHANNEL B — "THE ECHO" (Your Pre-Wipe Subconscious / World-Space Crimson Glitch + Audio):**

     * Speaks in your own distorted voice and flashes giant *Evangelion*-style kinetic typography across the background buildings whenever your Sync Rate exceeds $200\%$ or right after you rewind from a death.

     * **The Twist:** The Echo is a recording you left for yourself before the memory wipe. *There is no Syndicate ambush.* You discovered that Sara's corporation was using couriers as disposable neural bombs. **Sara is the one who stripped your modules and shot you off the roof.** She is currently sitting in the Gunship on Rooftop 09, trying to talk you into suppressing your own neural sync so you stay weak enough for her turrets to finish the job.

### 4.2 The Stolen Nervous System (End-of-Stage Module Choice)

At the end of Stages 1, 2, and 3, Vincent shatters a Command Enforcer and rips back one of his stolen neural modules. A sleek 4-second slow-motion HUD prompt appears without pausing the music:

* **`[PRESS Q] — STABILIZE MODULE (Listen to Sara)`:**

  * *Narrative:* Suppresses memory anomalies and lowers cortical stress (`corruption_count` stays low).

  * *Gameplay Buff:* Grants a high-reliability **Defensive / Mobility Upgrade** (wider parry window, longer Blackout Rebound survival timer, automatic laser telegraph sights).

* **`[PRESS E] — OVERCLOCK MODULE (Listen to The Echo)`:**

  * *Narrative:* Forces corrupted pre-wipe memories back into your visual cortex (`overclock_count += 1`), unlocking the truth about Rooftop 09.

  * *Gameplay Buff:* Grants an explosive **Berserk Offensive Upgrade** (parried bullets split into twin ricochets, Z-Lane switches trigger EMP blasts, permanent $+100\%$ minimum Sync floor).

### 4.3 Stage-by-Stage Architecture & Complete Dialogue Script

*(Store all lines in `res://scripts/autoload/DialogueData.gd` so agents can trigger them via non-blocking HUD toasts and world-space background labels)*

#### STAGE 1: THE AWAKENING ALLEY (`0:00 - 0:50`)

* **Visuals & Pacing:** Rain-slicked lower streets of *Warped City*. Neon signs flicker. Starts immediately mid-fall as the VHS tape rewinds Vincent onto a flickering balcony.

* **Mechanics Introduced:** $360^\circ$ Bullet Deflection, Aerial Recoil Pogo off turret fire, Coyote Jump.

* **Live Script & Triggers:**

  * **\[Trigger: 0.0s — VHS Rewind Intro Flash\]:**

    * *World-Space Giant Text:* `00:00:00 // IMPACT AVOIDED // BOUNCING BACK -60.0s`

    * **SARA (Cyan HUD):** *"Vincent?! Holy hell, your Lazarus implant actually fired! Listen to me—Syndicate hitters ambushed you on Tower 09 and stripped your weapons!"*

    * **SARA (Cyan HUD):** *"Your kinetic wrist-guard is still online. Aim at their fire and bounce it back into their teeth!"*

  * **\[Trigger: First Successful Parry Kill\]:**

    * **SARA (Cyan HUD):** *"Clean deflection! Keep climbing the scaffolding, I'm holding an extraction shuttle on the roof!"*

  * **\[Trigger: First Player Death Rewind OR Sync** $\ge 200\%$**\]:**

    * *World-Space Glitch Text (Behind Buildings):* `NO SYNDICATE ON THE ROOF.`

    * **THE ECHO (Crimson Glitch Toast):** *"...Why is she lying about the extraction shuttle? Check the ballistic angle on your chest plate..."*

  * **\[Trigger: Stage 1 End — Defeat Enforcer Unit & Recover `MODULE 01: CORTEX DASH RELAY`\]:**

    * **SARA:** *"You got your Dash Relay back! Don't overclock it, Vincent—your neural sync will spike and burn out your memory core. Press \[Q\] to Stabilize!"*

    * **THE ECHO:** *"Stabilizing it keeps the memory blocks locked. Overclock it \[E\]. Remember who was standing behind you in the rain."*

    * **Choice Buffs:**

      * `[Q] STABILIZE:` **Phase Dash** (Air-dash cooldown reduced by $40\%$ and grants `0.25s` invulnerability frames).

      * `[E] OVERCLOCK:` **Shockwave Dash** (Dashing through a projectile automatically deflects it at $2\times$ speed toward the nearest enemy).

#### STAGE 2: THE DUAL-HIGHWAY OVERPASS (`0:50 - 1:45`)

* **Visuals & Pacing:** High-speed neon freeway with flying cars in parallax and a parallel sniper catwalk in the background (`z_lane = 1`).

* **Mechanics Introduced:** 2.5D Z-Lane Switching (`Foreground` $\leftrightarrow$ `Background`), Cross-Lane Laser Parrying, Wall-Slam Ricochet.

* **Live Script & Triggers:**

  * **\[Trigger: Stage 2 Start\]:**

    * **SARA:** *"Snipers on the parallel overpass! Use heavy recoil or the kinetic rings to bounce yourself across lanes!"*

  * **\[Trigger: First Z-Lane Switch into Background\]:**

    * *World-Space Glitch Text:* `SHE LOCKED YOUR HOLSTER.`

    * **THE ECHO:** *"Memory fragment restored: 23:58. Two minutes before the fall. Only two people had the encryption key to disable your sidearm. You... and Sara."*

  * **\[Trigger: Mid-Stage Ambush\]:**

    * **SARA:** *"Vincent, your cortical telemetry is spiking! Stop listening to those feedback ghosts—the Lazarus rewind scrambles short-term memory!"*

  * **\[Trigger: Stage 2 End — Defeat Highway Heavy & Recover `MODULE 02: OPTIC Z-PRISM`\]:**

    * **SARA:** *"That's your Optic Prism! Stabilize it \[Q\] now so I can guide you safely up the central shaft!"*

    * **THE ECHO:** *"She doesn't want your optics running at full resolution. Overclock it \[E\] and look at the IFF tags on these drones. They're HER division."*

    * **Choice Buffs:**

      * `[Q] STABILIZE:` **Chrono-Sight** (Slows time by $30\%$ for `0.5s` whenever an enemy sniper locks onto you, extending the Blackout Rebound window to `2.2s`).

      * `[E] OVERCLOCK:` **Prism Split** (Every 3rd parried bullet splits into 2 neon-crimson ricochet shards that home in on nearby targets).

#### STAGE 3: THE ASCENT SHAFT (`1:45 - 2:35`)

* **Visuals & Pacing:** A vertical megastructure elevator shaft rising toward the storm clouds. The floor drops away—pure vertical *SANABI*-style aerial pogoing and high-speed **Ping-Pong Death Rallies** against Elite Deflector Drones.

* **Mechanics Introduced:** Multi-Bounce Ping-Pong Rallies (`bounce_count` $1 \rightarrow 4$), Continuous Airborne Sync Chains ($300\%+$).

* **Live Script & Triggers:**

  * **\[Trigger: Entering Vertical Shaft\]:**

    * *World-Space Glitch Text:* `CLIMB BACK TO THE SCENE OF THE CRIME.`

    * **SARA (Panicking):** *"Wait—why are you taking the express shaft straight to Rooftop 09?! The landing pad is too hot, turn back to Sector 4!"*

  * **\[Trigger: Winning First 3-Bounce Ping-Pong Rally\]:**

    * **THE ECHO:** *"Audio log recovered \[23:59:42\]: 'I'm sorry, Vincent. Command says if a courier reads the Lazarus files, we pull the plug.' ...That was her voice."*

    * **SARA (Mask Slipping):** *"Shut it down, Vincent! You weren't supposed to survive a 90-story drop! Why won't you just stay down?!"*

  * **\[Trigger: Stage 3 End — Top of the Shaft & Recover `MODULE 03: LIMBIC OVERDRIVE CORE`\]:**

    * **SARA:** *"Last warning, Courier. Stabilize that core \[Q\] and surrender at the roof door, or I will personally vaporize what's left of your nervous system."*

    * **THE ECHO:** *"60 seconds are up. We're back on the roof where we died. Overclock the core \[E\]. Let's return the bullet she gave us."*

    * **Choice Buffs:**

      * `[Q] STABILIZE:` **Aegis Capacitor** (Allows you to hold the Parry button for a `0.4s` omnidirectional kinetic barrier that absorbs rapid-fire barrages).

      * `[E] OVERCLOCK:` **400% Berserk Lock** (Locks Neural Sync at $400\%$, doubles rally bounce acceleration, and turns all player deflections into explosive rail-shots).

#### STAGE 4: ROOFTOP 09 — BOSS: SARA'S VALKYRIE GUNSHIP (`2:35 - 3:30`)

* **Visuals & Pacing:** The rain-drenched neon helipad at the pinnacle of Tower 09. Broken glass from where you fell at 00:00 litters the edge. Sara hovers in an armored **Valkyrie Interceptor Gunship** (`Warped City` vehicle/boss sprite assembled with glowing turret hardpoints).

* **Boss Phases (Pure "Bounce Back" Mastery):**

  * **Phase 1 (Foreground Barrage):** Gunship sweeps across the roof firing plasma spreads. Player deflects shots into the two wing turrets.

  * **Phase 2 (2.5D Depth Retreat):** Gunship pulls back into the Background Lane (`z_lane = 1`) and fires heavy rail-missiles across depth planes. Player must Z-Bounce onto floating drones or cross-plane parry the missiles back into the Gunship's hull.

  * **Phase 3 (The 5-Bounce Execution Rally):** At $15\%$ HP, Sara activates her kinetic cockpit deflector. She fires a massive Overcharged Core Sphere. When you parry it, **she parries it back.** You must win a blistering **5-Bounce Ping-Pong Rally** (each bounce shaking the screen harder and pitching up the synth audio) until the sphere shatters her cockpit armor and blasts her Gunship off the edge of Tower 09.

### 4.4 The Three Endings (Based on `[Q] Stabilize` vs. `[E] Overclock` Choices)

1. **ENDING A: "CLEAN REBOOT" (All 3 Modules Stabilized `[Q]`):**

   * You disable Sara's gunship without losing your humanity. As her craft crashes onto the lower deck, you purge the corporate tracker from your Lazarus implant and vanish into the Neo-Dhaka skyline—a free human who bounced back from erasure.

2. **ENDING B: "TOTAL OVERCLOCK // BERSERK" (All 3 Modules Overclocked `[E]`):**

   * At $400\%$ Sync, the final 5-bounce rally obliterates the gunship completely. Your pre-wipe consciousness ("The Echo") fully merges with your body. Standing on the edge of Rooftop 09, you hijack Sara's corporate comms network and broadcast the Lazarus files to every citizen in Warped City.

3. **ENDING C: "SYNAPSE EQUILIBRIUM" (Mixed Stabilize + Overclock):**

   * You balance human control with cybernetic fury. You deflect the final shot straight through the Gunship's engine core, walk up to the smoking wreckage, recover your original encrypted courier briefcase, and step off the roof—using a controlled recoil bounce to glide into the neon night.

## 5. TECHNICAL ARCHITECTURE, AUDIO MAPPING & EXECUTION ROADMAP

### 5.1 Project Directory Structure (`res://`)

```
res://
├── project.godot                # Compatibility renderer, 1152x648 viewport, Nearest texture filter
├── CREDITS.md                   # Attribution for Ansimuz, BDragon1727, TomMusic, Hove Audio, Helton Yan, Kenney
├── README.md                    # Game overview, controls, and architecture
├── assets/
│   ├── warped_city/             # Ansimuz spritesheets, tilesets, parallax backgrounds
│   ├── vfx/                     # BDragon1727 16x16 bullets, slashes, and impact shockwaves
│   ├── audio/
│   │   ├── bgm/                 # .ogg synthwave/cyberpunk loops (TomMusic / White Bat Audio)
│   │   └── sfx/                 # .wav parry, rally-ping, dash, rewind, UI glitch SFX (Hove / Helton Yan / Kenney)
│   └── fonts/                   # Monospace / Cyberpunk display font (.ttf)
├── shaders/
│   ├── crt_cyberpunk.gdshader   # Screen-space scanlines, vignette, chromatic aberration
│   ├── vhs_rewind.gdshader      # Horizontal UV tear + RGB split during 0.3s death rewind
│   ├── blackout_crimson.gdshader# Desaturates world except red/cyan during 1.5s Blackout Rebound
│   └── hit_flash.gdshader       # Solid white/cyan flash on sprites when parried/damaged
├── scripts/
│   ├── autoload/
│   │   ├── GameState.gd         # Sync rate, current_lane, module choices, death counter
│   │   ├── AudioManager.gd      # Pitch-scaling SFX pool + dynamic BGM filter controller
│   │   ├── JuiceManager.gd      # Hit-stop timer, camera trauma shake, shockwave spawner
│   │   └── DialogueData.gd      # All Stage 1-4 Sara/Echo scripts & choice definitions
│   ├── entities/
│   │   ├── Player.gd            # CharacterBody2D: movement, coyote time, 360 parry, Z-lane tween, Blackout state
│   │   ├── Projectile.gd        # Area2D/CharacterBody2D: velocity, bounce_count, rally scaling, lane mask
│   │   ├── EnemyBase.gd         # Turrets, flying drones, and Rally Enforcers (auto-parry logic)
│   │   └── BossGunship.gd       # Stage 4 multi-phase boss + 5-bounce final rally state machine
│   └── ui/
│       ├── HudController.gd     # Evangelion sync gauge, Sara comms toast, Module Choice modal
│       └── WorldGlitchText.gd   # Background parallax labels that flash Echo memories at >200% Sync
└── scenes/
    ├── Main.tscn                # Root wrapper with CanvasLayer shaders & SceneManager
    ├── ui/
    │   ├── MainMenu.tscn
    │   └── HUD.tscn
    ├── entities/
    │   ├── Player.tscn
    │   ├── Projectile.tscn
    │   └── EnemyTurret.tscn
    └── levels/
        ├── Stage01_Alley.tscn
        ├── Stage02_Highway.tscn
        ├── Stage03_Shaft.tscn
        └── Stage04_RooftopBoss.tscn

```

### 5.2 Dynamic Audio & Dopamine SFX Mapping (`AudioManager.gd`)

Agents must wire `AudioManager.gd` with an 8-channel `AudioStreamPlayer` SFX pool and a Master Bus `AudioEffectLowPassFilter` so every mechanical action triggers immediate auditory feedback:

| Sound Key (`play_sfx`) | Source Pack | Trigger & Dynamic Pitch/Filter Rule |
| :--- | :--- | :--- |
| `"parry_hit"` | Helton Yan *Retro Anime* / Kenney *Sci-Fi* | Played on standard bullet deflection. Randomize `pitch_scale` between `0.95` and `1.08`. |
| `"rally_ping"` | Hove Audio *Rings* + Helton Yan *Mecha* | Played during Ping-Pong Death Rallies. Set `pitch_scale = 1.0 + (bounce_count * 0.14)` so each volley rises in musical tension. |
| `"z_lane_whoosh"` | Kenney *Sci-Fi* (`thruster` / `warp`) | Played when tweening between Foreground (`z_lane = 0`) and Background (`z_lane = 1`). |
| `"blackout_heartbeat"` | Hove Audio *Glitches* + Low Sub Pulse | Triggered on entering 1.5s Blackout State; enable `AudioEffectLowPassFilter` (`cutoff_hz = 650.0`) on BGM bus to muffle music underwater. |
| `"blackout_rebound"` | Helton Yan *Anime Impact Explosion* | Played when successfully parrying out of Blackout State; snap BGM `cutoff_hz` back to `20500.0`. |
| `"vhs_rewind"` | Hove Audio *31 Glitches* (Tape Scratch) | Played during the 0.3s VHS Rewind respawn. |
| `"sara_comms"` | Hove Audio *Bleeps & Bloops* (Clean Cyan Beep) | Played when Sara's top-left HUD dialogue appears (`pitch_scale = 1.2`). |
| `"echo_glitch"` | Hove Audio *Glitches* (Distorted Static Burst) | Played when The Echo flashes world-space crimson typography (`pitch_scale = 0.75`). |

### 5.3 Core Shader Implementations (Ready for Agent Generation)

#### 1. `res://shaders/hit_flash.gdshader` (Attach to Player, Enemies & Projectiles)

```
shader_type canvas_item;

uniform bool active = false;
uniform vec4 flash_color : source_color = vec4(0.0, 0.95, 1.0, 1.0);

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    if (active) {
        COLOR = vec4(flash_color.rgb, tex_color.a);
    } else {
        COLOR = tex_color;
    }
}

```

#### 2. `res://shaders/blackout_crimson.gdshader` (Full-Screen `ColorRect` on `CanvasLayer`)

```
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float aberration : hint_range(0.0, 0.02) = 0.003;

void fragment() {
    vec2 uv = SCREEN_UV;
    float r = texture(screen_texture, uv + vec2(aberration * intensity, 0.0)).r;
    float g = texture(screen_texture, uv).g;
    float b = texture(screen_texture, uv - vec2(aberration * intensity, 0.0)).b;
    vec3 col = vec3(r, g, b);
    
    // Convert to high-contrast luma, preserve strong reds and cyans
    float luma = dot(col, vec3(0.299, 0.587, 0.114));
    float red_mask = clamp((col.r - max(col.g, col.b)) * 3.0, 0.0, 1.0);
    vec3 bw_crimson = mix(vec3(luma * 0.6), vec3(1.0, 0.05, 0.2), red_mask);
    
    COLOR = vec4(mix(col, bw_crimson, intensity), 1.0);
}

```

### 5.4 Step-by-Step Agent Build Order (Execute in Sequence)

1. **Phase 1 — Autoloads & Core Juice (`30 mins`):**

   * Generate `GameState.gd`, `JuiceManager.gd` (hit-stop, camera trauma shake, afterimage ghost spawner), `AudioManager.gd` (with the 8-key SFX mapping & low-pass filter above), and `DialogueData.gd`.

2. **Phase 2 — Player Controller & Triple-Stack Bounce (`60 mins`):**

   * Build `Player.gd` with Celeste-style movement (coyote time, jump buffer), $360^\circ$ mouse-aimed parry arc, aerial recoil pogo, 2.5D Z-Lane tween (`z_lane` $0 \leftrightarrow 1$), and the 1.5s Blackout Rebound state.

   * Build `Projectile.gd` with BDragon1727 sprites, `bounce_count` escalation, and collision layer flipping.

3. **Phase 3 — Enemies & Ping-Pong Rally AI (`45 mins`):**

   * Build standard Turrets, Flying Drones, and the **Syndicate Enforcer** that parries deflected bullets back at the player to trigger high-speed rallies.

4. **Phase 4 — HUD, Shaders & Dual-Voice Narrative (`45 mins`):**

   * Wire up `HudController.gd` (Sync Rate meter, Sara's top-left toast, `[Q] Stabilize / [E] Overclock` module UI) and `WorldGlitchText.gd` (The Echo's background typography).

5. **Phase 5 — Assemble the 4 Stages & Rooftop Boss (`90 mins`):**

   * Lay out the 4 compact stages using *Warped City* tiles and parallax backgrounds, culminating in `BossGunship.gd` on Rooftop 09.

6. **Phase 6 — WebGL2 Export Verification (`30 mins`):**

   * Test export to `export/web/index.html` using Godot's `Compatibility` renderer, verify shaders and audio loop cleanly in Chrome, and push all `.gd`, `.gdshader`, and `CREDITS.md` files to GitHub.