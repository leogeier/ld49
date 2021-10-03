extends StaticBody2D

var activated = false

signal button_clicked

func on_body_entered(node):
	if node == $RigidBody2D && !activated:
		emit_signal("button_clicked")
		activated = true


func _ready():
	pass
