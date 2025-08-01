# ABOUTME: UI component for the 50/50 Joker upgrade button
# ABOUTME: Handles user interaction and visual feedback for joker usage
extends Button

var upgrade: BaseUpgrade
var upgrade_manager: UpgradeManager
var sequence_controller: SequenceController


func _ready() -> void:
	# Start disabled until game/sequence begins
	disabled = true


func setup(upgrade_ref: BaseUpgrade, manager: UpgradeManager):
	upgrade = upgrade_ref
	upgrade_manager = manager

	# Connect button press
	pressed.connect(_on_pressed)

	# update the display when buying more
	manager.upgrade_purchased.connect(func(_up): _update_display())

	# Update display
	_update_display()

	# Connect to sequence events using lazy initialization
	_setup_sequence_connections()


func get_sequence_controller() -> SequenceController:
	if upgrade_manager:
		return upgrade_manager.sequence_controller
	return null


func _setup_sequence_connections():
	print("SETUP SEQUENCE CONTROLLER")
	sequence_controller = get_sequence_controller()
	if sequence_controller:
		# Only connect if not already connected
		if not sequence_controller.sequence_flash_start.is_connected(_on_sequence_flash_start):
			sequence_controller.sequence_flash_start.connect(_on_sequence_flash_start)
		if not sequence_controller.sequence_flash_end.is_connected(_on_sequence_flash_end):
			sequence_controller.sequence_flash_end.connect(_on_sequence_flash_end)
		if not sequence_controller.sequence_completed.is_connected(_on_sequence_completed):
			sequence_controller.sequence_completed.connect(_on_sequence_completed)


func _process(_delta):
	# Ensure sequence connections are set up when controller becomes available
	if not sequence_controller:
		_setup_sequence_connections()


func _update_display():
	if not upgrade:
		return

	# Update button text with count
	text = "50/50 (%d)" % upgrade.purchased_count

	if not upgrade.can_use_joker():
		disabled = true
		modulate.a = 0.5


func _on_pressed():
	var sequence_controller = get_sequence_controller()
	if not sequence_controller:
		return

	# Check if this is a joker upgrade and can be used
	if not upgrade.has_method("can_use_joker") or not upgrade.can_use_joker():
		return

	# Get current state from upgrade manager
	var correct_button = upgrade_manager.get_current_correct_button()
	if not correct_button:
		return

	# Get all buttons from the grid
	var grid = sequence_controller.get_node_or_null(".")
	if not grid:
		return

	var all_buttons: Array[SequenceButton] = []
	for child in grid.get_children():
		if child is SequenceButton:
			all_buttons.append(child)

	# Use the joker
	var eliminated = []
	if upgrade.has_method("use_joker"):
		eliminated = await upgrade.use_joker(correct_button, all_buttons)

	# Apply elimination effects
	for button in eliminated:
		await _highlight_button(button)

	# Visual feedback for joker usage
	await _show_joker_used_effect()

	# Update display immediately
	_update_display()


func _highlight_button(button: SequenceButton):
	# Safety check - only eliminate if button exists and is visible
	if not button or not button.visible:
		return

	await button.flash()


func _show_joker_used_effect():
	# Flash the joker button to indicate usage
	var original_modulate = modulate

	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.YELLOW, 0.1)
	tween.tween_interval(0.2)
	tween.tween_property(self, "modulate", original_modulate, 0.2)
	await tween.finished


func _on_sequence_flash_start():
	disabled = true
	modulate.a = 0.5


func _on_sequence_completed():
	disabled = true
	modulate.a = 0.5


func _on_sequence_flash_end():
	disabled = false
	modulate.a = 1.0
