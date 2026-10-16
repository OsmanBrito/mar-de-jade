@tool
extends Node2D
## Floor textiles and daylight remain below actors and never obstruct walking.
func _draw() -> void:
	var rug := PackedVector2Array([Vector2(-25,253),Vector2(100,191),Vector2(279,280),Vector2(154,342)])
	draw_colored_polygon(rug,Color("75654c"))
	var border := rug.duplicate(); border.append(rug[0])
	draw_polyline(border,Color("c1ac7b"),4,true)
	for i in range(1,28):
		var t := float(i)/28
		draw_line(rug[0].lerp(rug[3],t),rug[1].lerp(rug[2],t),Color(0.78,0.69,0.47,0.18 if i%3 else 0.38),1,true)
	for i in range(1,15):
		var t := float(i)/15
		draw_line(rug[0].lerp(rug[1],t),rug[3].lerp(rug[2],t),Color(0.2,0.22,0.16,0.15),1,true)
	# Soft window light crosses the floor rather than hiding the furniture.
	for shift in [Vector2(-182,115),Vector2(243,137)]:
		draw_colored_polygon(PackedVector2Array([shift+Vector2(-32,0),shift+Vector2(29,29),shift+Vector2(121,156),shift+Vector2(7,155)]),Color(1.0,0.88,0.59,0.075))
		for offset in [Vector2(0,0),Vector2(17,8)]:
			draw_line(shift+offset,shift+Vector2(70,147)+offset,Color(0.2,0.2,0.15,0.09),4,true)
