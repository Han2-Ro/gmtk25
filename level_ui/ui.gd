class_name LevelUI
extends Control

signal restart_button_pressed

@onready var overlay: Control = $Overlay
@onready var overlay_label: Label = $Overlay/Panel/VBoxContainer/Label


func show_overlay(is_win: bool) -> void:
	if is_win:
		overlay_label.text = "YOU WON!"
	else:
		overlay_label.text = "YOU ARE A LOOOOOSER"
	overlay.visible = true


func _on_restart_button_pressed() -> void:
	restart_button_pressed.emit()
