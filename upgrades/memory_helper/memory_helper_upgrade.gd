# ABOUTME: Memory Helper upgrade that flashes the next correct button as a hint
# ABOUTME: Triggers after each step completion to help players remember the sequence
class_name MemoryHelperUpgrade
extends BaseUpgrade

var level_controller: LevelController


func _on_step_completed(current_step: int, total_steps: int) -> void:
	# Only flash hint if there are more steps to go
	if current_step >= total_steps:
		return

	if not level_controller.upgrade_manager:
		return

	var next_button = level_controller.upgrade_manager.get_current_correct_button()
	if not next_button:
		return

	# Use call_deferred to add a small delay without blocking
	var tween = next_button.create_tween()
	tween.tween_callback(help.bind(next_button)).set_delay(5.0)
	# make sure we don't flash the button AFTER the player has already pressed it
	next_button.pressed.connect(func(): tween.kill())


func help(next_button: SequenceButton):
	if level_controller.upgrade_manager.cash_manager.pay(5):
		print("Paid 5 to get a hint")
		next_button.flash()
	else:
		print("Cannot afford help")
