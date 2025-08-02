# ABOUTME: Cancellable event args for life loss events that upgrades can intercept
# ABOUTME: Uses shared reference pattern to allow multiple handlers to cancel the same event
class_name LifeLossEventArgs
extends RefCounted

var is_cancelled: bool = false
var button_pressed: SequenceButton
var current_lives: int


func _init(button: SequenceButton, lives: int) -> void:
	button_pressed = button
	current_lives = lives


func cancel() -> void:
	is_cancelled = true
