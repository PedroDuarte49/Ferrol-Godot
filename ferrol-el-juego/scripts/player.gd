extends CharacterBody2D
class_name Player

# -------------------- NODOS --------------------
@onready var flipper: Node2D = $flipper
@onready var sprite: AnimatedSprite2D = $flipper/AnimatedSprite2D
@onready var attack_hitbox: Area2D = $flipper/attack_hitbox
@onready var blood_particles: CPUParticles2D = $flipper/blood_particles
@onready var hurtbox: CollisionShape2D = $CollisionShape2D
@onready var boost_particles: CPUParticles2D = $flipper/boost_particles
@onready var indicador: Node2D = $LandingIndicator
@export var botella_scene: PackedScene
@export var hud: CanvasLayer

# NUEVOS: Nodos de Audio
@onready var walk_sound = $Movimiento
@onready var attack_sound = $Ataque
@onready var hurt_sound = $Muerte 
@onready var drink_sound = $Beber
@onready var boost: AudioStreamPlayer2D = $boost

# -------------------- ESTADOS --------------------
enum State { IDLE, RUN, ATTACK, HURT, DEAD, DRINK }
var state: State = State.IDLE

# -------------------- VARIABLES --------------------
@export var speed := 180
@export var attack_power := 10
var attack_timer := 0.0

const Z_BASE = 100
var health := 100
var invulnerable := false
# --- Lanzamiento cargado ---
var cargando_botella := false
var fuerza := 0.0
var fuerza_dir := 1 # 1 sube, -1 baja

@export var fuerza_max := 1.0
@export var fuerza_speed := 1.5
@export var dist_min := 80.0
@export var dist_max := 350.0
var botellas = 0
var is_boosted := false
var drunk_time := 0.0
var drunk_tween: Tween


# -------------------- READY --------------------
func _ready():
	if not sprite.is_connected("frame_changed", Callable(self, "_on_frame_changed")):
		sprite.connect("frame_changed", Callable(self, "_on_frame_changed"))
	indicador.visible = false

# -------------------- PHYSICS PROCESS --------------------
func _physics_process(delta: float) -> void:
	z_index = Z_BASE + int(global_position.y)
	if state == State.DEAD:
		walk_sound.stop() # Parar pasos si muere
		return

	var direction := Vector2.ZERO

	if state not in [State.ATTACK, State.HURT, State.DRINK]:
		if Input.is_action_pressed("right"): direction.x += 1
		if Input.is_action_pressed("left"): direction.x -= 1
		if Input.is_action_pressed("down"): direction.y += 1
		if Input.is_action_pressed("up"): direction.y -= 1

		velocity = direction.normalized() * speed

		if direction.x != 0:
			flipper.scale.x = abs(flipper.scale.x) if direction.x > 0 else -abs(flipper.scale.x)

	if state == State.ATTACK or state == State.DRINK:
		velocity = Vector2.ZERO

	move_and_slide()
	if is_boosted:
		drunk_time += delta
		sprite.position.y = sin(drunk_time * 10.0) * 2.0
	else:
		sprite.position.y = 0

	# GESTIÓN DE ANIMACIONES Y SONIDO DE PASOS
	if state not in [State.ATTACK, State.HURT, State.DEAD, State.DRINK]:
		if direction != Vector2.ZERO:
			play_anim("correr")
			if not walk_sound.playing:
				walk_sound.play()
		else:
			play_anim("idle")
			walk_sound.stop()
	else:
		# Si está atacando, herido o bebiendo, no suenan los pasos
		walk_sound.stop()

	# Ataque
	if Input.is_action_just_pressed("attack") and state not in [State.ATTACK, State.HURT, State.DEAD]:
		start_attack()

	# Timer de ataque
	if state == State.ATTACK:
		attack_timer -= delta
		if attack_timer <= 0:
			state = State.IDLE
			attack_hitbox.monitoring = false
	
# ===============================
# CARGA BOTELLA (FINAL Y ÚNICA)
# ===============================

	if Input.is_action_just_pressed("lanzar") and GameManager.bottle > 0:
		print("EMPIEZA CARGA")
		cargando_botella = true
		fuerza = 0.0
		fuerza_dir = 1
		indicador.visible = true

	if Input.is_action_pressed("lanzar") and cargando_botella:
		fuerza += delta * fuerza_speed * fuerza_dir
		print("CARGANDO →", fuerza)

		if fuerza >= fuerza_max:
			fuerza = fuerza_max
			fuerza_dir = -1
		elif fuerza <= 0:
			fuerza = 0
			fuerza_dir = 1

		actualizar_indicador()

	if Input.is_action_just_released("lanzar") and cargando_botella:
		print("SUELTA →", fuerza)
		lanzar_botella()
		cargando_botella = false
		indicador.visible = false


