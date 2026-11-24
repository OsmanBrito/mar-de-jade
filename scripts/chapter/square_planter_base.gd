@tool
extends Node2D
## Stone-rimmed planter bed drawn under the actors (z below the sorted layer).
## Move the parent planter node to move bed, shrub and collision together.

func _draw() -> void:
	var bed := PackedVector2Array([Vector2(-65,0),Vector2(0,-32),Vector2(65,0),Vector2(0,32)])
	preload("res://scripts/chapter/contact_shadow.gd").draw_contact(self,Vector2(0,6),Vector2(80,30))
	for side in [[bed[0],bed[3],Color("8d826c")],[bed[3],bed[2],Color("6f6553")]]:
		draw_colored_polygon(PackedVector2Array([side[0],side[1],side[1]+Vector2(0,9),side[0]+Vector2(0,9)]),side[2])
	draw_colored_polygon(bed,Color("4a3f2c"))
	var outline := bed.duplicate(); outline.append(bed[0])
	draw_polyline(outline,Color("c9bb99"),6,true)
	for i in 70:
		var at := Vector2(sin(i*2.4)*46,cos(i*3.7)*16)
		draw_circle(at,1.2,Color("5e5a33") if i%2 else Color("6b5c3f"))
