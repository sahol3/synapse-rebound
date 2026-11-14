# SYNAPSE // REBOUND voice recording sheet

Generated from `game/scripts/autoload/DialogueData.gd` by `game/tests/VoiceSheet.gd`. Do not edit the
file names: the game looks for them. If a line's wording changes, change it in DialogueData and
regenerate this sheet.

## How to record

- One file per line. Name it by its number (`07.wav`) or by its file name (`s1_intro_3.wav`). Any
  common format works: wav, mp3, m4a, ogg, flac.
- A phone held 15 to 20 cm from the mouth in a quiet room with soft furnishings is enough. The radio
  effect removes the low and high ends, so the room matters more than the microphone.
- Speak a little faster and flatter than feels natural. Radio voices are clipped and to the point.
- Leave half a second of silence before and after. The import step trims it and evens out the volume.
- Do not add any effect yourself. The game adds the radio filter, the static and the click.
- Put all the files in one folder and run:
  `py -I scripts\import_voice.py <that folder>`
  A line with no recording stays as text, so a partial set is fine.

## Sara (34 lines)

| # | File name | Line | How to say it |
|---|---|---|---|
| 01 | `assist_ease_1` | I'm jamming their fire control. Their shots are slower now, so watch one and send it back. | The handler. Warm, fast, urgent, on his side. |
| 02 | `s1_intro_2` | Vincent?! Holy hell, your Lazarus implant actually fired! Listen to me. Syndicate hitters ambushed you on Tower 09 and stripped your weapons! | The handler. Warm, fast, urgent, on his side. |
| 03 | `s1_intro_3` | Your kinetic wrist-guard is still online. Aim at their fire and bounce it back into their teeth! | The handler. Warm, fast, urgent, on his side. |
| 04 | `s1_first_kill_1` | Clean deflection! Keep climbing the scaffolding, I'm holding an extraction shuttle on the roof! | The handler. Warm, fast, urgent, on his side. |
| 05 | `s1_enforcer_1` | Syndicate Enforcer! His kinetic shield throws your deflection straight back. Keep the rally going until the shot goes supernova! | The handler. Warm, fast, urgent, on his side. |
| 06 | `s1_module_1` | You got your Dash Relay back! Don't overclock it, Vincent. Your neural sync will spike and burn out your memory core. Press [Q] to Stabilize! | The handler. Warm, fast, urgent, on his side. |
| 07 | `s2_intro_1` | Snipers on the parallel overpass! Use heavy recoil or the kinetic rings to bounce yourself across lanes! | The handler. Warm, fast, urgent, on his side. |
| 08 | `s2_ambush_1` | Vincent, your cortical telemetry is spiking! Stop listening to those feedback ghosts. The Lazarus rewind scrambles short-term memory! | The handler. Warm, fast, urgent, on his side. |
| 09 | `s2_heavy_1` | Highway Heavy! Double shielding. You'll need two supernova rallies to crack it. | The handler. Warm, fast, urgent, on his side. |
| 10 | `s2_module_1` | That's your Optic Prism! Stabilize it [Q] now so I can guide you safely up the central shaft! | The handler. Warm, fast, urgent, on his side. |
| 11 | `s3_intro_2` | Wait. Why are you taking the express shaft straight to Rooftop 09?! The landing pad is too hot, turn back to Sector 4! | The handler. Warm, fast, urgent, on his side. |
| 12 | `s3_rally_2` | I'm sorry, Vincent. Command says if a courier reads the Lazarus files, we pull the plug. | Quiet and tired, close to the microphone. She is recording an apology nobody is meant to hear. |
| 13 | `s3_rally_4` | Shut it down, Vincent! You weren't supposed to survive a 90-story drop! Why won't you just stay down?! | The act is over. Cold, angry, giving orders. |
| 14 | `s3_module_1` | Last warning, Courier. Stabilize that core [Q] and surrender at the roof door, or I will personally vaporize what's left of your nervous system. | The act is over. Cold, angry, giving orders. |
| 15 | `s4_intro_2` | You really came back. Fine. The Valkyrie doesn't miss twice. | The act is over. Cold, angry, giving orders. |
| 16 | `s4_phase2_1` | Pulling back to the depth lane. Let's see you bounce across ninety stories of air. | The act is over. Cold, angry, giving orders. |
| 17 | `s4_phase3_1` | Cockpit deflector online! Every shot you send, I send back. You can't win a rally against a gunship! | The act is over. Cold, angry, giving orders. |
| 18 | `s4_win_1` | No... no, no, NO... | Breaking. The gunship is going down. |
| 19 | `first_death_s1_1` | That was the Lazarus implant. It throws you back a few seconds every time you die. Get up and go again. | The handler. Warm, fast, urgent, on his side. |
| 20 | `loop_a_3_1` | The implant caught you again. It will not hold forever, Vincent. Stay behind cover and let me guide you. | The handler. Warm, fast, urgent, on his side. |
| 21 | `loop_a_8_1` | Your telemetry looks like static. Stop pushing forward and wait for my signal. | The handler. Warm, fast, urgent, on his side. |
| 22 | `loop_b_3_1` | Every rewind burns away a little more of you. Stay down this time. | The act is over. Cold, angry, giving orders. |
| 23 | `loop_b_8_1` | How many times do I have to kill you, Courier? | The act is over. Cold, angry, giving orders. |
| 24 | `after_Q_1_1` | Good. You kept the relay stable. Keep trusting me and I will get you out of this. | The handler. Warm, fast, urgent, on his side. |
| 25 | `after_E_1_1` | You overclocked it? Vincent, that relay will cook your memory. Do not do that again. | The handler. Warm, fast, urgent, on his side. |
| 26 | `after_Q_2_1` | Optics stable. That is two for two. You are doing exactly what I need. | The handler. Warm, fast, urgent, on his side. |
| 27 | `after_E_2_1` | Stop. You are reading tags you were never cleared to read. | The handler. Warm, fast, urgent, on his side. |
| 28 | `after_Q_3_1` | Core stable. It will not save you up here. | The act is over. Cold, angry, giving orders. |
| 29 | `after_E_3_1` | Four hundred percent. You have burned out everything I left in you. | The act is over. Cold, angry, giving orders. |
| 30 | `pred_miss_a_1` | Your movement profile is drifting, Vincent. Hold a steady line so I can cover you. | The handler. Warm, fast, urgent, on his side. |
| 31 | `pred_miss_b_1` | Stop changing your ---- pattern. I know every route you have ever run. | The handler. Warm, fast, urgent, on his side. |
| 32 | `sync_high_1` | Your sync is climbing too fast. Ease off, Vincent. Slow is how you stay alive. | The handler. Warm, fast, urgent, on his side. |
| 33 | `idle_a_1` | Vincent? Your signal has gone flat. Keep moving. | The handler. Warm, fast, urgent, on his side. |
| 34 | `idle_b_1` | Standing still, Courier? Good. Stay right there. | The act is over. Cold, angry, giving orders. |

