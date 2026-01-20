extends CharacterBody2D
class_name Player

# -------------------- NODOS --------------------
@onready var flipper: Node2D = $flipper
@onready var sprite: AnimatedSprite2D = $flipper/AnimatedSprite2D
@onready var attack_hitbox: Area2D = $flipper/attack_hitbox
@onready var blood_particles: CPUParticles2D = $flipper/Bloodparticles

# -------------------- ESTADOS --------------------
enum State { IDLE, RUN, ATTACK, HURT, DEAD }
var state: State = State.IDLE

# -------------------- VARIABLES --------------------
@export var speed := 180
@export var attack_power := 10
var attack_timer := 0.0

var health := 100
var invulnerable := false
var botellas = 0
# -------------------- READY --------------------
func _ready():
	if not sprite.is_connected("frame_changed", Callable(self, "_on_frame_changed")):
		sprite.connect("frame_changed", Callable(self, "_on_frame_changed"))

# -------------------- PHYSICS PROCESS --------------------
func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	var direction := Vector2.ZERO

	# Movimiento solo si no está atacando
	if state not in [State.ATTACK, State.HURT]:
		if Input.is_action_pressed("right"):
			direction.x += 1
		if Input.is_action_pressed("left"):
			direction.x -= 1
		if Input.is_action_pressed("down"):
			direction.y += 1
		if Input.is_action_pressed("up"):
			direction.y -= 1

		velocity = direction.normalized() * speed

		# Flip usando flipper
		if direction.x != 0:
			flipper.scale.x = abs(flipper.scale.x) if direction.x > 0 else -abs(flipper.scale.x)

	# Mientras atacas, bloquea la velocity
	if state == State.ATTACK:
		velocity = Vector2.ZERO

	move_and_slide()

	# Animaciones
	if state not in [State.ATTACK, State.HURT, State.DEAD]:
		if direction != Vector2.ZERO:
			play_anim("correr")
		else:
			play_anim("idle")

	# Ataque
	if Input.is_action_just_pressed("attack") and state not in [State.ATTACK, State.HURT, State.DEAD]:
		start_attack()

	# Timer de ataque
	if state == State.ATTACK:
		attack_timer -= delta
		if attack_timer <= 0:
			state = State.IDLE
			attack_hitbox.monitoring = false

# -------------------- ANIMACIONES --------------------
func play_anim(name: String):
	if sprite.animation != name:
		sprite.play(name)

# -------------------- ATAQUE --------------------
func start_attack():
	state = State.ATTACK
	play_anim("ataque1")

	# Duración del ataque según frames
	var frames = sprite.sprite_frames.get_frame_count("ataque1")
	var fps = sprite.sprite_frames.get_animation_speed("ataque1")
	attack_timer = frames / fps

# Activar hitbox solo en frame exacto
func _on_frame_changed():
	if state == State.ATTACK:
		if sprite.frame == 2:  # ajusta a tu frame de impacto
			attack_hitbox.monitoring = true
		else:
			attack_hitbox.monitoring = false

# -------------------- DAÑO Y KNOCKBACK --------------------
func take_damage(amount: int, from_position: Vector2, attack_type: int):
	if invulnerable or health <= 0:
		return
		#apagamos la hitbox de ataque 
	attack_hitbox.monitoring = false
	invulnerable = true
	state = State.HURT
	anim_modulate(Color(1,0,0))
	apply_knockback(amount, from_position, attack_type)
	health -= amount
func apply_knockback(amount: int, from_position: Vector2, attack_type:int, knockback_strength: float = 10.0, knockback_time: float = 0.1):
	var dir = (global_position - from_position).normalized()
	dir.y = 0 if attack_type == 0 else -0.5
	velocity = dir * (knockback_strength)

	var t = get_tree().create_timer(knockback_time * amount)
	t.connect("timeout", Callable(self, "_end_knockback"))

func _end_knockback():
	velocity = Vector2.ZERO
	invulnerable = false
	if state == State.HURT:
		state = State.IDLE

# -------------------- EFECTO VISUAL --------------------
func anim_modulate(color: Color):
	sprite.modulate = color
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color(1,1,1,1)


func _on_attack_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy") or body.is_in_group("destructibles"):
		body.take_damage(attack_power,global_position,0)
#---------------------SKILLS------------------------------
func gain_life(amount:int):
	health += amount
	print("health: ",health)
	#actualizar el hud

func boost_ataque():
	sprite.modulate = Color(0.643, 0.0, 0.643, 1.0)
	attack_power *= 2
	speed = 200
	var t = get_tree().create_timer(5.0)
	t.connect("timeout", Callable(self, "end_boost"))
	
func end_boost():
		sprite.modulate = Color(1,1,1,1)
		attack_power /= 2
		speed = 180
