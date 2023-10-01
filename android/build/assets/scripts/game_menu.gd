extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_settings_menu_mute():
	pass # Replace with function body.

func _on_base_menu_panel_game_begin():
	get_tree().change_scene_to_file("res://scenes/level_1.tscn")
