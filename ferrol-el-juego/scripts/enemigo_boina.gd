extends CharacterBody2D
class_name Enemy

# Nodos
@onready var flipper: Node2D = $flipper
@onready var anim: AnimatedSprite2D = $flipper/AnimatedSprite2D
@onready var enemy_avoid_area: Area2D = $flipper/enemy_avoid_area
@onready var attack_hitbox: Area2D = $flipper/attack_hitbox
@onready var hurtbox: CollisionShape2D = $hurtbox
@onready var blood_particles: CPUParticles2D = $flipper/blood_particles

# Estados
enum State { IDLE, CHASE, READY, ATTACK, HURT, DEAD }
var state: State = State.IDLE

# Propiedades
var life = 3
var speed = 100.0
var attack_power = 1
var attack_cooldown = 1.5
var attack_timer = 0.0
var direction = -1
var attack_offset_x := 0.0
# Configuración de separación y ataque
const MAX_VERTICAL_DIFF := 20.0
const MIN_X_SEPARATION := 20.0
const ATTACK_DISTANCE_X := 20.0
const Z_BASE = 100

func _ready():
	anim.connect("animation_finished", Callable(self, "_on_anim_finished"))
	state = State.IDLE
	attack_offset_x = randf_range(-30, 30)

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		state_dead(delta)
		move_and_slide()
		return

	# Siempre restamos timer de ataque
	attack_timer = max(attack_timer - delta, 0)

	# Procesamos el estado
	process_state(delta)

	# Aplicamos separación con otros enemigos en cualquier estado
	velocity += apply_enemy_separation(delta)

	move_and_slide()

	# Orden de dibujo según Y
	z_index = Z_BASE + int(global_position.y)

# ------------------- ESTADOS -------------------
func process_state(delta: float):
	match state:
		State.IDLE: state_idle(delta)
		State.CHASE: state_chase(delta)
		State.READY: state_ready(delta)
		State.ATTACK: state_attack(delta)
		State.HURT: state_hurt(delta)
		State.DEAD: state_dead(delta)

func state_idle(delta):
	velocity = Vector2.ZERO
	play_anim("idle")

	# Pasar a CHASE si hay player
	if GameManager.player:
		state = State.CHASE

func state_chase(delta):
	if state == State.HURT or not GameManager.player:
		return

	play_anim("chase")

	var player_pos = GameManager.player.global_position
	var target_pos = player_pos + Vector2(attack_offset_x, 0)
	var dir = target_pos - global_position

	# ---- ALINEARSE EN Y ----
	if abs(dir.y) > MAX_VERTICAL_DIFF:
		velocity.y = sign(dir.y) * speed * 0.6
	else:
		velocity.y = 0

	# ---- ACERCARSE EN X ----
	if abs(dir.x) > ATTACK_DISTANCE_X:
		set_direction(sign(dir.x))
		velocity.x = direction * speed
	else:
		velocity.x = 0
		if abs(dir.x) <= ATTACK_DISTANCE_X and abs(dir.y) <= MAX_VERTICAL_DIFF:
			state = State.READY

func state_ready(delta):
	play_anim("ready")
	velocity = Vector2.ZERO

	if not GameManager.player:
		state = State.IDLE
		return

	var dir = GameManager.player.global_position - global_position

	# Si deslinea eje vertical vuelve a  perseguir
	if abs(dir.y) > MAX_VERTICAL_DIFF:
		state = State.CHASE
		return

	if anim.frame == anim.sprite_frames.get_frame_count("ready") - 1:
		state = State.ATTACK


func state_attack(delta):
	play_anim("attack")
	velocity.x = 0

	# Activar hitbox solo en frames de impacto
	if anim.frame in [2, 6]:
		attack_hitbox.monitoring = true
	else:
		attack_hitbox.monitoring = false

	if anim.frame == anim.sprite_frames.get_frame_count("attack") - 1:
		state = State.CHASE
		attack_timer = attack_cooldown

func state_hurt(delta):
	play_anim("hurt")
	# Durante HURT se puede dejar que la separación actúe para que no se superpongan

func state_dead(delta):
	velocity = Vector2.ZERO
	play_anim("die")
	attack_hitbox.monitoring = false
	hurtbox.disabled = true
	# timer para eliminar después de animación
	if not has_node("delete_timer"):
		var t = Timer.new()
		t.name = "delete_timer"
		t.one_shot = true
		t.wait_time = anim.sprite_frames.get_frame_count("die") / anim.sprite_frames.get_animation_speed("die")
		t.connect("timeout", Callable(self, "queue_free"))
		add_child(t)
		t.start()

# ------------------- LÓGICA -------------------
func apply_enemy_separation(delta: float) -> Vector2:
	var push := Vector2.ZERO

	for body in enemy_avoid_area.get_overlapping_bodies():
		if body == self:
			continue
		if not body.is_in_group("Enemy"):
			continue

		var diff := global_position - body.global_position

		# ---------- SEPARACIÓN HORIZONTAL (prioritaria) ----------
		if abs(diff.x) < MIN_X_SEPARATION:
			var strength_x = (MIN_X_SEPARATION - abs(diff.x)) / MIN_X_SEPARATION
			push.x += sign(diff.x) * strength_x * speed

		# ---------- SEPARACIÓN VERTICAL (suave) ----------
		if abs(diff.y) < MAX_VERTICAL_DIFF:
			var strength_y = (MAX_VERTICAL_DIFF - abs(diff.y)) / MAX_VERTICAL_DIFF
			push.y += sign(diff.y) * strength_y * speed * 0.4

	return push * delta

func take_damage(amount: int, from_position: Vector2, attack_type: int):
	if state == State.DEAD:
		return

	life -= amount
	spawn_blood()

	if life <= 0:
		state = State.DEAD
	else:
		state = State.HURT
		apply_knockback(amount, from_position, attack_type)

func apply_knockback(amount:int, from_position: Vector2, attack_type:int, knockback_strength: float = 100.0, knockback_time = 0.5):
	var dir = (global_position - from_position).normalized()
	dir.y = -0.5 if attack_type == 1 else 0
	velocity = dir * (knockback_strength * amount)

	var t = get_tree().create_timer(knockback_time)
	t.connect("timeout", Callable(self, "_end_knockback"))

func _end_knockback():
	if state != State.DEAD:
		state = State.CHASE
		anim.modulate = Color(1,1,1,1)

func spawn_blood():
	if blood_particles:
		blood_particles.emitting = false
		blood_particles.restart()
		blood_particles.emitting = true

func set_direction(dir):
	if dir == 0: return
	direction = dir
	var base_scale_x = abs(flipper.scale.x)
	flipper.scale.x = base_scale_x if dir > 0 else -base_scale_x

func _on_attack_hitbox_body_entered(body: Node2D):
	if body is Player:
		body.take_damage(attack_power, global_position, 0)

func play_anim(anim_name: String):
	if anim.animation != anim_name:
		anim.play(anim_name)

func _on_anim_finished():
	if anim.animation == "ready" and state == State.READY:
		state = State.ATTACK
