# ABOUTME: Coin Multiplier upgrade that doubles all coin rewards for the current run
# ABOUTME: Extends BaseUpgrade and uses cash_changed signal to add bonus cash
extends BaseUpgrade

@export var multiplier: float = 2.0

var cash_manager: CashManager


func _on_purchase() -> void:
	print("DOUBLE PURCHASED")
	super._on_purchase()

	if cash_manager:
		# Because we have to disconnect before adding the bonus
		# we can't use the broadcast from upgrade manager
		cash_manager.cash_changed.connect(_on_cash_changed)
		print("Connected to cash manager for coin doubling")
	else:
		push_error("Cash manager not available")


func _on_cash_changed(_new_total: int, amount_added: int) -> void:
	print("DOUBLE THE DOUBLOONS")
	# Add bonus cash based on the amount that was just added
	if amount_added > 0:
		var bonus_amount = int((multiplier - 1.0) * amount_added)
		if bonus_amount > 0:
			# Temporarily disconnect to avoid infinite loop
			cash_manager.cash_changed.disconnect(_on_cash_changed)
			cash_manager.add_cash(bonus_amount)
			cash_manager.cash_changed.connect(_on_cash_changed)


func _on_game_over() -> void:
	super._on_game_over()
	# Disconnect from cash manager
	if cash_manager and cash_manager.cash_changed.is_connected(_on_cash_changed):
		cash_manager.cash_changed.disconnect(_on_cash_changed)
