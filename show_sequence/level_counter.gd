# ABOUTME: UI component for displaying current level (sequence length)
# ABOUTME: Shows "Level X" where X is the current sequence length
extends Label


func update_level(length: int) -> void:
	self.text = "Level {0}".format([length])
