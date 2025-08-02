# ABOUTME: Extra Life upgrade that adds additional lives for the current run
# ABOUTME: Extends BaseUpgrade and uses level controller's add_lives method
extends BaseUpgrade

var level_controller: LevelController


func _on_purchase() -> void:
	super._on_purchase()

	if level_controller:
		# Add one life per stack
		level_controller.add_lives(1)
		print("Extra Life: Added 1 life (total stack: %d)" % get_stack_count())
	else:
		push_error("Level controller not available for Extra Life upgrade")
