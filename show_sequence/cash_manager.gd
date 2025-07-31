# ABOUTME: Manages the player's cash/coin system including tracking and reward calculations
# ABOUTME: Provides methods to add cash, get current amount, and handle reward distributions
class_name CashManager
extends Node

signal cash_changed(new_amount: int)

var current_cash: int = 0
var cash_per_step: int = 1
var subsequence_bonus: int = 1


func add_cash(amount: int) -> void:
	current_cash += amount
	cash_changed.emit(current_cash)


func get_cash() -> int:
	return current_cash


func reset_cash() -> void:
	current_cash = 0
	cash_changed.emit(current_cash)


func award_step_completion() -> void:
	add_cash(cash_per_step)


func award_subsequence_completion() -> void:
	add_cash(subsequence_bonus)


func award_sequence_completion(sequence_length: int) -> void:
	add_cash(sequence_length)
