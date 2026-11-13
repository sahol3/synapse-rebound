extends Node2D
## Boot scene. Proves the toolchain runs; replace once the real game starts.

const BOOT_MESSAGE: String = "Haven Dhaka boot OK"


func _ready() -> void:
	print(BOOT_MESSAGE)
	var label: Label = $Label
	label.text = BOOT_MESSAGE
