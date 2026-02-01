extends Area2D

@onready var escena = preload("res://scenes/scena_explosiva.tscn").instantiate()


func _on_body_entered(body: Node2D) -> void:
	if body.name != "player":
		return

	# bloquear player
	body.block_player = true
	body.visible = false

	# ocultar HUD
	GameManager.hud.visible = false
	$CanvasLayer/ColorRect/AnimationPlayer.play("to_black")
	
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name != "to_black":
		return

	get_tree().current_scene.add_child(escena)
	escena.get_node("cine").make_current()

	# señal para cuando termine la escena
	escena.connect("tree_exited", Callable(self, "_on_scene_finished"))

	$CanvasLayer/ColorRect/AnimationPlayer.play("to_transparent")

func _on_scene_finished():
	var player = GameManager.player
	player.visible = true
	player.block_player = false
	visible = false
	$CollisionShape2D.disabled = true
	
	GameManager.hud.visible = true
