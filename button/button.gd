extends StaticBody2D

signal button_clicked

func on_body_entered(node):
	if node == $RigidBody2D:
		print("owo")
		emit_signal("button_clicked")


func _ready():
	pass
