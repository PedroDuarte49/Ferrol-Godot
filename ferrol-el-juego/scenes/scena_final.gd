extends Node

@onready var anim: AnimationPlayer = $AnimationPlayer

var finished := false

func _ready():
	anim.play("win_animation")  # Asegúrate de que esta animación exista
	anim.animation_finished.connect(_on_animation_finished)

func _input(event):
	if event.is_action_pressed("saltar_animacion"):
		skip_animation()

func _on_animation_finished(anim_name: StringName) -> void:
	if finished:
		return
	finished = true
	GameManager.win_game()

func skip_animation():
	if finished:
		return
	finished = true
	anim.stop()
	GameManager.win_game()
