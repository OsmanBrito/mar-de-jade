@tool
extends Node2D
## Code-native original layout furniture. Collision remains an editable scene child.
@export_enum("bed", "table") var furniture: String = "bed"

func _draw() -> void:
	var top = PackedVector2Array([Vector2(-65,-48),Vector2(0,-80),Vector2(65,-48),Vector2(0,-16)])
	for foot in [Vector2(-50,-22),Vector2(0,2),Vector2(50,-22)]:
		draw_line(foot+Vector2(0,-25),foot,Color("594a36"),8)
	draw_colored_polygon(top,Color("a58b63"))
	draw_polyline(PackedVector2Array([top[0],top[1],top[2],top[3],top[0]]),Color("51432f"),3)
	if furniture == "bed":
		draw_colored_polygon(PackedVector2Array([Vector2(-53,-48),Vector2(0,-73),Vector2(53,-48),Vector2(0,-23)]),Color("d1c6aa"))
		draw_colored_polygon(PackedVector2Array([Vector2(-26,-36),Vector2(27,-61),Vector2(53,-48),Vector2(0,-23)]),Color("66867d"))
		draw_line(Vector2(-65,-48),Vector2(-65,-75),Color("594a36"),8)
		draw_line(Vector2(0,-80),Vector2(0,-107),Color("594a36"),8)
		draw_line(Vector2(-65,-75),Vector2(0,-107),Color("594a36"),8)
