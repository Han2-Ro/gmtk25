# ABOUTME: Level controller that manages game state, flow, and coordination between components
# ABOUTME: Handles lives, game over conditions, restart functionality, and UI coordination
extends Node

@export_range(1, 10, 1, "or_greater") var start_lives = 3
var current_lives: int
var cash_manager: CashManager
var shop_manager: ShopManager

var sequence_controller: SequenceController
@export var sequence_controller_scene: PackedScene
@onready var level_ui: LevelUI = $UI
@onready var life_counter: Label = $UI/Lives
@onready var overlay: Control = $UI/Overlay

signal next_level


func _ready() -> void:
	print("CALL READY")
	# Initialize shop manager first
	shop_manager = ShopManager.new()
	cash_manager = CashManager.new()

	shop_manager.cash_manager = cash_manager
	cash_manager.shop_manager = shop_manager
	cash_manager.cash_changed.connect(_on_cash_changed)

	add_child(shop_manager)
	add_child(cash_manager)

	# Apply upgrades to starting lives
	current_lives = start_lives
	life_counter.update_lives(current_lives)

	# Setup shop UI through level UI
	level_ui.setup_shop(shop_manager)

	level_ui.restart_button_pressed.connect(_on_restart_pressed)
	level_ui.next_level_pressed.connect(_on_play_again_pressed)
	level_ui.shop_button_pressed.connect(_on_shop_button_pressed)
	level_ui.shop_closed.connect(_on_shop_closed)
	level_ui.play_again_pressed.connect(_on_play_again_pressed)

	start_game()


func setup_sequence_controller() -> SequenceController:
	sequence_controller = sequence_controller_scene.instantiate()
	add_child(sequence_controller)

	sequence_controller.pressed_wrong.connect(_on_sequence_controller_pressed_wrong)
	sequence_controller.sequence_completed.connect(_on_sequence_controller_sequence_completed)
	sequence_controller.subsequence_completed.connect(_on_sequence_controller_subsequence_completed)
	sequence_controller.step_completed.connect(_on_sequence_controller_step_completed)

	# Connect shop manager to sequence controller
	sequence_controller.shop_manager = shop_manager

	return sequence_controller


func start_game() -> void:
	print(range(3, 13, 2))

	for length in range(3, 13, 2):
		sequence_controller = setup_sequence_controller()

		print(length)
		sequence_controller.sequence_length = length

		await sequence_controller.start_game()
		await next_level
		print("Finished Difficulty: ", length)
		level_ui.close()

		sequence_controller.queue_free()


func _on_sequence_controller_pressed_wrong(_btn: SequenceButton) -> void:
	current_lives -= 1
	life_counter.update_lives(current_lives)
	if current_lives <= 0:
		game_over()


func _on_sequence_controller_sequence_completed() -> void:
	cash_manager.award_sequence_completion(sequence_controller.sequence_length)
	game_won()


func _on_sequence_controller_subsequence_completed(current_round: int, total_rounds: int) -> void:
	cash_manager.award_subsequence_completion()
	level_ui.show_mini_win(current_round, total_rounds)


func _on_sequence_controller_step_completed(_current_step: int, _total_steps: int) -> void:
	cash_manager.award_step_completion()


func _on_cash_changed(new_amount: int) -> void:
	level_ui.update_cash(new_amount)


func game_over() -> void:
	level_ui.show_overlay(false)


func game_won() -> void:
	level_ui.show_overlay(true)


func _on_shop_button_pressed() -> void:
	level_ui.open_shop()


func _on_shop_closed() -> void:
	pass


func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()


func _on_play_again_pressed() -> void:
	next_level.emit()
