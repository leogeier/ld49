extends Node2D


var stroke_body = preload("res://stroke_body/stroke_body.tscn")
var stroke_joint = preload("res://stroke_joint/stroke_joint.tscn")
var identifier = 0

func translated_polygon(polygon, offset):
	var translated = PoolVector2Array()
	for original_point in polygon:
		var point = Vector2(original_point)
		point += offset
		translated.append(point)
	return translated

func create_bodies(polygons, color, layer, parent_node, dynamic = true):
	for polygon in polygons:
		var centroid = GoostGeometry2D.polygon_centroid(polygon)
		var offset_polygon = translated_polygon(polygon, -centroid)

		var body = stroke_body.instance()
		body.set_polygon(offset_polygon)
		body.set_color(color)
		body.set_collision(layer)
		body.name = str(identifier)
		if !dynamic:
			body.mode = RigidBody2D.MODE_STATIC
		identifier += 1
		parent_node.add_child(body)
		body.global_transform.origin = centroid # for some reason, this translation only works here, but not in stroke_body

func create_joints():
	for body_a in $A.get_children():
		for body_b in $B.get_children():
			if body_a.had_first_joint_pass && body_b.had_first_joint_pass:
				continue

			var trans_poly_a = translated_polygon(body_a.polygon, body_a.position)
			var trans_poly_b = translated_polygon(body_b.polygon, body_b.position)
			var intersections = GoostGeometry2D.intersect_polygons(trans_poly_a, trans_poly_b)
			for intersection in intersections:
				print("Found intersection between ", body_a.name, " and ", body_b.name)
				var joint = stroke_joint.instance()
				joint.position = GoostGeometry2D.polygon_centroid(intersection) - body_a.position
				joint.node_a = body_a.get_path()
				joint.node_b = body_b.get_path()
				body_a.add_child(joint)
	
	for body in $A.get_children():
		body.had_first_joint_pass = true
	for body in $B.get_children():
		body.had_first_joint_pass = true

func remove_children(node):
	for child in node.get_children():
		child.queue_free()

func clear():
	remove_children($A)
	remove_children($B)
	# $PolygonCanvas.clear()

func _ready():
	pass


func _process(_delta):
	if Input.is_action_just_pressed("toggle"):
		var polygons = $PolygonCanvas.generate_polygons()
		print("Creating bodies")
		create_bodies(polygons["a"], Color.red, 0, $A)
		create_bodies(polygons["a_static"], Color.red, 0, $A, false)
		create_bodies(polygons["b"], Color.blue, 1, $B)
		create_bodies(polygons["b_static"], Color.blue, 1, $B, false)
		print("Creating joints")
		create_joints()
		# $PolygonCanvas.clear()
		$PolygonCanvas.visible = false
	if Input.is_action_just_pressed("ui_cancel"):
		$PolygonCanvas.visible = true
		clear()
	if Input.is_action_just_pressed("ui_focus_next"):
		$PolygonCanvas.undo_last_stroke()
	if Input.is_action_just_pressed("ui_left"):
		$PolygonCanvas.load_from_file("res://level/configs/" + $Level.config_file)
