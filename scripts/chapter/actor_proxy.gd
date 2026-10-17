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
var seat_lift := 0.0
var empty_bowl := false
var tool_angle := 0.45:
	set(value): tool_angle = value; queue_redraw()
var cup_lift := 0.0:
	set(value): cup_lift = value; queue_redraw()

func _process(_delta: float) -> void:
	if walking:
		queue_redraw()

func _draw() -> void:
	if identity=="hero" and npc_id.is_empty() and injured and posture=="standing":
		preload("res://scripts/combat/portugal_actor_art.gd").draw_actor(self,"hero",Vector2.ZERO,facing!=3,"hurt",0,"PU",true,0,true,Vector2.RIGHT,1.4)
		return
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
	preload("res://scripts/chapter/contact_shadow.gd").draw_contact(self,Vector2.ZERO,Vector2(17 if child else 21,6 if child else 8))
	if seat_support and posture == "seated":
		preload("res://scripts/chapter/dining_art.gd").draw(self,"stool_east" if facing == 3 else "stool_west",Vector2(-5 if facing == 3 else 5,3),30 if child else 38,seat_lift)
	var cloth = Color("6f9996") if child else Color("8b795b")
	if identity in ["hero", "hero_child"]: cloth = Color("6f9996")
	if identity == "duarte": cloth = Color("866654")
	if identity in ["leonor", "leonor_adult"]:
		cloth = Color("a288b6")
	var eye_offset = Vector2(4 if facing == 3 else -4,-height+7)
	if NPC_ART.draw_actor(self,visual_id,facing,walking,frame_time,posture,1.0,Vector2(0,-seat_lift if posture == "seated" else 0.0),eye_glow):
		pass
	elif identity in ["hero", "hero_child"]:
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		var art = preload("res://scripts/chapter/quay_sprite.gd")
		var info: Dictionary = art.metadata().hero
		var index := clampi(facing,0,3)*4+(1+int(frame_time)%3 if walking else 0)
		var r: Array = info.frames[index]; var pivot: Array = info.pivots[index]
		var factor: float = height/295.0
		draw_texture_rect_region(art.artwork("hero"),Rect2(Vector2(-pivot[0],-pivot[1])*factor,Vector2(r[2],r[3])*factor),Rect2(r[0],r[1],r[2],r[3]))
		preload("res://scripts/chapter/hero_eyes.gd").draw(self,"walk",index,r,pivot,factor,eye_glow)
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
		preload("res://scripts/chapter/staged_instrument.gd").draw_tool(self,Vector2(5*side,-height*0.45),tool_angle,30 if child else 43,side)
	if carries_cup:
		preload("res://scripts/chapter/dining_art.gd").draw(self,"cup",Vector2(4 if facing == 3 else -4,-height*0.38-seat_lift-cup_lift),11)
	if carries_bowl:
		var hand := Vector2(6 if facing == 3 else -6,-height*(0.16 if posture == "crouched" else 0.33))
		if empty_bowl: preload("res://scripts/chapter/story_prop_art.gd").draw_item(self,"PT-Q02",hand,19)
		else: preload("res://scripts/chapter/dining_art.gd").draw(self,"bowl",hand,19)




