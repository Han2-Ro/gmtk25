# ABOUTME: Manages persistent high score storage and retrieval using Godot's user data system
# ABOUTME: Handles save/load operations and high score comparison logic
class_name HighScoreManager
extends RefCounted

const SAVE_FILE_PATH = "user://high_score.save"


func load_high_score() -> int:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		return 0

	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file == null:
		push_error("Failed to open high score file for reading")
		return 0

	var high_score = file.get_32()
	file.close()
	return high_score


func save_high_score(score: int) -> void:
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open high score file for writing")
		return

	file.store_32(score)
	file.close()


func check_and_update_high_score(current_score: int) -> bool:
	var previous_high_score = load_high_score()

	if current_score > previous_high_score:
		save_high_score(current_score)
		return true

	return false


func get_high_score() -> int:
	return load_high_score()
