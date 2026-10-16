@tool
extends Node2D
## Shared stage actor: original NPC sprites, with procedural overlays for held objects.
const NPC_ART = preload("res://scripts/npcs/lisbon_npc_library.gd")
@export var npc_id: String = "":
	set(value):
		npc_id = value
		queue_redraw()
@export_enum("child", "hero_child", "tome", "leonor", "hero", "duarte", "leonor_adult") var identity: String = "child"
@export_enum("standing", "crouched", "seated", "fallen") var posture: String = "standing":
	set(value):
		posture = value
		queue_redraw()
@export var carries_bowl: bool = false:
	set(value):
		carries_bowl = value
		queue_redraw()
@export var carries_cup: bool = false:
	set(value):
		carries_cup = value
		queue_redraw()
@export var carries_training_tool := false:
	set(value):
		carries_training_tool = value
		queue_redraw()
@export var injured := false:
	set(value):
		injured = value
		queue_redraw()
@export var eye_glow := false:
	set(value):
		eye_glow = value
		queue_redraw()
var walking := false
var frame_time := 0.0
var facing := 0
var seat_support := false

func _process(_delta: float) -> void:
	if walking:
		queue_redraw()

func _draw() -> void:
	if identity in ["hero", "hero_child"] and npc_id.is_empty() and posture=="fallen":
		# Reuse the actual defeat silhouette, rather than shrinking a standing walker.
		preload("res://scripts/combat/portugal_actor_art.gd").draw_actor(self,"hero",Vector2.ZERO,facing!=3,"kneel",0,"PU",true,0,false,Vector2.RIGHT,1.1)
		return
	var child = identity not in ["tome", "hero", "duarte", "leonor_adult"]
	var height = 44.0 if child else 66.0
	if identity == "hero": height = 84.0
	if identity == "hero_child": height = 52.0
	var visual_id: String = NPC_ART.resolve(npc_id if not npc_id.is_empty() else identity)
	if identity == "hero" and npc_id.is_empty() and posture in ["seated","crouched"]:
		visual_id = "hero_story"
	if NPC_ART.data().has(visual_id):
		height = float(NPC_ART.data()[visual_id].height)
		child = height<60
	if posture != "standing" and not NPC_ART.data().has(visual_id):
		height *= 0.75
	draw_set_transform(Vector2.ZERO,0,Vector2(1,0.4))
	draw_circle(Vector2.ZERO,17 if child else 21,Color(0.05,0.07,0.06,0.3))
	draw_set_transform(Vector2.ZERO)
	if seat_support and posture == "seated":
		for x in [-11,11]: draw_line(Vector2(x,-23),Vector2(x,0),Color("624a32"),4,true)
		draw_colored_polygon(PackedVector2Array([Vector2(-17,-24),Vector2(0,-32),Vector2(17,-24),Vector2(0,-16)]),Color("9c7950"))
	var cloth = Color("6f9996") if child else Color("8b795b")
	if identity in ["hero", "hero_child"]: cloth = Color("6f9996")
	if identity == "duarte": cloth = Color("866654")
	if identity in ["leonor", "leonor_adult"]:
		cloth = Color("a288b6")
	var eye_offset = Vector2(4 if facing == 3 else -4,-height+7)
	if NPC_ART.draw_actor(self,visual_id,facing,walking,frame_time,posture):
		pass
	elif identity in ["hero", "hero_child"]:
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		var art = preload("res://scripts/chapter/quay_sprite.gd")
		var info: Dictionary = art.metadata().hero
		var index := clampi(facing,0,3)*4+(1+int(frame_time)%3 if walking else 0)
		var r: Array = info.frames[index]; var pivot: Array = info.pivots[index]
		var factor: float = height/295.0
		draw_texture_rect_region(art.artwork("hero"),Rect2(Vector2(-pivot[0],-pivot[1])*factor,Vector2(r[2],r[3])*factor),Rect2(r[0],r[1],r[2],r[3]))
	else:
		draw_colored_polygon(PackedVector2Array([Vector2(-12,-height+14),Vector2(11,-height+14),Vector2(17,-8),Vector2(-16,-8)]),cloth)
		var stride = sin(frame_time*TAU/3.0)*4.0 if walking else 0.0
		draw_line(Vector2(-8,-8),Vector2(-9+stride,0),Color("40392e"),7)
		draw_line(Vector2(8,-8),Vector2(9-stride,0),Color("40392e"),7)
		draw_circle(Vector2(0,-height+6),10 if child else 12,Color("c6a583"))
		draw_arc(Vector2(0,-height+4),10 if child else 12,PI,TAU,16,Color("453a2b"),6)
		if facing != 2: draw_circle(eye_offset,1.3,Color("453a2b"))
	if carries_training_tool:
		var side := 1.0 if facing == 3 else -1.0
		draw_line(Vector2(5*side,-height*0.45),Vector2(30*side,-height*0.3),Color("b6a177"),4)
	if injured:
		draw_line(Vector2(-12,-height*0.35),Vector2(12,-height*0.28),Color("e5ddc7"),7)
	if eye_glow:
		draw_circle(eye_offset,3,Color("78c5af"))
	if carries_cup:
		draw_rect(Rect2(-5,-height*0.4,10,9),Color("c1b699"))
	if carries_bowl:
		draw_set_transform(Vector2(0,-height*0.4),0,Vector2(1,0.48))
		draw_circle(Vector2.ZERO,10,Color("c1b699"))
		draw_arc(Vector2.ZERO,8,0,TAU,24,Color("6d634d"),2)
		draw_set_transform(Vector2.ZERO)




