extends Control

# Función para el botón PLAY
func _on_play_pressed():
	# Cambia "res://nive_1.tscn" por la ruta de tu escena de juego real
	get_tree().change_scene_to_file("res://main_menu.tscn") 
	print("Cargando juego...")


#Funcion para el botón How to
func _on_how_to_pressed():
	get_tree().change_scene_to_file("res://how_to.tscn")
	print("Yendo a la pantalla How To...")
# Función para el botón EXIT
func _on_exit_pressed():
	get_tree().quit()
	print("Cerrando juego...")
