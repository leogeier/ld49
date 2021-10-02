extends ColorRect


export(String, "lclick", "rclick") var mouse_button = "lclick"

onready var project_size = Vector2(ProjectSettings.get_setting("display/window/size/width"), ProjectSettings.get_setting("display/window/size/height"))

var BrushMode = preload("res://polygon_canvas/brush_mode.gd")

var brush_radius
var brush_positions = [] setget set_brush_positions
var brush_positions_static = [] setget _set_brush_positions_static
var last_mouse_pos = Vector2.ZERO # ultra jank
var mouse_is_just_pressed = true
var current_stroke
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

func undo(mode):
	var brush_array = brush_positions
	if mode == BrushMode.Mode.STATIC:
		brush_array = brush_positions_static
	brush_array.pop_back()
	update()

func _ready():
	pass

func draw_array(arr):
	for stroke in arr:
		for i in range(stroke.size()):
			var pos = stroke[i] 
			draw_circle(pos, brush_radius, Color.white)

			if i == 0:
				continue
		
			var prev_pos = stroke[i - 1]
			var dir = prev_pos.direction_to(pos)
			var orth = dir.rotated(PI / 2)
			var offset = orth * brush_radius
			var rect = PoolVector2Array([
				pos + offset,
				prev_pos + offset,
				prev_pos - offset,
				pos - offset
				])
			draw_polygon(rect, PoolColorArray([Color.white]))

func _draw():
	draw_array(brush_positions)
	draw_array(brush_positions_static)


func _process(_delta):
	if Input.is_action_just_pressed(mouse_button):
		var brush_array = brush_positions
		if brush_mode == BrushMode.Mode.STATIC:
			brush_array = brush_positions_static
		current_stroke = []
		brush_array.append(current_stroke)
		emit_signal("new_stroke", brush_array.size(), brush_mode)
	if Input.is_action_pressed(mouse_button):
		current_stroke.append(last_mouse_pos)
		update()
		
