extends CanvasLayer

signal game_begin
signal settings_open

func _ready():
	pass

func _on_texture_button_pressed():
	$".".visible = false
	emit_signal("game_begin")

func _on_texture_button_2_pressed():
	$".".visible = false
	emit_signal("settings_open")

func _on_settings_menu_settings_close():
	$".".visible = true
