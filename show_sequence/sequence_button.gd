extends TextureButton
class_name SequenceButton

@onready var initial_modulate = self.modulate


func _controller_ready(controller: SequenceController):
	controller.sequence_flash_start.connect(on_sequence_flash_start)
	controller.sequence_flash_end.connect(_reset)
	controller.pressed_correct.connect(_on_pressed_correct_button)


func on_sequence_flash_start():
	self._reset()
	self.disabled = true


func _on_pressed_correct_button(_btn):
	self._reset()


func flash():
	self.modulate = Color.GRAY
	await get_tree().create_timer(.8).timeout
	self.modulate = initial_modulate
	await get_tree().create_timer(.2).timeout


func _reset():
	self.disabled = false
	self.modulate = initial_modulate


func this_pressed_correct():
	self.modulate = Color.GREEN_YELLOW


func this_pressed_wrong():
	self.modulate = Color.INDIAN_RED
	self.disabled = true
