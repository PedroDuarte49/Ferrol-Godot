extends StaticBody2D
const Z_BASE = 100

# Called when the node enters the scene tree for the first time.
func _physics_process(delta: float):
	z_index = Z_BASE + int(global_position.y) -48 #es para compensar el largo
