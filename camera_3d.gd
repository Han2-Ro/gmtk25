extends Camera3D

@export var map_look_target: Node3D
@export var start_menu_target: Node3D
@export var transition_duration: float = 2.0

var start_basis: Basis
var target_basis: Basis

func _ready() -> void:
	look_at(start_menu_target.position)
	await get_tree().create_timer(3.0).timeout
	transition_to_map()

func transition_to_map() -> void:
	start_basis = transform.basis
	target_basis = transform.looking_at(map_look_target.position, Vector3.UP).basis
	
	var tween = create_tween()
	tween.tween_method(_interpolate_rotation, 0.0, 1.0, transition_duration)

func transition_to_start_menu() -> void:
	start_basis = transform.basis
	target_basis = transform.looking_at(start_menu_target.position, Vector3.UP).basis
	
	var tween = create_tween()
	tween.tween_method(_interpolate_rotation, 0.0, 1.0, transition_duration)

func _interpolate_rotation(weight: float) -> void:
	transform.basis = start_basis.slerp(target_basis, weight)
