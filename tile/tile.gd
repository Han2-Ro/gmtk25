class_name SequenceButton
extends Node3D

signal pressed

var disabled := false
# TODO: is there a better way to get the player?
@onready var player = get_tree().current_scene.find_child("Player", true, false)
@onready var original_position: Vector3 = self.position

# TODO: find a way to use the name?
@export var surface_material_index = 1
@export_enum("emission", "albedo_color") var accent_property := "emission"
@export var disabled_color: Color = Color.DIM_GRAY
@export var enabled_color: Color = Color.DEEP_PINK
@export var hover_color: Color = Color.LIGHT_PINK
@export var mistake_color: Color = Color.INDIAN_RED
@export var correct_color: Color = Color.GREEN_YELLOW

var material: BaseMaterial3D

var _is_showing_correct := false


func _ready() -> void:
	var area: Area3D = $Area3D
	# Connect to Area3D input_event signal for proper 3D click detection
	area.input_event.connect(_on_area_3d_input_event)
	# Connect mouse enter/exit for cursor management
	area.mouse_entered.connect(_on_area_3d_mouse_entered)
	area.mouse_exited.connect(_on_area_3d_mouse_exited)


func _setup_material():
	# Look for MeshInstance3D in children (from imported 3D models)
	var mesh_holder = $Mesh
	var mesh_instance = mesh_holder.find_child("*", true, false) as MeshInstance3D
	var original_mesh: Mesh = mesh_instance.mesh
	# otherwise material overrides apply to all
	mesh_instance.mesh = original_mesh.duplicate()
	var new_material = (
		mesh_instance.get_surface_override_material(surface_material_index) as BaseMaterial3D
	)
	if not new_material:
		new_material = mesh_instance.mesh.surface_get_material(surface_material_index)
	new_material = new_material.duplicate()
	mesh_instance.set_surface_override_material(surface_material_index, new_material)
	new_material[accent_property] = disabled_color

	return new_material


func _controller_ready(controller: SequenceController):
	material = _setup_material()
	_on_sequence_flash_start()
	controller.sequence_flash_start.connect(_on_sequence_flash_start)
	controller.sequence_flash_end.connect(_on_sequence_flash_end)
	controller.pressed_correct.connect(_on_pressed_correct_button)
	original_position = self.position


func disable() -> void:
	self.disabled = true
	var tween = create_tween()
	tween.tween_property(material, accent_property, disabled_color, 0.2)
	await tween.finished


var _hover_tween: Tween


func hover() -> void:
	if _hover_tween and _hover_tween.is_running():
		_hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.tween_property(material, accent_property, hover_color, 0.2)
	await _hover_tween.finished


func unhover() -> void:
	if _hover_tween and _hover_tween.is_running():
		_hover_tween.kill()
	_hover_tween = create_tween()
	if disabled:
		_hover_tween.tween_property(material, accent_property, disabled_color, 0.2)
	else:
		_hover_tween.tween_property(material, accent_property, enabled_color, 0.2)
	await _hover_tween.finished


func _on_sequence_flash_start():
	self.disable()


func _on_sequence_flash_end():
	self.enable()


func _on_pressed_correct_button(_btn):
	self._reset()


func flash():
	var tween = create_tween()
	tween.tween_property(self, "position", original_position + Vector3(0, 0.3, 0), 0.2)
	tween.parallel().tween_property(material, accent_property, enabled_color, 0.2)
	tween.tween_interval(0.6)
	tween.tween_property(self, "position", original_position, 0.2)
	tween.parallel().tween_property(material, accent_property, disabled_color, 0.2)

	await tween.finished


func enable():
	var tween = create_tween()
	tween.tween_property(self, "position", original_position, 0.3)
	tween.parallel().tween_property(material, accent_property, enabled_color, 0.2)
	await tween.finished

	self.disabled = false


func _reset():
	await self.enable()
	self.show()


var _pressed_correct_tween: Tween


func this_pressed_correct():
	if _pressed_correct_tween and _pressed_correct_tween.is_running():
		_pressed_correct_tween.kill()
		# insta reset if clicked fast
		material[accent_property] = enabled_color
	if _hover_tween and _hover_tween.is_running():
		_hover_tween.kill()

	_pressed_correct_tween = create_tween()
	_pressed_correct_tween.tween_property(self, "_is_showing_correct", true, 0)
	_pressed_correct_tween.tween_property(material, accent_property, correct_color, 0.1)
	_pressed_correct_tween.tween_interval(0.1)
	_pressed_correct_tween.tween_property(material, accent_property, enabled_color, 0.25)
	_pressed_correct_tween.tween_property(player, "position", self.position, 0.1)
	_pressed_correct_tween.tween_property(self, "_is_showing_correct", false, 0)
	await _pressed_correct_tween.finished


func this_pressed_wrong():
	self.disabled = true

	var tween = create_tween()
	var parallel_tween = tween.parallel()
	tween.tween_property(material, accent_property, mistake_color, 0.05)
	tween.tween_interval(0.05)
	tween.tween_property(material, accent_property, disabled_color, 0.05)

	# Shake animation - quick left-right movement
	parallel_tween.tween_property(self, "position", original_position + Vector3(0.1, 0, 0), 0.05)
	parallel_tween.tween_property(self, "position", original_position + Vector3(-0.1, 0, 0), 0.05)
	parallel_tween.tween_property(self, "position", original_position, 0.05)

	tween.tween_interval(0.2)
	await tween.finished


func _on_area_3d_input_event(
	_camera: Camera3D, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int
) -> void:
	if not disabled and not _is_showing_correct:
		CursorManager.set_hover_cursor()
		hover()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not disabled:
			pressed.emit()
			print("tile clicked!")


func _on_area_3d_mouse_entered() -> void:
	if not disabled:
		CursorManager.set_hover_cursor()


func _on_area_3d_mouse_exited() -> void:
	if not disabled and not _is_showing_correct:
		CursorManager.set_default_cursor()
		unhover()
