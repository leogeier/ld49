extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export(int) var mouse_button = BUTTON_LEFT
export(float) var brush_radius = 20

var draw_positions = []

# Called when the node enters the scene tree for the first time.
func _ready():
	$MaskViewportA/MaskCanvas.brush_radius = brush_radius
	$MaskViewportB/MaskCanvas.brush_radius = brush_radius

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
