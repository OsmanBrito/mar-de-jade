extends Node2D
## The support is physical work; the pulse only indicates the injured worker.
var lifted := 0.0:
	set(value): lifted = value; queue_redraw()
var supported := false
var wound := Vector2(50,18)
var pulse := 0.0:
	set(value): pulse = value; queue_redraw()
func _draw() -> void:
	draw_set_transform(Vector2(0,-lifted*22),-lifted*0.14)
	draw_colored_polygon(PackedVector2Array([Vector2(-12,-22),Vector2(99,-12),Vector2(100,2),Vector2(-12,-8)]),Color("755139"))
	draw_line(Vector2(-9,-19),Vector2(96,-9),Color("b59868"),2,true)
	draw_line(Vector2(-8,-14),Vector2(97,-4),Color("523d2d"),1,true)
	draw_set_transform(Vector2.ZERO)
	if supported:
		draw_colored_polygon(PackedVector2Array([Vector2(9,8),Vector2(24,-3),Vector2(40,8),Vector2(24,15)]),Color("777765"))
		draw_line(Vector2(-24,18),Vector2(54,-23-lifted*12),Color("c8ae7d"),4,true)
	if pulse>0:
		var at := wound
		draw_arc(at,9+pulse*7,0,TAU,24,Color(0.45,0.85,0.65,pulse*0.6),1.2,true)
		draw_line(at+Vector2(-10,0),at+Vector2(-4,0),Color(0.45,0.85,0.65,pulse),1.5,true)
		draw_polyline(PackedVector2Array([at+Vector2(-4,0),at+Vector2(-1,-5),at+Vector2(2,4),at+Vector2(5,0),at+Vector2(11,0)]),Color(0.45,0.85,0.65,pulse),1.5,true)
