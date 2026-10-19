extends Node2D
## The near rail sorts in front of people standing on the bridge.
func _draw() -> void:
	draw_line(Vector2(-110,-21),Vector2(110,-21),Color("5a4933"),6,true)
	draw_line(Vector2(-110,-23),Vector2(110,-23),Color("a79165"),2,true)
	for x in [-100,0,100]:
		draw_line(Vector2(x,0),Vector2(x,-32),Color("685239"),7,true)
		draw_line(Vector2(x-1,-2),Vector2(x-1,-30),Color("9b8058"),2,true)
		draw_circle(Vector2(x,-33),4,Color("b4a17a"))
