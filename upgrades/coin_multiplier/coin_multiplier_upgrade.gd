# ABOUTME: Coin Multiplier upgrade that doubles all coin rewards for the current run
# ABOUTME: Extends BaseUpgrade and intercepts cash rewards by modifying CashManager values
extends BaseUpgrade

@export var multiplier: float = 2.0

var cash_manager: CashManager
var original_cash_per_step: int
var original_subsequence_bonus: int


func _on_purchase() -> void:
	super._on_purchase()
	# Find and connect to the cash manager
	_find_cash_manager()


func _find_cash_manager() -> void:
	# Get the cash manager through the upgrade manager's scene tree
	if has_meta("upgrade_manager"):
		var upgrade_manager = get_meta("upgrade_manager")
		if upgrade_manager:
			var level_controller = upgrade_manager.get_parent()
			if level_controller and level_controller.has_property("cash_manager"):
				cash_manager = level_controller.cash_manager


func _on_game_start() -> void:
	super._on_game_start()
	_apply_multipliers()


func _apply_multipliers() -> void:
	if not cash_manager:
		_find_cash_manager()

	if cash_manager:
		# Store original values
		original_cash_per_step = cash_manager.cash_per_step
		original_subsequence_bonus = cash_manager.subsequence_bonus

		# Apply multipliers
		cash_manager.cash_per_step = int(original_cash_per_step * multiplier)
		cash_manager.subsequence_bonus = int(original_subsequence_bonus * multiplier)


func _on_sequence_complete() -> void:
	super._on_sequence_complete()
	# For sequence completion, we need to intercept since it uses the parameter directly
	# This will be called after the normal reward, so we add the extra amount
	if cash_manager:
		var sequence_length = _get_current_sequence_length()
		if sequence_length > 0:
			var extra_amount = int(sequence_length * (multiplier - 1.0))
			cash_manager.add_cash(extra_amount)


func _get_current_sequence_length() -> int:
	# Try to get sequence length from upgrade manager's sequence controller
	if has_meta("upgrade_manager"):
		var upgrade_manager = get_meta("upgrade_manager")
		if upgrade_manager and upgrade_manager.sequence_controller:
			return upgrade_manager.sequence_controller.sequence_length
	return 0


func _on_game_over() -> void:
	super._on_game_over()
	_restore_original_values()


func _restore_original_values() -> void:
	if cash_manager:
		# Restore original values
		cash_manager.cash_per_step = original_cash_per_step
		cash_manager.subsequence_bonus = original_subsequence_bonus
