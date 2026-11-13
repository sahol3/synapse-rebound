extends Node
## Plays every AudioManager cue once, one per 0.8 s slot, with no music, so a movie-writer recording
## can prove each cue is audible. Slot 0 plays an unknown key on purpose and must stay silent
## (the negative control). Prints the slot order for scripts/sfx_probe_check.py.
## Record: Godot_console.exe --path game res://tests/SfxProbe.tscn --write-movie <ABS>\f.png --fixed-fps 30

const SLOT: float = 0.8


func _ready() -> void:
	var keys: Array = ["__silent_control__"]
	keys.append_array(AudioManager.CUES.keys())
	print("SFXPROBE slots=", ",".join(PackedStringArray(keys)))
	await get_tree().create_timer(0.5).timeout
	for k: String in keys:
		AudioManager.play_sfx(k)
		await get_tree().create_timer(SLOT).timeout
	get_tree().quit()
