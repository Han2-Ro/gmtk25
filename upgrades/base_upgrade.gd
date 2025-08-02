# ABOUTME: Base class for all upgrades, providing common interface and lifecycle hooks
# ABOUTME: Extends Resource for easy serialization and inspector editing
class_name BaseUpgrade
extends Resource

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var cost: int = 10
@export var is_stackable: bool = false
@export var max_stack: int = -1  # -1 = unlimited
@export var ui_scene: PackedScene  # Optional UI component

# Persistent state (saved between sessions)
@export var purchased_count: int = 0
@export var is_active: bool = false

# Session state (reset each game)
var session_data: Dictionary = {}


# Lifecycle hooks (virtual methods)
func _on_purchase() -> void:
	pass


func _on_game_start() -> void:
	session_data.clear()


func _on_sequence_start() -> void:
	pass


func _on_subsequence_start(_round: int, _total: int) -> void:
	pass


func _on_button_pressed(_button: SequenceButton, _is_correct: bool) -> void:
	pass


func _on_step_completed(_current_step: int, _total_steps: int) -> void:
	pass


func _on_subsequence_completed(_current_round: int, _total_rounds: int) -> void:
	pass


func _on_sequence_complete() -> void:
	pass


func _on_sequence_flash_start() -> void:
	pass


func _on_sequence_flash_end() -> void:
	pass


func _on_game_over() -> void:
	pass


func _on_life_about_to_be_lost(_event_args: LifeLossEventArgs) -> void:
	pass


# UI integration
func get_ui_component() -> Control:
	if ui_scene:
		return ui_scene.instantiate()
	return null


func can_purchase() -> bool:
	if not is_stackable:
		return purchased_count == 0
	if max_stack > 0:
		return purchased_count < max_stack
	return true


func get_display_name() -> String:
	if is_stackable and purchased_count > 0:
		return "%s (%d)" % [name, purchased_count]
	return name


func get_stack_count() -> int:
	return purchased_count
