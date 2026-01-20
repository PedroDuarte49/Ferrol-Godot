extends RigidBody2D
class_name Barrel

@export var life := 20
@export var pickup_scene: PackedScene   # Si es null → barril vacío
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Area2D

var is_breaking := false  # Evita romper dos veces

# Recibe daño amount es el pdoer de etaque, posicion la del player, tipo es para patada o puño asi podemso uasar knockback
func take_damage(amount: int, from_position: Vector2, attack_type: int):
	if is_breaking:
		return

	life -= amount
	anim.play("damage")
	shake()

	if life <= 0:
		break_barrel()

# Rompe el barril
func break_barrel():
	if is_breaking:
		return

	is_breaking = true

	# Desactivamos hitbox
	hitbox.set_deferred("monitoring", false)
	hitbox.set_deferred("monitorable", false)

	# Reproducimos animación de break
	anim.play("break")
	await anim.animation_finished

	# Spawn pickup si existe
	if pickup_scene:
		spawn_pickup()

	queue_free()

# Genera el pickup
func spawn_pickup():
	if pickup_scene:
		var pickup = pickup_scene.instantiate()
		pickup.global_position = global_position
		
		get_parent().call_deferred("add_child", pickup)

# Feedback visual al recibir daño
func shake():
	var t := 0.15
	var base_pos := position
	while t > 0:
		t -= get_process_delta_time()
		position = base_pos + Vector2(
			randf_range(-3, 3),
			randf_range(-3, 3)
		)
		await get_tree().process_frame
	position = base_pos
