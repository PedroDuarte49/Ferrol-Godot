extends Node2D

# inyectar referecia al player 
@onready var fade: ColorRect = $CanvasLayer/Fade
@onready var levelcontainer: Node2D = $levelcontainer
@onready var hud: Control = $Hud
@onready var camera: Camera2D = $Camera2D

#func _ready():
	# 🔗 Inyectar referencias en GameManager
	#GameManager.hud = hud
	#GameManager.player = drunkmaster
	#GameManager.levelcontainer = levelcontainer
	#GameManager.fade = fade
	
	# 🔒 Player desactivado mientras carga
	#player.set_physics_process(false)

	# 📍 Checkpoint inicial (SIEMPRE)


	# ▶️ Cargar primer nivel usando GameManager
	#await GameManager.load_level(GameManager.levels[0])

	# 🎮 Activar player
	#player.set_physics_process(true)

	# 🧠 HUD
	#hud.set_max_health(drunkmaster.life)
	#hud.update_health(drunkmaster.life)
	#hud.update_points()
