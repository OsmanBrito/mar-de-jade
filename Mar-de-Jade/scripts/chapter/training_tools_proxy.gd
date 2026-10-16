@tool
extends Node2D
## Original placeholders for stored practice instruments; no combat behavior.
@export_range(1,4) var count := 2:
	set(value):
		count = value
		queue_redraw()

func _draw() -> void:
	for i in range(count):
		var offset = Vector2(i*9,i*3)
		draw_line(offset+Vector2(-13,-6),offset+Vector2(15,8),Color("d4b881"),4)
		draw_line(offset+Vector2(-10,-5),offset+Vector2(-6,-3),Color("66513a"),5)
