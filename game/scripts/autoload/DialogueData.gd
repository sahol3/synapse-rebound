extends Node
## Every line of the Stage 1-4 script, the module choices and the endings.
## Speakers: SARA (cyan HUD comms, top-left), ECHO (crimson glitch toast),
## WORLD (giant kinetic typography burned onto the buildings), SYS (HUD banner).

const LINES: Dictionary = {
	# ---------------------------------------------------------------- ADAPTIVE DIRECTOR
	"assist_ease": [
		{"who": "SARA", "text": "I'm jamming their fire control. Their shots are slower now, so watch one and send it back."},
	],
	"assist_hard": [
		{"who": "ECHO", "text": "They have stopped holding back. So have you."},
	],
	# ---------------------------------------------------------------- STAGE 1
	"s1_intro": [
		{"who": "WORLD", "text": "00:00:00 // IMPACT AVOIDED // BOUNCING BACK -60.0s"},
		{"who": "SARA", "text": "Vincent?! Holy hell, your Lazarus implant actually fired! Listen to me. Syndicate hitters ambushed you on Tower 09 and stripped your weapons!"},
		{"who": "SARA", "text": "Your kinetic wrist-guard is still online. Aim at their fire and bounce it back into their teeth!"},
	],
	"s1_tutorial": [
		{"who": "SYS", "text": "Click to deflect toward the cursor. Space jumps, and Space again in the air dashes upward. Shift dashes toward the cursor."},
	],
	"s1_pogo": [
		{"who": "SYS", "text": "Deflect in mid-air to recoil off the shot. It gives your air-dash back."},
	],
	"s1_first_kill": [
		{"who": "SARA", "text": "Clean deflection! Keep climbing the scaffolding, I'm holding an extraction shuttle on the roof!"},
	],
	"s1_echo": [
		{"who": "WORLD", "text": "NO SYNDICATE ON THE ROOF."},
		{"who": "ECHO", "text": "...Why is she lying about the extraction shuttle? Check the ballistic angle on your chest plate..."},
	],
	"s1_enforcer": [
		{"who": "SARA", "text": "Syndicate Enforcer! His kinetic shield throws your deflection straight back. Keep the rally going until the shot goes supernova!"},
		{"who": "SYS", "text": "Keep parrying what the shield throws back. The third bounce becomes a railgun."},
	],
	"s1_module": [
		{"who": "SARA", "text": "You got your Dash Relay back! Don't overclock it, Vincent. Your neural sync will spike and burn out your memory core. Press [Q] to Stabilize!"},
		{"who": "ECHO", "text": "Stabilizing it keeps the memory blocks locked. Overclock it [E]. Remember who was standing behind you in the rain."},
	],
	# ---------------------------------------------------------------- STAGE 2
	"s2_intro": [
		{"who": "SARA", "text": "Snipers on the parallel overpass! Use heavy recoil or the kinetic rings to bounce yourself across lanes!"},
		{"who": "SYS", "text": "Press W or S right after a deflection, or touch a Z-ring, to change lanes. Parry sniper shots back into the depth."},
	],
	"s2_first_lane": [
		{"who": "WORLD", "text": "SHE LOCKED YOUR HOLSTER."},
		{"who": "ECHO", "text": "Memory fragment restored: 23:58. Two minutes before the fall. Only two people had the encryption key to disable your sidearm. You... and Sara."},
	],
	"s2_wallslam": [
		{"who": "SYS", "text": "Hit a wall and deflect within 0.1s to ricochet off it."},
	],
	"s2_ambush": [
		{"who": "SARA", "text": "Vincent, your cortical telemetry is spiking! Stop listening to those feedback ghosts. The Lazarus rewind scrambles short-term memory!"},
	],
	"s2_heavy": [
		{"who": "SARA", "text": "Highway Heavy! Double shielding. You'll need two supernova rallies to crack it."},
	],
	"s2_module": [
		{"who": "SARA", "text": "That's your Optic Prism! Stabilize it [Q] now so I can guide you safely up the central shaft!"},
		{"who": "ECHO", "text": "She doesn't want your optics running at full resolution. Overclock it [E] and look at the IFF tags on these drones. They're HER division."},
	],
	# ---------------------------------------------------------------- STAGE 3
	"s3_intro": [
		{"who": "WORLD", "text": "CLIMB BACK TO THE SCENE OF THE CRIME."},
		{"who": "SARA", "text": "Wait. Why are you taking the express shaft straight to Rooftop 09?! The landing pad is too hot, turn back to Sector 4!"},
		{"who": "SYS", "text": "The floor is gone. Jump, then press Space again to dash upward. A deflection in the air gives the dash back."},
	],
	"s3_rally": [
		{"who": "ECHO", "text": "Audio log recovered [23:59:42]: 'I'm sorry, Vincent. Command says if a courier reads the Lazarus files, we pull the plug.' ...That was her voice."},
		{"who": "SARA", "text": "Shut it down, Vincent! You weren't supposed to survive a 90-story drop! Why won't you just stay down?!"},
	],
	"s3_module": [
		{"who": "SARA", "text": "Last warning, Courier. Stabilize that core [Q] and surrender at the roof door, or I will personally vaporize what's left of your nervous system."},
		{"who": "ECHO", "text": "60 seconds are up. We're back on the roof where we died. Overclock the core [E]. Let's return the bullet she gave us."},
	],
	# ---------------------------------------------------------------- STAGE 4
	"s4_intro": [
		{"who": "WORLD", "text": "ROOFTOP 09 // 00:00:00"},
		{"who": "SARA", "text": "You really came back. Fine. The Valkyrie doesn't miss twice."},
		{"who": "SYS", "text": "Deflect her plasma into the wing turrets."},
	],
	"s4_phase2": [
		{"who": "SARA", "text": "Pulling back to the depth lane. Let's see you bounce across ninety stories of air."},
		{"who": "SYS", "text": "Parry the rail missiles back across the depth plane. Z-rings and W or S change lanes."},
	],
	"s4_phase3": [
		{"who": "SARA", "text": "Cockpit deflector online! Every shot you send, I send back. You can't win a rally against a gunship!"},
		{"who": "ECHO", "text": "Five bounces. That's all it takes. She taught us that."},
		{"who": "SYS", "text": "Five bounces to break the core. Don't drop it."},
	],
	"s4_win": [
		{"who": "SARA", "text": "No... no, no, NO..."},
	],
	# ---------------------------------------------------------------- generic
	"first_death": [
		{"who": "ECHO", "text": "Rewind. Again. You've died on this roof before, Vincent. Count the loops."},
	],
	"first_blackout": [
		{"who": "SYS", "text": "Blackout. A shot is coming for you. Deflect it before the timer runs out to rebound."},
	],
	"first_rebound": [
		{"who": "ECHO", "text": "There it is. We always bounce back."},
	],
	# ------------------------------------------------------------ reactive: the two voices watch you play
	"first_death_s1": [
		{"who": "SARA", "text": "That was the Lazarus implant. It throws you back a few seconds every time you die. Get up and go again."},
	],
	"loop_a_3": [
		{"who": "SARA", "text": "The implant caught you again. It will not hold forever, Vincent. Stay behind cover and let me guide you."},
	],
	"loop_a_5": [
		{"who": "ECHO", "text": "Five loops. Every one of them ends with you on your feet."},
	],
	"loop_a_8": [
		{"who": "SARA", "text": "Your telemetry looks like static. Stop pushing forward and wait for my signal."},
	],
	"loop_a_12": [
		{"who": "ECHO", "text": "Twelve loops. She keeps asking you to wait. Ask yourself what she is waiting for."},
	],
	"loop_b_3": [
		{"who": "SARA", "text": "Every rewind burns away a little more of you. Stay down this time."},
	],
	"loop_b_5": [
		{"who": "ECHO", "text": "She shot us once. We have come back five times. Do the arithmetic for her."},
	],
	"loop_b_8": [
		{"who": "SARA", "text": "How many times do I have to kill you, Courier?"},
	],
	"loop_b_12": [
		{"who": "ECHO", "text": "Twelve loops. She is running out of ways to say stay down."},
	],
	"loop_many": [
		{"who": "ECHO", "text": "Count the loops if you like. The one that matters is the last."},
	],
	"rebound_3": [
		{"who": "ECHO", "text": "Three hits that should have ended it. Three shots sent back. Keep that feeling."},
	],
	"rebound_7": [
		{"who": "ECHO", "text": "Seven times she has put us on the floor. Seven times we got up. She is counting too."},
	],
	"rally_3": [
		{"who": "ECHO", "text": "Third bounce. The shot comes back harder every time. So do we."},
	],
	"berserk": [
		{"who": "WORLD", "text": "BERSERK OVERDRIVE"},
	],
}

