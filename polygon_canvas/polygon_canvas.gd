extends Node2D

export(int) var mouse_button = BUTTON_LEFT
export(float) var brush_radius = 20
export(int) var circle_detail = 20
export(float) var max_stroke_area = 5000

export(bool) var dev_mode = false

var BrushMode = preload("res://polygon_canvas/brush_mode.gd")
var SplatterFade = preload("res://splatter_fade/splatter_fade.tscn")

onready var mask_canvas_a = $MaskViewportA/MaskCanvas
onready var mask_canvas_b = $MaskViewportB/MaskCanvas

var polyBoolean = PolyBoolean2D.new_instance()
var last_mouse_pos = Vector2.ZERO
var stroke_history = []
var brush_mode = BrushMode.Mode.DYNAMIC
var drawing_enabled = true setget set_drawing_enabled

signal stroke_count_changed(count_a, count_b)

func set_bounds(bounds_node):
	var bounds = Rect2(bounds_node.rect_position, bounds_node.rect_size)
	mask_canvas_a.bounds = bounds
	mask_canvas_b.bounds = bounds

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

func stroke_counts():
	return {"a": mask_canvas_a.stroke_count(), "b": mask_canvas_b.stroke_count()}

func undo_last_stroke():
	if stroke_history.empty():
		print("No stroke to undo!")
		return

	var last = stroke_history.pop_back()
	print("Undoing stroke ", last)
	var stroke = last["canvas"].last_stroke()
	var was_empty = last["canvas"].undo(last["brush_mode"])
	if was_empty:
		undo_last_stroke()
	else:
		emit_stroke_count_changed()
		var color = Color.red
		if last["canvas"] == mask_canvas_b:
			color = Color.blue
		fade_polygons(polygon_for_stroke(stroke), color)
	# last["canvas"].resize_brushes(last["index"], last["brush_mode"])

func polygon_for_stroke(stroke):
	var shapes = shapes_for_stroke(stroke)
	return polyBoolean.merge_polygons(shapes)

func stroke_area(stroke):
	var polygon = polygon_for_stroke(stroke)
	return GoostGeometry2D.polygon_area(polygon[0])

func on_new_position_a(mode):
	if mode == BrushMode.Mode.STATIC:
		return
	mask_canvas_a.stroke_area = stroke_area(mask_canvas_a.last_stroke())

func on_new_position_b(mode):
	if mode == BrushMode.Mode.STATIC:
		return
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

func fade_polygons(polygons, color):
	var fade = SplatterFade.instance()
	add_child(fade)
	fade.start_fade(polygons, color)

func clear():
	var polygons = generate_polygons()
	fade_polygons(polygons["a"], Color.red)
	fade_polygons(polygons["b"], Color.blue)
	mask_canvas_a.clear()
	mask_canvas_b.clear()
	stroke_history = []
	emit_stroke_count_changed()

func get_adjusted_bounds_size():
	var bounds_size = Rect2($PolygonBounds.rect_position, $PolygonBounds.rect_size)
	bounds_size.grow(brush_radius / 2)
	return bounds_size

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

	return merged_polygons

	# if $PolygonBounds == null || is_static:
	# 	return merged_polygons

	# print("Clipping...")
	# var bounds_size = get_adjusted_bounds_size()
	# var bounding_polygon = PoolVector2Array([
	# 	bounds_size.position,
	# 	bounds_size.position + Vector2(bounds_size.size.x, 0),
	# 	bounds_size.position + bounds_size.size,
	# 	bounds_size.position + Vector2(0, bounds_size.size.y)
	# 	])
	# var clipped_polygons = []
	# for polygon in merged_polygons:
	# 	clipped_polygons.append_array(GoostGeometry2D.intersect_polygons(polygon, bounding_polygon))
	# print(clipped_polygons.size(), " polygons after clipping")

	# return clipped_polygons

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
	if dev_mode:
		mask_canvas_a.max_stroke_area = 1000000
		mask_canvas_b.max_stroke_area = 1000000
	else:
		mask_canvas_a.max_stroke_area = max_stroke_area
		mask_canvas_b.max_stroke_area = max_stroke_area


	if $PolygonBounds != null && !dev_mode:
		set_bounds($PolygonBounds)

func _process(_delta):
	last_mouse_pos = get_global_mouse_position()
	mask_canvas_a.last_mouse_pos = last_mouse_pos
	mask_canvas_b.last_mouse_pos = last_mouse_pos

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
