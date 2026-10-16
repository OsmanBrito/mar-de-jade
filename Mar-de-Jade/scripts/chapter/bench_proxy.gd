@tool
extends Node2D

func _draw() -> void:
	var seat = PackedVector2Array([Vector2(-110,-60),Vector2(-50,-90),Vector2(110,-10),Vector2(50,20)])
	for foot in [Vector2(-100,-25),Vector2(-50,-50),Vector2(100,25),Vector2(50,50)]:
		draw_line(foot+Vector2(0,-35),foot,Color("66533b"),8)
	draw_colored_polygon(seat,Color("a38b63"))
	draw_polyline(PackedVector2Array([seat[0],seat[1],seat[2],seat[3],seat[0]]),Color("66533b"),3)
	draw_line(seat[1]+Vector2(0,-25),seat[2]+Vector2(0,-25),Color("66533b"),8)
	draw_line(seat[1],seat[1]+Vector2(0,-25),Color("66533b"),6)
	draw_line(seat[2],seat[2]+Vector2(0,-25),Color("66533b"),6)
