extends Area2D

signal flag_reached

func on_body_entered(body):
	if body.is_in_group("car"):
		emit_signal("flag_reached")


func _ready():
	pass
