extends Node2D

@onready var music_player = $MusicPlayer
var sound_player = preload("res://scenes/audio_player_universal.tscn")

var music = preload("res://art/sounds/dungeon_music.mp3")
var sounds = [
	preload("res://art/sounds/figure_match.mp3")
]

var fixed_sounds = [
	preload("res://art/sounds/concrete_break.mp3")
]
# Called when the node enters the scene tree for the first time.
func _ready():
	pass
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func play_random_music():
	music_player.stream = music
	music_player.play()

func play_random_sound():
	var sound_current = sound_player.instantiate()
	add_child(sound_current)
	sound_current.play_sound(sounds[0])

func play_fixed_sound(sound):
	var sound_current = sound_player.instantiate()
	add_child(sound_current)
	sound_current.play_sound(fixed_sounds[sound])
