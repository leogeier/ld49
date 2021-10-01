extends ColorRect


export(int) var mouse_button = BUTTON_LEFT

var brush_radius
var brush_positions = []


func _ready():
	pass

func _draw():
	for pos in brush_positions:
		draw_circle(pos, brush_radius, Color.white)


func _process(_delta):
	if Input.is_mouse_button_pressed(mouse_button):
		brush_positions.append(get_global_mouse_position())
		print(brush_positions.size())
		update()
