extends Control
## Ornament layer behind the dialogue text: lacquered ink panel, double gold rule,
## jade corner studs and a nameplate notch. Drawn in code so it scales to any size.
const GOLD := Color("d9bc80")
const JADE := Color("3f8f78")
var name_width := 0.0: ## width of the speaker plate; 0 hides it
	set(value): name_width = value; queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var r := Rect2(Vector2.ZERO,size)
	# Lacquer: deep green-black with a faint warm sheen toward the top.
	draw_rect(r,Color(0.035,0.07,0.068,0.95))
	for i in 12:
		var t := float(i)/12.0
		draw_rect(Rect2(0,0,size.x,size.y*(1.0-t)),Color(0.85,0.7,0.45,0.006))
	# Double rule.
	draw_rect(r.grow(-1),Color("3b2c1a"),false,3)
	draw_rect(r.grow(-1.5),Color(GOLD,0.9),false,1.4)
	draw_rect(r.grow(-7),Color(GOLD,0.28),false,1)
	# Corner studs.
	for corner in [Vector2(7,7),Vector2(size.x-7,7),Vector2(7,size.y-7),Vector2(size.x-7,size.y-7)]:
		_stud(corner,5.0)
	# Centre ornament on the top edge.
	var top := Vector2(size.x*0.5,1.5)
	draw_line(top-Vector2(70,0),top-Vector2(14,0),GOLD,1.4,true)
	draw_line(top+Vector2(14,0),top+Vector2(70,0),GOLD,1.4,true)
	_stud(top,7.0)

func _stud(at: Vector2,s: float) -> void:
	var diamond := PackedVector2Array([at+Vector2(0,-s),at+Vector2(s,0),at+Vector2(0,s),at+Vector2(-s,0)])
	draw_colored_polygon(diamond,JADE)
	diamond.append(diamond[0])
	draw_polyline(diamond,GOLD,1.2,true)
	draw_circle(at+Vector2(-s*0.25,-s*0.3),s*0.22,Color(1,1,1,0.4))
