extends Area2D
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var picked := false 
@onready var sonido: AudioStreamPlayer2D = $Sonido


#para que esto funcione player debe tener una funcion gain_life()
func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		if picked:
			return
		picked = true
		anim.visible =false
		sonido.play()
		body.boost_ataque()
		await sonido.finished
	
	
		queue_free()
