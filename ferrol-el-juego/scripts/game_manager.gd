extends Node
var fade: ColorRect
var hud: Node = null
var levelcontainer: Node2D = null
var player: Node = null
var level_index := 0
var current_level: Node = null
var current_level_path := ""
var player_spawn_tag := "Spawn"

var score := 0
var saved_score := 0
var bottle := 1
# Called when the node enters the scene tree for the first time.
var summoned_enemies_alive := 0
var levels = ["res://scenes/mapa-1.tscn",
]

func _ready() -> void:
	pass # Replace with function body.

func load_level(path: String) -> void:
	# Fade a negro instantáneo
	fade.modulate.a = 1.0
	await get_tree().process_frame  # renderiza un frame completamente negro
	
	if current_level:
		current_level.queue_free()

	var scene = load(path)
	current_level = scene.instantiate()
	levelcontainer.add_child(current_level)

	current_level_path = path

	await get_tree().process_frame

	# Spawn
	var spawn := current_level.get_node_or_null(player_spawn_tag)
	if spawn:
		player.global_position = spawn.global_position
	await get_tree().process_frame  
	# Cámara
	var camera := get_tree().current_scene.get_node_or_null("Camera2D")
	if camera and current_level.has_method("apply_camera_limits"):
		current_level.apply_camera_limits(camera)

	await get_tree().process_frame

	hud.bottle(bottle)
	# Ahora sí hacemos fade desde negro hacia transparente
	fade.fade_from_black()

func add_points(points:int):
	score += points
	print("Points: ", score)

func game_over():
	await fade.fade_to_black()
	get_tree().change_scene_to_file("res://scenes/game_over.tscn") 
	
func register_summoned_enemy():
	summoned_enemies_alive += 1

func summoned_enemy_died():
	summoned_enemies_alive -= 1
	if summoned_enemies_alive < 0:
		summoned_enemies_alive = 0
