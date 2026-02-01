extends Node

@onready var anim: AnimationPlayer = $AnimationPlayer
@export var next_scene := "res://scenes/main_level.tscn"

var finished := false

func _ready():
	anim.animation_finished.connect(_on_animation_finished)

func _input(event):
	if event.is_action_pressed("saltar_animacion"):
		skip_scene()

func _on_animation_finished(anim_name: StringName) -> void:
	if finished:
		return
	finished = true
	change_scene()

func skip_scene():
	if finished:
		return
	finished = true
	anim.stop()
	change_scene()

func change_scene():
	get_tree().change_scene_to_file(next_scene)