## Shown again when the director sees the player stuck (repeat deaths, or a long time without
## reaching the next checkpoint). One per stage, the one thing that gets you through it.
const STUCK_HINTS: PackedStringArray = [
	"Put the cursor on a shot and click as it reaches you. Space again in the air dashes upward.",
	"Deflect a shot, then press W or S at once to change lanes. A Z-ring changes lanes for you.",
	"Jump, then press Space again to dash upward. Hold A or D to steer the dash.",
	"Send her shots back: the wing turrets first, then the hull, then five bounces off the cockpit.",
]

## Shown in place of the stage hint when the director's skill model says the player has had the
## chance to use a mechanic and has not shown it yet.
const SKILL_HINTS: Dictionary = {
	"parry": "To deflect, put the cursor on the shot and click just before it reaches you.",
	"rebound": "When you are hit, time slows and the screen turns red. Deflect any shot in that moment to come back.",
	"airjump": "In the air, press Space again to dash upward. Hold A or D to steer the dash.",
	"dash": "Shift dashes toward the cursor. It crosses gaps and gets you out of a crossfire.",
	"lane": "Deflect a shot, then press W or S at once to change lanes.",
}

## Burned onto the buildings at random while Sync is 200%+ (The Echo leaking through).
const ECHO_FRAGMENTS: PackedStringArray = [
	"WHO PULLED THE TRIGGER",
	"SHE WAS BEHIND YOU",
	"23:59:42",
	"LAZARUS FILES // CLASSIFIED",
	"COURIERS ARE AMMUNITION",
	"YOU WERE THE BOMB",
	"REMEMBER THE RAIN",
	"DON'T STABILIZE",
	"HER DIVISION // HER DRONES",
	"BOUNCE BACK",
]

