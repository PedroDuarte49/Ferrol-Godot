extends Control

func _on_play_pressed():
	GameManager.player = null
	GameManager.hud = null
	GameManager.levelcontainer = null
	GameManager.fade = null
	GameManager.pause_menu = null

	# Resetear datos globales
	GameManager.score = 0
	get_tree().change_scene_to_file("res://scenes/main_level.tscn")

func _on_options_pressed():
	get_tree().change_scene_to_file("res://scenes/opciones.tscn")

func _on_how_to_pressed():
	get_tree().change_scene_to_file("res://scenes/howto_menu.tscn")

func _on_exit_pressed():
	get_tree().quit()
