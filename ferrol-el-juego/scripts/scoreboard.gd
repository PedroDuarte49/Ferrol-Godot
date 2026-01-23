extends Control

@onready var score_list: Label = $VBoxContainer/score_list


func _ready():
	load_scoreboard()

func load_scoreboard():
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_scoreboard_received)
	http_request.request("http://127.0.0.1:8000/score", [], HTTPClient.METHOD_GET)

func _on_scoreboard_received(result, response_code, headers, body):
	if response_code != 200:
		score_list.text = "Error HTTP: %d" % response_code
		return

	var json_result = JSON.parse_string(body.get_string_from_utf8())
	if typeof(json_result) != TYPE_DICTIONARY or not json_result.has("scores"):
		score_list.text = "JSON inválido"
		return

	var data = json_result["scores"]  # <-- Aquí tomamos el array real

	# Agrupar por jugador y mantener su puntuación máxima
	var player_max_scores := {}
	for entry in data:
		var player = entry["player"]
		var points = int(entry["points"])
		if not player_max_scores.has(player) or points > player_max_scores[player]:
			player_max_scores[player] = points

	# Convertir a array de diccionarios para mostrar
	var players_array := []
	for player in player_max_scores.keys():
		players_array.append({"player": player, "points": player_max_scores[player]})

	# Top 10
	var top_players = players_array.slice(0, 10)

	# Construir texto
	var text := ""
	for i in range(top_players.size()):
		var entry = top_players[i]
		text += "%d. %s : %d\n" % [i + 1, entry["player"], entry["points"]]

	score_list.text = text



func _on_volver_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn") 
