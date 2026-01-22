extends Node2D
@onready var line_edit: LineEdit = $LineEdit
@onready var label: Label = $Label
@onready var score: Label = $Score
@onready var submit: Button = $Subir


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	score.text=str(GameManager.saved_score)

	

func _on_server_has_responded(_result, response_code, headers, body):
	var response = JSON.parse_string(body.get_string_from_utf8())
	print("Server response:")
	print(response)


func _on_volver_pressed() -> void:
	get_tree().change_scene_to_file("res://main_menu.tscn") 



func _on_subir_pressed() -> void:
	var username = line_edit.text
	print("username is: " + username)
	if username == null:
		printerr("Will NOT send POST data with score due to invalid username")
		printerr("There might have been an error loading user_data file")
		return


	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", _on_server_has_responded)
	var body = JSON.stringify({"username": username, "score": int(score.text)})
	var headers = ["Content-Type: application/json", "Client-Secret: abc"] # CLIENT_SECRET should never be public! If leaked, AL
	http_request.request("http://127.0.0.1:8000/score", headers, HTTPClient.METHOD_POST, body)
	get_tree().change_scene_to_file("res://scenes/scoreboard.tscn") 
