# ABOUTME: UI component for the 50/50 Joker upgrade button
# ABOUTME: Handles user interaction and visual feedback for joker usage
extends Button

var upgrade: BaseUpgrade
var upgrade_manager: UpgradeManager
var is_sequence_flashing: bool = false
var sequence_controller: SequenceController


func setup(upgrade_ref: BaseUpgrade, manager: UpgradeManager):
	upgrade = upgrade_ref
	upgrade_manager = manager

	# Start disabled until game/sequence begins
	disabled = true
	is_sequence_flashing = true  # Treat initial state as "waiting for sequence"

	# Connect button press
	pressed.connect(_on_pressed)

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
	_update_display()
	# Ensure sequence connections are set up when controller becomes available
	if not sequence_controller:
		_setup_sequence_connections()


func _update_display():
	if not upgrade:
		return

	# Update button text with count
	text = "50/50 (%d)" % upgrade.purchased_count

	# Always disabled during sequence flashing
	if is_sequence_flashing:
		disabled = true
		modulate.a = 0.5
		return

	# Disable if can't use (check if this is a joker upgrade)
	if upgrade.has_method("can_use_joker"):
		disabled = not upgrade.can_use_joker()
	else:
		disabled = upgrade.purchased_count <= 0

	# Additional visual feedback
	if disabled:
		modulate.a = 0.5
	else:
		modulate.a = 1.0


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
		eliminated = upgrade.use_joker(correct_button, all_buttons)

	# Apply elimination effects
	for button in eliminated:
		_eliminate_button(button)

	# Visual feedback for joker usage
	_show_joker_used_effect()

	# Update display immediately
	_update_display()


func _eliminate_button(button: SequenceButton):
	# Safety check - only eliminate if button exists and is visible
	if not button or not button.visible:
		return

	# Disable the button
	button.disabled = true

	# Visual effect - sink and fade out using position tweening like existing animations
	var tween = create_tween()
	tween.tween_property(button, "position", button.position + Vector3(0, -0.3, 0), 0.3)
	tween.tween_callback(func(): button.hide())


func _show_joker_used_effect():
	# Safety check - ensure we can modulate this button
	if not is_inside_tree():
		return

	# Flash the joker button to indicate usage
	var original_modulate = modulate

	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.YELLOW, 0.1)
	tween.tween_property(self, "modulate", original_modulate, 0.2)


func _on_sequence_flash_start():
	# Track that we're in sequence flashing mode
	is_sequence_flashing = true
	# Disable during sequence display
	disabled = true
	modulate.a = 0.5


func _on_sequence_completed():
	disabled = true
	modulate.a = 0.5


func _on_sequence_flash_end():
	# Track that sequence flashing is done
	is_sequence_flashing = false
	# Re-enable after sequence display
	_update_display()
