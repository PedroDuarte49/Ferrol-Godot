extends Area2D
@export var point_value = 20
var picked := false 

# Referencia al nodo de sonido
@onready var coin_sound = $SonidoDinero 

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		if picked:
			return
			
		picked = true
		GameManager.add_points(point_value)
		
		# 1. Reproducir el sonido
		if coin_sound:
			coin_sound.play()
		
		# 2. Hacer invisible la moneda (para que parezca que la recogiste)
		# Suponiendo que tu nodo visual se llama Sprite2D o AnimatedSprite2D
		if has_node("Sprite2D"):
			$Sprite2D.hide()
		
		# 3. Desactivar la colisión para no recogerla dos veces por error
		$CollisionShape2D.set_deferred("disabled", true)
		
		# 4. ESPERAR a que el sonido termine antes de eliminar el objeto
		if coin_sound:
			await coin_sound.finished
		
		queue_free()
