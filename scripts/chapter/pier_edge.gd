extends RefCounted
## Exposed side of the timber pier: a plank fascia, piles going down into the
## river (wet and darker below the waterline), cross bracing and the pier's shadow
## on the water. Same painted plank texture as the deck.
const Assets = preload("res://scripts/navigation/boarding_assets.gd")
const FASCIA := 12.0
const WATERLINE := 40.0
const PILE_DEPTH := 58.0
const SPACING := 44.0

static func draw(canvas: CanvasItem,a: Vector2,b: Vector2) -> void:
	var along := b-a
	var count := maxi(1,roundi(along.length()/SPACING))
	# Shade on the water under the deck.
	canvas.draw_colored_polygon(PackedVector2Array([a+Vector2(0,FASCIA),b+Vector2(0,FASCIA),b+Vector2(14,WATERLINE+6),a+Vector2(14,WATERLINE+6)]),Color(0.0,0.08,0.09,0.32))
	# Cross bracing behind the piles.
	for i in count:
		var p := a.lerp(b,float(i)/count); var q := a.lerp(b,float(i+1)/count)
		canvas.draw_line(p+Vector2(0,FASCIA+2),q+Vector2(0,WATERLINE-4),Color("3e3022"),2.0,true)
	for i in count+1:
		_pile(canvas,a.lerp(b,float(i)/count))
	# Fascia board with the deck's painted planks running along it.
	var wood: Texture2D = Assets.texture("regional-deck.png",true)
	var u0 := a.dot(along.normalized())/150.0; var u1 := b.dot(along.normalized())/150.0
	canvas.draw_polygon(PackedVector2Array([a,b,b+Vector2(0,FASCIA),a+Vector2(0,FASCIA)]),
		PackedColorArray([Color("a8916f"),Color("a8916f"),Color("6e5a42"),Color("6e5a42")]),
		PackedVector2Array([Vector2(u0,0.1),Vector2(u1,0.1),Vector2(u1,0.32),Vector2(u0,0.32)]),wood)
	canvas.draw_line(a,b,Color(1.0,0.93,0.78,0.45),1.2,true)
	canvas.draw_line(a+Vector2(0,FASCIA),b+Vector2(0,FASCIA),Color("2b2016"),1.4,true)

static func _pile(canvas: CanvasItem,top: Vector2) -> void:
	var w := 4.5
	var dry_top := top+Vector2(0,FASCIA-1)
	var wet := top+Vector2(0,WATERLINE-10)
	var bottom := top+Vector2(0,PILE_DEPTH)
	canvas.draw_polygon(PackedVector2Array([dry_top-Vector2(w,0),dry_top+Vector2(w,0),wet+Vector2(w,0),wet-Vector2(w,0)]),
		PackedColorArray([Color("6b5238"),Color("4a3826"),Color("4a3826"),Color("6b5238")]))
	canvas.draw_polygon(PackedVector2Array([wet-Vector2(w,0),wet+Vector2(w,0),bottom+Vector2(w,0),bottom-Vector2(w,0)]),
		PackedColorArray([Color("33402f"),Color("22302a"),Color(0.1,0.25,0.25,0.0),Color(0.13,0.28,0.26,0.0)]))
	canvas.draw_line(dry_top-Vector2(w-1.2,0),wet-Vector2(w-1.2,0),Color(1,0.9,0.7,0.25),1.0,true)
	# Ripple where the pile meets the water.
	canvas.draw_set_transform(top+Vector2(0,WATERLINE),0,Vector2(1,0.35))
	canvas.draw_arc(Vector2.ZERO,w+3,0,TAU,20,Color(0.75,0.9,0.86,0.18),1.0,true)
	canvas.draw_set_transform(Vector2.ZERO)
