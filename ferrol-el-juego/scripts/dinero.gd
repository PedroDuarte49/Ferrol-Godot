extends Area2D
@export var point_value = 20
var picked := false 


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		if picked:
			return
			
		GameManager.add_points(point_value)
		picked = true
		queue_free()
