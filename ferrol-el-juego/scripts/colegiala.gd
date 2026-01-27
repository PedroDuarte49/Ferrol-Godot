extends Enemy

class_name Colegiala
@onready var risa: AudioStreamPlayer2D = $risa
var awakened = false

func _ready():
	super._ready()
	health = 60
	speed = 140
	attack_power = 25
	point_value = 150


func state_idle(delta):
	velocity = Vector2.ZERO
	anim.play("idle")
	if awakened:
		state = State.CHASE

func take_damage(amount: int, from_position: Vector2, attack_type: int):
	if not awakened:
		risa.play()
		awakened = true
		state = State.CHASE
	
	#super sirve para que apartir de aqui se comporte como el resto de la clase principal
	super.take_damage(amount, from_position, attack_type)
	
