extends Area2D
@onready var sonido: AudioStreamPlayer2D = $Sonido
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var picked := false 

#para que esto funcione player debe tener una funcion gain_life()
func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		if picked:
			return
		sonido.play()
		picked = true
		anim.visible = false
		
		get_tree().change_scene_to_file("res://scenes/scena_final.tscn")
	
