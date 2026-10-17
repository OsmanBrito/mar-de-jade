@tool
extends Node2D
## Surface-only marks: no new obstacle changes the approved walking exercises.
func _draw() -> void:
	for i in 130:
		var at := Vector2(fposmod(i*137.3,900)-450,125+fposmod(i*89.7,355))
		if absf(at.x)/640+absf(at.y-288)/320 > 0.85: continue
		var w := 5.0+fposmod(i*3.1,8)
		var tile := PackedVector2Array([at-Vector2(w,0),at-Vector2(0,w*0.5),at+Vector2(w,0),at+Vector2(0,w*0.5)])
		draw_colored_polygon(tile,Color(0.39,0.34,0.22,0.09) if i%3 else Color(0.9,0.85,0.67,0.13))
		if i%7 == 0:
			draw_polyline(PackedVector2Array([at-Vector2(4,0),at+Vector2(-1,2),at+Vector2(3,0),at+Vector2(6,3)]),Color(0.18,0.23,0.15,0.25),0.8,true)
	for origin in [Vector2(-350,300),Vector2(360,300),Vector2(50,374)]:
		preload("res://scripts/chapter/contact_shadow.gd").draw_contact(self,origin,Vector2(48,16))
		for i in 17:
			var at: Vector2 = origin+Vector2(sin(i*2.39)*47,cos(i*3.73)*14)
			var length := Vector2(2.3,1).rotated(i*0.93)
			draw_line(at-length,at+length,Color(0.32,0.33,0.15,0.52),1.5,true)
