extends Node2D

# ============================================================
# CONFIGURACIÓN
# ============================================================
@export var speed := 400.0
@export var gravity := 1400.0
@export var ground_y := 300.0
@export var damage := 50
@export var arc_height := 80.0 # Altura máxima de la parábola

# ============================================================
# ESTADO
# ============================================================
var velocity := Vector2.ZERO
var exploded := false
var start_y := 0.0
var t := 0.0 # tiempo de vuelo
var flight_time := 0.7 # duración total del vuelo en segundos
var target_x := 0.0
var start_pos: Vector2

# ============================================================
# NODOS
# ============================================================
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var damage_area: Area2D = $DamageArea
@onready var animation_player: AnimationPlayer = $AnimatedSprite2D/animation_player

# ============================================================
# INICIALIZACIÓN
# ============================================================
func _ready():
	# El área de daño empieza desactivada
	damage_area.monitoring = false

# ============================================================
# LANZAMIENTO
# ============================================================
func throw_cargada(dir: float, dist: float):
	start_pos = global_position
	target_x = start_pos.x + dir * dist
	t = 0
	sprite.play("default")
	animation_player.play("rotar")

# ============================================================
# FÍSICA / MOVIMIENTO
# ============================================================
func _physics_process(delta):
	if exploded:
		return

	t += delta
	var p = clamp(t / flight_time, 0.0, 1.0)

	# Movimiento horizontal
	global_position.x = lerp(start_pos.x, target_x, p)

	# PARÁBOLA CORRECTA (sube y baja)
	var h = 4.0 * arc_height * p * (1.0 - p)
	global_position.y = start_pos.y - h

	if p >= 1.0:
		explode()
# ============================================================
# EXPLOSIÓN
# ============================================================
func explode():
	if exploded:
		return

	exploded = true
		# Detener animación de rotación
	if animation_player.is_playing():
		animation_player.stop()
	
	sprite.play("explode")
	damage_area.monitoring = true
	print("Detectados:", damage_area.get_overlapping_bodies())

	# ===============================
	# DAÑO POR DISTANCIA (falso 3D)
	# ===============================
	var radius_x = 80   # alcance horizontal
	var radius_y = 35   # profundidad permitida

	for enemy in get_tree().get_nodes_in_group("Enemy"):
		var dx = abs(enemy.global_position.x - global_position.x)
		var dy = abs(enemy.global_position.y - global_position.y)

		if dx <= radius_x and dy <= radius_y:
			enemy.take_damage(damage, global_position, 1)

	await sprite.animation_finished
	queue_free()
