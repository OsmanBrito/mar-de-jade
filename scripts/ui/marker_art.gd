extends RefCounted
## World-space markers drawn in the same language as the dialogue frame:
## jade badge with gold rim, serif caption plate, isometric ground ring.
const Presentation = preload("res://scripts/ui/presentation.gd")
const GOLD := Color("d9bc80")
const JADE := Color("3f8f78")
const INK := Color(0.035,0.07,0.068,0.94)

## Floating badge with a symbol ("!", "…", "?").
static func badge(canvas: CanvasItem,center: Vector2,symbol: String,highlighted: bool,clock: float) -> void:
	var s := 12.0+(1.5 if highlighted else 0.0)
	var glow := 0.5+0.5*sin(clock*3.0)
	if highlighted:
		for ring in range(4,0,-1):
			canvas.draw_circle(center,s+ring*3.0,Color(GOLD,0.04*glow))
	var d := PackedVector2Array([center+Vector2(0,-s),center+Vector2(s,0),center+Vector2(0,s),center+Vector2(-s,0)])
	canvas.draw_colored_polygon(d,INK)
	var inner := PackedVector2Array()
	for p in d: inner.append(center+(p-center)*0.72)
	canvas.draw_colored_polygon(inner,Color(JADE,0.55 if highlighted else 0.35))
	d.append(d[0])
	canvas.draw_polyline(d,GOLD if highlighted else Color(GOLD,0.7),1.6,true)
	var font: Font = Presentation.serif()
	var size := 15
	var w := font.get_string_size(symbol,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
	canvas.draw_string(font,center+Vector2(-w*0.5,font.get_ascent(size)*0.5-1),symbol,HORIZONTAL_ALIGNMENT_LEFT,-1,size,Color("fff2d1") if highlighted else Color("e5d6b0"))

## Caption plate centred above a point.
static func caption(canvas: CanvasItem,bottom_center: Vector2,text: String,font_size: int = 14) -> void:
	if text.is_empty(): return
	var font: Font = Presentation.serif()
	var w := font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
	var h := font.get_height(font_size)+8
	var rect := Rect2(bottom_center-Vector2(w*0.5+12,h),Vector2(w+24,h))
	canvas.draw_rect(rect,INK)
	canvas.draw_rect(rect.grow(-1),Color(GOLD,0.85),false,1.2)
	canvas.draw_rect(rect.grow(-4),Color(GOLD,0.22),false,1.0)
	for x in [rect.position.x+1,rect.end.x-1]:
		var c := Vector2(x,rect.get_center().y)
		canvas.draw_colored_polygon(PackedVector2Array([c+Vector2(0,-4),c+Vector2(4,0),c+Vector2(0,4),c+Vector2(-4,0)]),JADE)
	canvas.draw_string(font,Vector2(rect.position.x+12,rect.position.y+4+font.get_ascent(font_size)),text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color("f1e4c3"))

## Pulsing ellipse lying on the isometric ground.
static func ground_ring(canvas: CanvasItem,at: Vector2,radius: float,clock: float,color: Color = GOLD) -> void:
	var pulse := 0.5+0.5*sin(clock*3.5)
	canvas.draw_set_transform(at,0,Vector2(1,0.5))
	canvas.draw_arc(Vector2.ZERO,radius+pulse*3.0,0,TAU,40,Color(color,0.75),2.2,true)
	canvas.draw_arc(Vector2.ZERO,radius+8+pulse*5.0,0,TAU,40,Color(color,0.22*(1.0-pulse)),1.5,true)
	canvas.draw_set_transform(Vector2.ZERO)
