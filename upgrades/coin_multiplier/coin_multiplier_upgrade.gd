# ABOUTME: Coin Multiplier upgrade that doubles all coin rewards for the current run
# ABOUTME: Extends BaseUpgrade and intercepts cash rewards through CashManager signals
extends BaseUpgrade

@export var multiplier: float = 2.0

var cash_manager: CashManager


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
			if (
				level_controller
				and level_controller.has_method("get")
				and level_controller.get("cash_manager")
			):
				cash_manager = level_controller.cash_manager
				cash_manager.cash_changed.connect(_on_cash_changed)


func _on_cash_changed(new_amount: int) -> void:
	# This gets called after cash is added, but we need to intercept before
	# We'll override the cash manager's methods instead
	pass


func _on_game_start() -> void:
	super._on_game_start()
	_override_cash_methods()


func _override_cash_methods() -> void:
	if not cash_manager:
		_find_cash_manager()

	if cash_manager:
		# Store original methods
		session_data["original_award_step"] = cash_manager.award_step_completion
		session_data["original_award_subsequence"] = cash_manager.award_subsequence_completion
		session_data["original_award_sequence"] = cash_manager.award_sequence_completion

		# Replace with multiplied versions
		cash_manager.award_step_completion = _multiplied_step_completion
		cash_manager.award_subsequence_completion = _multiplied_subsequence_completion
		cash_manager.award_sequence_completion = _multiplied_sequence_completion


func _multiplied_step_completion() -> void:
	if cash_manager:
		cash_manager.add_cash(int(cash_manager.cash_per_step * multiplier))


func _multiplied_subsequence_completion() -> void:
	if cash_manager:
		cash_manager.add_cash(int(cash_manager.subsequence_bonus * multiplier))


func _multiplied_sequence_completion(sequence_length: int) -> void:
	if cash_manager:
		cash_manager.add_cash(int(sequence_length * multiplier))


func _on_game_over() -> void:
	super._on_game_over()
	_restore_cash_methods()


func _restore_cash_methods() -> void:
	if cash_manager and session_data.has("original_award_step"):
		# Restore original methods
		cash_manager.award_step_completion = session_data["original_award_step"]
		cash_manager.award_subsequence_completion = session_data["original_award_subsequence"]
		cash_manager.award_sequence_completion = session_data["original_award_sequence"]
