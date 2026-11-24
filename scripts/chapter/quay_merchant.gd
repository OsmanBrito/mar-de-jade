extends Node2D
## Original Lisbon civilian art and the quay's existing illustrated market stall.
const ACTOR = preload("res://scripts/chapter/actor_proxy.gd")
var available := false
var highlighted := false
var clock := 0.0
var person: Node2D
var approach: Vector2:
	get: return position+Vector2(-35,40)

func _ready() -> void:
	person = ACTOR.new(); person.npc_id = "observer"; person.facing = 0; add_child(person)
	var body := StaticBody2D.new(); body.collision_mask = 0; add_child(body)
	var footprint := CollisionPolygon2D.new(); var polygon := PackedVector2Array()
	for i in 12: polygon.append(Vector2.from_angle(i*TAU/12)*12)
	footprint.polygon = polygon; body.add_child(footprint)

func style_label(label: Label, size: int) -> void:
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE; label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",Color("f2dfb0")); label.add_theme_color_override("font_outline_color",Color("183432"))
	label.add_theme_constant_override("outline_size",5)

func _process(delta: float) -> void:
	clock += delta
	queue_redraw()

func _draw() -> void:
	if person != null: person.outlined = available and highlighted
	if not available: return
	# Same marker language as the residents: badge, and a name plate while in focus.
	var art = preload("res://scripts/ui/marker_art.gd")
	var center := Vector2(0,-112+sin(clock*2)*2)
	art.badge(self,center,"…",highlighted,clock)
	if highlighted:
		art.caption(self,center+Vector2(0,-20),"Comerciante · Provisões")
		art.ground_ring(self,Vector2.ZERO,23,clock)
