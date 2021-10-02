extends Node2D


var stroke_body = preload("res://stroke_body/stroke_body.tscn")

func create_bodies(polygons, color, layer, parent_node):
	for polygon in polygons:
		var centroid = GoostGeometry2D.polygon_centroid(polygon)
		for i in range(polygon.size()):
			var point = polygon[i]
			point -= centroid
			polygon.set(i, point)

		var collision_polygon = CollisionPolygon2D.new();
		collision_polygon.polygon = polygon

		var visualization_polygon = Polygon2D.new();
		visualization_polygon.polygon = polygon
		visualization_polygon.color = color

		# var body = RigidBody2D.new();
		# body.add_child(collision_polygon)
		# body.add_child(visualization_polygon)
		# body.global_transform.origin = centroid
		# add_child(body)

		var body = stroke_body.instance()
		body.set_polygon(polygon)
		body.set_color(color)
		body.set_collision(layer)
		parent_node.add_child(body)
		body.global_transform.origin = centroid # for some reason, this translation only works here, but not in stroke_body

func _ready():
	pass


func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		var polygons = $PolygonCanvas.generate_polygons()
		create_bodies(polygons["a"], Color.red, 0, $A)
		create_bodies(polygons["b"], Color.blue, 1, $B)
		$PolygonCanvas.clear()
