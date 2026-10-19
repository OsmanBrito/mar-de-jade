@tool
extends Node2D
var kind := "tide"
var released := false
func _draw() -> void:
	if kind=="tide":
		draw_line(Vector2(-2,8),Vector2(-2,-53),Color("6e5337"),9,true)
		for y in [-43,-27,-11]: draw_line(Vector2(-8,y),Vector2(7,y),Color("d7c8a0"),2,true)
		draw_line(Vector2(-6,-6),Vector2(7,-6),Color("6bb5ad"),4,true)
	elif kind=="mooring":
		draw_line(Vector2(-13,-13),Vector2(13,-13),Color("6e5337"),7,true)
		draw_circle(Vector2(-10,-7),5,Color("756246")); draw_circle(Vector2(10,-7),5,Color("756246"))
		var rope := PackedVector2Array([Vector2(0,-8),Vector2(30,35),Vector2(62,90),Vector2(88,138)])
		if released: rope = PackedVector2Array([Vector2(0,-8),Vector2(0,15),Vector2(22,28),Vector2(42,10)])
		draw_polyline(rope,Color("695139"),5,true); draw_polyline(rope,Color("c1a475"),2,true)
	else:
		var page := PackedVector2Array([Vector2(-22,-41),Vector2(8,-52),Vector2(30,-35),Vector2(-3,-24)])
		draw_colored_polygon(page,Color("e0d2a7"))
		draw_string(ThemeDB.fallback_font,Vector2(-15,-36),"5 + 2",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("3b514b"))
		for i in 3: draw_line(Vector2(-12+i*3,-31+i*2),Vector2(10+i*3,-39+i*2),Color("716c50"),1,true)
