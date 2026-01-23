extends Area2D

var activated = false

func _on_body_entered(body: Node) -> void:
	if activated:
		return
	if body.name != "player":
		return
	activated = true
	GameManager.new_zone(1)
