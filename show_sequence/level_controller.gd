# ABOUTME: Level controller that manages game state, flow, and coordination between components
# ABOUTME: Handles lives, game over conditions, restart functionality, and UI coordination
class_name LevelController
extends Node

@export var sequence_controller_scene: PackedScene
@export_range(1, 10, 1, "or_greater") var start_lives = 3
@export_group("Debug")
@export var debug_start_money: int = 0
@export var debug_open_shop_on_start: bool = false

var current_lives: int
var cash_manager: CashManager
var shop_manager: ShopManager
var upgrade_manager: UpgradeManager

var sequence_controller: SequenceController
@onready var level_ui: LevelUI = $UI
@onready var life_counter: Label = $UI/Lives
@onready var overlay: Control = $UI/Overlay
@onready var player = $Player

signal next_level
signal life_changed(new_count: int, amount_changed: int)
signal life_about_to_be_lost(event_args: LifeLossEventArgs)


func _ready() -> void:
	# Initialize shop manager first
	shop_manager = ShopManager.new()
	cash_manager = CashManager.new()
	upgrade_manager = UpgradeManager.new(self)

	shop_manager.cash_manager = cash_manager
	shop_manager.upgrade_manager = upgrade_manager

	cash_manager.shop_manager = shop_manager
	cash_manager.cash_changed.connect(_on_cash_changed)

	add_child(shop_manager)
	add_child(cash_manager)

	# Apply upgrades to starting lives
	current_lives = start_lives
	life_counter.update_lives(current_lives)
	life_changed.emit(current_lives, current_lives)

	# Setup shop UI through level UI
	level_ui.setup_shop(shop_manager)
	level_ui.setup_upgrades(upgrade_manager)

	level_ui.restart_button_pressed.connect(_on_restart_pressed)
	level_ui.next_level_pressed.connect(_on_next_level_button_pressed)
	level_ui.shop_button_pressed.connect(_on_shop_button_pressed)
	level_ui.upgrade_selected.connect(_on_upgrade_selected)

	level_ui.shop_closed.connect(_on_shop_closed)

	# Apply debug settings
	if debug_start_money > 0:
		cash_manager.add_cash(debug_start_money)
		print("Debug: Added %d starting money" % debug_start_money)

	if debug_open_shop_on_start:
		await get_tree().process_frame
		show_upgrades()
		# level_ui.open_shop()
		print("Debug: Opening shop on start")
	else:
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
	# TODO: turn into signal?
	upgrade_manager.broadcast_game_start()

	for length in range(3, 13, 2):
		sequence_controller = setup_sequence_controller()
		player.setup(sequence_controller)

		upgrade_manager.register_sequence_controller(sequence_controller)

		sequence_controller.sequence_length = length

		await sequence_controller.start_game()
		await next_level
		print("Finished Difficulty: ", length)
		level_ui.close()

		sequence_controller.queue_free()


func _on_sequence_controller_pressed_wrong(_btn: SequenceButton) -> void:
	var event_args = LifeLossEventArgs.new(_btn, current_lives)
	life_about_to_be_lost.emit(event_args)
	
	if not event_args.is_cancelled:
		current_lives -= 1
		life_counter.update_lives(current_lives)
		life_changed.emit(current_lives, -1)
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


func _on_cash_changed(new_total: int, _amount_added: int) -> void:
	level_ui.update_cash(new_total)


func game_over() -> void:
	level_ui.show_overlay(false)


func game_won() -> void:
	# Show upgrade selection first
	show_upgrades()


func show_upgrades() -> void:
	var random_upgrades = upgrade_manager.get_random_upgrades(3)
	level_ui.show_upgrade_selection(random_upgrades)


func _on_shop_button_pressed() -> void:
	level_ui.open_shop()


func _on_shop_closed() -> void:
	# If shop was opened on start and no game has started yet, start it now
	if debug_open_shop_on_start and not sequence_controller:
		start_game()


func _on_restart_pressed() -> void:
	print("RESTART")
	get_tree().reload_current_scene()


func _on_next_level_button_pressed() -> void:
	next_level.emit()


func add_lives(count: int) -> void:
	current_lives += count
	life_counter.update_lives(current_lives)
	life_changed.emit(current_lives, count)


func _on_upgrade_selected(upgrade: BaseUpgrade) -> void:
	# Purchase the selected upgrade
	print("Selected upgrade: ", upgrade.name)
	shop_manager.purchase_upgrade(upgrade.id)

	# Show the win overlay now
	next_level.emit()
	if debug_open_shop_on_start and not sequence_controller:
		start_game()
