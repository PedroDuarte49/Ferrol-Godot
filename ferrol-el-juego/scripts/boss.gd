extends CharacterBody2D
class_name Boss

# --- NODOS ---
@onready var flipper: Node2D = $flipper
@onready var anim: AnimatedSprite2D = $flipper/AnimatedSprite2D
@onready var enemy_avoid_area: Area2D = $flipper/enemy_avoid_area
@onready var attack_hitbox: Area2D = $flipper/attack_hitbox
@onready var hurtbox: CollisionShape2D = $hurtbox
@onready var blood_particles: CPUParticles2D = $flipper/blood_particles
@onready var summon_particles: CPUParticles2D = $flipper/summon_particles

# --- NODOS DE AUDIO ---
# Asegúrate de que estos nodos existan en tu escena con estos nombres exactos
@onready var walk_sound = $Movimiento
@onready var attack_sound = $Golpe
@onready var death_sound = $Muerte
@export var summon_markers: Array[Marker2D]
var paquete_scene = preload("res://scenes/paquete.tscn")
# --- ESTADOS ---
enum State { IDLE, CHASE, READY, ATTACK, HURT, DEAD, SUMMON}
var state: State = State.IDLE
var is_invulnerable := false
var is_sitting := false
var summon_target: Vector2
var summon_speed := 140.0
var has_started_summon := false
var summon_round := 0
var base_summons := 2
# --- PROPIEDADES ---
var health = 150
var speed = 100.0
var attack_power = 10
var attack_cooldown = 1.0
var attack_timer = 0.0
var direction = -1
var attack_offset_x := 0.0

const MAX_VERTICAL_DIFF := 20.0
const MIN_X_SEPARATION := 20.0
const ATTACK_DISTANCE_X := 20.0
const Z_BASE = 100

# ------------------- CICLO DE VIDA -------------------

func _ready():
	anim.connect("animation_finished", Callable(self, "_on_anim_finished"))
	if GameManager:
		GameManager.connect("all_enemies_defeated", Callable(self, "_on_all_enemies_defeated"))
	state = State.IDLE
	attack_offset_x = randf_range(-20, 20)

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
		State.SUMMON: state_summon(delta)

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

	
	if anim.frame == 8:
		attack_hitbox.monitoring = true
	else:
		attack_hitbox.monitoring = false

func state_hurt(_delta):
	play_anim("hurt")
	# Se detienen los pasos mientras recibe el golpe
	if walk_sound.playing: walk_sound.stop()

func state_dead(_delta):
	velocity = Vector2.ZERO
	play_anim("die")
	attack_hitbox.monitoring = false
	# Usamos set_deferred para evitar errores de física en Godot
	hurtbox.set_deferred("disabled", true)

	# --- AUDIO: Muerte ---
	if not death_sound.playing and anim.frame == 0:
		death_sound.play()

	# Timer para eliminar el enemigo después de su animación
	if not has_node("delete_timer"):
		var t = Timer.new()
		t.name = "delete_timer"
		t.one_shot = true
		t.wait_time = anim.sprite_frames.get_frame_count("die") / anim.sprite_frames.get_animation_speed("die")
		t.connect("timeout", Callable(self, "spawn_paquete"))
		add_child(t)
		t.start()
func state_summon(delta):
	# 1️⃣ Ir al marker
	if not is_sitting:
		play_anim("chase")

		var dir = summon_target - global_position
		if dir.length() > 5:
			velocity = dir.normalized() * summon_speed
			set_direction(sign(dir.x))
		else:
			velocity = Vector2.ZERO
			is_sitting = true
			play_anim("sentar")
			summon_particles.emitting = true
		return

	# 2️⃣ Ya está sentado
	velocity = Vector2.ZERO

	# Empieza a invocar UNA sola vez
	if is_sitting and not has_started_summon and anim.animation == "sentada":
		start_summoning()


# ------------------- LÓGICA DE COMBATE -------------------

func take_damage(amount: int, from_position: Vector2, attack_type: int):
	if state == State.DEAD or is_invulnerable:
		return

	health -= amount
	print(health)
	spawn_blood()

	if health <= 0:
		state = State.DEAD
		GameManager.add_points(200)
	else:
		state = State.HURT
		apply_knockback(amount, from_position, attack_type)

func apply_knockback(amount:int, from_position: Vector2, attack_type:int, knockback_strength: float = 10.0, knockback_time = 0.2):
	var dir = (global_position - from_position).normalized()
	dir.y = -0.5 if attack_type == 1 else 0.0
	velocity = dir * (knockback_strength * amount)

	var t = get_tree().create_timer(knockback_time)
	t.connect("timeout", Callable(self, "_end_knockback"))

func _end_knockback():
	if state != State.DEAD:
		if health <= 100 and state != State.SUMMON:
			start_summon_state()
		else:
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
	elif anim.animation == "sentar" and state == State.SUMMON:
		play_anim("sentada")
	elif anim.animation == "levantar" and state == State.SUMMON:
		is_invulnerable = false
		is_sitting = false
		has_started_summon = false
		state = State.CHASE
	
func _on_attack_hitbox_area_entered(area: Area2D):
	if area.is_in_group("player_hurtbox"):
		var player = area.get_parent().get_parent()
		player.take_damage(attack_power, global_position, 0)
		
func start_summon_state():
	state = State.SUMMON
	is_invulnerable = true
	has_started_summon = false
	velocity = Vector2.ZERO

	# Elegir un marker al azar
	if summon_markers.size() > 0:
		var marker = summon_markers.pick_random()
		summon_target = marker.global_position

func start_summoning():
	has_started_summon = true
	summon_round += 1

	var total_enemies := summon_round * base_summons

	
	GameManager.cant_ene = total_enemies
	GameManager.enemigo_vivo = 0
	GameManager.spawn_enemies(-50, 0)

	
func exit_summon_state():
	summon_particles.emitting = false
	play_anim("levantar")

func _on_all_enemies_defeated():
	# Solo reaccionar si el boss está invocando
	if state != State.SUMMON:
		return

	# Si aún no está sentado o no empezó a invocar, ignorar
	if not has_started_summon:
		return

	exit_summon_state()

func spawn_paquete():
	# Instanciar la escena
	var paquete_instance = paquete_scene.instantiate()
	paquete_instance.global_position = global_position  # Aparece donde estaba el boss
	get_tree().current_scene.add_child(paquete_instance)
	
	# Eliminar al boss
	queue_free()
	
	# Opcional: Si quieres que GameManager haga algo extra
	# GameManager.win_game()
