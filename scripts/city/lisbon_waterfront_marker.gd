extends Node2D
## A physical embarkation landmark, with movement distinct from the market.
var clock := 0.0
func _process(delta: float) -> void:
	clock += delta; queue_redraw()
func _draw() -> void:
	draw_set_transform(Vector2(12,4),0,Vector2(1,.4)); draw_circle(Vector2.ZERO,15,Color(0,0,0,.18)); draw_set_transform(Vector2.ZERO)
	draw_line(Vector2.ZERO,Vector2(0,-158),Color("6c5438"),6,true)
	draw_line(Vector2(-1,-155),Vector2(-1,-4),Color("b2986c"),2,true)
	var flutter := sin(clock*2.2)*5
	var flag := PackedVector2Array([Vector2(2,-153),Vector2(70,-142+flutter),Vector2(53,-118+flutter*.6),Vector2(2,-126)])
	draw_colored_polygon(flag,Color("b6c9bd"))
	draw_line(Vector2(2,-153),Vector2(70,-142+flutter),Color("e3dbbb"),2,true)
	draw_line(Vector2(24,-146),Vector2(24,-125),Color("8e3931"),4,true)
	draw_line(Vector2(15,-138),Vector2(34,-134),Color("8e3931"),4,true)
