extends Area2D

var picked := false 

#para que esto funcione player debe tener una funcion gain_life()
func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		if picked:
			return
			
		body.boost_ataque()
		picked = true
		queue_free()
