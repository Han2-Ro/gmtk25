# ABOUTME: Manages custom cursor states and visuals for the game
# ABOUTME: Provides centralized cursor control with preloaded textures and proper hotspots

extends Node

enum CursorType { DEFAULT, HOVER, TARGET }

var cursor_textures: Dictionary = {}
var cursor_hotspots: Dictionary = {}


func _ready():
	_load_cursor_textures()
	set_cursor(CursorType.DEFAULT)


func _load_cursor_textures():
	cursor_textures[CursorType.DEFAULT] = load(
		"res://cursors/PNG/Basic/Default/pointer_scifi_a.png"
	)
	cursor_textures[CursorType.HOVER] = load("res://cursors/PNG/Basic/Default/hand_point.png")
	cursor_textures[CursorType.TARGET] = load("res://cursors/PNG/Basic/Default/target_a.png")

	cursor_hotspots[CursorType.DEFAULT] = Vector2(2, 2)
	cursor_hotspots[CursorType.HOVER] = Vector2(8, 2)
	cursor_hotspots[CursorType.TARGET] = Vector2(16, 16)


func set_cursor(cursor_type: CursorType):
	if cursor_textures.has(cursor_type) and cursor_hotspots.has(cursor_type):
		Input.set_custom_mouse_cursor(
			cursor_textures[cursor_type], Input.CURSOR_ARROW, cursor_hotspots[cursor_type]
		)


func set_default_cursor():
	set_cursor(CursorType.DEFAULT)


func set_hover_cursor():
	set_cursor(CursorType.HOVER)


func set_target_cursor():
	set_cursor(CursorType.TARGET)
