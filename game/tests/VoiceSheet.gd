extends SceneTree
## Writes the recording sheet for the voiced lines from DialogueData, so the sheet's file names
## always match the keys the game looks for.
##   godot --headless --path game --script res://tests/VoiceSheet.gd -- --out=<abs path>/VOICE_SCRIPT.md

const COLD: PackedStringArray = ["s3_rally", "s3_module", "s4_intro", "s4_phase2", "s4_phase3", "s4_win",
		"loop_b_3", "loop_b_8", "idle_b", "after_Q_3", "after_E_3"]


func _init() -> void:
	_run()


func _how(id: String, who: String) -> String:
	if who == "LOG":
		return "Quiet and tired, close to the microphone. He is recording an apology nobody is meant to hear."
	if id == "s4_win":
		return "Breaking. The gunship is going down."
	if id in COLD:
		return "The act is over. Cold, angry, giving orders."
	return "The handler. Warm, fast, urgent, on his side."


func _run() -> void:
	await process_frame
	var out: String = ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.get_slice("=", 1)
	var data: Node = root.get_node("DialogueData")
	var saif: Array = []
	var echo: Array = []
	for id: String in data.LINES:
		var all: Array = data.LINES[id]
		for i: int in all.size():
			var who: String = all[i]["who"]
			var row: Dictionary = {"key": "%s_%d" % [id, i + 1], "id": id, "who": who, "text": all[i]["text"]}
			if who == "SAIF" or who == "LOG":
				saif.append(row)
			elif who == "ECHO":
				echo.append(row)
	var md: PackedStringArray = []
	md.append("# SYNAPSE // REBOUND voice recording sheet")
	md.append("")
	md.append("Generated from `game/scripts/autoload/DialogueData.gd` by `game/tests/VoiceSheet.gd`. Do not edit the")
	md.append("file names: the game looks for them. If a line's wording changes, change it in DialogueData and")
	md.append("regenerate this sheet.")
	md.append("")
	md.append("## How to record")
	md.append("")
	md.append("- One file per line. Name it by its number (`07.wav`) or by its file name (`s1_intro_3.wav`). Any")
	md.append("  common format works: wav, mp3, m4a, ogg, flac.")
	md.append("- A phone held 15 to 20 cm from the mouth in a quiet room with soft furnishings is enough. The radio")
	md.append("  effect removes the low and high ends, so the room matters more than the microphone.")
	md.append("- Speak a little faster and flatter than feels natural. Radio voices are clipped and to the point.")
	md.append("- Leave half a second of silence before and after. The import step trims it and evens out the volume.")
	md.append("- Do not add any effect yourself. The game adds the radio filter, the static and the click.")
	md.append("- Put all the files in one folder and run:")
	md.append("  `py -I scripts\\import_voice.py <that folder>`")
	md.append("  A line with no recording stays as text, so a partial set is fine.")
	md.append("")
	md.append("## Saif (%d lines)" % saif.size())
	md.append("")
	md.append("| # | File name | Line | How to say it |")
	md.append("|---|---|---|---|")
	for i: int in saif.size():
		var r: Dictionary = saif[i]
		md.append("| %02d | `%s` | %s | %s |" % [i + 1, r["key"], String(r["text"]).replace("|", "/"), _how(r["id"], r["who"])])
	md.append("")
	md.append("## The Echo (%d lines, optional)" % echo.size())
	md.append("")
	md.append("The Echo is Vincent's own voice from before the memory wipe. The game lowers and degrades whatever is")
	md.append("recorded. Say these slowly and evenly, like someone reading a message they wrote for themselves. Name")
	md.append("the files by file name with an `echo_` prefix on the number (`echo_03.wav`) or by file name alone.")
	md.append("")
	md.append("| # | File name | Line |")
	md.append("|---|---|---|")
	for i: int in echo.size():
		var r: Dictionary = echo[i]
		md.append("| %02d | `%s` | %s |" % [i + 1, r["key"], String(r["text"]).replace("|", "/")])
	md.append("")
	md.append("## Joke takes (2, optional)")
	md.append("")
	md.append("Two short takes in your own voice, played as they are with no radio effect. Without them the game")
	md.append("plays a low thud for the first and nothing for the second.")
	md.append("")
	md.append("- `oh_hell_nah`: plays when Vincent goes down within three seconds of getting up. At most once every")
	md.append("  40 seconds. Say it the way the meme does, under two seconds.")
	md.append("- `hehe_boi`: plays the first time Saif's fire control calls a move wrong, and on every fifth miss")
	md.append("  after that. Smug, under two seconds.")
	md.append("")
	var f: FileAccess = FileAccess.open(out, FileAccess.WRITE)
	if f == null:
		push_error("VoiceSheet: cannot write " + out)
	else:
		f.store_string("\n".join(md))
		f.close()
		print("VOICESHEET saif=", saif.size(), " echo=", echo.size(), " out=", out)
	quit()
