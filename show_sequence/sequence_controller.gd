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

enum TileShape { SQUARE, HEXAGON }

@export_range(2, 20, 1, "or_greater") var sequence_length = 5
@export_range(1, 20, 1, "or_greater") var steps_to_reveal = 1
@export var grid_width: int = 3
@export var grid_height: int = 3
@export_category("Tiles")
@export var tile_scene: PackedScene
@export var tile_spaceing: float = 1.0
@export var tile_shape: TileShape

var shop_manager: ShopManager
var upgrade_manager: Node


func flash_sequence(sequence: Array[SequenceButton]):
	sequence_flash_start.emit()
	for step in sequence:
		flash_button.emit(step)
		await step.flash()
	sequence_flash_end.emit()


func generate_sequence(buttons: Array[SequenceButton], length: int) -> Array[SequenceButton]:
	var sequence: Array[SequenceButton] = []
	for i in range(length):
		sequence.append(buttons.pick_random())
	return sequence


func generate_grid() -> Grid:
	# Calculate grid center offset
	var grid_center_x = (grid_width - 1) * tile_spaceing * 0.5
	var grid_center_y = (grid_height - 1) * tile_spaceing * 0.5

	var button_grid = Grid.new(grid_width, grid_height)

	for y in range(grid_height):
		for x in range(grid_width):
			var button_instance = tile_scene.instantiate()
			add_child(button_instance)

			# Position button in grid
			var pos_x = x * tile_spaceing - grid_center_x
			var pos_z = y * tile_spaceing - grid_center_y
			button_instance.position = Vector3(pos_x, 0, pos_z)

			# Add button to grid
			button_grid.set_at(x, y, button_instance)

	return button_grid


func generate_hexagon_grid() -> Grid:
	var max_width = grid_width * 2 - 1

	# Calculate grid center offset
	var grid_center_x = (max_width - 1) * tile_spaceing * 0.5
	var grid_center_y = (max_width - 1) * tile_spaceing * 0.5

	var button_grid = Grid.new(max_width, max_width)

	# store it in acial coords https://www.redblobgames.com/grids/hexagons/#map-storage
	for y in range(grid_height * 2 - 1):
		for x in range(
			clamp(-grid_width + y + 1, 0, max_width), clamp(grid_width + y, 0, max_width)
		):
			print("Coords: ", y, x)
			var button_instance = tile_scene.instantiate()
			add_child(button_instance)

			# used these formulas: https://www.redblobgames.com/grids/hexagons/#hex-to-pixel
			var pos_x = (2 / sqrt(3) * x - sqrt(3) / 3 * y) * tile_spaceing - grid_center_x
			var pos_z = y * tile_spaceing - grid_center_y
			button_instance.position = Vector3(pos_x, 0, pos_z)

			# Add button to grid
			button_grid.set_at(x, y, button_instance)

	return button_grid


func generate_path(grid: Grid, length: int, start: Vector2i) -> Array[SequenceButton]:
	var path: Array[SequenceButton] = []
	var current_coordinates: Vector2i = start
	var previous_coordinates: Vector2i = start
	path.append(grid.get_at(current_coordinates.x, current_coordinates.y))
	for i in range(length - 1):
		var choices: Array[Vector2i] = [
			Vector2i(current_coordinates.x, current_coordinates.y + 1),
			Vector2i(current_coordinates.x + 1, current_coordinates.y),
			Vector2i(current_coordinates.x, current_coordinates.y - 1),
			Vector2i(current_coordinates.x - 1, current_coordinates.y)
		]
		choices = choices.filter(func(c): return grid.get_at(c.x, c.y))
		choices = choices.filter(func(c): return c != previous_coordinates)
		if choices.is_empty():
			push_error("No valid choices available for path generation.")
			return []
		previous_coordinates = current_coordinates
		current_coordinates = choices.pick_random()
		path.append(grid.get_at(current_coordinates.x, current_coordinates.y))
	return path


func _ready():
	# Get upgrade manager reference
	upgrade_manager = get_node_or_null("/root/UpgradeManager")
	if upgrade_manager:
		upgrade_manager.register_sequence_controller(self)


func start_game() -> void:
	# Reset player position at the start of each new level
	sequence_flash_start.emit()

	var grid: Grid
	match tile_shape:
		TileShape.SQUARE:
			grid = generate_grid()
		TileShape.HEXAGON:
			grid = generate_hexagon_grid()

	# Notify upgrade manager
	if upgrade_manager:
		upgrade_manager.broadcast_game_start()

	# Wait for the scene tree to process the new nodes
	await get_tree().process_frame

	for button in grid.array:
		button.pressed.connect(_on_wrong_button_pressed.bind(button))
		button._controller_ready(self)

	var sequence := generate_sequence(grid.array, sequence_length)

	# Store sequence in upgrade manager
	if upgrade_manager:
		upgrade_manager.current_sequence = sequence

	var current_step = steps_to_reveal
	while current_step < len(sequence):
		for button in grid.array:
			button.disabled = true
		# wait a moment between each new subsequence
		await get_tree().create_timer(2).timeout

		var sub_sequence = sequence.slice(0, current_step)
		if upgrade_manager:
			upgrade_manager.broadcast_subsequence_start(current_step, len(sequence))
		await play_sequence(sub_sequence)
		subsequence_completed.emit(current_step, len(sequence))

		current_step += steps_to_reveal

	# Always play the full sequence at the end
	for button in grid.array:
		button.disabled = true
	await get_tree().create_timer(2).timeout

	if upgrade_manager:
		upgrade_manager.broadcast_subsequence_start(len(sequence), len(sequence))
	await play_sequence(sequence)
	subsequence_completed.emit(len(sequence), len(sequence))

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
