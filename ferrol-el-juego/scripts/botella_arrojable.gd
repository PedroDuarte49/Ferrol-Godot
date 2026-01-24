extends Node2D

# ============================================================
# CONFIGURACIÓN
# ============================================================
@export var speed := 400.0
@export var gravity := 1400.0
@export var ground_y := 300.0
@export var damage := 50
@export var arc_height := -100.0 # Altura máxima de la parábola

# ============================================================
# ESTADO
# ============================================================
var velocity := Vector2.ZERO
var exploded := false
var start_y := 0.0
var t := 0.0 # tiempo de vuelo
var flight_time := 0.5 # duración total del vuelo en segundos


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
func throw(direction: Vector2):
	start_y = position.y
	velocity.x = direction.x * speed
	velocity.y = -550.0
	sprite.play("default")
	animation_player.play("rotar")
	t = 0

# ============================================================
# FÍSICA / MOVIMIENTO
# ============================================================
func _physics_process(delta):
	if exploded:
		return
	t += delta
	position.x += velocity.x * delta
	# Altura simulada con parábola
	var h = -4 * arc_height * (t/flight_time) * (t/flight_time - 1)
	position.y = start_y + h

	if t >= flight_time:
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
