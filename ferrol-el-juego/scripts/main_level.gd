extends Node2D

# inyectar referecia al player 
@onready var levelcontainer: Node2D = $levelcontainer
@onready var fade: ColorRect = $CanvasLayer/fade
@onready var camera_2d: Camera2D = $Camera2D
@onready var hud: CanvasLayer = $Hud
@onready var player: Player = $player
@onready var pause_menu: Control = $CanvasLayer2/pause_menu




func _ready():
	# 🔗 Inyectar referencias en GameManager
	GameManager.hud = hud
	GameManager.player = player
	GameManager.levelcontainer = levelcontainer
	GameManager.fade = fade
	GameManager.pause_menu = pause_menu
	
	#  Player desactivado mientras carga
	player.set_physics_process(false)

	# 📍 Checkpoint inicial (SIEMPRE)
	#AAQUI ASIGNAMOS EL PRIMER SPAWN

	# ▶️ Cargar primer nivel usando GameManager
	await GameManager.load_level(GameManager.levels[0])

	#  Activar player
	player.set_physics_process(true)
