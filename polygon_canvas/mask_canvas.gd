extends ColorRect


export(int) var mouse_button = BUTTON_LEFT

onready var project_size = Vector2(ProjectSettings.get_setting("display/window/size/width"), ProjectSettings.get_setting("display/window/size/height"))

var brush_radius
var brush_positions = []
var last_mouse_pos = Vector2.ZERO # ultra jank

func clear():
	brush_positions.clear()
	update()

func _ready():
	pass

func _draw():
	for pos in brush_positions:
		draw_circle(pos, brush_radius, Color.white)


func _process(_delta):
	if Input.is_mouse_button_pressed(mouse_button):
		var offset = (OS.get_window_size() - project_size) / 2
		# print(offset)
		# print(OS.get_window_size())
		# print(project_size)
		offset.y *= -1
		# brush_positions.append(get_global_mouse_position() - offset)
		brush_positions.append(last_mouse_pos)
		# print(brush_positions.size())
		update()
