extends Node
var fade: ColorRect
var hud: Node = null
var pause_menu : Node = null
var levelcontainer: Node2D = null
var player: Node = null
var level_index := 0
var current_level: Node = null
var current_level_path := ""
var player_spawn := "spawn"
var camera_locked := false
var camera_lock_position := Vector2.ZERO
signal all_enemies_defeated
var pause_enabled := true
var score := 0
var cant_ene := 0
var aleatoria := 0
var enemigo
var enemigo_vivo 
var zona := 1
var zona1
var zona2

# PreCargar
var enemigo_boina = preload("res://scenes/enemigo_boina.tscn")
var enemigo_fuerte = preload("res://scenes/enemigo_fuerte.tscn")

var saved_score := 0
var bottle := 3
# Called when the node enters the scene tree for the first time.

var levels = ["res://scenes/mapa-1.tscn","res://scenes/mapa-2.tscn","res://scenes/mapa-3.tscn"]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

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
	var spawn := current_level.get_node_or_null(player_spawn)
	if spawn:
		player.global_position = spawn.global_position
	await get_tree().process_frame  
	# Cámara
	var camera := get_tree().current_scene.get_node_or_null("Camera2D")
	if camera:
		# Fuerza actualización con el jugador
		camera.global_position = player.global_position

		# Resetea cualquier bloqueo anterior
		camera.limit_left = -100000
		camera.limit_right = 100000
		camera.limit_top = -100000
		camera.limit_bottom = 100000

		# Asegura que la cámara esté activa
		camera.process_mode = Node.PROCESS_MODE_INHERIT
		camera.make_current()

	if camera and current_level.has_method("apply_camera_limits"):
		current_level.apply_camera_limits(camera)
	zona1 = current_level.get_node("bordes/borde_zona1/CollisionShape2D")
	zona2 = current_level.get_node("bordes/borde_zona2/CollisionShape2D")
	await get_tree().process_frame

	hud.bottle(bottle)
	# Ahora sí hacemos fade desde negro hacia transparente
	if level_index == 0:
		lock_camera()
		aleatoria = randi_range(1,2)
		if aleatoria == 1:
			spawn_enemies(-64,0)
		elif aleatoria == 2:
			spawn_enemies(700,750)
		
		
	fade.fade_from_black()
	
	

func add_points(points:int):
	score += points
	print("Points: ", score)

func spawn_enemies(left_border: int, right_border: int):
	await get_tree().create_timer(2.0).timeout
	enemigo_vivo = cant_ene
	print(cant_ene)
	print(enemigo_vivo)
	while cant_ene > 0:
		aleatoria = randi_range(1,2)
		if aleatoria == 1:
			enemigo = enemigo_boina.instantiate()
		elif aleatoria == 2:
			enemigo = enemigo_fuerte.instantiate()
		
		if aleatoria == 1:
			enemigo.position = Vector2(randf_range(left_border,right_border), randf_range(50,-50 ))
		
		
		add_child(enemigo)
		cant_ene -= 1
		await get_tree().create_timer(2.0).timeout

func enemigo_muerto():
	enemigo_vivo -= 1
	if enemigo_vivo == 0:
		emit_signal("all_enemies_defeated")
		if zona == 3:
			unlock_camera()
			zona = 0
			level_index += 1
			fade.fade_to_black()
			await get_tree().process_frame 
			load_level(levels[level_index])
		elif zona == 1 or zona == 2:
			zona1.disabled = true
			zona2.disabled = true
			unlock_camera()
			
func enable_zones():
	zona1.set_deferred("disabled", false)
	zona2.set_deferred("disabled", false)
func lock_camera():
	var camera := get_tree().current_scene.get_node_or_null("Camera2D")
	if camera:
		camera.lock()
		
func unlock_camera():
	var camera := get_tree().current_scene.get_node_or_null("Camera2D")
	if camera:
		camera.unlock()

func new_zone(cant: int):
	lock_camera()
	enable_zones()
	cant_ene= cant
	if player.global_position.x < 1300 and player.global_position.x > 700:
		aleatoria = randi_range(1,2)
		if aleatoria == 1:
			spawn_enemies(650,690)
		elif aleatoria == 2:
			spawn_enemies(1350,1400)
		
	elif  player.global_position.x > 1300:
		aleatoria = randi_range(1,2)
		if aleatoria == 1:
			spawn_enemies(1250,1290)
		elif aleatoria == 2:
			spawn_enemies(1950,2000)
	else:
		aleatoria = randi_range(1,2)
		if aleatoria == 1:
			spawn_enemies(-64,0)
		elif aleatoria == 2:
			spawn_enemies(700,750)
	
	
func win_game():
	pause_enabled = false
	get_tree().paused = false
	pause_menu.visible = false
	await fade.fade_to_black()
	get_tree().change_scene_to_file("res://scenes/Win_Scene.tscn")

	#para pedro aqui es donde iria tu escena de cinematicas
func game_over():
	pause_enabled = false
	get_tree().paused = false
	pause_menu.visible = false
	await fade.fade_to_black()
	get_tree().change_scene_to_file("res://scenes/game_over.tscn")


func _input(event):
	if not pause_enabled:
		return

	if event.is_action_pressed("Pause"):
		if get_tree().paused:
			resume_game()
		else:
			pause_game()

func pause_game():
	get_tree().paused = true
	pause_menu.visible = true
func resume_game():
	get_tree().paused = false
	pause_menu.visible = false
