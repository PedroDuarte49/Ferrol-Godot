extends Area2D
@export var point_value = 20
@onready var sonido: AudioStreamPlayer2D = $Sonido
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var picked := false 

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		if picked:
			return
		picked = true
		anim.visible = false
		GameManager.add_points(point_value)
		GameManager.hud.update_points()
		sonido.play()
		await sonido.finished
		
		queue_free()
