extends CharacterBody2D
class_name Enemy

# --- NODOS ---
@onready var flipper: Node2D = $flipper
@onready var anim: AnimatedSprite2D = $flipper/AnimatedSprite2D
@onready var enemy_avoid_area: Area2D = $flipper/enemy_avoid_area
@onready var attack_hitbox: Area2D = $flipper/attack_hitbox
@onready var hurtbox: CollisionShape2D = $hurtbox
@onready var blood_particles: CPUParticles2D = $flipper/blood_particles

# --- NODOS DE AUDIO ---
# Asegúrate de que estos nodos existan en tu escena con estos nombres exactos
@onready var walk_sound: AudioStreamPlayer2D = $Movimiento
@onready var attack_sound = $Golpe
@onready var death_sound = $Muerte

# --- ESTADOS ---
enum State { IDLE, CHASE, READY, ATTACK, HURT, DEAD }
var state: State = State.IDLE

# --- PROPIEDADES ---
var health = 40
var speed = 120.0
var attack_power = 5
var attack_cooldown = 1.5
var attack_timer = 0.0
var direction = -1
var attack_offset_x := 0.0
var death_started 
const MAX_VERTICAL_DIFF := 20.0
const MIN_X_SEPARATION := 20.0
const ATTACK_DISTANCE_X := 20.0
const Z_BASE = 100

# ------------------- CICLO DE VIDA -------------------

func _ready():
	anim.connect("animation_finished", Callable(self, "_on_anim_finished"))
	state = State.IDLE
	attack_offset_x = randf_range(-30, 30)

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		# Seguridad: Detener pasos si está muerto
		if walk_sound.playing: walk_sound.stop()
		state_dead(delta)
		move_and_slide()
		return

	attack_timer = max(attack_timer - delta, 0)
	process_state(delta)

	# --- LÓGICA DE AUDIO DE PASOS ---
	# Solo suena si el enemigo tiene velocidad y está persiguiendo
	if velocity.length() > 10 and state == State.CHASE:
		if not walk_sound.playing:
			walk_sound.play()
	else:
		if walk_sound.playing:
			walk_sound.stop()

	# Aplicar separación y mover
	velocity += apply_enemy_separation(delta)
	move_and_slide()
	
	# Orden de dibujo (Y-Sort manual)
	z_index = Z_BASE + int(global_position.y)

# ------------------- GESTIÓN DE ESTADOS -------------------

func process_state(delta: float):
	match state:
		State.IDLE: state_idle(delta)
		State.CHASE: state_chase(delta)
		State.READY: state_ready(delta)
		State.ATTACK: state_attack(delta)
		State.HURT: state_hurt(delta)
		State.DEAD: state_dead(delta)

func state_idle(_delta):
	velocity = Vector2.ZERO
	play_anim("idle")
	if GameManager.player:
		state = State.CHASE

func state_chase(_delta):
	if state == State.HURT or not GameManager.player:
		return
	play_anim("chase")

	var player_pos = GameManager.player.global_position
	var target_pos = player_pos + Vector2(attack_offset_x, 0)
	var dir = target_pos - global_position

	# Alineación en Y
	if abs(dir.y) > MAX_VERTICAL_DIFF:
		velocity.y = sign(dir.y) * speed * 0.6
	else:
		velocity.y = 0

	# Acercamiento en X
	if abs(dir.x) > ATTACK_DISTANCE_X:
		set_direction(sign(dir.x))
		velocity.x = direction * speed
	else:
		velocity.x = 0
		if abs(dir.y) <= MAX_VERTICAL_DIFF:
			state = State.READY

func state_ready(_delta):
	play_anim("ready")
	velocity = Vector2.ZERO
	if not GameManager.player:
		state = State.IDLE
		return
	
	var dir = GameManager.player.global_position - global_position
	if abs(dir.y) > MAX_VERTICAL_DIFF:
		state = State.CHASE

func state_attack(_delta):
	play_anim("attack")
	velocity.x = 0

	# --- AUDIO: Golpe al aire ---
	if anim.frame == 0 and not attack_sound.playing:
		attack_sound.play()

	# Frames de impacto (ajusta según tu animación)
	if anim.frame in [2, 6]:
		attack_hitbox.monitoring = true
	else:
		attack_hitbox.monitoring = false

func state_hurt(_delta):
	play_anim("hurt")
	# Se detienen los pasos mientras recibe el golpe
	if walk_sound.playing: walk_sound.stop()

func state_dead(_delta):
	if death_started:
		return

	death_started = true

	velocity = Vector2.ZERO
	play_anim("die")
	attack_hitbox.monitoring = false
	hurtbox.disabled = true
	if not (self is Colegiala):
		GameManager.enemigo_muerto()
	
	death_sound.play()
	await death_sound.finished
	queue_free()

		

# ------------------- LÓGICA DE COMBATE -------------------

func take_damage(amount: int, from_position: Vector2, attack_type: int):
	if state == State.DEAD:
		return

	health -= amount
	spawn_blood()

	if health <= 0:
		state = State.DEAD
		GameManager.add_points(50)
	else:
	
		
		state = State.HURT
		apply_knockback(amount, from_position, attack_type)

func apply_knockback(amount:int, from_position: Vector2, attack_type:int, knockback_strength: float = 10.0, knockback_time = 0.5):
	var dir = (global_position - from_position).normalized()
	dir.y = -0.5 if attack_type == 1 else 0.0
	velocity = dir * (knockback_strength * amount)

	var t = get_tree().create_timer(knockback_time)
	t.connect("timeout", Callable(self, "_end_knockback"))

func _end_knockback():
	if state != State.DEAD:
		state = State.CHASE

# ------------------- UTILIDADES -------------------

func apply_enemy_separation(delta: float) -> Vector2:
	var push := Vector2.ZERO
	for body in enemy_avoid_area.get_overlapping_bodies():
		if body == self or not body.is_in_group("Enemy"): continue
		var diff := global_position - body.global_position
		if abs(diff.x) < MIN_X_SEPARATION:
			push.x += sign(diff.x) * (MIN_X_SEPARATION - abs(diff.x)) / MIN_X_SEPARATION * speed
		if abs(diff.y) < MAX_VERTICAL_DIFF:
			push.y += sign(diff.y) * (MAX_VERTICAL_DIFF - abs(diff.y)) / MAX_VERTICAL_DIFF * speed * 0.4
	return push * delta

func spawn_blood():
	if blood_particles:
		blood_particles.restart()
		blood_particles.emitting = true

func set_direction(dir):
	if dir == 0: return
	direction = dir
	flipper.scale.x = abs(flipper.scale.x) if dir > 0 else -abs(flipper.scale.x)

func play_anim(anim_name: String):
	if anim.animation != anim_name:
		anim.play(anim_name)

func _on_anim_finished():
	if anim.animation == "ready" and state == State.READY:
		state = State.ATTACK
	elif anim.animation == "attack" and state == State.ATTACK:
		state = State.CHASE
		attack_timer = attack_cooldown

func _on_attack_hitbox_area_entered(area: Area2D):
	if area.is_in_group("player_hurtbox"):
		var player = area.get_parent().get_parent()
		player.take_damage(attack_power, global_position, 0)
