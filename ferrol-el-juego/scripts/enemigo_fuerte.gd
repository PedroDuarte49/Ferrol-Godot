extends Enemy
#hereda de Enemy y sobreescibe comportamiento, stats aprovechando  ready y overiding state attack

func _ready():
	super._ready()

	# Stats modificados
	health = 60
	speed = 65
	attack_power = 15

func state_attack(delta):
	play_anim("attack")
	velocity.x = 0

	# SOLO frame 2
	if anim.frame == 2:
		attack_hitbox.monitoring = true
	else:
		attack_hitbox.monitoring = false

	if anim.frame == anim.sprite_frames.get_frame_count("attack") - 1:
		state = State.CHASE
		attack_timer = attack_cooldown
