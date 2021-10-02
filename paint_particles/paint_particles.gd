extends Particles2D


export(Color) var color = Color.red


func _ready():
	modulate = color

func _process(_delta):
	position = get_global_mouse_position()
