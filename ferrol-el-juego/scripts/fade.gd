extends ColorRect

@export var fade_time := 1.5

func fade_from_black():
	# Negro -> transparente
	modulate.a = 1.0
	await get_tree().process_frame
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_time)
	await tween.finished

func fade_to_black():
	# Transparente -> negro
	modulate.a = 0.0
	await get_tree().process_frame
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_time)
	await tween.finished
