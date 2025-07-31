class_name SequenceButton
extends Node3D

signal pressed

var disabled := false
var mouse_inside := false
# TODO: is there a better way to get the player?
@onready var player = get_tree().current_scene.find_child("Player", true, false)


func _ready() -> void:
	pass


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
	print("flashing: ", self)
	self.translate(Vector3(0, 0.3, 0))
	await get_tree().create_timer(.8).timeout
	self.translate(Vector3(0, -0.3, 0))
	await get_tree().create_timer(.2).timeout


func _reset():
	self.show()
	self.disabled = false


func this_pressed_correct():
	player.transform = self.transform


func this_pressed_wrong():
	self.hide()
	self.disabled = true


func _on_area_3d_mouse_entered() -> void:
	mouse_inside = true
	print("mouse entered")


func _on_area_3d_mouse_exited() -> void:
	mouse_inside = false
	print("mouse exited")


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if mouse_inside && !disabled:
			pressed.emit()
			print("tile clicked!")
