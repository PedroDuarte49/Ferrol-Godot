extends CanvasLayer

@onready var Vida: TextureProgressBar = $HBoxContainer/Barra_Vida
@onready var botella1: AnimatedSprite2D = $HBoxContainer/Botellas/Botella_1
@onready var botella2: AnimatedSprite2D = $HBoxContainer/Botellas/Botella_2
@onready var botella3: AnimatedSprite2D = $HBoxContainer/Botellas/Botella_3
func _ready() -> void:
	Vida.value = 100

func update_life_bar(health: int) -> void:
	Vida.value = health
	print(Vida.value)

func bottle(cant: int) -> void:
	if cant == 0:
		botella1.visible = false
		botella2.visible = false
		botella3.visible = false
	elif cant == 1:
		botella1.visible = true
		botella2.visible = false
		botella3.visible = false
	elif cant == 2:
		botella1.visible = true
		botella2.visible = true
		botella3.visible = false
	elif cant == 3:
		botella1.visible = true
		botella2.visible = true
		botella3.visible = true
