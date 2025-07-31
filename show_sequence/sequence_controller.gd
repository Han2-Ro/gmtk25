extends Node
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
		button.pressed.connect(_on_wrong_button_pressed.bind(button))

	var sequence = generate_sequence(buttons, 10)

	for i in range(len(sequence)):
		# wait a moment between each new step
		await get_tree().create_timer(2.0).timeout
		var sub_sequence = sequence.slice(0, i + 1)
		await play_sequence(sub_sequence)

	print("FULLY WON THIS SHIT!!!")


func play_sequence(
	sequence: Array[SequenceButton],
):
	flash_sequence(sequence)

	for step in sequence:
		step.pressed.disconnect(_on_wrong_button_pressed)

		await step.pressed
		pressed_correct.emit(step)
		step.this_pressed_correct()

		step.pressed.connect(_on_wrong_button_pressed.bind(step))

		step_completed.emit()
		print("Correct")

	print("SEQUENCE COMPLETE")


func _on_wrong_button_pressed(pressed_button: SequenceButton):
	print("WRONG!")
	pressed_wrong.emit(pressed_button)
	await pressed_button.this_pressed_wrong()