# -------------------- ANIMACIONES --------------------
func play_anim(name: String):
	if sprite.animation != name:
		sprite.play(name)

# -------------------- ATAQUE --------------------
func start_attack():
	state = State.ATTACK
	play_anim("ataque1")
	
	# Sonido de ataque (el "swish" de la espada o golpe)
	if attack_sound:
		attack_sound.play()

	var frames = sprite.sprite_frames.get_frame_count("ataque1")
	var fps = sprite.sprite_frames.get_animation_speed("ataque1")
	attack_timer = frames / fps

func _on_frame_changed():
	if state == State.ATTACK:
		if sprite.frame == 2:
			attack_hitbox.monitoring = true
		else:
			attack_hitbox.monitoring = false

# -------------------- DAÑO --------------------
func take_damage(amount: int, from_position: Vector2, attack_type: int):
	if invulnerable or health <= 0:
		return
	attack_hitbox.monitoring = false
	invulnerable = true
	state = State.HURT

	play_anim("hurt")
	spawn_blood()

	apply_knockback(amount, from_position, attack_type)
	health -= amount
	GameManager.hud.update_life_bar(health)

	if health <= 0:
		die()


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

func die():
	if state == State.DEAD:
		return

	state = State.DEAD
	invulnerable = true
	velocity = Vector2.ZERO

	# Apagar ataque
	attack_hitbox.monitoring = false
	hurtbox.disabled = true
	blood_particles.emitting = true
	
	hurt_sound.play()
	sprite.play("muerte")
	await sprite.animation_finished


	GameManager.game_over()

func _on_attack_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy") or body.is_in_group("destructibles"):
		body.take_damage(attack_power,global_position,0)
		

func spawn_blood():
	if blood_particles:
		blood_particles.emitting = false
		blood_particles.restart()
		blood_particles.emitting = true

func gain_life(amount:int) -> void:
	if health + amount >= 100:
		health = 100
	else:
		health += amount
	
	realizar_accion_beber()
	print("health:", health)
	state = State.DRINK
	invulnerable = true
	play_anim("beber")
	await sprite.animation_finished
	invulnerable=false
	state = State.IDLE
	GameManager.hud.update_life_bar(health)

func boost_ataque() -> void:
	if is_boosted:
		return
	is_boosted = true
	drunk_time = 0.0
	boost.play()
	await realizar_accion_beber()
	start_drunk_effect()
	attack_power *= 2
	speed = 200
	await get_tree().create_timer(10.0).timeout
	end_boost()


func realizar_accion_beber():
	state = State.DRINK
	if drink_sound:
		drink_sound.play()
	play_anim("beber")
	await sprite.animation_finished
	state = State.IDLE

func end_boost():
	is_boosted = false

	stop_drunk_effect()
	sprite.position = Vector2.ZERO

	attack_power /= 2
	speed = 180


func _on_anim_finished() -> void:
	if state == State.HURT:
		state = State.IDLE
		
func start_drunk_effect():
	if drunk_tween:
		drunk_tween.kill()

	drunk_tween = create_tween()
	drunk_tween.set_loops()
	drunk_tween.tween_property(
		sprite,
		"modulate",
		Color(0.915, 0.617, 0.906, 1.0),
		0.4
	)
	drunk_tween.tween_property(
		sprite,
		"modulate",
		Color(0.643, 0.0, 0.643, 1.0),
		0.4
	)
	boost_particles.emitting = true
	
func stop_drunk_effect():
	if drunk_tween:
		drunk_tween.kill()
		drunk_tween = null

	sprite.modulate = Color.WHITE
	boost_particles.emitting = false
func lanzar_botella():
	print("Intentando lanzar botella, botellas restantes:", GameManager.bottle)
	if GameManager.bottle <= 0:
		return
	GameManager.bottle -= 1
	GameManager.hud.bottle(GameManager.bottle)

	var b = botella_scene.instantiate()
	get_parent().add_child(b)
	b.global_position = global_position

	# distancia depende de la fuerza
	var dir: float = sign(flipper.scale.x)
	var dist = lerp(dist_min, dist_max, fuerza)
	b.global_position = global_position
	b.throw_cargada(dir, dist)
	
func actualizar_indicador():
	var dir = sign(flipper.scale.x)
	var dist = lerp(dist_min, dist_max, fuerza)
	var y_offset = 30  # ajusta este valor según qué tan abajo quieras el indicador
	indicador.global_position = global_position + Vector2(dir * dist, y_offset)
	indicador.visible = true
	
func ocultar_indicador():
	indicador.visible = false
