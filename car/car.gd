extends RigidBody2D

func start():
	$RearWheel.applied_torque = 2500
	$RearWheel.mode = RigidBody2D.MODE_RIGID
	$FrontWheel.applied_torque = 2500
	$FrontWheel.mode = RigidBody2D.MODE_RIGID
	mode = RigidBody2D.MODE_RIGID


func _ready():
	pass
