class_name SequenceButton
extends Node3D

signal pressed

var disabled := false
var mouse_inside := false
# TODO: is there a better way to get the player?
@onready var player = get_tree().current_scene.find_child("Player", true, false)
@onready var original_position: Vector3 = self.position


func _controller_ready(controller: SequenceController):
	controller.sequence_flash_start.connect(on_sequence_flash_start)
	controller.sequence_flash_end.connect(_reset)
	controller.pressed_correct.connect(_on_pressed_correct_button)


func on_sequence_flash_start():
	self.disabled = true


func _on_pressed_correct_button(_btn):
	self._reset()


func flash():
	print("flashing: ", self)

	var tween = create_tween()
	tween.tween_property(self, "position", original_position + Vector3(0, 0.3, 0), 0.2)
	tween.tween_interval(0.6)
	tween.tween_property(self, "position", original_position, 0.2)

	await tween.finished


func _reset():
	self.show()

	var tween = create_tween()
	tween.tween_property(self, "position", original_position, 0.3)
	await tween.finished

	self.disabled = false


func this_pressed_correct():
	var distance = player.position.distance_to(self.position)
	print(distance)
	var tween = create_tween()
	tween.tween_property(player, "position", self.position, 0.1)
	await tween.finished


func this_pressed_wrong():
	self.disabled = true

	# Shake animation - quick left-right movement
	var tween = create_tween()
	tween.set_loops(3)
	tween.tween_property(self, "position", original_position + Vector3(0.1, 0, 0), 0.05)
	tween.tween_property(self, "position", original_position + Vector3(-0.1, 0, 0), 0.05)
	tween.tween_property(self, "position", original_position, 0.05)
	tween.set_loops(1)
	tween.tween_property(self, "position", original_position + Vector3(0, -0.8, 0), 0.3)
	await tween.finished

	self.hide()


func _on_area_3d_mouse_entered() -> void:
	mouse_inside = true


func _on_area_3d_mouse_exited() -> void:
	mouse_inside = false


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if mouse_inside && !disabled:
			pressed.emit()
			print("tile clicked!")
