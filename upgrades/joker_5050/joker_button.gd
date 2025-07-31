# ABOUTME: UI component for the 50/50 Joker upgrade button
# ABOUTME: Handles user interaction and visual feedback for joker usage
extends Button

var upgrade: BaseUpgrade
var upgrade_manager: Node
var sequence_controller: SequenceController


func setup(upgrade_ref: BaseUpgrade, manager: Node):
	upgrade = upgrade_ref
	upgrade_manager = manager

	# Get sequence controller reference
	sequence_controller = upgrade_manager.sequence_controller

	# Connect button press
	pressed.connect(_on_pressed)

	# Update display
	_update_display()

	# Listen for sequence events to update button state
	if sequence_controller:
		sequence_controller.sequence_flash_start.connect(_on_sequence_flash_start)
		sequence_controller.sequence_flash_end.connect(_on_sequence_flash_end)


func _process(_delta):
	_update_display()


func _update_display():
	if not upgrade:
		return

	# Update button text with count
	text = "50/50 (%d)" % upgrade.purchased_count

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
	# Disable the button
	button.disabled = true

	# Visual effect - fade out
	var tween = create_tween()
	tween.tween_property(button, "modulate:a", 0.3, 0.3)

	# Optional: Add particle effect or other visual feedback
	# You could also change the button color, add an X overlay, etc.


func _show_joker_used_effect():
	# Flash the joker button to indicate usage
	var original_modulate = modulate

	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.YELLOW, 0.1)
	tween.tween_property(self, "modulate", original_modulate, 0.2)


func _on_sequence_flash_start():
	# Disable during sequence display
	disabled = true
	modulate.a = 0.5


func _on_sequence_flash_end():
	# Re-enable after sequence display
	_update_display()
