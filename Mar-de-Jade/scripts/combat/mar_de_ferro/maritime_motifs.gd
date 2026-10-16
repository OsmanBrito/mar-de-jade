extends RefCounted
## Restrained inlaid marks: decorative, never targets or walkability information.
static func rose(canvas: Node2D, at: Vector2, radius: float, tint: Color, flatten:=0.42) -> void:
	for size in [radius,radius*.82]:
		var ring:=PackedVector2Array()
		for i in 65:
			var angle:=i*TAU/64
			ring.append(at+Vector2(cos(angle),sin(angle)*flatten)*size)
		canvas.draw_polyline(ring,tint,1.1,true)
	for i in 8:
		var angle:=i*TAU/8-PI*.5
		var direction:=Vector2(cos(angle),sin(angle)*flatten)
		var side:=Vector2(-sin(angle),cos(angle)*flatten)
		var length:=radius*.76 if i%2==0 else radius*.49
		var tip:=at+direction*length
		var edge:=at+side*radius*.09
		canvas.draw_colored_polygon(PackedVector2Array([at,tip,edge]),Color(tint,tint.a*.55))
		canvas.draw_polyline(PackedVector2Array([at-side*radius*.09,tip,edge]),tint,1,true)
	canvas.draw_circle(at,3,Color(tint,tint.a*.65),true,-1,true)

