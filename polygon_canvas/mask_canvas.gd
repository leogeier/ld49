extends ColorRect


export(String, "lclick", "rclick") var mouse_button = "lclick"
export(float) var max_stroke_area = 5000

onready var project_size = Vector2(ProjectSettings.get_setting("display/window/size/width"), ProjectSettings.get_setting("display/window/size/height"))

var BrushMode = preload("res://polygon_canvas/brush_mode.gd")

var brush_radius
var brush_positions = [] setget set_brush_positions
var brush_positions_static = [] setget _set_brush_positions_static
var last_mouse_pos = Vector2.ZERO # ultra jank
var mouse_is_just_pressed = true
var currently_drawing = false
var current_stroke
var brush_mode = BrushMode.Mode.DYNAMIC
var bounds = Rect2(Vector2.ZERO, OS.get_window_size())
var stroke_area = 0
var drawing_enabled = true

signal new_stroke(brush_index, brush_mode)
signal positions_added
signal stopped_drawing

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

func last_stroke():
	return brush_positions.back()

func stroke_count():
	var count = 0
	for stroke in brush_positions:
		if stroke != []:
			count += 1
	if currently_drawing:
		count += 1
	return count

func undo(mode):
	var brush_array = brush_positions
	if mode == BrushMode.Mode.STATIC:
		brush_array = brush_positions_static
	var last = brush_array.pop_back()
	update()
	return last == []

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
	if Input.is_action_just_pressed(mouse_button) && bounds.has_point(last_mouse_pos) && drawing_enabled:
		currently_drawing = true
		var brush_array = brush_positions
		if brush_mode == BrushMode.Mode.STATIC:
			brush_array = brush_positions_static
		current_stroke = []
		brush_array.append(current_stroke)
		emit_signal("new_stroke", brush_array.size(), brush_mode)

	if currently_drawing && bounds.has_point(last_mouse_pos) && drawing_enabled:
		current_stroke.append(last_mouse_pos)
		emit_signal("positions_added")
		update()

	if (currently_drawing && Input.is_action_just_released(mouse_button)) || stroke_area > max_stroke_area:
		currently_drawing = false
		stroke_area = 0
		emit_signal("stopped_drawing")
		
