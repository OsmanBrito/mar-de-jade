extends Node2D
## The support is physical work; the pulse only indicates the injured worker.
## The fallen beam is an isometric timber block textured with the painted deck
## planks, so it reads as the same material as the quay's wood.
const Assets = preload("res://scripts/navigation/boarding_assets.gd")
const Shadows = preload("res://scripts/chapter/contact_shadow.gd")
var lifted := 0.0:
	set(value): lifted = value; queue_redraw()
var supported := false
var wound := Vector2(50,18)
var pulse := 0.0:
	set(value): pulse = value; queue_redraw()

func _draw() -> void:
	var start := Vector2(-12,-12); var end := Vector2(100,-2)
	var back := Vector2(7,-6)       # beam width, receding into the ground plane
	var up := Vector2(0,-11)        # beam height
	# Ground shadow stays put while the beam is lifted.
	Shadows.draw_contact(self,start.lerp(end,0.5)+Vector2(0,4),Vector2(62,9))
	draw_set_transform(Vector2(0,-lifted*22),-lifted*0.14)
	var wood: Texture2D = Assets.texture("regional-deck.png",true)
	var top := PackedVector2Array([start+up,end+up,end+up+back,start+up+back])
	var side := PackedVector2Array([start,end,end+up,start+up])
	draw_polygon(top,PackedColorArray([Color("d8c3a0")]),_planks(top,0.0),wood)
	draw_polygon(side,PackedColorArray([Color("8d7354")]),_planks(side,0.5),wood)
	# End grain with growth rings.
	var cap := PackedVector2Array([start,start+up,start+up+back,start+back])
	draw_colored_polygon(cap,Color("a8865a"))
	var ring_center := start+up*0.5+back*0.5
	for r in [1.8,3.6]:
		draw_arc(ring_center,r,0,TAU,16,Color("7a5c3a"),0.8,true)
	draw_polyline(PackedVector2Array([start+up,end+up,end+up+back]),Color(1,0.92,0.75,0.35),1.0,true)
	draw_line(start,end,Color("3d2c1e"),1.2,true)
	draw_set_transform(Vector2.ZERO)
	if supported:
		_stone(Vector2(24,8))
		# Lever: a tapered pole lit along its top edge.
		var a := Vector2(-24,18); var b := Vector2(54,-23-lifted*12)
		var n := (b-a).orthogonal().normalized()
		draw_colored_polygon(PackedVector2Array([a+n*2.8,b+n*1.8,b-n*1.8,a-n*2.8]),Color("8f6b43"))
		draw_line(a+n*1.6,b+n*1.0,Color("d6b886"),1.2,true)
	if pulse>0:
		var at := wound
		draw_arc(at,9+pulse*7,0,TAU,24,Color(0.45,0.85,0.65,pulse*0.6),1.2,true)
		draw_line(at+Vector2(-10,0),at+Vector2(-4,0),Color(0.45,0.85,0.65,pulse),1.5,true)
		draw_polyline(PackedVector2Array([at+Vector2(-4,0),at+Vector2(-1,-5),at+Vector2(2,4),at+Vector2(5,0),at+Vector2(11,0)]),Color(0.45,0.85,0.65,pulse),1.5,true)

## Plank texture coordinates running along the beam.
func _planks(points: PackedVector2Array,offset: float) -> PackedVector2Array:
	var uv := PackedVector2Array()
	var axis := (points[1]-points[0]).normalized()
	for p in points:
		uv.append(Vector2((p-points[0]).dot(axis)/140.0,offset+(p-points[0]).dot(axis.orthogonal())/60.0))
	return uv

## Squared stone used as the fulcrum: top, two faces, soft contact.
func _stone(at: Vector2) -> void:
	Shadows.draw_contact(self,at+Vector2(0,3),Vector2(20,7))
	var h := Vector2(0,-9)
	var l := at+Vector2(-15,0); var f := at+Vector2(0,7); var r := at+Vector2(15,0); var b := at+Vector2(0,-7)
	draw_colored_polygon(PackedVector2Array([l,f,f+h,l+h]),Color("7c7868"))
	draw_colored_polygon(PackedVector2Array([f,r,r+h,f+h]),Color("625f52"))
	draw_colored_polygon(PackedVector2Array([l+h,f+h,r+h,b+h]),Color("a7a28c"))
	draw_polyline(PackedVector2Array([l+h,f+h,r+h]),Color(1,1,0.9,0.25),1.0,true)
