@tool
extends Node2D
## Shared soft floor contact; no shadow is baked into the painted sprites.
var footprint := Vector2(35,12)
var center := Vector2(0,-5)

static func draw_contact(canvas: Node2D,at: Vector2,size: Vector2) -> void:
	canvas.draw_set_transform(at,0,size)
	for ring in range(5,0,-1):
		canvas.draw_circle(Vector2.ZERO,float(ring)/5,Color(0.075,0.063,0.043,0.035))
	canvas.draw_set_transform(Vector2.ZERO)

func _draw() -> void:
	draw_contact(self,center,footprint)
