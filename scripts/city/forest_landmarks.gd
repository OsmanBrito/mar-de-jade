extends Node2D
## Small grounded clues are readable before the journal interaction.
func _draw() -> void:
	var nest := Vector2(630,478)
	draw_set_transform(nest,0,Vector2(1,.55))
	draw_circle(Vector2.ZERO,17,Color("584a32")); draw_arc(Vector2.ZERO,14,0,TAU,24,Color("a48a57"),4,true)
	draw_arc(Vector2(1,1),11,.3,TAU,20,Color("c0aa75"),2,true)
	for at in [Vector2(-4,0),Vector2(4,-2)]: draw_circle(at,3.8,Color("d8d0b0"))
	draw_set_transform(Vector2.ZERO)
	for i in 6:
		var at := Vector2(1065+i*9,1279-i*3)
		draw_line(at,at+Vector2(13,-10),Color("363c30"),6,true)
	for at in [Vector2(983,677),Vector2(1011,687)]:
		draw_line(at,at+Vector2(8,14),Color("7c694a"),3,true)
