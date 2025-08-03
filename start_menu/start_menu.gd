class_name StartMenu
extends Node3D

signal start_game

@export var start_button: Button3D

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)

func _on_start_pressed():
	var camera: GameCamera = $"../Camera3D"
	if camera:
		await camera.transition_to_map()
	else:
		printerr("Camera not found")
	print("Emitting start_game")
	start_game.emit()
