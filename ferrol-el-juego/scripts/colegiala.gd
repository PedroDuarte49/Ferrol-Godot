extends Enemy
class_name Colegiala
var awakened = false


func _ready():
	super._ready()

	# Stats modificados
	health = 20
	speed = 120
	attack_power = 15

func state_idle(delta):
	velocity = Vector2.ZERO
	play_anim("idle")

	# NO persigue al jugador mientras duerme
	if awakened:
		state = State.CHASE

func take_damage(amount: int, from_position: Vector2, attack_type: int):
	if not awakened:
		awakened = true
		state = State.CHASE
	#super hace que el resto de la funcion sea como la de enemy
	super.take_damage(amount, from_position, attack_type)
