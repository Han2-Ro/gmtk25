extends Control

var tween: Tween
@onready var label: Label = $MarginContainer/HBoxContainer/CashLabel


func update_cash(amount: int) -> void:
	if tween:
		tween.kill()
	tween = create_tween()
	var current_value = int(label.text)
	var duration = clamp(sqrt(abs(amount - current_value) / 10), 0.1, 0.7)
	tween.tween_method(set_label_text, current_value, amount, duration)


func set_label_text(value: int):
	label.text = str(value)