## The Echo (35 lines, optional)

The Echo is Vincent's own voice from before the memory wipe. The game lowers and degrades whatever is
recorded. Say these slowly and evenly, like someone reading a message they wrote for themselves. Name
the files by file name with an `echo_` prefix on the number (`echo_03.wav`) or by file name alone.

| # | File name | Line |
|---|---|---|
| 01 | `assist_hard_1` | They have stopped holding back. So have you. |
| 02 | `s1_echo_2` | ...Why is she lying about the extraction shuttle? Check the ballistic angle on your chest plate... |
| 03 | `s1_module_2` | Stabilizing it keeps the memory blocks locked. Overclock it [E]. Remember who was standing behind you in the rain. |
| 04 | `s2_first_lane_2` | Memory fragment restored: 23:58. Two minutes before the fall. Only two people had the encryption key to disable your sidearm. You... and Sara. |
| 05 | `s2_module_2` | She doesn't want your optics running at full resolution. Overclock it [E] and look at the IFF tags on these drones. They're HER division. |
| 06 | `s3_rally_1` | Audio log recovered. 23:59:42, eighteen seconds before the fall. |
| 07 | `s3_rally_3` | That was her voice. |
| 08 | `s3_module_2` | 60 seconds are up. We're back on the roof where we died. Overclock the core [E]. Let's return the bullet she gave us. |
| 09 | `s4_phase3_2` | Five bounces. That's all it takes. She taught us that. |
| 10 | `s4_phase3_4` | Her fire control is ours now. The blue outline is where she will be. |
| 11 | `first_death_1` | Rewind. Again. You've died on this roof before, Vincent. Count the loops. |
| 12 | `first_rebound_1` | There it is. We always bounce back. |
| 13 | `loop_a_5_1` | Five loops. Every one of them ends with you on your feet. |
| 14 | `loop_a_12_1` | Twelve loops. She keeps asking you to wait. Ask yourself what she is waiting for. |
| 15 | `loop_b_5_1` | She shot us once. We have come back five times. Do the arithmetic for her. |
| 16 | `loop_b_12_1` | Twelve loops. She is running out of ways to say stay down. |
| 17 | `loop_many_1` | Count the loops if you like. The one that matters is the last. |
| 18 | `rebound_3_1` | Three hits that should have ended it. Three shots sent back. Keep that feeling. |
| 19 | `rebound_7_1` | Seven times she has put us on the floor. Seven times we got up. She is counting too. |
| 20 | `rally_3_1` | Third bounce. The shot comes back harder every time. So do we. |
| 21 | `after_Q_1_2` | She sounded relieved. Ask yourself what a handler has to be relieved about. |
| 22 | `after_E_1_2` | One block gone. I can see rain on the roof, and someone standing behind us. |
| 23 | `after_Q_2_2` | Exactly what she needs. Listen to how she said that. |
| 24 | `after_E_2_2` | Her division. Her drones. Now you can read the tags yourself. |
| 25 | `after_Q_3_2` | Stable or not, we are standing where we fell. Finish it. |
| 26 | `after_E_3_2` | Everything she left in us was a leash. Finish it. |
| 27 | `pred_first_1` | That outline is her fire control. She trained it on forty of our deliveries. Be someone she has not met. |
| 28 | `pred_miss_b_2` | Not this one. |
| 29 | `pred_npc_1` | Five calls in a row. You are moving like an NPC. Break the pattern. |
| 30 | `idle_aura_1` | Aura farming on a rooftop. She can still see you. |
| 31 | `sync_high_2` | Slow is how she keeps us small. |
| 32 | `resume_1_1` | Back in the alley. Someone shot us off the roof, and Sara says it was a syndicate. Keep climbing. |
| 33 | `resume_2_1` | The overpass. Our holster was locked from the inside. Remember that when she talks. |
| 34 | `resume_3_1` | The shaft. We heard her voice on the recording. The roof is straight up. |
| 35 | `resume_4_1` | Rooftop 09. She is in the gunship. Send everything back. |

## Joke takes (2, optional)

Two short takes in your own voice, played as they are with no radio effect. Without them the game
plays a low thud for the first and nothing for the second.

- `oh_hell_nah`: plays when Vincent goes down within three seconds of getting up. At most once every
  40 seconds. Say it the way the meme does, under two seconds.
- `hehe_boi`: plays the first time Sara's fire control calls a move wrong, and on every fifth miss
  after that. Smug, under two seconds.
