# ABOUTME: Slow Motion upgrade that reduces time scale during sequence flashing
# ABOUTME: Extends BaseUpgrade and uses Engine.time_scale to slow down sequence display
extends BaseUpgrade

var original_time_scale: float = 1.0


func _on_sequence_flash_start() -> void:
	# Only store original time scale if not already active
	if not is_active:
		original_time_scale = Engine.time_scale
		is_active = true

	# Calculate time scale based on stack count (0.5^stack_count)
	var slow_factor = pow(0.5, purchased_count)
	Engine.time_scale = slow_factor

	print(
		"Slow Motion activated: time_scale = ", Engine.time_scale, " (stack: ", purchased_count, ")"
	)


func _on_sequence_flash_end() -> void:
	# Restore original time scale and mark as inactive
	Engine.time_scale = original_time_scale
	is_active = false
	print("Slow Motion deactivated: time_scale restored to ", Engine.time_scale)


func _on_game_over() -> void:
	super._on_game_over()
	# Ensure time scale is restored on game over
	Engine.time_scale = original_time_scale
