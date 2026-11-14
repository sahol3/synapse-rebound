extends Node

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
