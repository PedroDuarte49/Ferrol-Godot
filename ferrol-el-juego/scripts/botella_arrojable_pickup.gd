extends Area2D

var picked := false 

# Referencia al nodo de sonido
@onready var break_sound = $Sonido
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		if picked:
			return

		if GameManager.bottle <3:
			GameManager.bottle += 1
			GameManager.hud.bottle(GameManager.bottle)
		picked = true
		anim.visible = false
		break_sound.play()
		await break_sound.finished
		
		queue_free()
