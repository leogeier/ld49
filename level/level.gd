extends Node2D


export(String) var config_file;
export(int) var max_strokes_a = 10;
export(int) var max_strokes_b = 10;

signal level_complete

func condition_fulfilled():
	emit_signal("level_complete")

func _ready():
	for body in $Bodies.get_children():
		var vis_polygon = Polygon2D.new()
		vis_polygon.color = Color(166.0 / 255, 144.0 / 255, 0)
		vis_polygon.polygon = body.get_node(@"CollisionPolygon2D").polygon
		$Bodies.add_child(vis_polygon)
