# ABOUTME: Memory Helper upgrade that provides manual hints when player clicks button
# ABOUTME: Costs 35 coins per use to flash the next correct button
class_name MemoryHelperUpgrade
extends BaseUpgrade

var level_controller: LevelController


func _init():
	if ui_scene == null:
		ui_scene = preload("res://upgrades/memory_helper/memory_helper_button.tscn")


func can_use_hint() -> bool:
	return purchased_count > 0


func use_hint() -> bool:
	if not can_use_hint():
		return false

	if not level_controller or not level_controller.upgrade_manager:
		return false

	# Check if player can afford the hint
	if not level_controller.cash_manager.pay(35):
		print("Cannot afford hint - need 35 coins")
		return false

	var next_button = level_controller.upgrade_manager.get_current_correct_button()
	if not next_button:
		print("No current correct button available")
		return false

	print("Used hint for 35 coins")
	next_button.flash()
	return true
