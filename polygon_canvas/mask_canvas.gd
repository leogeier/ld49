extends ColorRect


export(int) var mouse_button = BUTTON_LEFT

onready var project_size = Vector2(ProjectSettings.get_setting("display/window/size/width"), ProjectSettings.get_setting("display/window/size/height"))

var brush_radius
var brush_positions = []
var last_mouse_pos = Vector2.ZERO # ultra jank
var mouse_is_just_pressed = true

signal new_stroke(brush_index)

func clear():
	brush_positions.clear()
	update()

func resize_brushes(index):
	brush_positions.resize(index)
	update()

func _ready():
	pass

func _draw():
	for pos in brush_positions:
		draw_circle(pos, brush_radius, Color.white)


func _process(_delta):
	if Input.is_mouse_button_pressed(mouse_button):
		if mouse_is_just_pressed:
			mouse_is_just_pressed = false
			emit_signal("new_stroke", brush_positions.size())
		brush_positions.append(last_mouse_pos)
		update()
	else:
		mouse_is_just_pressed = true
