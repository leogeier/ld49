extends ColorRect


export(int) var mouse_button = BUTTON_LEFT

onready var project_size = Vector2(ProjectSettings.get_setting("display/window/size/width"), ProjectSettings.get_setting("display/window/size/height"))

var BrushMode = preload("res://polygon_canvas/brush_mode.gd")

var brush_radius
var brush_positions = [] setget set_brush_positions
var brush_positions_static = [] setget _set_brush_positions_static
var last_mouse_pos = Vector2.ZERO # ultra jank
var mouse_is_just_pressed = true
var brush_mode = BrushMode.Mode.DYNAMIC

signal new_stroke(brush_index, brush_mode)

func set_brush_positions(val):
	brush_positions = val
	update()

func _set_brush_positions_static(val):
	brush_positions_static = val
	update()

func clear():
	brush_positions.clear()
	brush_positions_static.clear()
	update()

func resize_brushes(index, mode):
	var brush_array = brush_positions
	if mode == BrushMode.Mode.STATIC:
		brush_array = brush_positions_static
	brush_array.resize(index)
	update()

func _ready():
	pass

func _draw():
	for pos in brush_positions:
		draw_circle(pos, brush_radius, Color.white)
	for pos in brush_positions_static:
		draw_circle(pos, brush_radius, Color.white)


func _process(_delta):
	if Input.is_mouse_button_pressed(mouse_button):
		var brush_array = brush_positions
		if brush_mode == BrushMode.Mode.STATIC:
			brush_array = brush_positions_static
		if mouse_is_just_pressed:
			mouse_is_just_pressed = false
			emit_signal("new_stroke", brush_array.size(), brush_mode)
		brush_array.append(last_mouse_pos)
		update()
	else:
		mouse_is_just_pressed = true
