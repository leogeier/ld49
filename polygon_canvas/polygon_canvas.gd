extends Node2D

export(int) var mouse_button = BUTTON_LEFT
export(float) var brush_radius = 20
export(int) var circle_detail = 20
export(float) var max_stroke_area = 5000

export(bool) var dev_mode = false

var BrushMode = preload("res://polygon_canvas/brush_mode.gd")

onready var mask_canvas_a = $MaskViewportA/MaskCanvas
onready var mask_canvas_b = $MaskViewportB/MaskCanvas

var polyBoolean = PolyBoolean2D.new_instance()
var last_mouse_pos = Vector2.ZERO
var stroke_history = []
var brush_mode = BrushMode.Mode.DYNAMIC
var drawing_enabled = true setget set_drawing_enabled

signal stroke_count_changed(count_a, count_b)

func set_drawing_enabled(val):
	drawing_enabled = val
	mask_canvas_a.drawing_enabled = drawing_enabled
	mask_canvas_b.drawing_enabled = drawing_enabled

func add_stroke_to_history(brush_index, bmode, canvas):
	stroke_history.append({"index": brush_index, "canvas": canvas, "brush_mode": bmode})
	print(stroke_history)

func on_new_stroke_a(brush_index, bmode):
	print("New stroke for A")
	$ParticlesRed.emitting = true
	add_stroke_to_history(brush_index, bmode, mask_canvas_a)
	emit_stroke_count_changed()

func on_new_stroke_b(brush_index, bmode):
	print("New stroke for B")
	$ParticlesBlue.emitting = true
	add_stroke_to_history(brush_index, bmode, mask_canvas_b)
	emit_stroke_count_changed()

func emit_stroke_count_changed():
	emit_signal("stroke_count_changed", mask_canvas_a.stroke_count(), mask_canvas_b.stroke_count())

func undo_last_stroke():
	if stroke_history.empty():
		print("No stroke to undo!")
		return

	var last = stroke_history.pop_back()
	print("Undoing stroke ", last)
	var was_empty = last["canvas"].undo(last["brush_mode"])
	if was_empty:
		undo_last_stroke()
	else:
		emit_stroke_count_changed()
	# last["canvas"].resize_brushes(last["index"], last["brush_mode"])

func stroke_area(stroke):
	var shapes = shapes_for_stroke(stroke)
	var polygon = polyBoolean.merge_polygons(shapes)
	return GoostGeometry2D.polygon_area(polygon[0])

func on_new_position_a():
	mask_canvas_a.stroke_area = stroke_area(mask_canvas_a.last_stroke())

func on_new_position_b():
	mask_canvas_b.stroke_area = stroke_area(mask_canvas_b.last_stroke())

func generate_polygons():
	print("Generating polygons...")
	return {
		"a": generate_polygons_for_strokes(mask_canvas_a.brush_positions),
		"a_static": generate_polygons_for_strokes(mask_canvas_a.brush_positions_static, true),
		"b": generate_polygons_for_strokes(mask_canvas_b.brush_positions),
		"b_static": generate_polygons_for_strokes(mask_canvas_b.brush_positions_static, true),
		}

func on_stopped_drawing_a():
	$ParticlesRed.emitting = false

func on_stopped_drawing_b():
	$ParticlesBlue.emitting = false

func clear():
	mask_canvas_a.clear()
	mask_canvas_b.clear()
	emit_stroke_count_changed()

func generate_polygons_for_strokes(strokes, is_static = false):
	if strokes.empty():
		print("no strokes to generate circles for")
		return []
	var shapes = []
	for stroke in strokes:
		shapes.append_array(shapes_for_stroke(stroke))

	print("Merging ", shapes.size(), " polygons...")
	# var merged_polygons = polyBoolean.merge_polygons(circles)
	var merged_polygons = extract_outermost_polygons(polyBoolean.boolean_polygons_tree(shapes, [], PolyBoolean2D.OP_UNION))
	print(merged_polygons.size(), " polygons after merge")

	if $PolygonBounds == null || is_static:
		return merged_polygons

	print("Clipping...")
	var bounds_position = $PolygonBounds.rect_position
	var bounds_size = $PolygonBounds.rect_size
	var bounding_polygon = PoolVector2Array([
		bounds_position + Vector2(0, 0),
		bounds_position + Vector2(bounds_size.x, 0),
		bounds_position + bounds_size,
		bounds_position + Vector2(0, bounds_size.y)
		])
	var clipped_polygons = []
	for polygon in merged_polygons:
		clipped_polygons.append_array(GoostGeometry2D.intersect_polygons(polygon, bounding_polygon))
	print(clipped_polygons.size(), " polygons after clipping")

	return clipped_polygons

