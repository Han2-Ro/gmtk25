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

var buttons: Array[SequenceButton]

var level_sequence: Array[SequenceButton]
var user_presses: Array[SequenceButton] = []

func generate_sequence(length: int):
	var sequence: Array[SequenceButton] = []
	for i in range(length):
		sequence.append(buttons.pick_random())
	return sequence

func _ready() -> void:
	# can't directly assign get_childred()
	# because it's type is Array[Node]
	# this way we get almost compile time type checking
	for button in get_children():
		buttons.append(button)
		button._controller_ready(self)
		
		# TODO: do not use index but actual tile
		button.pressed.connect(_on_button_pressed.bind(button))
		
	level_sequence = generate_sequence(9)
	flash_sequence(level_sequence)


func _on_button_pressed(pressed_button: SequenceButton) -> void:
	var current_step = len(user_presses)
	var expected_button = level_sequence[current_step]
	var is_correct = expected_button == pressed_button
	if is_correct:
		user_presses.append(pressed_button)
		pressed_correct.emit(pressed_button)
		await pressed_button.this_pressed_correct()
		step_completed.emit()
	else:
		print("WRONG! Should have been button", expected_button)
		pressed_wrong.emit(pressed_button)
		await pressed_button.this_pressed_wrong()
