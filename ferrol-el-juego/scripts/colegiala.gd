extends Enemy

var awakened = false

# Referencias a los nodos de sonido
#@onready var death_sound = $SonidoMuerte
#@onready var walk_sound = $Pasos # Añade este nodo en tu escena

func _ready():
	super._ready()
	health = 20
	speed = 120
	attack_power = 15

func _physics_process(delta):
	# Si el enemigo está vivo y moviéndose, suena el caminar
	if health > 0 and velocity.length() > 10:
		if not walk_sound.playing:
			walk_sound.play()
	else:
		walk_sound.stop()

func state_idle(delta):
	velocity = Vector2.ZERO
	play_anim("idle")
	if awakened:
		state = State.CHASE

func take_damage(amount: int, from_position: Vector2, attack_type: int):
	if not awakened:
		awakened = true
		state = State.CHASE
	
	super.take_damage(amount, from_position, attack_type)
	
	if health <= 0:
		reproducir_muerte()

func reproducir_muerte():
	# 1. Detenemos los pasos inmediatamente para que no se mezclen mal
	if walk_sound.playing:
		walk_sound.stop()
	
	# 2. Reproducimos el sonido de muerte
	if death_sound and not death_sound.playing:
		death_sound.play()
	
	# 3. Importante: Desactivamos el procesamiento para que no se mueva mientras muere
	set_physics_process(false)
	
	# Si tienes animación de muerte, ponla aquí
	# play_anim("death")
	
	# 4. Esperamos a que el sonido termine antes de borrar al enemigo
	await death_sound.finished
	queue_free()
