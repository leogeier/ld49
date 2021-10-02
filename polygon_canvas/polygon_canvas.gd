extends Node2D

export(int) var mouse_button = BUTTON_LEFT
export(float) var brush_radius = 20
export(int) var circle_detail = 20

export(bool) var dev_mode = false

var BrushMode = preload("res://polygon_canvas/brush_mode.gd")

onready var mask_canvas_a = $MaskViewportA/MaskCanvas
onready var mask_canvas_b = $MaskViewportB/MaskCanvas

var polyBoolean = PolyBoolean2D.new_instance()
var last_mouse_pos = Vector2.ZERO
var stroke_history = []
var brush_mode = BrushMode.Mode.DYNAMIC

func add_stroke_to_history(brush_index, bmode, canvas):
	stroke_history.append({"index": brush_index, "canvas": canvas, "brush_mode": bmode})
	print(stroke_history)

func on_new_stroke_a(brush_index, bmode):
	print("New stroke for A")
	add_stroke_to_history(brush_index, bmode, mask_canvas_a)

func on_new_stroke_b(brush_index, bmode):
	print("New stroke for B")
	add_stroke_to_history(brush_index, bmode, mask_canvas_b)

func undo_last_stroke():
	if stroke_history.empty():
		print("No stroke to undo!")
		return

	var last = stroke_history.pop_back()
	print("Undoing stroke ", last)
	last["canvas"].undo(last["brush_mode"])
	# last["canvas"].resize_brushes(last["index"], last["brush_mode"])

func generate_polygons():
	print("Generating polygons...")
	return {
		"a": generate_polygons_for_positions(mask_canvas_a.brush_positions),
		"a_static": generate_polygons_for_positions(mask_canvas_a.brush_positions_static, true),
		"b": generate_polygons_for_positions(mask_canvas_b.brush_positions),
		"b_static": generate_polygons_for_positions(mask_canvas_b.brush_positions_static, true),
		}

func clear():
	mask_canvas_a.clear()
	mask_canvas_b.clear()

func generate_polygons_for_positions(strokes, is_static = false):
	if strokes.empty():
		print("no strokes to generate circles for")
		return []
	var shapes = []
	for stroke in strokes:
		for i in range(stroke.size()):
			shapes.append(generate_circle(stroke[i]))
			if i > 0:
				shapes.append(generate_rect(stroke[i], stroke[i - 1]))

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

func extract_outermost_polygons(tree):
	var polygons = []
	for child in tree.get_children():
		polygons.append(child.points)
	return polygons

func generate_circle(position):
	print(position)
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

	if Input.is_action_pressed("lclick"):
		$ParticlesRed.emitting = true
	else:
		$ParticlesRed.emitting = false
	if Input.is_action_pressed("rclick"):
		$ParticlesBlue.emitting = true
	else:
		$ParticlesBlue.emitting = false

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
		if Input.is_action_just_pressed("ui_accept"):
			var time = OS.get_time()
			var filepath = "res://level/configs/config-%d-%d-%d.json" % [time.hour, time.minute, time.second]
			save_to_file(filepath)
