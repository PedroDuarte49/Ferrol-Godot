extends Enemy

var awakened = false

func _ready():
	super._ready()
	health = 20
	speed = 120
	attack_power = 15


func state_idle(delta):
	velocity = Vector2.ZERO
	anim.play("idle")
	if awakened:
		state = State.CHASE

func take_damage(amount: int, from_position: Vector2, attack_type: int):
	if not awakened:
		awakened = true
		state = State.CHASE
	
	#super sirve para que apartir de aqui se comporte como el resto de la clase principal
	super.take_damage(amount, from_position, attack_type)
	
