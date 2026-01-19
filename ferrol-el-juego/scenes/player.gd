extends CharacterBody2D

class_name Player

@export var speed := 200
@export var attack_damage := 1
@onready var attack_hitbox: Area2D = $attack_hitbox
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

@onready var sprite := $AnimatedSprite2D

var attacking := false

#recibir daño
var invulnerable = false
var invulnerable_time = 1.0
#recibir daño

#Vida
var health = 100
var alive = true
#Vida


func _physics_process(delta):
	if attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	var direction := Vector2.ZERO

	# Movimiento
	if Input.is_action_pressed("right"):
		direction.x += 1
	if Input.is_action_pressed("left"):
		direction.x -= 1
	if Input.is_action_pressed("down"):
		direction.y += 1
	if Input.is_action_pressed("up"):
		direction.y -= 1

	direction = direction.normalized()
	velocity = direction * speed
	move_and_slide()

	# Animación
	if direction != Vector2.ZERO:
		if sprite.animation != "correr":
			sprite.play("correr")

		# Volteo solo según X
		if direction.x != 0:
			sprite.flip_h = direction.x < 0
	else:
		if sprite.animation != "idle":
			sprite.play("idle")
	# Ataque
	if Input.is_action_just_pressed("attack"):
		attack()

func attack():
	attacking = true
	sprite.play("ataque1")
	$attack_hitbox.monitoring = true

	await sprite.animation_finished

	$attack_hitbox.monitoring = false
	attacking = false

		
func start_hit_effect():
	# Alterna el color del sprite para parpadear
	sprite.play("hurt")
	var blink_count = 5
	var blink_timer = 0.1
	for i in range(blink_count):
		$AnimatedSprite2D.modulate = Color(1, 0, 0)  # rojo
		await get_tree().create_timer(blink_timer).timeout
		$AnimatedSprite2D.modulate = Color(1, 1, 1)  # normal
		await get_tree().create_timer(blink_timer).timeout
	
	invulnerable = false
	
func take_damage(amount: int = 1):
	if invulnerable or health <= 0:
		return
		
	invulnerable = true
	start_hit_effect()
	


func _on_attack_hitbox_body_entered(body: Node2D) -> void:
		if body.is_in_group("Enemy"):
			body.take_damage(attack_damage,global_position,0)
