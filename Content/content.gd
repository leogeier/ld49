extends Node2D

var Main = preload("res://main/main.tscn")

func on_start():
	$Title.queue_free()
	add_child(Main.instance())

func _ready():
	pass
