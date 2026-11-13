extends Node
## Every line of the Stage 1-4 script, the module choices and the endings.
## Speakers: SARA (cyan HUD comms, top-left), ECHO (crimson glitch toast),
## WORLD (giant kinetic typography burned onto the buildings), SYS (HUD banner).

const LINES: Dictionary = {
	# ---------------------------------------------------------------- STAGE 1
	"s1_intro": [
		{"who": "WORLD", "text": "00:00:00 // IMPACT AVOIDED // BOUNCING BACK -60.0s"},
		{"who": "SARA", "text": "Vincent?! Holy hell, your Lazarus implant actually fired! Listen to me. Syndicate hitters ambushed you on Tower 09 and stripped your weapons!"},
		{"who": "SARA", "text": "Your kinetic wrist-guard is still online. Aim at their fire and bounce it back into their teeth!"},
	],
	"s1_tutorial": [
		{"who": "SYS", "text": "Click to deflect toward the cursor. Space jumps, Shift air-dashes."},
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
		{"who": "SYS", "text": "The floor is gone. Chain deflections in the air to climb. Gold drones rally back."},
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
		{"who": "SYS", "text": "Blackout. Deflect any shot before the timer runs out to rebound."},
	],
	"first_rebound": [
		{"who": "ECHO", "text": "There it is. We always bounce back."},
	],
	"berserk": [
		{"who": "WORLD", "text": "BERSERK OVERDRIVE"},
	],
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

const STAGES: Array[Dictionary] = [
	{"title": "STAGE 01", "name": "THE AWAKENING ALLEY", "time": "0:00 - 0:50"},
	{"title": "STAGE 02", "name": "THE DUAL-HIGHWAY OVERPASS", "time": "0:50 - 1:45"},
	{"title": "STAGE 03", "name": "THE ASCENT SHAFT", "time": "1:45 - 2:35"},
	{"title": "STAGE 04", "name": "ROOFTOP 09 // VALKYRIE GUNSHIP", "time": "2:35 - 3:30"},
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
		"body": "At 400% Sync the final rally obliterates the gunship. Your pre-wipe consciousness, The Echo, fully merges with your body. Standing on the edge of Rooftop 09, you hijack Sara's corporate comms network and broadcast the Lazarus files to every citizen in Warped City.",
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
