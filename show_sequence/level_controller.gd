# ABOUTME: Level controller that manages game state, flow, and coordination between components
# ABOUTME: Handles lives, game over conditions, restart functionality, and UI coordination
extends Node

@export_range(1, 10, 1, "or_greater") var start_lives = 3
var current_lives: int

@onready var sequence_controller: SequenceController = $SequenceController
@onready var level_ui: LevelUI = $UI
@onready var life_counter: Label = $UI/Lives
@onready var overlay: Control = $UI/Overlay


func _ready() -> void:
	current_lives = start_lives
	life_counter.update_lives(current_lives)

	sequence_controller.pressed_wrong.connect(_on_sequence_controller_pressed_wrong)
	sequence_controller.sequence_completed.connect(_on_sequence_controller_sequence_completed)
	sequence_controller.subsequence_completed.connect(_on_sequence_controller_subsequence_completed)

	level_ui.restart_button_pressed.connect(_on_restart_button_pressed)

	start_game()


func start_game() -> void:
	sequence_controller.start_game()


func _on_sequence_controller_pressed_wrong(_btn: SequenceButton) -> void:
	current_lives -= 1
	life_counter.update_lives(current_lives)
	if current_lives <= 0:
		game_over()


func _on_sequence_controller_sequence_completed() -> void:
	game_won()


func _on_sequence_controller_subsequence_completed(current_round: int, total_rounds: int) -> void:
	level_ui.show_mini_win(current_round, total_rounds)


func game_over() -> void:
	level_ui.show_overlay(false)


func game_won() -> void:
	level_ui.show_overlay(true)


func _on_restart_button_pressed() -> void:
	get_tree().reload_current_scene()
