extends Node2D

signal start

func on_click():
	emit_signal("start")

func _ready():
	pass