## Shown under the title on the menu: the premise and the jam theme in one line.
const TAGLINE: String = "Shot off Tower 09 at midnight. Sixty seconds to bounce back."

## "beat" is the meaning of Bounce Back that the stage is built on. It shows on the stage card.
const STAGES: Array[Dictionary] = [
	{"title": "STAGE 01", "name": "THE AWAKENING ALLEY", "time": "0:00 - 0:50", "beat": "Bounce their bullets back."},
	{"title": "STAGE 02", "name": "THE DUAL-HIGHWAY OVERPASS", "time": "0:50 - 1:45", "beat": "Bounce between the lanes."},
	{"title": "STAGE 03", "name": "THE ASCENT SHAFT", "time": "1:45 - 2:35", "beat": "Bounce back up the tower."},
	{"title": "STAGE 04", "name": "ROOFTOP 09 // VALKYRIE GUNSHIP", "time": "2:35 - 3:30", "beat": "Bounce back from the fall."},
]

const MODULES: Array[Dictionary] = [
	{
		"name": "MODULE 01: CORTEX DASH RELAY",
		"q_name": "PHASE DASH",
		"q_desc": "Air-dash cooldown -40%. Dashing grants 0.25s of invulnerability.",
		"e_name": "SHOCKWAVE DASH",
		"e_desc": "Dashing through a projectile deflects it at 2x speed toward the nearest enemy.",
	},
	{
		"name": "MODULE 02: OPTIC Z-PRISM",
		"q_name": "CHRONO-SIGHT",
		"q_desc": "Time slows 30% for 0.5s when a sniper locks on. Blackout window extends to 2.2s.",
		"e_name": "PRISM SPLIT",
		"e_desc": "Every 3rd deflected shot splits into 2 crimson shards that home on targets.",
	},
	{
		"name": "MODULE 03: LIMBIC OVERDRIVE CORE",
		"q_name": "AEGIS CAPACITOR",
		"q_desc": "Hold Parry for a 0.4s omnidirectional kinetic barrier that eats barrages.",
		"e_name": "400% BERSERK LOCK",
		"e_desc": "Sync locked at 400%. Rally acceleration doubled. Every deflection is an explosive rail-shot.",
	},
]

const MODULE_COMMON: Dictionary = {
	"q_tag": "STABILIZE // LISTEN TO SARA",
	"q_extra": "+ wider parry window, longer Blackout, laser telegraph sights",
	"e_tag": "OVERCLOCK // LISTEN TO THE ECHO",
	"e_extra": "+ permanent +100% Sync floor, corrupted memories unlocked",
}

const ENDINGS: Dictionary = {
	"A": {
		"title": "ENDING A // CLEAN REBOOT",
		"body": "You disable Sara's gunship without losing your humanity. As the craft crashes onto the lower deck, you purge the corporate tracker from your Lazarus implant and vanish into the Neo-Dhaka skyline. A free human who bounced back from erasure.",
		"color": Color("#00F0FF"),
	},
	"B": {
		"title": "ENDING B // TOTAL OVERCLOCK // BERSERK",
		"body": "At 400% Sync the final rally obliterates the gunship. Your pre-wipe consciousness, The Echo, fully merges with your body. Standing on the edge of Rooftop 09, you hijack Sara's corporate comms network and broadcast the Lazarus files to every citizen in Warped City. By morning the whole city knows how a courier bounced back.",
		"color": Color("#FF0033"),
	},
	"C": {
		"title": "ENDING C // SYNAPSE EQUILIBRIUM",
		"body": "You balance human control with cybernetic fury. The final shot goes straight through the Gunship's engine core. You walk up to the smoking wreckage, recover your original encrypted courier briefcase, and step off the roof, gliding into the neon night on a controlled recoil bounce.",
		"color": Color("#FF9900"),
	},
}


func lines(id: String) -> Array:
	return LINES.get(id, [])


## The line a voice says when the player has died `n` times this run, or "" for most counts.
## Sara still plays the handler in Stages 1 and 2 and has dropped the act by Stage 3.
func loop_id(n: int, stage: int) -> String:
	if n in [3, 5, 8, 12]:
		return "loop_%s_%d" % ["a" if stage <= 2 else "b", n]
	if n >= 16 and n % 8 == 0:
		return "loop_many"
	return ""
