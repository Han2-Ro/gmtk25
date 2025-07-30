extends GridContainer

func flash_sequence(sequence: Array[int]):
	for selected in sequence:
		var selected_button: Button = get_node("Button{0}".format([selected]))
		selected_button.text = "O"
		await get_tree().create_timer(.8).timeout
		selected_button.text = "X"
		
func generate_sequence(length: int):
	var sequence: Array[int]
	for i in range(length):
		sequence.append(randi_range(1, 9))
	return sequence

func _ready() -> void:
	var sequence = generate_sequence(10)
	flash_sequence(sequence)
