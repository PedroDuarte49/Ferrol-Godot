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
var cant_ene := 0
var aleatoria := 0
var enemigo 
# PreCargar
var enemigo_boina = preload("res://scenes/enemigo_boina.tscn")
var enemigo_fuerte = preload("res://scenes/enemigo_fuerte.tscn")

# Called when the node enters the scene tree for the first time.

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

	# Ahora sí hacemos fade desde negro hacia transparente
	fade.fade_from_black()
	
	spawn_enemies(0,500)

func add_points(points:int):
	score += points
	print("Points: ", score)

func spawn_enemies(left_border: int, right_border: int):
	await get_tree().create_timer(5.0).timeout
	while cant_ene > 0:
		aleatoria = randi_range(1,2)
		if aleatoria == 1:
			enemigo = enemigo_boina.instantiate()
		elif aleatoria == 2:
			enemigo = enemigo_fuerte.instantiate()
		
		aleatoria = randi_range(1,2)
		if aleatoria == 1:
			enemigo.position = Vector2(randf_range(-500,-100 ), randf_range(50,-50 ))
		elif aleatoria == 2:
			enemigo.position = Vector2(randf_range(500,700 ), randf_range(50,-50 ))
		
		add_child(enemigo)
		cant_ene -= 1
		await get_tree().create_timer(2.0).timeout
	
