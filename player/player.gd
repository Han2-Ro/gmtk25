extends Node3D

var start_position: Transform3D


func _ready() -> void:
	start_position = self.transform


func on_sequence_flash_start() -> void:
	var tween = create_tween()
	tween.tween_property(self, "position", start_position.origin, 0.3)
	await tween.finished
