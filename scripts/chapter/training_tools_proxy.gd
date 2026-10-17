@tool
extends Node2D
## Painted practice rack shared with the training courtyard.
@export_range(1,4) var count := 2:
	set(value):
		count = value
		queue_redraw()

func _draw() -> void:
	var rack: Texture2D = preload("res://assets/art/combat/portugal/training-rack-mar-de-ferro.png")
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var width := 58.0+count*7.0
	var size := rack.get_size()*(width/rack.get_width())
	draw_texture_rect(rack,Rect2(Vector2(-size.x*0.5,-size.y),size),false)
