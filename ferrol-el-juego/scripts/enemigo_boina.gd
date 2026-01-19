extends CharacterBody2D
class_name enemy

@onready var flipper: Node2D = $flipper
@onready var anim: AnimatedSprite2D = $flipper/AnimatedSprite2D
@onready var enemy_avoid_area: Area2D = $flipper/enemy_avoid_area
@onready var blood_particles: CPUParticles2D = $flipper/blood_particles

@onready var attack_hitbox: Area2D = $flipper/attack_hitbox

@onready var hurtbox: CollisionShape2D = $hurtbox

enum State { IDLE, CHASE, READY,  ATTACK, HURT, DEAD }
var state: State = State.IDLE
var direction = -1
var life = 3
var attack_power = 1
var speed = 100.0
var point_value=50
var patrol_time = 0.0
var idle_time = 0.0

const MAX_VERTICAL_DIFF := 20.0
var attack_cooldown = 1.5 
var attack_timer = 0.0
var head_timer_started = false

func _ready():
	state = State.IDLE
	idle_time = randf_range(2.0, 5.0)  # ajusta según cuánto quieres que esté idle
	anim.connect("animation_finished", Callable(self, "_on_anim_finished"))


func _physics_process(delta: float) -> void:
	if state != State.ATTACK:
		attack_hitbox.monitoring = false
		
	if state == State.DEAD:
		state_dead(delta)
	else:
		attack_timer = max(attack_timer - delta, 0)
		proccess_state(delta)

	move_and_slide()
	


func play_anim(anim_name: String):
	if anim.animation != anim_name:
		anim.play(anim_name)


func proccess_state(delta):
	match state:
		State.IDLE: state_idle(delta)
		State.CHASE: state_chase(delta)
		State.READY: state_ready(delta)
		State.ATTACK: state_attack(delta)
		State.HURT: state_hurt(delta)
		State.DEAD: state_dead(delta)

func state_idle(delta):
	play_anim("idle")
	velocity = Vector2.ZERO

	idle_time -= delta
	if idle_time <= 0.0:
		state = State.CHASE


func state_chase(_delta):
	if state == State.HURT:
		return

	play_anim("chase")

	if not GameManager.player:
		state = State.IDLE
		return

	var player_pos = GameManager.player.global_position 
	var dir = player_pos - global_position

	# ---------- FASE 1: ALINEARSE EN Y ----------
	if abs(dir.y) > MAX_VERTICAL_DIFF:
		var y_sign = sign(dir.y)
		if y_sign != 0:
			velocity.y = y_sign * speed * 0.6
		else:
			velocity.y = 0

		velocity.x = 0
		return
	else:
		velocity.y = 0

	# ---------- FASE 2: ACERCARSE EN X ----------
	if dir.x != 0:
		set_direction(sign(dir.x))

	velocity.x = direction * speed

	# ---------- RESPETO DE ESPACIO ----------
	var min_distance := 14.0
	if abs(dir.x) < min_distance:
		velocity.x = 0

	# ---------- SEPARACIÓN ENTRE ENEMIGOS ----------
	velocity += apply_enemy_separation(_delta)

	# ---------- FASE 3: ATAQUE ----------
	var attack_distance := 20.0
	if abs(dir.x) <= attack_distance:
		state = State.READY



func state_ready(_delta):
	if state != State.HURT:
		velocity = Vector2.ZERO
		play_anim("ready")
		

func state_attack(_delta):
	if state != State.HURT:
		velocity.x = 0
		play_anim("attack")
		update_attack_hitbox()
		var frames = anim.sprite_frames.get_frame_count("attack")
		if anim.frame == frames - 1:
			state = State.CHASE
			attack_timer = attack_cooldown
		
func state_hurt(_delta):
	play_anim("hurt")
	
func state_dead(_delta):
	velocity = Vector2.ZERO

	if anim.animation != "die":
		attack_hitbox.set_deferred("monitoring", false)
		attack_hitbox.set_deferred("monitorable", false)
		hurtbox.set_deferred("disabled", true)
		play_anim("die")
		#GameManager.add_point(point_value)

		# Timer para desaparecer
		var frames = anim.sprite_frames.get_frame_count("die")
		var fps = anim.sprite_frames.get_animation_speed("die")
		if fps > 0:
			var t = Timer.new()
			t.wait_time = frames / fps
			t.one_shot = true
			t.connect("timeout", Callable(self, "queue_free"))
			add_child(t)
			t.start()

# ------------------- Lógica ------------------- #
func update_attack_hitbox():
	if anim.frame == 2 or anim.frame == 6:
		attack_hitbox.monitoring = true
	else:
		attack_hitbox.monitoring = false

func take_damage(amount, enemyposition: Vector2, attacktype: int):
	if state == State.DEAD:
		return
	life -= amount
	spawn_blood()
	if life <= 0:
		state = State.DEAD
	else:
		state = State.HURT
		#anim.modulate = Color(1.0, 0.408, 0.471, 1.0)
		apply_knockback(amount, enemyposition, attacktype)

func apply_knockback(amount:int, from_position: Vector2, attack_type:int, knockback_strength: float = 100.0,knockback_time = 0.5):
	var dir = global_position - from_position
	dir.x = sign(dir.x)  
	dir.y = -1.0 if attack_type == 1.0 else 0.0
	dir = dir.normalized()
	velocity = dir * (knockback_strength * amount)  # fuerza proporcional
	var t = get_tree().create_timer(amount * knockback_time)
	t.connect("timeout", Callable(self, "_end_knockback"))

func _end_knockback():
	if state != State.DEAD:
		state = State.CHASE
		anim.modulate = Color(1,1,1,1)
# ------------------- Detección ------------------- #
func turn():
	direction *= -1
	set_direction(direction)

func set_direction(dir):
	if dir == 0: return
	direction = dir
	var base_scale_x = abs(flipper.scale.x)
	flipper.scale.x = base_scale_x if dir > 0 else -base_scale_x

func _on_attack_hitbox_body_entered(body: Node2D) -> void:
	if body is Player:
		var player: Player = body as Player
		player.take_damage(attack_power,global_position,0)

func apply_enemy_separation(delta: float) -> Vector2:
	var separation := Vector2.ZERO
	for body in enemy_avoid_area.get_overlapping_bodies():
		if body != self and body.is_in_group("Enemy"):
			var diff = global_position - body.global_position
			var dist = diff.length()
			if dist > 0:
				separation += diff.normalized() * (200.0 / dist) #cambiar el valor numerico mas bajo si se empujan mucho
	return separation * delta

func spawn_blood():
	if blood_particles:
				# Reiniciamos partículas
		blood_particles.emitting = false
		blood_particles.restart()
		blood_particles.emitting = true

func _on_anim_finished() -> void:
	if anim.animation == "ready" and state == State.READY:
		state = State.ATTACK
	
