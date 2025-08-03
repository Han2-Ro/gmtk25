# ABOUTME: UI component for displaying current lives count
extends Control

var bars: Array[Node]


func _ready():
	bars = $MarginContainer/HBoxContainer.get_children() as Array[Node]


func update_lives(count: int) -> void:
	var active_barse = bars.slice(0, count)
	var inactive_bars = bars.slice(count)
	for bar in active_barse:
		bar.show()
	for bar in inactive_bars:
		bar.hide()
