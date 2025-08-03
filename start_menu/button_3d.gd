class_name Button3D
extends Area3D

# Signal that mimics UI Button
signal pressed()

# Exported properties
@export var mesh: Mesh
@export var disabled: bool = false : set = set_disabled

# Internal state
var is_hovered: bool = false
var is_pressed: bool = false

# Color constants for different states
const NORMAL_COLOR = Color.WHITE
const HOVERED_COLOR = Color(1.2, 1.2, 1.2)  # Slightly brighter
const DISABLED_COLOR = Color(0.5, 0.5, 0.5)  # Gray
const PRESSED_COLOR = Color(0.8, 0.8, 0.8)   # Darker

func _ready():
	# Connect Area3D signals
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Initialize visual state
	_update_visual_state()

func _on_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int):
	if disabled:
		return
	
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				is_pressed = true
				_update_visual_state()
			elif is_pressed:
				is_pressed = false
				_update_visual_state()
				# Emit pressed signal only if mouse is still over the button
				if is_hovered:
					pressed.emit()

func _on_mouse_entered():
	if disabled:
		return
	
	is_hovered = true
	_update_visual_state()

func _on_mouse_exited():
	is_hovered = false
	is_pressed = false  # Cancel press if mouse leaves
	_update_visual_state()

func set_disabled(value: bool):
	disabled = value
	_update_visual_state()

func _update_visual_state():
	if not mesh:
		return
	
	var mesh_instance = get_child(0) as MeshInstance3D
	if not mesh_instance:
		return
	
	var material = mesh_instance.get_surface_override_material(0)
	if not material:
		# Create a new StandardMaterial3D if none exists
		material = StandardMaterial3D.new()
		mesh_instance.set_surface_override_material(0, material)
	
	# Update color based on current state
	var target_color: Color
	if disabled:
		target_color = DISABLED_COLOR
	elif is_pressed:
		target_color = PRESSED_COLOR
	elif is_hovered:
		target_color = HOVERED_COLOR
	else:
		target_color = NORMAL_COLOR
	
	if material is StandardMaterial3D:
		var std_material = material as StandardMaterial3D
		std_material.albedo_color = target_color
