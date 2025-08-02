# ABOUTME: UI component for the 50/50 Joker upgrade button
# ABOUTME: Handles user interaction and visual feedback for joker usage
extends Button

var upgrade: BaseUpgrade
var level_controller: LevelController


func _ready() -> void:
	print("JOKER BUTTON READY")
	# Start disabled until game/sequence begins
	disabled = true


func setup(upgrade_ref: BaseUpgrade, level_controller_p: LevelController):
	upgrade = upgrade_ref
	level_controller = level_controller_p

	# Connect button press
	pressed.connect(_on_pressed)

	# Update display
	_update_display()


func _update_display():
	if not upgrade:
		return

	# Update button text with count
	text = "50/50 (%d)" % upgrade.purchased_count

	if not upgrade.can_use_joker():
		disable()


func _on_pressed():
	if not level_controller.sequence_controller:
		return

	# Check if this is a joker upgrade and can be used
	if not upgrade.has_method("can_use_joker") or not upgrade.can_use_joker():
		return

	# Get current state from upgrade manager
	var correct_button = level_controller.upgrade_manager.get_current_correct_button()
	if not correct_button:
		return

	# Get all buttons from the grid
	var grid = level_controller.sequence_controller.get_node_or_null(".")
	if not grid:
		return

	level_controller.upgrade_manager.upgrade_activated.emit(upgrade)

	var all_buttons: Array[SequenceButton] = []
	for child in grid.get_children():
		if child is SequenceButton:
			all_buttons.append(child)

	# Use the joker
	var eliminated = []
	if upgrade.has_method("use_joker"):
		eliminated = await upgrade.use_joker(correct_button, all_buttons)

	var original_modulate = modulate
	var intro_tween = create_tween()
	intro_tween.tween_property(self, "modulate", Color.YELLOW, 0.3)
	await intro_tween.finished

	# Apply elimination effects
	for button in eliminated:
		await button.flash()

	# the other tween is already finished
	var outro_tween = create_tween()
	outro_tween.tween_property(self, "modulate", original_modulate, 0.3)
	outro_tween.tween_property(self, "modulate:a", 0.5, 0.1)
	await outro_tween.finished

	await _update_display()


func disable():
	disabled = true

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.5, 0.1)
	await tween.finished


func enable():
	# Only enable if the joker can still be used
	if not upgrade or not upgrade.can_use_joker():
		return

	disabled = false

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.1)
	await tween.finished
