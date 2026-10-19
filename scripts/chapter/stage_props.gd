extends Node2D
const Art = preload("res://scripts/chapter/story_prop_art.gd")
const Dining = preload("res://scripts/chapter/dining_art.gd")
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
var meal_surface_offset := Vector2.ZERO
var delivery_active := false
var clock := 0.0
var hero: Node2D
func _ready() -> void:
	var task_marker := preload("res://scripts/chapter/stage_task_marker.gd").new()
	task_marker.props = self; task_marker.z_index = 9; add_child(task_marker)
func _process(delta: float) -> void:
	clock += delta
	queue_redraw()
func _draw() -> void:
	var p := object_position
	if carrying and hero != null: p = hero.position+Vector2(20,-20)
	if delivery_active:
		Art.draw_item(self,"PT-Q01",p,32)
		return
	if map_kind == "cais" and not cargo_freed and not get_parent().has_node("../ChapterStaging"):
		draw_rect(Rect2(p+Vector2(-15,-24),Vector2(115,12)),Color("765538"))
		draw_line(p+Vector2(-5,0),p+Vector2(40,-40),Color("c6af83"),4)
	elif map_kind == "cais" and crate_task:
		draw_rect(Rect2(p-Vector2(15,24),Vector2(30,24)),Color("876442"))
		draw_line(p-Vector2(13,22),p+Vector2(13,-2),Color("b89a70"),3)
		draw_line(p+Vector2(13,-22),p+Vector2(-13,-2),Color("b89a70"),3)
	elif map_kind in ["room","courtyard"]:
		Art.draw_item(self,"PT-Q01",p,42)
	elif map_kind == "service":
		if carrying:
			Dining.draw(self,"bowl",p,22)
		elif meal_ready:
			p += meal_surface_offset
			Dining.draw(self,"napkin",p+Vector2(-6,-28),24)
			Dining.draw(self,"bread",p+Vector2(3,-36),26)
			Dining.draw(self,"cup",p+Vector2(-37,-25),12)
			Dining.draw(self,"bowl",p+Vector2(-19,-15),24)
			Dining.draw(self,"bowl",p+Vector2(25,-25),24)
	# The departure deck draws the actual coils in its timber plane.
	if green_sight:
		draw_arc(object_position+Vector2(45,-12),28+sin(clock*5)*2,0,TAU,32,Color(0.4,0.9,0.6,0.65),2)

