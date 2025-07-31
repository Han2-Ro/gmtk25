extends GridContainer

func flash_sequence(sequence: Array[int]):
	for selected in sequence:
		var selected_button: BaseButton = get_node("Button{0}".format([selected]))
		selected_button.text = "O"
		await get_tree().create_timer(.8).timeout
		selected_button.text = "X"

var level_sequence = generate_sequence(3)
var buttons: Array[BaseButton]
var user_presses = []

func generate_sequence(length: int):
	var sequence: Array[int]
	for i in range(length):
		sequence.append(randi_range(1, 9))
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
	flash_sequence(level_sequence)


func _on_button_pressed(id: int) -> void:
	var current_step = len(user_presses)
	var expected_button = level_sequence[current_step]
	if (expected_button == id):
		print("Correct")
		user_presses.append(id)
	else:
		# TODO: disable wrong button until next step
		print("WRONG! Should have been button", expected_button)
