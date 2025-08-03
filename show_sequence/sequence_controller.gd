class_name SequenceController
extends Node

signal sequence_flash_start
signal flash_button(button: SequenceButton)
signal sequence_flash_end

signal sequence_button_pressed(button: SequenceButton)
signal pressed_correct(button: SequenceButton)
signal pressed_wrong(button: SequenceButton)

signal sequence_start(sequence: Array[SequenceButton])
signal subsequence_start(current_round: int, total_rounds: int)
signal step_completed(current_step: int, total_steps: int)
signal subsequence_completed(current_round: int, total_rounds: int)
signal sequence_completed(sequence: Array[SequenceButton])
signal fast_forward_toggled(is_enabled: bool)

enum TileShape { SQUARE, HEXAGON }

@export_range(2, 20, 1, "or_greater") var sequence_length = 5
@export_range(1, 20, 1, "or_greater") var steps_to_reveal = 1
@export var grid_width: int = 3
@export var grid_height: int = 3
@export var hex_grid_outer_width: int = 3
@export_category("Tiles")
@export var square_tile_scene: PackedScene
@export var hexagon_tile_scene: PackedScene
@export var tile_spaceing: float = 1.0
@export var tile_shape: TileShape

# Audio
@export var correct_sound: AudioStream
@export var wrong_sound: AudioStream

var audio_player: AudioStreamPlayer

# Fast forward state
var stored_time_scale: float = 1.0
var is_fast_forward_enabled: bool = false


func _ready():
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)


func play_correct_sound():
	AudioManager.play_correct_sound()


func play_wrong_sound():
	AudioManager.play_wrong_sound()


func flash_sequence(sequence: Array[SequenceButton]):
	sequence_flash_start.emit()

	# Apply fast forward if enabled
	if is_fast_forward_enabled:
		Engine.time_scale = 2.0
	else:
		Engine.time_scale = 1.0

	for step in sequence:
		flash_button.emit(step)
		await step.flash()

	# Always reset to normal speed after sequence
	Engine.time_scale = 1.0
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
			var button_instance = square_tile_scene.instantiate()
			add_child(button_instance)

			# Position button in grid
			var pos_x = x * tile_spaceing - grid_center_x
			var pos_z = y * tile_spaceing - grid_center_y
			button_instance.position = Vector3(pos_x, 0, pos_z)

			# Add button to grid
			button_grid.set_at(x, y, button_instance)

	return button_grid


func generate_hexagon_grid() -> Grid:
	var max_width = hex_grid_outer_width * 2 - 1

	# Calculate grid center offset
	var grid_center_x = (hex_grid_outer_width - 1) * tile_spaceing * 0.5
	var grid_center_y = (max_width - 1) * sqrt(3) / 2 * tile_spaceing * 0.5  #(max_width - 1) * tile_spaceing * 0.5
	var button_grid = Grid.new(max_width, max_width)

	# store it in acial coords https://www.redblobgames.com/grids/hexagons/#map-storage
	for y in range(max_width):
		for x in range(
			clamp(-hex_grid_outer_width + y + 1, 0, max_width),
			clamp(hex_grid_outer_width + y, 0, max_width)
		):
			var button_instance = hexagon_tile_scene.instantiate()
			add_child(button_instance)

			# used these formulas: https://www.redblobgames.com/grids/hexagons/#hex-to-pixel
			var pos_x = (x - y * 0.5) * tile_spaceing - grid_center_x
			var pos_z = y * sqrt(3) / 2 * tile_spaceing - grid_center_y
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


func start_game() -> void:
	# Reset player position at the start of each new level

	var grid: Grid
	match tile_shape:
		TileShape.SQUARE:
			grid = generate_grid()
		TileShape.HEXAGON:
			grid = generate_hexagon_grid()

	# Wait for the scene tree to process the new nodes
	await get_tree().process_frame

	for button in grid.array:
		button.pressed.connect(_on_sequence_button_pressed.bind(button))
		button._controller_ready(self)

	var sequence := generate_sequence(grid.array, sequence_length)
	sequence_start.emit(sequence)

	var current_step = steps_to_reveal
	while current_step < len(sequence):
		for button in grid.array:
			button.disabled = true
		# wait a moment between each new subsequence
		await get_tree().create_timer(2).timeout

		var current_sub_sequence = sequence.slice(0, current_step)
		subsequence_start.emit(current_step, len(sequence))
		await play_sequence(current_sub_sequence)
		subsequence_completed.emit(current_step, len(sequence))
		current_step += steps_to_reveal

	# Always play the full sequence at the end
	for button in grid.array:
		button.disabled = true
	await get_tree().create_timer(2).timeout

	subsequence_start.emit(len(sequence), len(sequence))
	await play_sequence(sequence)
	subsequence_completed.emit(len(sequence), len(sequence))

	sequence_completed.emit()


func play_sequence(sequence: Array[SequenceButton]):
	await flash_sequence(sequence)

	var step = 0
	while step < len(sequence):
		var correct_button = sequence[step]

		var pressed_button: SequenceButton = await sequence_button_pressed
		if pressed_button == correct_button:
			print("Correct")
			play_correct_sound()
			pressed_correct.emit(pressed_button)
			pressed_button.this_pressed_correct()
			step_completed.emit(step + 1, len(sequence))
			step += 1
		else:
			print("WRONG!")
			play_wrong_sound()
			pressed_wrong.emit(pressed_button)
			await pressed_button.this_pressed_wrong()
			# Wait for mistake notification to display before replaying sequence
			await get_tree().create_timer(1.5).timeout
			await flash_sequence(sequence)
			step = 0


func _on_sequence_button_pressed(pressed_button: SequenceButton):
	sequence_button_pressed.emit(pressed_button)


func toggle_fast_forward() -> void:
	is_fast_forward_enabled = not is_fast_forward_enabled
	fast_forward_toggled.emit(is_fast_forward_enabled)
	print("Fast forward toggled: ", is_fast_forward_enabled)
