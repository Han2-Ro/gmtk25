extends Node3D

var start_position: Transform3D
@onready var sequence_controller: SequenceController = get_tree().current_scene.get_node(
	"SequenceController"
)


func _ready() -> void:
	start_position = self.transform
	sequence_controller.sequence_flash_start.connect(on_sequence_flash_start)


func on_sequence_flash_start() -> void:
	self.transform = start_position
