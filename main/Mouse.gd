extends Node2D

var brush_radius

func _draw():
	var circle = GoostGeometry2D.circle(brush_radius)
	circle.append(circle[0])
	draw_set_transform(get_global_mouse_position(), 0, Vector2.ONE)
	draw_polyline(circle, Color.black, 3)

func _ready():
	pass

func _process(_delta):
	update()
