@tool
extends Node2D
@export var definition: Dictionary = {}
var highlighted: bool = false
var pulse: float = 0.0
@export var interact_radius: float = 91.0

func _process(delta: float) -> void:
	pulse += delta
	queue_redraw()

func _draw() -> void:
	if Engine.is_editor_hint():
		draw_arc(Vector2.ZERO,interact_radius,0,TAU,64,Color(0.9,0.8,0.5,0.35),1.0)
	if definition.get("kind") == "npc":
		draw_set_transform(Vector2.ZERO,0,Vector2(1,0.42))
		draw_circle(Vector2.ZERO,15,Color(0.025,0.07,0.06,0.24))
		draw_set_transform(Vector2.ZERO)
	if definition.get("kind") == "ledger":
		var tabletop = PackedVector2Array([Vector2(-38,-31),Vector2(0,-49),Vector2(38,-31),Vector2(0,-13)])
		draw_line(Vector2(-27,-26),Vector2(-27,-2),Color("6e4930"),6)
		draw_line(Vector2(27,-26),Vector2(27,-2),Color("6e4930"),6)
		draw_colored_polygon(tabletop,Color("97714b"))
		draw_polyline(PackedVector2Array([Vector2(-17,-32),Vector2(0,-40),Vector2(17,-32),Vector2(0,-23),Vector2(-17,-32)]),Color("e5d3a7"),2)
		if highlighted:
			draw_colored_polygon(PackedVector2Array([Vector2(-17,-32),Vector2(0,-40),Vector2(0,-23)]),Color("e5d3a7"))
	var color = Color("e9d5a0") if highlighted else Color(0.88,0.83,0.65,0.5)
	var lift = -82.0 if definition.get("kind") == "npc" else -52.0
	if definition.get("kind") == "door":
		lift = -25
	var center = Vector2(0,lift + sin(pulse*2.3)*2)
	draw_polyline(PackedVector2Array([center+Vector2(0,-5),center+Vector2(4,0),center+Vector2(0,5),center+Vector2(-4,0),center+Vector2(0,-5)]),color,1.3)
	if highlighted:
		draw_set_transform(Vector2(0,1),0,Vector2(1,0.45))
		draw_arc(Vector2.ZERO,22,0,TAU,36,Color(0.87,0.78,0.52,0.7),1.4)
		draw_set_transform(Vector2.ZERO)
