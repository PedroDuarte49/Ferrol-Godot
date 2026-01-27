extends Control

func _on_play_pressed():
	
	get_tree().change_scene_to_file("res://scenes/main_level.tscn")

func _on_options_pressed():
	get_tree().change_scene_to_file("res://scenes/opciones.tscn")

func _on_how_to_pressed():
	get_tree().change_scene_to_file("res://scenes/howto_menu.tscn")

func _on_exit_pressed():
	get_tree().quit()
