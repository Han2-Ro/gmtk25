# ABOUTME: Level controller that manages game state, flow, and coordination between components
# ABOUTME: Handles lives, game over conditions, restart functionality, and UI coordination
class_name LevelController
extends Node

@export var sequence_controller_scene: PackedScene
@export_range(1, 10, 1, "or_greater") var start_lives = 3
@export_group("Debug")
@export var debug_start_money: int = 0
@export var debug_open_shop_on_start: bool = false
@export_enum(
	"coin_multiplier",
	"extra_life",
	"joker_5050",
	"lucky_charm",
	"memory_helper",
	"slow_motion",
)
var debug_forced_upgrade: String

var current_lives: int
var current_level: int = 1
var is_fast_forward_enabled: bool = false
var cash_manager: CashManager
var shop_manager: ShopManager
var upgrade_manager: UpgradeManager

var sequence_controller: SequenceController
@onready var level_ui: LevelUI = $UI
@onready var life_counter: Control = $UI/Lives
@onready var level_counter: Label = level_ui.level_label
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
	# Connect life loss events to upgrade manager
	life_about_to_be_lost.connect(upgrade_manager.broadcast_life_about_to_be_lost)

	add_child(shop_manager)
	add_child(cash_manager)

	# Apply upgrades to starting lives
	current_lives = start_lives
	life_counter.update_lives(current_lives)
	life_changed.emit(current_lives, current_lives)

	# Setup shop UI through level UI
	level_ui.setup_shop(shop_manager)
	level_ui.setup_upgrade_selection(shop_manager)
	level_ui.setup_upgrades(upgrade_manager)

	level_ui.restart_button_pressed.connect(_on_restart_pressed)
	level_ui.next_level_pressed.connect(_on_next_level_button_pressed)
	level_ui.shop_button_pressed.connect(_on_shop_button_pressed)
	level_ui.upgrade_selected.connect(_on_upgrade_selected)
	level_ui.upgrade_skipped.connect(_on_upgrade_skipped)
	level_ui.fast_forward_pressed.connect(_on_fast_forward_pressed)
	level_ui.try_again_pressed.connect(_on_try_again_pressed)

	level_ui.shop_closed.connect(_on_shop_closed)

	# Apply debug settings
	if debug_start_money > 0:
		cash_manager.add_cash(debug_start_money)
		print("Debug: Added %d starting money" % debug_start_money)

	var start_menu: StartMenu = $StartMenu
	var camera: GameCamera = $Camera3D

	# Wait for start button to be clicked
	await start_menu.start_game

	# Wait for camera animation to complete
	await camera.transition_completed

	# Now show UI elements
	level_ui.show_ui_elements()

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
	sequence_controller.subsequence_start.connect(_on_sequence_controller_subsequence_start)
	sequence_controller.step_completed.connect(_on_sequence_controller_step_completed)
	sequence_controller.sequence_flash_start.connect(_on_sequence_flash_start)
	sequence_controller.sequence_flash_end.connect(_on_sequence_flash_end)
	sequence_controller.fast_forward_toggled.connect(_on_fast_forward_toggled)

	return sequence_controller


class Map:
	var map_size: int
	var tile_shape: SequenceController.TileShape

	func _init(size: int, shape: SequenceController.TileShape):
		map_size = size
		tile_shape = shape


