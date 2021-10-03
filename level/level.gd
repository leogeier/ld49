extends Node2D


export(String) var config_file;
export(int) var max_strokes_a = 10;
export(int) var max_strokes_b = 10;

var arrived_cars = 0

signal level_complete

func condition_fulfilled():
	emit_signal("level_complete")

func car_arrived():
	var car_num = get_tree().get_nodes_in_group("car").size()
	arrived_cars += 1
	print("car arrived ", arrived_cars, " ", car_num)
	if arrived_cars >= car_num:
		emit_signal("level_complete")

func _ready():
	for body in $Bodies.get_children():
		var vis_polygon = Polygon2D.new()
		vis_polygon.color = Color(166.0 / 255, 144.0 / 255, 0)
		vis_polygon.modulate = Color(1,1,1,0.8)
		vis_polygon.polygon = body.get_node(@"CollisionPolygon2D").polygon
		$Bodies.add_child(vis_polygon)
