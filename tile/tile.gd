class_name SequenceButton
extends Node3D

signal pressed

var disabled := false
# TODO: is there a better way to get the player?
@onready var player = get_tree().current_scene.find_child("Player", true, false)
@onready var original_position: Vector3 = self.position

@export var disabled_color: Color = Color.DIM_GRAY
@export var enabled_color: Color = Color.DEEP_PINK

var material: BaseMaterial3D


func _ready() -> void:
	# Connect to Area3D input_event signal for proper 3D click detection
	$Area3D.input_event.connect(_on_area_3d_input_event)


func _setup_material():
	# Look for MeshInstance3D in children (from imported 3D models)
	var mesh_holder = $Mesh
	var mesh_instance = mesh_holder.find_child("*", true, false) as MeshInstance3D
	var original_mesh: Mesh = mesh_instance.mesh
	# otherwise material overrides apply to all
	mesh_instance.mesh = original_mesh.duplicate()
	var new_material = mesh_instance.get_surface_override_material(0) as BaseMaterial3D
	if not new_material:
		new_material = mesh_instance.mesh.surface_get_material(0)
	new_material = new_material.duplicate()
	mesh_instance.set_surface_override_material(0, new_material)
	new_material.albedo_color = disabled_color

	return new_material


func _controller_ready(controller: SequenceController):
	material = _setup_material()
	on_sequence_flash_start()
	controller.sequence_flash_start.connect(on_sequence_flash_start)
	controller.sequence_flash_end.connect(_reset)
	controller.pressed_correct.connect(_on_pressed_correct_button)
	original_position = self.position


func on_sequence_flash_start():
	self.disabled = true
	var tween = create_tween()
	tween.tween_property(material, "albedo_color", disabled_color, 0.2)
	await tween.finished


func _on_pressed_correct_button(_btn):
	self._reset()


func flash():
	var tween = create_tween()
	tween.tween_property(self, "position", original_position + Vector3(0, 0.3, 0), 0.2)
	tween.parallel().tween_property(material, "albedo_color", enabled_color, 0.2)
	tween.tween_interval(0.6)
	tween.parallel().tween_property(material, "albedo_color", disabled_color, 0.2)
	tween.tween_property(self, "position", original_position, 0.2)

	await tween.finished


func _reset():
	self.show()

	var tween = create_tween()
	tween.tween_property(self, "position", original_position, 0.3)
	tween.parallel().tween_property(material, "albedo_color", enabled_color, 0.2)
	await tween.finished

	self.disabled = false


func this_pressed_correct():
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


func _on_area_3d_input_event(
	_camera: Camera3D, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int
) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not disabled:
			pressed.emit()
			print("tile clicked!")
