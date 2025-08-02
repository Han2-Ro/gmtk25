# ABOUTME: 50/50 Joker upgrade that eliminates half the wrong options once per sequence
# ABOUTME: Extends BaseUpgrade to integrate seamlessly with upgrade system
extends BaseUpgrade

@export var elimination_percentage: float = 0.5
@export var min_buttons_to_eliminate: int = 1


func _init():
	if ui_scene == null:
		ui_scene = preload("res://upgrades/joker_5050/joker_button.tscn")


func _on_sequence_start():
	super._on_sequence_start()
	session_data["used_this_sequence"] = false


func can_use_joker() -> bool:
	return purchased_count > 0 and not session_data.get("used_this_sequence", false)


func use_joker(
	correct_button: SequenceButton, all_buttons: Array[SequenceButton]
) -> Array[SequenceButton]:
	if not can_use_joker():
		return []

	var wrong_buttons: Array[SequenceButton] = []
	for button in all_buttons:
		if button != correct_button and button.visible:
			wrong_buttons.append(button)

	# Don't use joker if there are too few wrong buttons
	if wrong_buttons.size() <= 1:
		return []

	var distractor = wrong_buttons.pick_random()
	var buttons_to_flash: Array[SequenceButton] = [distractor, correct_button]
	buttons_to_flash.shuffle()

	session_data["used_this_sequence"] = true
	purchased_count -= 1

	# Save the state after using a joker
	if has_meta("upgrade_manager"):
		var manager = get_meta("upgrade_manager")
		if manager and manager.has_method("save_upgrades"):
			manager.save_upgrades()

	return buttons_to_flash


func get_display_name() -> String:
	if purchased_count > 0:
		return "%s (%d)" % [name, purchased_count]
	return name
