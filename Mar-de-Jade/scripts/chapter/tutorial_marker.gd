@tool
extends Marker2D
@export var active := false:
	set(value):
		active = value
		queue_redraw()
@export var reach_radius := 22.0

func _draw() -> void:
	if active or Engine.is_editor_hint():
		draw_set_transform(Vector2.ZERO,0,Vector2(1,0.5))
		draw_arc(Vector2.ZERO,reach_radius,0,TAU,48,Color(0.08,0.15,0.14,0.9),5)
		draw_arc(Vector2.ZERO,reach_radius,0,TAU,48,Color("e7d294"),2)
		draw_line(Vector2(-6,0),Vector2(6,0),Color("e7d294"),1)
		draw_line(Vector2(0,-6),Vector2(0,6),Color("e7d294"),1)
