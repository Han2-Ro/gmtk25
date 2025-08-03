# ABOUTME: UI component for displaying current level number
# ABOUTME: Shows "Level X" where X increments from 1 for each completed sequence
extends Label


func update_level(level: int) -> void:
	self.text = "Level {0}".format([level])
