extends Node
## Every line of the Stage 1-4 script, the module choices and the endings.
## Speakers: SAIF (cyan HUD comms, top-left), ECHO (crimson glitch toast), LOG (a recording of
## Saif's voice that the Echo plays back),
## WORLD (giant kinetic typography burned onto the buildings), SYS (HUD banner).

const LINES: Dictionary = {
	# ---------------------------------------------------------------- ADAPTIVE DIRECTOR
	"assist_ease": [
		{"who": "SAIF", "text": "I'm jamming their fire control. Their shots are slower now, so watch one and send it back."},
	],
	"assist_hard": [
		{"who": "ECHO", "text": "They have stopped holding back. So have you."},
	],
	# ---------------------------------------------------------------- STAGE 1
	"s1_intro": [
		{"who": "WORLD", "text": "00:00:00 // IMPACT AVOIDED // BOUNCING BACK -60.0s"},
		{"who": "SAIF", "text": "Vincent?! Holy hell, your Lazarus implant actually fired! Listen to me. Syndicate hitters ambushed you on Tower 09 and stripped your weapons!"},
		{"who": "SAIF", "text": "Your kinetic wrist-guard is still online. Aim at their fire and bounce it back into their teeth!"},
	],
	"s1_tutorial": [
		{"who": "SYS", "text": "Click to deflect toward the cursor. Space jumps, and Space again in the air dashes upward. Shift dashes toward the cursor."},
	],
	"s1_pogo": [
		{"who": "SYS", "text": "Deflect in mid-air to recoil off the shot. It gives your air-dash back."},
	],
	"s1_first_kill": [
		{"who": "SAIF", "text": "Clean deflection! Keep climbing the scaffolding, I'm holding an extraction shuttle on the roof!"},
	],
	"s1_echo": [
		{"who": "WORLD", "text": "NO SYNDICATE ON THE ROOF."},
		{"who": "ECHO", "text": "...Why is he lying about the extraction shuttle? Check the ballistic angle on your chest plate..."},
	],
	"s1_enforcer": [
		{"who": "SAIF", "text": "Syndicate Enforcer! His kinetic shield throws your deflection straight back. Keep the rally going until the shot goes supernova!"},
		{"who": "SYS", "text": "Keep parrying what the shield throws back. The third bounce becomes a railgun."},
	],
	"s1_module": [
		{"who": "SAIF", "text": "You got your Dash Relay back! Don't overclock it, Vincent. Your neural sync will spike and burn out your memory core. Press [Q] to Stabilize!"},
		{"who": "ECHO", "text": "Stabilizing it keeps the memory blocks locked. Overclock it [E]. Remember who was standing behind you in the rain."},
	],
	# ---------------------------------------------------------------- STAGE 2
	"s2_intro": [
		{"who": "SAIF", "text": "Snipers on the parallel overpass! Use heavy recoil or the kinetic rings to bounce yourself across lanes!"},
		{"who": "SYS", "text": "Press W or S right after a deflection, or touch a Z-ring, to change lanes. Parry sniper shots back into the depth."},
	],
	"s2_first_lane": [
		{"who": "WORLD", "text": "HE LOCKED YOUR HOLSTER."},
		{"who": "ECHO", "text": "Memory fragment restored: 23:58. Two minutes before the fall. Only two people had the encryption key to disable your sidearm. You... and Saif."},
	],
	"s2_wallslam": [
		{"who": "SYS", "text": "Hit a wall and deflect within 0.1s to ricochet off it."},
	],
	"s2_ambush": [
		{"who": "SAIF", "text": "Vincent, your cortical telemetry is spiking! Stop listening to those feedback ghosts. The Lazarus rewind scrambles short-term memory!"},
	],
	"s2_heavy": [
		{"who": "SAIF", "text": "Highway Heavy! Double shielding. You'll need two supernova rallies to crack it."},
	],
	"s2_module": [
		{"who": "SAIF", "text": "That's your Optic Prism! Stabilize it [Q] now so I can guide you safely up the central shaft!"},
		{"who": "ECHO", "text": "He doesn't want your optics running at full resolution. Overclock it [E] and look at the IFF tags on these drones. They're HIS division."},
	],
	# ---------------------------------------------------------------- STAGE 3
	"s3_intro": [
		{"who": "WORLD", "text": "CLIMB BACK TO THE SCENE OF THE CRIME."},
		{"who": "SAIF", "text": "Wait. Why are you taking the express shaft straight to Rooftop 09?! The landing pad is too hot, turn back to Sector 4!"},
		{"who": "SYS", "text": "The floor is gone. Jump, then press Space again to dash upward. A deflection in the air gives the dash back."},
	],
	"s3_rally": [
		{"who": "ECHO", "text": "Audio log recovered. 23:59:42, eighteen seconds before the fall."},
		{"who": "LOG", "text": "I'm sorry, Vincent. Command says if a courier reads the Lazarus files, we pull the plug."},
		{"who": "ECHO", "text": "That was his voice."},
		{"who": "SAIF", "text": "Shut it down, Vincent! You weren't supposed to survive a 90-story drop! Why won't you just stay down?!"},
	],
	"s3_module": [
		{"who": "SAIF", "text": "Last warning, Courier. Stabilize that core [Q] and surrender at the roof door, or I will personally vaporize what's left of your nervous system."},
		{"who": "ECHO", "text": "60 seconds are up. We're back on the roof where we died. Overclock the core [E]. Let's return the bullet he gave us."},
	],
	# ---------------------------------------------------------------- STAGE 4
	"s4_intro": [
		{"who": "WORLD", "text": "ROOFTOP 09 // 00:00:00"},
		{"who": "SAIF", "text": "You really came back. Fine. The Valkyrie doesn't miss twice."},
		{"who": "SYS", "text": "Deflect his plasma into the wing turrets."},
	],
	"s4_phase2": [
		{"who": "SAIF", "text": "Pulling back to the depth lane. Let's see you bounce across ninety stories of air."},
		{"who": "SYS", "text": "Parry the rail missiles back across the depth plane. Z-rings and W or S change lanes."},
	],
	"s4_phase3": [
		{"who": "SAIF", "text": "Cockpit deflector online! Every shot you send, I send back. You can't win a rally against a gunship!"},
		{"who": "ECHO", "text": "Five bounces. That's all it takes. He taught us that."},
		{"who": "SYS", "text": "Five bounces to break the core. Don't drop it."},
		{"who": "ECHO", "text": "His fire control is ours now. The blue outline is where he will be."},
	],
	"s4_win": [
		{"who": "SAIF", "text": "No... no, no, NO..."},
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
		{"who": "SAIF", "text": "That was the Lazarus implant. It throws you back a few seconds every time you die. Get up and go again."},
	],
	"loop_a_3": [
		{"who": "SAIF", "text": "The implant caught you again. It will not hold forever, Vincent. Stay behind cover and let me guide you."},
	],
	"loop_a_5": [
		{"who": "ECHO", "text": "Five loops. Every one of them ends with you on your feet."},
	],
	"loop_a_8": [
		{"who": "SAIF", "text": "Your telemetry looks like static. Stop pushing forward and wait for my signal."},
	],
	"loop_a_12": [
		{"who": "ECHO", "text": "Twelve loops. He keeps asking you to wait. Ask yourself what he is waiting for."},
	],
	"loop_b_3": [
		{"who": "SAIF", "text": "Every rewind burns away a little more of you. Stay down this time."},
	],
	"loop_b_5": [
		{"who": "ECHO", "text": "He shot us once. We have come back five times. Do the arithmetic for him."},
	],
	"loop_b_8": [
		{"who": "SAIF", "text": "How many times do I have to kill you, Courier?"},
	],
	"loop_b_12": [
		{"who": "ECHO", "text": "Twelve loops. He is running out of ways to say stay down."},
	],
	"loop_many": [
		{"who": "ECHO", "text": "Count the loops if you like. The one that matters is the last."},
	],
	"rebound_3": [
		{"who": "ECHO", "text": "Three hits that should have ended it. Three shots sent back. Keep that feeling."},
	],
	"rebound_7": [
		{"who": "ECHO", "text": "Seven times he has put us on the floor. Seven times we got up. He is counting too."},
	],
	"rally_3": [
		{"who": "ECHO", "text": "Third bounce. The shot comes back harder every time. So do we."},
	],
	# ------------------------------------------------------------ the two voices answer the module choice
	"after_Q_1": [
		{"who": "SAIF", "text": "Good. You kept the relay stable. Keep trusting me and I will get you out of this."},
		{"who": "ECHO", "text": "He sounded relieved. Ask yourself what a handler has to be relieved about."},
	],
	"after_E_1": [
		{"who": "SAIF", "text": "You overclocked it? Vincent, that relay will cook your memory. Do not do that again."},
		{"who": "ECHO", "text": "One block gone. I can see rain on the roof, and someone standing behind us."},
	],
	"after_Q_2": [
		{"who": "SAIF", "text": "Optics stable. That is two for two. You are doing exactly what I need."},
		{"who": "ECHO", "text": "Exactly what he needs. Listen to how he said that."},
	],
	"after_E_2": [
		{"who": "SAIF", "text": "Stop. You are reading tags you were never cleared to read."},
		{"who": "ECHO", "text": "His division. His drones. Now you can read the tags yourself."},
	],
	"after_Q_3": [
		{"who": "SAIF", "text": "Core stable. It will not save you up here."},
		{"who": "ECHO", "text": "Stable or not, we are standing where we fell. Finish it."},
	],
	"after_E_3": [
		{"who": "SAIF", "text": "Four hundred percent. You have burned out everything I left in you."},
		{"who": "ECHO", "text": "Everything he left in us was a leash. Finish it."},
	],
	# ------------------------------------------------------------ fire control: he has a model of you
	"pred_first": [
		{"who": "ECHO", "text": "That outline is his fire control. He trained it on forty of our deliveries. Be someone he has not met."},
	],
	"pred_miss_a": [
		{"who": "SAIF", "text": "Your movement profile is drifting, Vincent. Hold a steady line so I can cover you."},
	],
	"pred_miss_b": [
		{"who": "SAIF", "text": "Stop changing your ---- pattern. I know every route you have ever run.", "sfx": "meme_beep"},
		{"who": "ECHO", "text": "Not this one."},
	],
	"pred_npc": [
		{"who": "ECHO", "text": "Five calls in a row. You are moving like an NPC. Break the pattern."},
	],
	"idle_aura": [
		{"who": "ECHO", "text": "Aura farming on a rooftop. He can still see you."},
	],
	# ------------------------------------------------------------ Saif wants you slow
	"sync_high": [
		{"who": "SAIF", "text": "Your sync is climbing too fast. Ease off, Vincent. Slow is how you stay alive."},
		{"who": "ECHO", "text": "Slow is how he keeps us small."},
	],
	"idle_a": [
		{"who": "SAIF", "text": "Vincent? Your signal has gone flat. Keep moving."},
	],
	"idle_b": [
		{"who": "SAIF", "text": "Standing still, Courier? Good. Stay right there."},
	],
	# ------------------------------------------------------------ Continue: where we were
	"resume_1": [
		{"who": "ECHO", "text": "Back in the alley. Someone shot us off the roof, and Saif says it was a syndicate. Keep climbing."},
	],
	"resume_2": [
		{"who": "ECHO", "text": "The overpass. Our holster was locked from the inside. Remember that when he talks."},
	],
	"resume_3": [
		{"who": "ECHO", "text": "The shaft. We heard his voice on the recording. The roof is straight up."},
	],
	"resume_4": [
		{"who": "ECHO", "text": "Rooftop 09. He is in the gunship. Send everything back."},
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
	"Send his shots back: the wing turrets first, then the hull, then five bounces off the cockpit.",
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
	"HE WAS BEHIND YOU",
	"23:59:42",
	"LAZARUS FILES // CLASSIFIED",
	"COURIERS ARE AMMUNITION",
	"YOU WERE THE BOMB",
	"REMEMBER THE RAIN",
	"DON'T STABILIZE",
	"HIS DIVISION // HIS DRONES",
	"BOUNCE BACK",
]

## The three reveals the plot turns on. Time slows for two seconds when one starts, so the player
## can take it in.
const FOCUS: PackedStringArray = ["s1_echo", "s2_first_lane", "s3_rally"]

## Shown once before a new game, one line at a time. Any key skips it.
const PROLOGUE: PackedStringArray = [
	"23:59. The roof of Tower 09, Neo-Dhaka.",
	"Someone you trusted takes your gun, wipes your memory and shoots you off the edge.",
	"One second before the street, the implant in your spine throws you back sixty seconds.",
	"You have a wrist-guard that sends shots back, and a tower to climb.",
]

## The Lore tab. Entries without "how" are readable from the start; the rest are recovered by
## playing, and a locked entry shows its title and what recovers it.
const MEMORIES: Array[Dictionary] = [
	{"id": "vincent", "title": "VINCENT-09",
		"text": "You are a courier in Neo-Dhaka. You carry sealed cases between towers and you do not open them. At midnight someone took your modules, locked your weapons, wiped your memory and shot you off the roof of Tower 09."},
	{"id": "lazarus", "title": "THE LAZARUS IMPLANT",
		"text": "Hardware in your spine. A moment before you hit the street it threw you back sixty seconds, onto the scaffolding below the roof. It still fires every time you die, a few seconds at a time."},
	{"id": "voices", "title": "TWO VOICES",
		"text": "Saif is your handler, live on the comms. The Echo is a recording you left for yourself before the wipe. Saif says a rival syndicate shot you. The Echo says to check who was standing behind you."},
	{"id": "guard", "title": "THE WRIST-GUARD", "how": "Send 25 shots back.",
		"text": "They locked your sidearm and left the kinetic guard on your wrist, because a guard cannot fire. It returns whatever it is given, and it returns it faster."},
	{"id": "blackout", "title": "BLACKOUT", "how": "Come back from a Blackout.",
		"text": "The implant's last second before a rewind. Send one shot back inside it and the rewind is cancelled. You stay on your feet."},
	{"id": "third", "title": "THE THIRD BOUNCE", "how": "Hold a rally for 5 bounces.",
		"text": "A shot gains speed each time it is sent back. Enforcers carry shields that return your deflection. By the third return the shot is fast enough to go through the shield."},
	{"id": "firecontrol", "title": "FIRE CONTROL", "how": "Make his prediction miss 10 times.",
		"text": "The gunship's targeting was trained on forty of your delivery runs. It draws where it expects you to be and sends part of every shot there. Each habit you break is a shot that lands where you are not."},
	{"id": "holster", "title": "THE HOLSTER", "how": "Reach the Overpass.",
		"text": "Your sidearm was locked at 23:58, two minutes before the fall. Two people held the key. You were one of them."},
	{"id": "2359", "title": "23:59:42", "how": "Reach the Ascent Shaft.",
		"text": "Eighteen seconds before midnight a voice on the command channel said it was sorry. The Echo kept the recording. You know the voice."},
	{"id": "files", "title": "THE LAZARUS FILES", "how": "Reach Rooftop 09.",
		"text": "The case you opened. The company fits its couriers with implants and uses them as weapons, and the file says what happens to a courier who reads it."},
	{"id": "saif", "title": "SAIF", "how": "Finish the game.",
		"text": "There was no syndicate on the roof. Saif took the order, locked your holster and flew the gunship himself. He spent the whole climb asking you to stay weak."},
	{"id": "end_A", "title": "CLEAN REBOOT", "how": "Finish with every module stabilized.",
		"text": "You walk away as yourself. The tracker is purged and nobody else has read the files."},
	{"id": "end_B", "title": "TOTAL OVERCLOCK", "how": "Finish with every module overclocked.",
		"text": "The Echo takes the body back, and the whole city receives the files."},
	{"id": "end_C", "title": "EQUILIBRIUM", "how": "Finish with a mix of both.",
		"text": "You keep both voices and leave the roof with the case."},
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
	"q_tag": "STABILIZE // LISTEN TO SAIF",
	"q_extra": "+ wider parry window, longer Blackout, laser telegraph sights",
	"e_tag": "OVERCLOCK // LISTEN TO THE ECHO",
	"e_extra": "+ permanent +100% Sync floor, corrupted memories unlocked",
}

const ENDINGS: Dictionary = {
	"A": {
		"title": "ENDING A // CLEAN REBOOT",
		"body": "You disable Saif's gunship without losing your humanity. As the craft crashes onto the lower deck, you purge the corporate tracker from your Lazarus implant and vanish into the Neo-Dhaka skyline. A free human who bounced back from erasure.",
		"color": Color("#00F0FF"),
	},
	"B": {
		"title": "ENDING B // TOTAL OVERCLOCK // BERSERK",
		"body": "At 400% Sync the final rally obliterates the gunship. Your pre-wipe consciousness, The Echo, fully merges with your body. Standing on the edge of Rooftop 09, you hijack Saif's corporate comms network and broadcast the Lazarus files to every citizen in Warped City. By morning the whole city knows how a courier bounced back.",
		"color": Color("#FF0033"),
	},
	"C": {
		"title": "ENDING C // SYNAPSE EQUILIBRIUM",
		"body": "You balance human control with cybernetic fury. The final shot goes straight through the Gunship's engine core. You walk up to the smoking wreckage, recover your original encrypted courier briefcase, and step off the roof, gliding into the neon night on a controlled recoil bounce.",
		"color": Color("#FF9900"),
	},
}


## The second page of each ending: where everyone is after the part the ending tells.
const EPILOGUE: Dictionary = {
	"A": [
		{"who": "VINCENT", "text": "He took a room above a noodle bar in Sector 4, under a name that is on no courier list. He still wakes at midnight. He has not carried a sealed case since."},
		{"who": "SAIF", "text": "He climbed out of the wreck with a broken arm and a report to write. The report says the courier died in the fall. Command accepted it, and he has never corrected it."},
		{"who": "THE ECHO", "text": "The recording stayed locked behind the stabilized blocks. Some nights it plays a few seconds of rain and then stops."},
		{"who": "THE LAZARUS FILES", "text": "Nobody else has read them. The company still fits its couriers with implants."},
	],
	"B": [
		{"who": "VINCENT", "text": "The man who carried the cases is gone. The one who walked down from Rooftop 09 remembers everything and answers to the name he had before the wipe."},
		{"who": "SAIF", "text": "He did not leave the gunship. His last transmission was an order to fire, sent to turrets that were already down."},
		{"who": "THE ECHO", "text": "It stopped being a recording when the last block broke. There is one voice now."},
		{"who": "NEO-DHAKA", "text": "By morning every screen in the city carried the files. Forty couriers walked off shift that day, and the company's towers went dark one floor at a time."},
	],
	"C": [
		{"who": "VINCENT", "text": "He kept the case and both voices. He sells nothing from it. He delivers it one page at a time to the people named inside."},
		{"who": "SAIF", "text": "He survived the crash and woke in a company clinic with a courier's implant in his own spine. Command does not waste trained staff."},
		{"who": "THE ECHO", "text": "It still argues with him. He has stopped calling it a recording."},
		{"who": "NEO-DHAKA", "text": "The couriers named in the file have started to leave, one tower at a time. Nobody at the company can work out who is telling them."},
	],
}


func lines(id: String) -> Array:
	return LINES.get(id, [])


func memory(id: String) -> Dictionary:
	for m: Dictionary in MEMORIES:
		if m["id"] == id:
			return m
	return {}


## The line a voice says when the player has died `n` times this run, or "" for most counts.
## Saif still plays the handler in Stages 1 and 2 and has dropped the act by Stage 3.
func loop_id(n: int, stage: int) -> String:
	if n in [3, 5, 8, 12]:
		return "loop_%s_%d" % ["a" if stage <= 2 else "b", n]
	if n >= 16 and n % 8 == 0:
		return "loop_many"
	return ""
