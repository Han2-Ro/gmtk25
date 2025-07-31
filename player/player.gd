extends Node3D

var start_position: Transform3D


func _ready() -> void:
	start_position = self.transform


func on_sequence_flash_start() -> void:
	self.transform = start_position
