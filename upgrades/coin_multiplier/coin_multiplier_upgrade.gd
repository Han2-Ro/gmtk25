# ABOUTME: Coin Multiplier upgrade that doubles all coin rewards for the current run
# ABOUTME: Extends BaseUpgrade and uses cash_changed signal to add bonus cash
extends BaseUpgrade

@export var multiplier: float = 2.0

var cash_manager: CashManager


func _on_purchase() -> void:
	print("DOUBLE PURCHASED")
	super._on_purchase()
	# Find and connect to the cash manager
	cash_manager = _find_cash_manager()


func _find_cash_manager() -> CashManager:
	# Get the cash manager through the upgrade manager's scene tree
	if has_meta("upgrade_manager"):
		var upgrade_manager = get_meta("upgrade_manager")
		if upgrade_manager:
			var level_controller = upgrade_manager.get_parent()
			if level_controller and "cash_manager" in level_controller:
				var m = level_controller.cash_manager
				m.cash_changed.connect(_on_cash_changed)
				return m
	push_error("Could not find cash manager")
	return


func _on_cash_changed(_new_total: int, amount_added: int) -> void:
	print("DOUBLE THE DOUBLOUNS")
	# Add bonus cash based on the amount that was just added
	if amount_added > 0:
		var bonus_amount = int((multiplier - 1.0) * amount_added)
		if bonus_amount > 0:
			# Temporarily disconnect to avoid infinite loop
			cash_manager.cash_changed.disconnect(_on_cash_changed)
			cash_manager.add_cash(bonus_amount)
			cash_manager.cash_changed.connect(_on_cash_changed)


func _on_game_start() -> void:
	super._on_game_start()
	if not cash_manager:
		cash_manager = _find_cash_manager()


func _on_game_over() -> void:
	super._on_game_over()
	# Disconnect from cash manager
	if cash_manager and cash_manager.cash_changed.is_connected(_on_cash_changed):
		cash_manager.cash_changed.disconnect(_on_cash_changed)
