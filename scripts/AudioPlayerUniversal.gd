extends AudioStreamPlayer2D

func remove_self():
	queue_free()

func play_sound(sound_stream):
	set_stream(sound_stream)
	play()

func _ready():
	pass # Replace with function body.

func _on_finished():
	queue_free()
