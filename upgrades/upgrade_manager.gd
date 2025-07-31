# ABOUTME: Central manager for all upgrades, handles loading, lifecycle, and event broadcasting
# ABOUTME: Singleton pattern ensures single source of truth for upgrade state
extends Node

signal upgrade_purchased(upgrade: BaseUpgrade)
signal upgrade_activated(upgrade: BaseUpgrade)

var all_upgrades: Dictionary = {}  # id -> BaseUpgrade
var active_upgrades: Array[BaseUpgrade] = []
var upgrade_ui_container: Control
var sequence_controller: SequenceController

# For tracking current game state
var current_sequence: Array[SequenceButton] = []
var current_step: int = 0


func _ready():
	# Load all upgrade resources from subdirectories
	load_upgrades_from_directory("res://upgrades/")


func load_upgrades_from_directory(path: String) -> void:
	var dir = DirAccess.open(path)
	if not dir:
		push_warning("Could not open upgrades directory: " + path)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		# Skip system files and current directory entries
		if file_name.begins_with(".") or file_name in ["base_upgrade.gd", "upgrade_manager.gd"]:
			file_name = dir.get_next()
			continue
		# Check if it's a directory (upgrade subfolder)
		var full_path = path + file_name
		if dir.current_is_dir():
			# Look for .tres files in the upgrade subfolder
			var subdir = DirAccess.open(full_path)
			if subdir:
				subdir.list_dir_begin()
				var sub_file = subdir.get_next()
				while sub_file != "":
					if sub_file.ends_with(".tres") or sub_file.ends_with(".res"):
						var upgrade_path = full_path + "/" + sub_file
						var upgrade = load(upgrade_path) as BaseUpgrade
						if upgrade:
							all_upgrades[upgrade.id] = upgrade
							if upgrade.is_active:
								active_upgrades.append(upgrade)
							print("Loaded upgrade: ", upgrade.name)
					sub_file = subdir.get_next()
		else:
			# Legacy: also check for .tres files directly in the upgrades folder
			if file_name.ends_with(".tres") or file_name.ends_with(".res"):
				var upgrade_path = full_path
				var upgrade = load(upgrade_path) as BaseUpgrade
				if upgrade:
					all_upgrades[upgrade.id] = upgrade
					if upgrade.is_active:
						active_upgrades.append(upgrade)
					print("Loaded upgrade: ", upgrade.name)
		file_name = dir.get_next()


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

	# Save state
	save_upgrades()

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


func save_upgrades():
	# Save upgrade states to file
	var save_data = {}
	for id in all_upgrades:
		var upgrade = all_upgrades[id]
		save_data[id] = {"purchased_count": upgrade.purchased_count, "is_active": upgrade.is_active}

	var save_file = FileAccess.open("user://upgrades.save", FileAccess.WRITE)
	if save_file:
		save_file.store_var(save_data)
		save_file.close()


func load_upgrades_state():
	var save_file = FileAccess.open("user://upgrades.save", FileAccess.READ)
	if save_file:
		var save_data = save_file.get_var()
		save_file.close()

		for id in save_data:
			var upgrade = get_upgrade(id)
			if upgrade:
				upgrade.purchased_count = save_data[id].get("purchased_count", 0)
				upgrade.is_active = save_data[id].get("is_active", false)
				if upgrade.is_active and upgrade not in active_upgrades:
					active_upgrades.append(upgrade)


# Helper methods for specific upgrades
func get_current_sequence() -> Array[SequenceButton]:
	return current_sequence


func set_current_sequence(sequence: Array[SequenceButton]):
	current_sequence = sequence


func get_current_step() -> int:
	return current_step


func get_current_correct_button() -> SequenceButton:
	if current_sequence.is_empty() or current_step >= current_sequence.size():
		return null
	return current_sequence[current_step]
