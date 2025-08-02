class_name SequenceButton
extends Node3D

signal pressed

var disabled := false:
	set(input):
		disabled = input
		# Change color based on disabled state
		if mesh:
			if disabled:
				set_albedo_color(Color.GRAY)
			else:
				set_albedo_color(Color.WHITE)  # or your default color
# TODO: is there a better way to get the player?
@onready var player = get_tree().current_scene.find_child("Player", true, false)
@onready var original_position: Vector3 = self.position

@export var mesh: MeshInstance3D


func _ready() -> void:
	# Connect to Area3D input_event signal for proper 3D click detection
	$Area3D.input_event.connect(_on_area_3d_input_event)
	
	# Auto-assign mesh if not set in editor
	if not mesh:
		# Look for MeshInstance3D in children (from imported 3D models)
		for child in get_children():
			var mesh_instance = child.find_child("*", true, false) as MeshInstance3D
			if mesh_instance:
				mesh = mesh_instance
				break



func _controller_ready(controller: SequenceController):
	controller.sequence_flash_start.connect(on_sequence_flash_start)
	controller.sequence_flash_end.connect(_reset)
	controller.pressed_correct.connect(_on_pressed_correct_button)
	original_position = self.position


func on_sequence_flash_start():
	self.disabled = true


func _on_pressed_correct_button(_btn):
	self._reset()


func flash():
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


func set_albedo_color(color: Color, surface_index: int = 0):
	"""Set the albedo color of the mesh material."""
	if not mesh:
		return
	
	# Try to get existing material first
	var existing_material = mesh.get_surface_override_material(surface_index)
	if not existing_material and mesh.mesh:
		existing_material = mesh.mesh.surface_get_material(surface_index)
	
	var material: StandardMaterial3D
	if existing_material and existing_material is StandardMaterial3D:
		# Duplicate the existing material to avoid affecting other instances
		material = existing_material.duplicate()
	else:
		# Create a new StandardMaterial3D
		material = StandardMaterial3D.new()
	
	material.albedo_color = color
	mesh.set_surface_override_material(surface_index, material)


func get_albedo_color(surface_index: int = 0) -> Color:
	"""Get the current albedo color of the mesh material."""
	if not mesh:
		return Color.WHITE
	
	var material = mesh.get_surface_override_material(surface_index)
	if not material and mesh.mesh:
		material = mesh.mesh.surface_get_material(surface_index)
	
	if material and material is StandardMaterial3D:
		return material.albedo_color
	
	return Color.WHITE


func _on_area_3d_input_event(
	_camera: Camera3D, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int
) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not disabled:
			pressed.emit()
			print("tile clicked!")
