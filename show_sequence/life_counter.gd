# ABOUTME: UI component for displaying current lives count
extends Label


func update_lives(count: int) -> void:
	self.text = "{0} Lives".format([count])
