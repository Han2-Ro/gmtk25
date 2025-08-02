# ABOUTME: Lucky Charm upgrade that forgives the first mistake in each sequence
# ABOUTME: Uses session data to track whether first mistake has been used per sequence
class_name LuckyCharmUpgrade
extends BaseUpgrade


func _on_game_start() -> void:
	super._on_game_start()
	session_data["first_mistake_used"] = false


func _on_sequence_start() -> void:
	# Reset first mistake tracking at the start of each new sequence
	session_data["first_mistake_used"] = false


func _on_life_about_to_be_lost(event_args: LifeLossEventArgs) -> void:
	# Only forgive if this is the first mistake in the sequence
	if not session_data.get("first_mistake_used", false):
		session_data["first_mistake_used"] = true
		event_args.cancel()
		print("Lucky Charm: Forgave first mistake in sequence!")
