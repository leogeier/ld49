extends Node2D

export(int) var level_idx = 0

var stroke_body = preload("res://stroke_body/stroke_body.tscn")
var stroke_joint = preload("res://stroke_joint/stroke_joint.tscn")
var identifier = 0
var is_running = false

var level_list = [
	preload("res://level/level1.tscn"),
	preload("res://level/level2.tscn"),
	preload("res://level/level3.tscn"),
	preload("res://level/level4.tscn"),
	preload("res://level/level5.tscn"),
	preload("res://level/level_sandbox.tscn"),
	]

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
		identifier += 1
		if !dynamic:
			body.mode = RigidBody2D.MODE_STATIC
		parent_node.add_child(body)
		body.global_transform.origin = centroid # for some reason, this translation only works here, but not in stroke_body

func create_joints_between(body_a, body_b):
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

func create_joints():
	for body_a in $A.get_children():
		for body_b in $B.get_children():
			if body_a.had_first_joint_pass && body_b.had_first_joint_pass:
				continue
			create_joints_between(body_a, body_b)

	var bodies = $A.get_children().duplicate()
	bodies.append_array($B.get_children())
	print("bodies ", bodies)
	for connectable in $LevelContainer.get_child(0).get_node(@"Connectables").get_children():
		for body in bodies:
			create_joints_between(body, connectable)
	
	for body in $A.get_children():
		body.had_first_joint_pass = true
	for body in $B.get_children():
		body.had_first_joint_pass = true

func remove_children(node):
	for child in node.get_children():
		child.queue_free()

func clear_bodies_node(node, fade_color):
	var polygons = []
	for child in node.get_children():
		var polygon = PoolVector2Array()
		for point in child.polygon:
			polygon.append(child.global_transform.xform(point))
		polygons.append(polygon)
	$PolygonCanvas.fade_polygons(polygons, fade_color)

	remove_children(node)

func clear_bodies():
	clear_bodies_node($A, Color.red)
	clear_bodies_node($B, Color.blue)

func on_undo_button_pressed():
	$PolygonCanvas.undo_last_stroke()

func clear_canvas():
	$PolygonCanvas.clear()

func on_clear_button_pressed():
	clear_canvas()

func toggle_running():
	if !is_running:
		$Interface/UndoButton.disabled = true
		$Interface/ClearButton.disabled = true
		var polygons = $PolygonCanvas.generate_polygons()
		print("Creating bodies")
		create_bodies(polygons["a"], Color.red, 0, $A)
		create_bodies(polygons["a_static"], Color.red, 0, $A, false)
		create_bodies(polygons["b"], Color.blue, 1, $B)
		create_bodies(polygons["b_static"], Color.blue, 1, $B, false)
		print("Creating joints")
		create_joints()
		$PolygonCanvas.visible = false
		$PolygonCanvas.drawing_enabled = false
		$Interface/StartButton.visible = false
		$Interface/StopButton.visible = true
		$LevelContainer.get_child(0).get_node("PolygonBounds").visible = false
		for car in get_tree().get_nodes_in_group("car"):
			car.start()
		is_running = true
	else:
		set_up_painting()
		clear_bodies()
		load_level()

func set_up_painting():
	$PolygonCanvas.visible = true
	$PolygonCanvas.drawing_enabled = true
	$Interface/UndoButton.disabled = false
	$Interface/ClearButton.disabled = false
	$Interface/StartButton.visible = true
	$Interface/StopButton.visible = false
	$Interface/Continue.visible = false
	is_running = false

func next_level():
	if level_idx == level_list.size() - 1:
		print("NO MORE LEVELS")
		return
	level_idx += 1
	clear_canvas()
	load_level()

func load_level():
	clear_bodies()
	set_up_painting()
	for child in $LevelContainer.get_children():
		child.queue_free()
	var level = level_list[level_idx].instance()
	level.connect("level_complete", self, "on_level_complete")
	$PolygonCanvas.set_bounds(level.get_node(@"PolygonBounds"))
	$LevelContainer.add_child(level)
	$Interface/StrokeCountA.stroke_limit = level.max_strokes_a
	$Interface/StrokeCountA.on_stroke_count_changed(0, 0)
	$Interface/StrokeCountB.stroke_limit = level.max_strokes_b
	$Interface/StrokeCountB.on_stroke_count_changed(0, 0)

func on_level_complete():
	$Interface/Continue.visible = true
	var counts = $PolygonCanvas.stroke_counts()
	var level = $LevelContainer.get_child(0)
	var good = counts["a"] <= level.max_strokes_a && counts["b"] <= level.max_strokes_b
	$Interface/Continue/Good.visible = good
	$Interface/Continue/Bad.visible = !good

func _ready():
	load_level()
	$Mouse.brush_radius = $PolygonCanvas.brush_radius

func _process(_delta):
	if Input.is_action_just_pressed("toggle"):
		toggle_running()

	if !is_running:
		if Input.is_action_just_pressed("undo"):
			$PolygonCanvas.undo_last_stroke()
		if Input.is_action_just_pressed("clear"):
			clear_canvas()

	if Input.is_action_just_pressed("ui_left"):
		$PolygonCanvas.load_from_file("res://level/configs/" + $Level.config_file)
