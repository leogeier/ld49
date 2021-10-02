extends Node2D


export(int) var mouse_button = BUTTON_LEFT
export(float) var brush_radius = 20
export(int) var circle_detail = 20

var polyBoolean = PolyBoolean2D.new_instance()
var last_mouse_pos = Vector2.ZERO
var stroke_history = []

func add_stroke_to_history(brush_index, canvas):
	stroke_history.append({"index": brush_index, "canvas": canvas})

func on_new_stroke_a(brush_index):
	print("New stroke for a")
	add_stroke_to_history(brush_index, $MaskViewportA/MaskCanvas)

func on_new_stroke_b(brush_index):
	print("New stroke for b")
	add_stroke_to_history(brush_index, $MaskViewportB/MaskCanvas)

func undo_last_stroke():
	if stroke_history.empty():
		print("No stroke to undo!")
		return

	var last = stroke_history.pop_back()
	print("Undoing stroke ", last)
	last["canvas"].resize_brushes(last["index"])

func generate_polygons():
	print("Generating polygons...")
	return {
		"a": generate_polygons_for_positions($MaskViewportA/MaskCanvas.brush_positions),
		"b": generate_polygons_for_positions($MaskViewportB/MaskCanvas.brush_positions)
		}

func clear():
	$MaskViewportA/MaskCanvas.clear()
	$MaskViewportB/MaskCanvas.clear()

func generate_polygons_for_positions(positions):
	if positions.empty():
		print("no positions to generate circles for")
		return []
	var circles = []
	for position in positions:
		circles.append(generate_circle(position))
	print("Merging ", circles.size(), " polygons...")
	# var merged_polygons = polyBoolean.merge_polygons(circles)
	var merged_polygons = extract_outermost_polygons(polyBoolean.boolean_polygons_tree(circles, [], PolyBoolean2D.OP_UNION))
	print(merged_polygons.size(), " polygons after merge")

	if $PolygonBounds == null:
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
	var printed = false
	var arr = PoolVector2Array()
	var fcircle_detail = float(circle_detail)
	for i in range(circle_detail):
		arr.append(position + Vector2(1, 0).rotated(2 * PI * i / fcircle_detail) * brush_radius)
		if !printed:
			printed = true

	return arr

func _ready():
	$MaskViewportA/MaskCanvas.brush_radius = brush_radius
	$MaskViewportB/MaskCanvas.brush_radius = brush_radius

func _draw():
	var circle = GoostGeometry2D.circle(brush_radius)
	circle.append(circle[0])
	draw_set_transform(last_mouse_pos, 0, Vector2.ONE)
	draw_polyline(circle, Color.black, 3)

func _process(_delta):
	last_mouse_pos = get_global_mouse_position()
	$MaskViewportA/MaskCanvas.last_mouse_pos = last_mouse_pos
	$MaskViewportB/MaskCanvas.last_mouse_pos = last_mouse_pos
	update()
