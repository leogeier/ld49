extends Area2D

signal flag_reached
signal car_arrived

func on_body_entered(body):
	if body.is_in_group("car") && body.layers == collision_layer:
		emit_signal("flag_reached")
		if !body.has_arrived:
			body.has_arrived = true
			emit_signal("car_arrived")


func _ready():
	pass
