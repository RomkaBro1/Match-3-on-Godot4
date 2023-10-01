extends CanvasLayer

signal mute
signal settings_close

func _on_texture_button_pressed():
	pass

func _on_texture_button_2_pressed():
	$".".visible = false
	emit_signal("settings_close")


func _on_base_menu_panel_settings_open():
	$".".visible = true
