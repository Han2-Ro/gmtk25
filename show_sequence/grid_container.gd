extends GridContainer
class_name SequenceController

signal sequence_flash_start
signal flash_button(SequenceButton)
signal sequence_flash_end
signal pressed_correct(SequenceButton)
signal pressed_wrong(SequenceButton)
signal step_completed

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

func _ready() -> void:
	# can't directly assign get_childred()
	# because it's type is Array[Node]
	# this way we get almost compile time type checking
	var buttons: Array[SequenceButton]
	for button in get_children():
		buttons.append(button)
		button._controller_ready(self)
		
	var sequence = generate_sequence(buttons, 3)
	play_sequence(buttons, sequence)
	
func play_sequence(
	buttons: Array[SequenceButton],
	level_sequence: Array[SequenceButton],
):
	flash_sequence(level_sequence)
	
	for button in level_sequence:
		var wrong_buttons = buttons.filter(func(b): return b != button)
		connect_wrong_buttons(wrong_buttons)
		
		await button.pressed	
		pressed_correct.emit(button)
		await button.this_pressed_correct()
		
		disconnect_wrong_buttons(wrong_buttons)
		step_completed.emit()
		print("Correct")
	
	print("WINNER")
	
func connect_wrong_buttons(buttons):
	for other_button in buttons:
		other_button.pressed.connect(_on_wrong_button_pressed.bind(other_button))
	
func disconnect_wrong_buttons(buttons):
	for other_button in buttons:
		other_button.pressed.disconnect(_on_wrong_button_pressed)

func _on_wrong_button_pressed(pressed_button: SequenceButton):
	print("WRONG!")
	pressed_wrong.emit(pressed_button)
	await pressed_button.this_pressed_wrong()
