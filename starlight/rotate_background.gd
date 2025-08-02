extends Node3D

@export var rotation_speed: float = 1.0  # Degrees per second
@export var rotation_axis: Vector3 = Vector3.UP  # Default to Y-axis (up)


func _ready():
	# Normalize the rotation axis to ensure consistent rotation speed
	rotation_axis = rotation_axis.normalized()


func _process(delta):
	rotate(rotation_axis, deg_to_rad(rotation_speed * delta))