func start_game() -> void:
	# TODO: turn into signal?
	upgrade_manager.broadcast_game_start()
	level_ui.show_level()

	var maps: Array[Map] = [
		Map.new(2, SequenceController.TileShape.SQUARE),
		Map.new(2, SequenceController.TileShape.HEXAGON),
		Map.new(3, SequenceController.TileShape.SQUARE),
		Map.new(4, SequenceController.TileShape.SQUARE),
		Map.new(3, SequenceController.TileShape.HEXAGON),
	]
	# initialize the difficulty dimensions
	var map_index = 0
	var length = 3
	var steps_to_reveal = 1

	for difficulty in range(100):
		sequence_controller = setup_sequence_controller()
		player.setup(sequence_controller)

		upgrade_manager.register_sequence_controller(sequence_controller)

		# Restore fast forward state from previous level
		if is_fast_forward_enabled:
			sequence_controller.is_fast_forward_enabled = true
			sequence_controller.fast_forward_toggled.emit(true)

		sequence_controller.sequence_length = length
		sequence_controller.steps_to_reveal = steps_to_reveal
		sequence_controller.tile_shape = maps[map_index].tile_shape
		sequence_controller.grid_width = maps[map_index].map_size
		sequence_controller.grid_height = maps[map_index].map_size
		sequence_controller.hex_grid_outer_width = maps[map_index].map_size
		level_counter.update_level(current_level)

		await sequence_controller.start_game()
		await next_level
		print("Finished Difficulty: ", difficulty)
		level_ui.close()

		sequence_controller.queue_free()

		#randomly increase a diffculty dimension
		var rng = randf()
		if rng < .2 and steps_to_reveal < 3:  # 3 is maximum
			steps_to_reveal += 1
		elif .2 <= rng and rng < .6 and map_index < (maps.size() - 1):
			map_index += 1
		else:
			length += 2


func _on_sequence_controller_pressed_wrong(_btn: SequenceButton) -> void:
	# Show mistake notification immediately
	level_ui.show_mistake_notification()

	var event_args = LifeLossEventArgs.new(_btn, current_lives)
	life_about_to_be_lost.emit(event_args)

	if not event_args.is_cancelled:
		current_lives -= 1
		life_counter.update_lives(current_lives)
		life_changed.emit(current_lives, -1)
		if current_lives <= 0:
			game_over()
		else:
			# Only show try again button if player still has lives
			level_ui.show_try_again_button()


func _on_sequence_controller_sequence_completed() -> void:
	cash_manager.award_sequence_completion(sequence_controller.sequence_length)
	current_level += 1
	level_ui.clear_progress()
	level_ui.show_victory_message()
	# Give player time to enjoy their victory before showing upgrade screen
	await get_tree().create_timer(2.0).timeout
	game_won()


func _on_sequence_controller_subsequence_completed(current_round: int, total_rounds: int) -> void:
	cash_manager.award_subsequence_completion()
	level_ui.show_mini_win(current_round, total_rounds)


func _on_sequence_controller_subsequence_start(current_round: int, total_rounds: int) -> void:
	level_ui.update_subsequence_progress(current_round, total_rounds)


func _on_sequence_controller_step_completed(current_step: int, total_steps: int) -> void:
	cash_manager.award_step_completion()
	level_ui.update_step_progress(current_step, total_steps)


func _on_cash_changed(new_total: int, _amount_added: int) -> void:
	level_ui.update_cash(new_total)


func game_over() -> void:
	var last_completed_level = current_level - 1
	# Wait a moment to let player see the mistake notification
	await get_tree().create_timer(1.5).timeout
	# Hide the notification before showing game over screen
	level_ui.hide_try_again_button()
	level_ui.show_overlay(false, last_completed_level)


func game_won() -> void:
	# Show upgrade selection first
	show_upgrades()


func show_upgrades() -> void:
	var random_upgrades = upgrade_manager.get_random_upgrades(3)
	if debug_forced_upgrade:
		var forced_upgrade = upgrade_manager.get_upgrade(debug_forced_upgrade)
		if forced_upgrade not in random_upgrades:
			random_upgrades.pop_back()
			random_upgrades.push_front(forced_upgrade)
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


func _on_upgrade_skipped() -> void:
	# Skip purchasing any upgrade and continue to next level
	print("Skipped upgrade selection")
	next_level.emit()
	if debug_open_shop_on_start and not sequence_controller:
		start_game()


func _on_fast_forward_pressed() -> void:
	if sequence_controller:
		sequence_controller.toggle_fast_forward()


func _on_sequence_flash_start() -> void:
	level_ui.show_fast_forward_button()


func _on_sequence_flash_end() -> void:
	level_ui.hide_fast_forward_button()


func _on_fast_forward_toggled(is_enabled: bool) -> void:
	is_fast_forward_enabled = is_enabled
	level_ui.update_fast_forward_state(is_enabled)


func _on_try_again_pressed() -> void:
	# Hide try again button and mistake notification
	level_ui.hide_try_again_button()
	# Signal sequence controller to continue
	if sequence_controller:
		sequence_controller.try_again_ready.emit()
