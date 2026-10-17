extends Node2D
var angle := 0.0:
	set(value): angle = value; queue_redraw()
var grounded := false:
	set(value): grounded = value; queue_redraw()

static func draw_tool(canvas: Node2D,grip: Vector2,radians: float,length: float = 43.0,side: float = 1.0) -> void:
	var direction := Vector2(cos(radians)*side,sin(radians))
	var normal := Vector2(-direction.y,direction.x)
	var tip := grip+direction*length
	canvas.draw_colored_polygon(PackedVector2Array([grip-normal*2,tip-normal,tip+normal,grip+normal*2]),Color("977349"))
	canvas.draw_line(grip-normal*0.5,tip-normal*0.5,Color("d6bd8e"),1.4,true)
	canvas.draw_line(grip-direction*9,grip,Color("544536"),4,true)
	canvas.draw_line(grip-normal*5,grip+normal*5,Color("b99a6b"),2.5,true)

func _draw() -> void:
	if grounded: preload("res://scripts/chapter/contact_shadow.gd").draw_contact(self,Vector2(8,2),Vector2(22,4))
	draw_tool(self,Vector2.ZERO,angle)
