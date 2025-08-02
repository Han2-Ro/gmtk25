# ABOUTME: Manages the player's cash/coin system including tracking and reward calculations
# ABOUTME: Provides methods to add cash, get current amount, and handle reward distributions
class_name CashManager
extends Node

signal cash_changed(new_total: int, amount_added: int)

var _current_cash: int = 0
var current_cash:
	get:
		return _current_cash
	set(value):
		var amount_changed = value - _current_cash
		_current_cash = value
		cash_changed.emit(_current_cash, amount_changed)

@export_range(1, 20, 1, "or_greater") var cash_per_step: int = 1
@export_range(1, 20, 1, "or_greater") var subsequence_bonus: int = 1

var shop_manager: ShopManager


func add_cash(amount: int) -> void:
	assert(amount > 0)
	current_cash += amount


func pay(amount: int) -> bool:
	assert(amount > 0)
	if current_cash >= amount:
		current_cash -= amount
		return true
	return false


func can_afford(price: int) -> bool:
	return current_cash >= price


func award_step_completion() -> void:
	add_cash(cash_per_step)


func award_subsequence_completion() -> void:
	add_cash(subsequence_bonus)


func award_sequence_completion(sequence_length: int) -> void:
	add_cash(sequence_length)
