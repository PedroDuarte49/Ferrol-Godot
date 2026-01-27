extends Camera2D

var target: Node2D = null
var shake_strength: float = 0.0
var shake_decay: float = 5.0
var shake_offset := Vector2.ZERO
@export var smooth: float = 0.1        # Suavizado general
@export var deadzone_size := Vector2(120, 70)  # Tamaño de la zona muerta (mitad ancho/alto)
var cam_float_pos := Vector2.ZERO

# NUEVO: bandera para bloquear cámara
var locked: bool = false
var lock_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	enabled = true # las activa el gamemanager
	target = GameManager.player
	cam_float_pos = global_position

func _process(_delta: float) -> void:
	if not enabled:
		return
	if locked:
		global_position = lock_position  # mantiene la posición bloqueada
		return
	if target == null:
		target = GameManager.player
		return
	follow_with_deadzone(_delta)

func follow_with_deadzone(_delta):
	var cam_pos = global_position
	var player_pos = target.global_position

	var min_x = cam_pos.x - deadzone_size.x
	var max_x = cam_pos.x + deadzone_size.x
	var min_y = cam_pos.y - deadzone_size.y
	var max_y = cam_pos.y + deadzone_size.y

	var new_pos = cam_pos
	# horizontal
	if player_pos.x < min_x:
		new_pos.x = player_pos.x + deadzone_size.x
	if player_pos.x > max_x:
		new_pos.x = player_pos.x - deadzone_size.x
	# vertical
	if player_pos.y < min_y:
		new_pos.y = player_pos.y + deadzone_size.y
	if player_pos.y > max_y:
		new_pos.y = player_pos.y - deadzone_size.y

	# suavizado
	cam_float_pos = cam_float_pos.lerp(new_pos, smooth)
	cam_float_pos = _apply_limits(cam_float_pos)

	global_position = cam_float_pos

func _apply_limits(pos : Vector2) -> Vector2:
	pos.x = clamp(pos.x, limit_left, limit_right)
	pos.y = clamp(pos.y, limit_top, limit_bottom)
	return pos

# --- NUEVOS MÉTODOS PARA BLOQUEAR / DESBLOQUEAR ---
func lock():
	locked = true
	lock_position = global_position

func unlock():
	locked = false
