extends Control

# Rutas actualizadas: Ahora buscan dentro de "Fondo Secundario"
@onready var line_edit: LineEdit = $"Fondo Secundario/LineEdit"
@onready var label: Label = $"Fondo Secundario/Titulo" 
@onready var score: Label = $"Fondo Secundario/Score"
@onready var submit: Button = $"Fondo Secundario/Subir"
const API_BASE_URL ="https://breixo.pythonanywhere.com/score"
#https://breixo.pythonanywhere.com/score" para usar el server online 
# para servidor local -> "http://127.0.0.1:8000/score"


func _ready() -> void:
	# Verificación de seguridad para evitar el error 'null instance'
	if score:
		score.text = str(GameManager.score)
	else:
		printerr("Error: No se encontró el nodo Score. Revisa la ruta en el Inspector.")

func _on_server_has_responded(_result, response_code, headers, body):
	var response = JSON.parse_string(body.get_string_from_utf8())
	print("Respuesta del servidor:", response)
	
	# Solo cambiamos de escena cuando el servidor responde correctamente
	if response_code == 200 or response_code == 201:
		get_tree().change_scene_to_file("res://scenes/scoreboard.tscn")
	else:
		printerr("Error al subir puntuación. Código: ", response_code)

func _on_volver_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_subir_pressed() -> void:
	var username = line_edit.text
	
	if username == "" or username == null:
		printerr("Nombre de usuario inválido.")
		return

	# Creamos el request
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_server_has_responded)
	
	var body = JSON.stringify({"player": username, "points": GameManager.score})
	var headers = ["Content-Type: application/json", "Client-Secret: abc"]
	
	var error = http_request.request(API_BASE_URL, headers, HTTPClient.METHOD_POST, body)
	
	if error != OK:
		printerr("Error al lanzar la petición HTTP")
