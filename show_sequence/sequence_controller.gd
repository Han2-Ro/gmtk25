class_name SequenceController
extends Node

signal sequence_flash_start
signal flash_button(button: SequenceButton)
signal sequence_flash_end
signal pressed_correct(button: SequenceButton)
signal pressed_wrong(button: SequenceButton)
signal step_completed(current_step: int, total_steps: int)
signal subsequence_completed(current_round: int, total_rounds: int)
signal sequence_completed

@export_range(2, 20, 1, "or_greater") var sequence_length = 5

@export var grid_width: int = 3
@export var grid_height: int = 3
@export var button_scene: PackedScene
@export var button_spacing: float = 1.0

var shop_manager: ShopManager


func flash_sequence(sequence: Array[SequenceButton]):
	sequence_flash_start.emit()
	for step in sequence:
		flash_button.emit(step)
		await step.flash()
	sequence_flash_end.emit()


func generate_sequence(buttons: Array[SequenceButton], length: int):
	var sequence: Array[SequenceButton] = []
	for i in range(length):
		sequence.append(buttons.pick_random())
	return sequence


func generate_grid() -> Grid:
	# Calculate grid center offset
	var grid_center_x = (grid_width - 1) * button_spacing * 0.5
	var grid_center_y = (grid_height - 1) * button_spacing * 0.5

	var button_grid = Grid.new(grid_width, grid_height)

	for y in range(grid_height):
		for x in range(grid_width):
			var button_instance = button_scene.instantiate()
			add_child(button_instance)

			# Position button in grid
			var pos_x = x * button_spacing - grid_center_x
			var pos_z = y * button_spacing - grid_center_y
			button_instance.position = Vector3(pos_x, 0, pos_z)

			# Add button to grid
			button_grid.set_at(x, y, button_instance)

	return button_grid


func generate_path(grid: Grid, length: int, start: Vector2i) -> Array[SequenceButton]:
	var path: Array[SequenceButton] = []
	var current_coordinates: Vector2i = start
	path.append(grid.get_at(current_coordinates.x, current_coordinates.y))
	for i in range(length):
		var choices: Array[Vector2i] = [
			Vector2i(current_coordinates.x, current_coordinates.y + 1),
			Vector2i(current_coordinates.x + 1, current_coordinates.y),
			Vector2i(current_coordinates.x, current_coordinates.y - 1),
			Vector2i(current_coordinates.x - 1, current_coordinates.y)
		]
		choices = choices.filter(func(c): return grid.get_at(c.x, c.y))
		if choices.is_empty():
			push_error("No valid choices available for path generation.")
			return []
		current_coordinates = choices.pick_random()
		path.append(grid.get_at(current_coordinates.x, current_coordinates.y))
	return path


func start_game() -> void:
	var grid := generate_grid()

	# Wait for the scene tree to process the new nodes
	await get_tree().process_frame

	for button in grid.array:
		button.pressed.connect(_on_wrong_button_pressed.bind(button))
		button._controller_ready(self)

	var sequence := generate_path(grid, sequence_length, Vector2i(0, 0))

	for i in range(len(sequence)):
		for button in grid.array:
			button.disabled = true
		# wait a moment between each new subsequence
		await get_tree().create_timer(2).timeout

		var sub_sequence = sequence.slice(0, i + 1)
		await play_sequence(sub_sequence)
		subsequence_completed.emit(i + 1, len(sequence))

	sequence_completed.emit()


func play_sequence(sequence: Array[SequenceButton]):
	flash_sequence(sequence)

	for i in range(len(sequence)):
		var step = sequence[i]
		step.pressed.disconnect(_on_wrong_button_pressed)

		await step.pressed
		pressed_correct.emit(step)
		step.this_pressed_correct()

		step.pressed.connect(_on_wrong_button_pressed.bind(step))

		step_completed.emit(i + 1, len(sequence))
		print("Correct")

	print("SEQUENCE COMPLETE")


func _on_wrong_button_pressed(pressed_button: SequenceButton):
	print("WRONG!")
	pressed_wrong.emit(pressed_button)
	await pressed_button.this_pressed_wrong()
