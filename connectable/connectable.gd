extends StaticBody2D

var polygon

func _ready():
	polygon = $CollisionPolygon2D.polygon
