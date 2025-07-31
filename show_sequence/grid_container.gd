extends GridContainer

func flash_sequence(sequence: Array[int]):
	for button in buttons:
		button.disabled = true
	for selected in sequence:
		var selected_button: TextureButton = buttons[selected]
		var original_modulate = selected_button.modulate
		selected_button.modulate = Color.GRAY
		await get_tree().create_timer(.8).timeout
		selected_button.release_focus()
		selected_button.modulate = original_modulate
		await get_tree().create_timer(.2).timeout
	for button in buttons:
		button.disabled = false

var buttons: Array[TextureButton]

var level_sequence: Array[int]
var user_presses = []

func generate_sequence(length: int):
	var max_index = len(buttons) - 1
	var sequence: Array[int] = []
	for i in range(length):
		var next = randi_range(0, max_index)
		sequence.append(next)
	return sequence

func _ready() -> void:
	# can't directly assign get_childred()
	# because it's type is Array[Node]
	# this way we get almost compile time type checking
	for button in get_children():
		buttons.append(button)
	
	for button_index in range(len(buttons)):
		var button: BaseButton = buttons[button_index]
		button.connect("pressed", _on_button_pressed.bind(button_index))
		
	level_sequence = generate_sequence(4)
	flash_sequence(level_sequence)


func _on_button_pressed(index: int) -> void:
	var current_step = len(user_presses)
	var expected_index = level_sequence[current_step]
	var pressed_button = buttons[index]
	if (expected_index == index):
		pressed_button.modulate = Color.GREEN_YELLOW
		user_presses.append(index)
	else:
		# TODO: disable wrong button until next step
		pressed_button.modulate = Color.INDIAN_RED
		print("WRONG! Should have been button", expected_index)
