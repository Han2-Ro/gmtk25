class_name Grid
extends RefCounted

var width: int:
	get:
		return width
var height: int:
	get:
		return height
var _data: Array[SequenceButton]
var array: Array[SequenceButton]:
	get:
		return _data


func _init(width: int, height: int):
	self.width = width
	self.height = height
	_data = []
	_data.resize(width * height)


func get_at(x: int, y: int) -> SequenceButton:
	if x < 0 or x >= width or y < 0 or y >= height:
		return null

	return _data[y * width + x]


func set_at(x: int, y: int, value: SequenceButton):
	if x < 0 or x >= width or y < 0 or y >= height:
		push_error("Grid coordinates out of bounds: (%d, %d)" % [x, y])
		return

	_data[y * width + x] = value


func get_size() -> Vector2i:
	return Vector2i(width, height)
