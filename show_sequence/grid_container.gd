extends GridContainer

func flash_sequence(sequence: Array[int]):
	for selected in sequence:
		var selected_button: BaseButton = get_node("Button{0}".format([selected]))
		selected_button.text = "O"
		await get_tree().create_timer(.8).timeout
		selected_button.text = "X"

var level_sequence = generate_sequence(3)
var user_presses = []

func generate_sequence(length: int):
	var sequence: Array[int]
	for i in range(length):
		sequence.append(randi_range(1, 9))
	return sequence

func _ready() -> void:
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