func shapes_for_stroke(stroke):
	var shapes = []
	for i in range(stroke.size()):
		shapes.append(generate_circle(stroke[i]))
		if i > 0:
			shapes.append(generate_rect(stroke[i], stroke[i - 1]))
	return shapes

func extract_outermost_polygons(tree):
	var polygons = []
	for child in tree.get_children():
		polygons.append(child.points)
	return polygons

func generate_circle(position):
	var printed = false
	var arr = PoolVector2Array()
	var fcircle_detail = float(circle_detail)
	for i in range(circle_detail):
		arr.append(position + Vector2(1, 0).rotated(2 * PI * i / fcircle_detail) * brush_radius)
		if !printed:
			printed = true

	return arr

func generate_rect(pos, prev_pos):
	var dir = prev_pos.direction_to(pos)
	var orth = dir.rotated(PI / 2)
	var offset = orth * brush_radius
	return PoolVector2Array([
		pos + offset,
		prev_pos + offset,
		prev_pos - offset,
		pos - offset
		])

func split_vector_array(arr):
	var split_arr = []
	for vec in arr:
		split_arr.append({"x": vec.x, "y": vec.y})
	return split_arr

func join_vector_array(arr):
	var join_arr = []
	for vec in arr:
		join_arr.append(Vector2(vec["x"], vec["y"]))
	return join_arr

func save_to_file(filepath):
	print("Saving to ", filepath, "...")
	var data = {
		"a": {
			"dynamic": split_vector_array(mask_canvas_a.brush_positions),
			"static": split_vector_array(mask_canvas_a.brush_positions_static),
			},
		"b": {
			"dynamic": split_vector_array(mask_canvas_b.brush_positions),
			"static": split_vector_array(mask_canvas_b.brush_positions_static),
			},
		"both": {
			"dynamic": [],
			"static": [],
			},
		}
	var file = File.new()
	file.open(filepath, File.WRITE)
	file.store_string(JSON.print(data))
	file.close()

func load_from_file(filepath):
	print("Loading from ", filepath, "...")
	var file = File.new()
	file.open(filepath, File.READ)
	var content = file.get_as_text()
	file.close()
	var data = JSON.parse(content).result
	mask_canvas_a.brush_positions = join_vector_array(data["a"]["dynamic"])
	mask_canvas_a.brush_positions_static = join_vector_array(data["a"]["static"])
	mask_canvas_b.brush_positions = join_vector_array(data["b"]["dynamic"])
	mask_canvas_b.brush_positions_static = join_vector_array(data["b"]["static"])

func _ready():
	$BrushModeLabel.visible = dev_mode
	mask_canvas_a.brush_radius = brush_radius
	mask_canvas_b.brush_radius = brush_radius
	mask_canvas_a.max_stroke_area = max_stroke_area
	mask_canvas_b.max_stroke_area = max_stroke_area

	if $PolygonBounds != null:
		var bounds = Rect2($PolygonBounds.rect_position, $PolygonBounds.rect_size)
		mask_canvas_a.bounds = bounds
		mask_canvas_b.bounds = bounds

func _draw():
	var circle = GoostGeometry2D.circle(brush_radius)
	circle.append(circle[0])
	draw_set_transform(last_mouse_pos, 0, Vector2.ONE)
	draw_polyline(circle, Color.black, 3)

func _process(_delta):
	last_mouse_pos = get_global_mouse_position()
	mask_canvas_a.last_mouse_pos = last_mouse_pos
	mask_canvas_b.last_mouse_pos = last_mouse_pos
	update()

	if dev_mode:
		if Input.is_action_just_pressed("ui_right"):
			if brush_mode == BrushMode.Mode.STATIC:
				brush_mode = BrushMode.Mode.DYNAMIC 
				$BrushModeLabel.text = "dynamic"
			else:
				brush_mode = BrushMode.Mode.STATIC
				$BrushModeLabel.text = "static"
			mask_canvas_a.brush_mode = brush_mode
			mask_canvas_b.brush_mode = brush_mode
		if Input.is_action_just_pressed("save"):
			var time = OS.get_time()
			var filepath = "res://level/configs/config-%d-%d-%d.json" % [time.hour, time.minute, time.second]
			save_to_file(filepath)
