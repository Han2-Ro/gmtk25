extends Node3D

@onready var start_position: Vector3 = position


func on_sequence_flash_start() -> void:
	var tween = create_tween()
	tween.tween_property(self, "position", start_position, 0.3)
	await tween.finished
