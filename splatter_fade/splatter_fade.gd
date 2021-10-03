extends Node2D

export(Curve) var progress_curve;


func start_fade(polygons, color = Color.red):
	var bounds_size = Vector2(1024, 576)
	# if $PolygonBounds != null:
	# 	bounds_size = $PolygonBounds.rect_size
	var image = Image.new()
	image.create(bounds_size.x, bounds_size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color.green)
	var blender = ImageBlender.new()
	blender.alpha_equation = ImageBlender.FUNC_MIN
	for polygon in polygons:
		var poly_image = GoostImage.render_polygon(polygon, true, color, Color.green)
		var size = poly_image.get_size()
		blender.blend_rect(poly_image, Rect2(Vector2.ZERO, size), image, Vector2.ZERO)
	var image_texture = ImageTexture.new()
	image_texture.create_from_image(image)
	$Sprite.texture = image_texture

	$Timer.start()

func on_timer_end():
	queue_free()

func _ready():
	pass

func _process(_delta):
	if !$Timer.is_stopped():
		var p = ($Timer.wait_time - $Timer.time_left) / $Timer.wait_time
		$Sprite.material.set_shader_param("progress", progress_curve.interpolate(p))
	else:
		$Sprite.material.set_shader_param("progress", 0.0)
