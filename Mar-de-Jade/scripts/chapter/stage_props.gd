extends Node2D
var map_kind := ""
var object_position := Vector2.ZERO
var marker := Vector2.ZERO
var marker_active := false
var marker_label := ""
var carrying := false
var cargo_freed := false
var green_sight := false
var packed := false
var crate_task := false
var meal_ready := false
var bedside := false
var bedside_point := Vector2.ZERO
var clock := 0.0
var hero: Node2D
func _process(delta: float) -> void:
	clock += delta
	queue_redraw()
func _draw() -> void:
	var p := object_position
	if carrying and hero != null: p = hero.position+Vector2(20,-20)
	if map_kind == "cais" and not cargo_freed:
		draw_rect(Rect2(p+Vector2(-15,-24),Vector2(115,12)),Color("765538"))
		draw_line(p+Vector2(-5,0),p+Vector2(40,-40),Color("c6af83"),4)
	elif map_kind == "cais" and crate_task:
		draw_rect(Rect2(p-Vector2(15,24),Vector2(30,24)),Color("876442"))
		draw_line(p-Vector2(13,22),p+Vector2(13,-2),Color("b89a70"),3)
		draw_line(p+Vector2(13,-22),p+Vector2(-13,-2),Color("b89a70"),3)
	elif map_kind in ["room","courtyard"]:
		draw_rect(Rect2(p-Vector2(13,23),Vector2(26,22)),Color("9b8862"))
		draw_arc(p+Vector2(0,-23),10,PI,TAU,12,Color("5c4d35"),3)
		if packed: draw_line(p+Vector2(-10,-12),p+Vector2(10,-12),Color("eee5cc"),2)
		if bedside:
			draw_rect(Rect2(bedside_point+Vector2(-5,-10),Vector2(10,10)),Color("c1b699"))
			draw_set_transform(bedside_point+Vector2(20,0),0,Vector2(1,0.5))
			draw_circle(Vector2.ZERO,11,Color("c1b699"))
			draw_arc(Vector2.ZERO,9,0,TAU,24,Color("6d634d"),2)
			draw_set_transform(Vector2.ZERO)
	elif map_kind == "service":
		draw_rect(Rect2(object_position+Vector2(-30,-18),Vector2(70,13)),Color("968569"))
		for offset in ([Vector2(-12,-24),Vector2(20,-24)] if carrying or meal_ready else []):
			draw_circle(p+offset,7,Color("c1b699"))
			draw_circle(p+offset+Vector2(0,16),9,Color("ddd2ae"))
	elif map_kind == "deck":
		draw_arc(p,23,0,TAU,24,Color("68ABF0"),5)
		draw_arc(p+Vector2(110,0),23,0,TAU,24,Color("eee5cc"),5)
	if green_sight:
		draw_arc(object_position+Vector2(45,-12),28+sin(clock*5)*2,0,TAU,32,Color(0.4,0.9,0.6,0.65),2)
	if marker_active:
		draw_arc(marker,21+sin(clock*4)*2,0,TAU,32,Color("e5c787"),2)
		draw_string(ThemeDB.fallback_font,marker+Vector2(-45,-30),marker_label,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("eee5cc"))

