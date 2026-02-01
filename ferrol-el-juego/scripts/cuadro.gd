extends Panel

@export var texto:String = "":
	set(value):
		visible = true
		texto = value
		index = 0
		$Label.text = ""
		$Timer.stop()
		$Timer2.stop()
		$Timer.start()
var index = 0;
	
func _on_timer_timeout() -> void:
	if index >= texto.length():
		$Timer.stop()
		$Timer2.start()
		return

	$Label.text += texto[index]
	index += 1


func _on_timer_2_timeout() -> void:
	visible = false # Replace with function body.
