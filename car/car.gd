extends RigidBody2D

var has_arrived = false

func start():
	$RearWheel.applied_torque = 2500
	$RearWheel.mode = RigidBody2D.MODE_RIGID
	$FrontWheel.applied_torque = 2500
	$FrontWheel.mode = RigidBody2D.MODE_RIGID
	mode = RigidBody2D.MODE_RIGID


func _ready():
	$RearWheel.layers = layers
	$FrontWheel.layers = layers
