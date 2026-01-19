extends Control

func _ready():
	# Configuración de Sliders
	$VBoxContainer/MusicSlider.min_value = 0
	$VBoxContainer/MusicSlider.max_value = 1
	$VBoxContainer/MusicSlider.step = 0.05
	
	$VBoxContainer/SfxSlider.min_value = 0
	$VBoxContainer/SfxSlider.max_value = 1
	$VBoxContainer/SfxSlider.step = 0.05
	
	# Detecta si el juego ya inició en pantalla completa para marcar el botón
	$VBoxContainer/HBoxContainer/FullScreenButton.button_pressed = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)

# Control de Volumen Música
func _on_music_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))

# Control de Volumen SFX (Efectos)
func _on_sfx_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))

# Función de Pantalla Completa
func _on_full_screen_button_toggled(button_pressed: bool) -> void:
	if button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

# Botón para volver al menú 
func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://main_menu.tscn")
