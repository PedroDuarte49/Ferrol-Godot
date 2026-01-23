extends Area2D

var picked := false 

# Referencia al nodo de sonido
@onready var break_sound = $Sonido

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		if picked:
			return
			
		picked = true
		
		# Sumamos la botella al contador del jugador
		body.botellas += 1
		
		# 1. Reproducir el sonido de cristal
		if break_sound:
			break_sound.play()
		
		# 2. Hacer invisible la botella para que parezca que se rompió/recogió
		# (Asegúrate de que el Sprite de la botella se llame Sprite2D)
		if has_node("Sprite2D"):
			$Sprite2D.hide()
		
		# 3. Desactivar la colisión para que no se active dos veces
		$CollisionShape2D.set_deferred("disabled", true)
		
		# 4. Esperar a que el sonido termine antes de hacer el queue_free
		if break_sound:
			await break_sound.finished
		
		queue_free()
