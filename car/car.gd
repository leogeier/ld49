extends RigidBody2D

func start():
	$RearWheel.applied_torque = 2500
	$FrontWheel.applied_torque = 2500


func _ready():
	start()
