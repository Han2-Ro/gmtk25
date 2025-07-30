extends GridContainer

func flash_sequence(sequence: Array[int]):
	for selected in sequence:
		var selected_button: Button = get_node("Button{0}".format([selected]))
		selected_button.text = "O"
		await get_tree().create_timer(1).timeout
		selected_button.text = "X"

func _ready() -> void:
	flash_sequence([1, 9, 4])
