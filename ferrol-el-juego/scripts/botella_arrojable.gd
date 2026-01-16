extends Node2D

# ============================================================
# CONFIGURACIÓN
# ============================================================
@export var speed := 400.0
@export var gravity := 1400.0
@export var ground_y := 300.0
@export var damage := 25

# ============================================================
# ESTADO
# ============================================================
var velocity := Vector2.ZERO
var exploded := false

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
	velocity.x = direction.x * speed
	velocity.y = -550.0
	sprite.play("default")
	animation_player.play("rotar")

# ============================================================
# FÍSICA / MOVIMIENTO
# ============================================================
func _physics_process(delta):
	if exploded:
		return

	# Simular arco
	velocity.y += gravity * delta
	position += velocity * delta

	# Impacto contra suelo plano (sin colisiones)
	if position.y >= ground_y:
		explode()

# ============================================================
# EXPLOSIÓN
# ============================================================
func explode():
	if exploded:
		return

	exploded = true
	velocity = Vector2.ZERO

	# Ajustar exactamente al suelo para que no se vea hundida
	position.y = ground_y

	# Reproducir animación de explosión
	sprite.play("explode")

	# Activar área de daño
	damage_area.monitoring = true

	await sprite.animation_finished
	queue_free()

# ============================================================
# DAÑO A ENEMIGOS
# ============================================================
func _on_damage_area_body_entered(body):
	if body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
