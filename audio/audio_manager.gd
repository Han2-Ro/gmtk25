extends Node

var sound_player: AudioStreamPlayer
var music_player: AudioStreamPlayer

# Exported sounds - assign these in the inspector
@export var correct_sound: AudioStream
@export var wrong_sound: AudioStream
@export var background_music: AudioStream

func _ready():
	sound_player = AudioStreamPlayer.new()
	music_player = AudioStreamPlayer.new()
	add_child(sound_player)
	add_child(music_player)
	
	# Start background music if available
	if background_music:
		play_music(background_music)

func play_sound(stream: AudioStream):
	if stream:
		sound_player.stream = stream
		sound_player.play()

func play_correct_sound():
	play_sound(correct_sound)

func play_wrong_sound():
	play_sound(wrong_sound)

func play_music(stream: AudioStream, loop: bool = true):
	if stream:
		music_player.stream = stream
		if loop and stream is AudioStreamOggVorbis:
			stream.loop = true
		music_player.play()

func stop_music():
	music_player.stop()

func set_music_volume(volume_db: float):
	music_player.volume_db = volume_db

func set_sound_volume(volume_db: float):
	sound_player.volume_db = volume_db
