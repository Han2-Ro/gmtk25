# ABOUTME: Central manager for all upgrades, handles loading, lifecycle, and event broadcasting
# ABOUTME: Singleton pattern ensures single source of truth for upgrade state
extends Node

signal upgrade_purchased(upgrade: BaseUpgrade)
signal upgrade_activated(upgrade: BaseUpgrade)

# Manually configured list of all available upgrades
const ALL_UPGRADE_RESOURCES = [
	preload("res://upgrades/joker_5050/joker_5050.tres"),
]

var all_upgrades: Dictionary = {}  # id -> BaseUpgrade
var active_upgrades: Array[BaseUpgrade] = []
var upgrade_ui_container: Control
var sequence_controller: SequenceController

# For tracking current game state
var current_sequence: Array[SequenceButton] = []
var current_step: int = 0


func _ready():
	# Load all upgrades from the preloaded array
	for upgrade_resource in ALL_UPGRADE_RESOURCES:
		var upgrade = upgrade_resource as BaseUpgrade
		all_upgrades[upgrade.id] = upgrade
		if upgrade.is_active:
			active_upgrades.append(upgrade)
		print("Loaded upgrade: ", upgrade.name)


func get_upgrade(id: String) -> BaseUpgrade:
	return all_upgrades.get(id)


func get_all_upgrades() -> Array[BaseUpgrade]:
	var upgrades: Array[BaseUpgrade] = []
	for upgrade in all_upgrades.values():
		upgrades.append(upgrade)
	return upgrades


func get_purchasable_upgrades() -> Array[BaseUpgrade]:
	var upgrades: Array[BaseUpgrade] = []
	for upgrade in all_upgrades.values():
		if upgrade.can_purchase():
			upgrades.append(upgrade)
	return upgrades


func purchase_upgrade(upgrade_id: String) -> bool:
	var upgrade = get_upgrade(upgrade_id)
	if not upgrade:
		return false

	upgrade.purchased_count += 1
	upgrade.is_active = true

	if upgrade not in active_upgrades:
		active_upgrades.append(upgrade)

	upgrade._on_purchase()
	upgrade_purchased.emit(upgrade)

	# Create UI if needed
	if upgrade_ui_container and upgrade.ui_scene:
		add_upgrade_ui(upgrade)

	return true


func broadcast_game_start():
	for upgrade in active_upgrades:
		upgrade._on_game_start()


func broadcast_sequence_start():
	current_step = 0
	for upgrade in active_upgrades:
		upgrade._on_sequence_start()


func broadcast_subsequence_start(current_round: int, total: int):
	for upgrade in active_upgrades:
		upgrade._on_subsequence_start(current_round, total)


func broadcast_button_pressed(button: SequenceButton, is_correct: bool):
	for upgrade in active_upgrades:
		upgrade._on_button_pressed(button, is_correct)


func broadcast_step_completed(current: int, total: int):
	current_step = current
	for upgrade in active_upgrades:
		upgrade._on_step_completed(current, total)


func broadcast_subsequence_completed(current_round: int, total: int):
	for upgrade in active_upgrades:
		upgrade._on_subsequence_completed(current_round, total)


func broadcast_sequence_complete():
	for upgrade in active_upgrades:
		upgrade._on_sequence_complete()


func broadcast_game_over():
	for upgrade in active_upgrades:
		upgrade._on_game_over()


func register_ui_container(container: Control):
	upgrade_ui_container = container
	refresh_upgrade_ui()


func register_sequence_controller(controller: SequenceController):
	sequence_controller = controller
	# Connect to sequence controller signals
	controller.sequence_flash_start.connect(_on_sequence_flash_start)
	controller.sequence_flash_end.connect(_on_sequence_flash_end)
	controller.pressed_correct.connect(_on_pressed_correct)
	controller.pressed_wrong.connect(_on_pressed_wrong)
	controller.step_completed.connect(broadcast_step_completed)
	controller.subsequence_completed.connect(broadcast_subsequence_completed)
	controller.sequence_completed.connect(broadcast_sequence_complete)


func _on_sequence_flash_start():
	broadcast_sequence_start()


func _on_sequence_flash_end():
	pass


func _on_pressed_correct(button: SequenceButton):
	broadcast_button_pressed(button, true)


func _on_pressed_wrong(button: SequenceButton):
	broadcast_button_pressed(button, false)


func refresh_upgrade_ui():
	if not upgrade_ui_container:
		return

	# Clear existing UI
	for child in upgrade_ui_container.get_children():
		child.queue_free()

	# Add UI for active upgrades
	for upgrade in active_upgrades:
		if upgrade.purchased_count > 0:
			add_upgrade_ui(upgrade)


func add_upgrade_ui(upgrade: BaseUpgrade):
	var ui_component = upgrade.get_ui_component()
	if ui_component and upgrade_ui_container:
		upgrade_ui_container.add_child(ui_component)
		# Call setup if it exists
		if ui_component.has_method("setup"):
			ui_component.setup(upgrade, self)


func get_current_correct_button() -> SequenceButton:
	if current_sequence.is_empty() or current_step >= current_sequence.size():
		return null
	return current_sequence[current_step]
