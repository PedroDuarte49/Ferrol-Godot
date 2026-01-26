extends Area2D
@onready var sonido: AudioStreamPlayer2D = $Sonido
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var picked := false 

#para que esto funcione player debe tener una funcion gain_life()
func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		if picked:
			return
			
		picked = true
		anim.visible = false
		sonido.play()
		body.gain_life(20)
		await sonido.finished
		
		queue_free()
