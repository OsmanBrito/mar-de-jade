extends Node2D
func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(-10,-6),Vector2(8,-12),Vector2(16,-3),Vector2(-2,4)]),Color("c8b78a"))
	for i in 3: draw_line(Vector2(-5+i,-5+i*2),Vector2(7+i,-9+i*2),Color("504a38"),0.8,true)
	draw_circle(Vector2(8,-3),2,Color("827442"))
