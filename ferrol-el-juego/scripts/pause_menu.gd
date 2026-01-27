extends Control


func _on_resume_game_pressed() -> void:
	get_tree().paused = false
	visible = false
