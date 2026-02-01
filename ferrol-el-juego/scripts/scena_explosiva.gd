extends Node2D

@export var duracion := 19.0 # segundos que dura la escena

func _ready():
	await get_tree().create_timer(duracion).timeout
	queue_free() # ← esto hace que todo vuelva
