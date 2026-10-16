extends Node2D
## Original Lisbon civilian art and the quay's existing illustrated market stall.
const ACTOR = preload("res://scripts/chapter/actor_proxy.gd")
var available := false
var highlighted := false
var clock := 0.0
var approach: Vector2:
	get: return position+Vector2(-35,40)

func _ready() -> void:
	var person = ACTOR.new(); person.npc_id = "observer"; person.facing = 0; add_child(person)
	var body := StaticBody2D.new(); body.collision_mask = 0; add_child(body)
	var footprint := CollisionPolygon2D.new(); var polygon := PackedVector2Array()
	for i in 12: polygon.append(Vector2.from_angle(i*TAU/12)*12)
	footprint.polygon = polygon; body.add_child(footprint)
	var name_label := Label.new(); name_label.text = "Comerciante"; name_label.position = Vector2(-65,-104)
	name_label.size.x = 130; name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	style_label(name_label,14); add_child(name_label)

func style_label(label: Label, size: int) -> void:
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE; label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",Color("f2dfb0")); label.add_theme_color_override("font_outline_color",Color("183432"))
	label.add_theme_constant_override("outline_size",5)

func _process(delta: float) -> void:
	clock += delta
	queue_redraw()

func _draw() -> void:
	if not available: return
	var center := Vector2(0,-123+sin(clock*2)*2)
	var color := Color("f2dfb0") if highlighted else Color("94c7ad")
	draw_polyline(PackedVector2Array([center+Vector2(0,-5),center+Vector2(5,0),center+Vector2(0,5),center+Vector2(-5,0),center+Vector2(0,-5)]),color,1.5,true)
	if highlighted:
		draw_set_transform(Vector2.ZERO,0,Vector2(1,0.45))
		draw_arc(Vector2.ZERO,23,0,TAU,40,Color(0.87,0.78,0.52,0.8),2,true)
		draw_set_transform(Vector2.ZERO)
