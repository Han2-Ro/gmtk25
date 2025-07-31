extends Label

@export var start_lives = 3
@onready var current_lives = start_lives


func _on_sequence_controller_pressed_wrong(_btn: SequenceButton) -> void:
	current_lives -= 1
	self.text = "{0} Lives".format([current_lives])
	if current_lives <= 0:
		$"../Overlay".visible = true


func _on_restart_button_pressed() -> void:
	get_tree().reload_current_scene()
