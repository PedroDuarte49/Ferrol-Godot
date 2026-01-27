extends Area2D
@export var cant = 1
var activated = false

func _on_body_entered(body: Node) -> void:
	if activated:
		return
	if body.name != "player":
		return
	activated = true
	GameManager.new_zone(cant)
	GameManager.zona =GameManager.zona + 1
