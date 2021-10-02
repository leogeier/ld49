extends Node2D


export(int) var mouse_button = BUTTON_LEFT
export(float) var brush_radius = 20
export(int) var circle_detail = 20

var polyBoolean = PolyBoolean2D.new_instance()
var last_mouse_pos = Vector2.ZERO

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
	print("Merging ", circles.size(), " polygons")
	var merged_polygons = PolyBoolean2D.merge_polygons(circles)
	print(merged_polygons.size(), " polygons after merge")
	# print("Clipping")
	# var size = $Combination.rect_size
	# var bounding_polygon = PoolVector2Array([Vector2(0, 0), Vector2(size.x, 0), size, Vector2(0, size.y)])
	# var clipped_polygons = []
	# for polygon in merged_polygons:
		# clipped_polygons.append(PolyBoolean2D.intersect_polygons(bounding_polygon, polygon))
	# print(clipped_polygons.size(), " polygons after clipping")
	# print(clipped_polygons)
	return merged_polygons

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
	# polyBoolean.parameters.clip_fill_rule = 1
	$MaskViewportA/MaskCanvas.brush_radius = brush_radius
	$MaskViewportB/MaskCanvas.brush_radius = brush_radius

func _draw():
	draw_circle(last_mouse_pos, brush_radius, Color.black)

func _process(_delta):
	last_mouse_pos = get_global_mouse_position()
	$MaskViewportA/MaskCanvas.last_mouse_pos = last_mouse_pos
	$MaskViewportB/MaskCanvas.last_mouse_pos = last_mouse_pos
	update()
