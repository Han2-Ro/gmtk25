class_name LevelUI
extends Control

signal restart_button_pressed

@onready var overlay: Control = $Overlay
@onready var overlay_label: Label = $Overlay/Panel/VBoxContainer/Label
@onready var mini_win_label: Label = $MiniWinContainer/MiniWinLabel


func show_overlay(is_win: bool) -> void:
	if is_win:
		overlay_label.text = "YOU WON!"
	else:
		overlay_label.text = "YOU ARE A LOOOOOSER"
	overlay.visible = true


func show_mini_win(current_step: int, total_steps: int) -> void:
	var messages = ["Great!", "Perfect!", "Excellent!", "Keep going!", "Awesome!"]
	var message = messages.pick_random()
	mini_win_label.text = "%s (%d/%d)" % [message, current_step, total_steps]

	# Cancel any existing tween
	if mini_win_label.has_meta("tween"):
		var old_tween: Tween = mini_win_label.get_meta("tween")
		old_tween.kill()

	# Create fade in/out animation
	mini_win_label.visible = true
	var tween = create_tween()
	mini_win_label.set_meta("tween", tween)

	# Fade in
	tween.tween_property(mini_win_label, "modulate:a", 1.0, 0.2)
	# Hold
	tween.tween_interval(0.8)
	# Fade out
	tween.tween_property(mini_win_label, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): mini_win_label.visible = false)


func _on_restart_button_pressed() -> void:
	restart_button_pressed.emit()
