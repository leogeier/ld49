extends RigidBody2D


func set_polygon(polygon):
	var centroid = GoostGeometry2D.polygon_centroid(polygon)
	# global_transform.origin = centroid

	for i in range(polygon.size()):
		var point = polygon[i]
		point -= centroid
		polygon.set(i, point)

	$CollisionPolygon2D.polygon = polygon
	$Polygon2D.polygon = polygon

func set_color(color):
	$Polygon2D.color = color

func set_collision(bit):
	set_collision_layer_bit(bit, true)
	set_collision_mask_bit(bit, true)

func _ready():
	pass
