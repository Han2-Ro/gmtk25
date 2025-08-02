extends Node3D

@onready var start_position: Vector3 = position


func reset_position() -> void:
	var tween = create_tween()
	tween.tween_property(self, "position", start_position, 0.3)
	await tween.finished


func _on_subsequence_completed(_current, total) -> void:
	await create_tween().tween_interval(0.5).finished
	await reset_position()

func _on_pressed_wrong(_btn) -> void:
	await reset_position()

func setup(sequence_controller: SequenceController) -> void:
	sequence_controller.subsequence_completed.connect(_on_subsequence_completed)
	sequence_controller.pressed_wrong.connect(_on_pressed_wrong)
