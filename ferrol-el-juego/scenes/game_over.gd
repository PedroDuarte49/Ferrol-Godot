extends Node
@onready var line_edit: LineEdit = $LineEdit
@onready var label: Label = $Label
@onready var score: Label = $Score
@onready var submit: Button = $Subir


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	score.text=str(GameManager.score)

	

func _on_server_has_responded(_result, response_code, _headers, body):
	var response = JSON.parse_string(body.get_string_from_utf8())
	print("Server response:", response)

	if response_code == 201:
		print("Score guardado correctamente")

	queue_free()



func _on_volver_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn") 



func _on_subir_pressed() -> void:
	var username = line_edit.text
	print("Nombre: " + username)
	if username.strip_edges() == "":
		printerr("Nombre vacío")
		return

	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", _on_server_has_responded)
	var body = JSON.stringify({"player": username, "points": int(score.text)})
	var headers = ["Content-Type: application/json", "Client-Secret: abc"] 
	http_request.request("http://127.0.0.1:8000/score", headers, HTTPClient.METHOD_POST, body)
	
	#cambio a scoreboard si eso
