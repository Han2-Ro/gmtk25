# ABOUTME: UI component for the Memory Helper upgrade button
# ABOUTME: Handles user interaction and visual feedback for hint usage
extends Button

var upgrade: BaseUpgrade
var level_controller: LevelController


func _ready() -> void:
	print("MEMORY HELPER BUTTON READY")
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

	# Update button text with cost
	text = "Hint (35 coins)"

	if not upgrade.can_use_hint():
		disable()
	elif (
		not level_controller
		or not level_controller.cash_manager
		or not level_controller.cash_manager.can_afford(35)
	):
		disable()


func _on_pressed():
	if not level_controller.sequence_controller:
		return

	# Check if this is a memory helper upgrade and can be used
	if not upgrade.has_method("can_use_hint") or not upgrade.can_use_hint():
		return

	# Check if player can afford the hint
	if not level_controller.cash_manager.can_afford(35):
		return

	level_controller.upgrade_manager.upgrade_activated.emit(upgrade)

	# Visual feedback for button press
	var original_modulate = modulate
	var intro_tween = create_tween()
	intro_tween.tween_property(self, "modulate", Color.CYAN, 0.3)
	await intro_tween.finished

	# Use the hint
	var success = false
	if upgrade.has_method("use_hint"):
		success = await upgrade.use_hint()

	# Reset button appearance
	var outro_tween = create_tween()
	outro_tween.tween_property(self, "modulate", original_modulate, 0.3)
	if success:
		outro_tween.tween_property(self, "modulate:a", 1.0, 0.1)
	else:
		outro_tween.tween_property(self, "modulate:a", 0.5, 0.1)
	await outro_tween.finished

	await _update_display()


func disable():
	disabled = true

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.5, 0.1)
	await tween.finished


func enable():
	# Only enable if the hint can still be used and player can afford it
	if not upgrade or not upgrade.can_use_hint():
		return
	if (
		not level_controller
		or not level_controller.cash_manager
		or not level_controller.cash_manager.can_afford(35)
	):
		return

	disabled = false

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.1)
	await tween.finished
