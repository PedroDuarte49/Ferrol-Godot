extends Panel

@export var texto:String = "":
	set(value):
		# Guardamos el texto
		_texto = value
		index = 0
		# Limpiamos el Label
		if label:
			label.text = ""
		# Mostramos el panel (ya empieza visible)
		visible = true
		# Reiniciamos timers
		if timer:
			timer.stop()
			timer.start()
		if timer2:
			timer2.stop()

var index = 0
var _texto:String = ""

# Nodo Label y timers
@onready var label: Label = $Label
@onready var timer: Timer = $Timer
@onready var timer2: Timer = $Timer2

# Timer que escribe letra a letra
func _on_timer_timeout() -> void:
	if index >= _texto.length():
		timer.stop()
		if timer2:
			timer2.start()
		return

	label.text += _texto[index]
	index += 1

# Timer que oculta el panel al final
func _on_timer_2_timeout() -> void:
	visible = false
