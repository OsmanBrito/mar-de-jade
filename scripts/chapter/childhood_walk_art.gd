@tool
extends RefCounted
## The approved eight-phase convent gait also follows the child into the city.
const SIDE:Texture2D=preload("res://assets/art/portugal-v2/hero-child-side-walk-v1.png")
const VERTICAL:Texture2D=preload("res://assets/art/portugal-v2/hero-child-vertical-walk-v1.png")
const FRONT:=[0,1,2,3,0,1,2,3]
const FRONT_FLIP:=[false,false,false,false,true,true,true,true]
const BACK:=[0,3,1,2,0,3,1,2]
const BACK_FLIP:=[false,true,true,false,true,false,false,true]
static func sample(facing:int,time:float) -> Dictionary:
	var phase:=clampi(int(fposmod(time,3.0)/3.0*8),0,7)
	if facing in [1,3]:return {"texture":SIDE,"region":Rect2(phase*96,0,96,96),"flip":facing==1,"phase":phase}
	return {"texture":VERTICAL,"region":Rect2((BACK[phase] if facing==2 else FRONT[phase])*96,96 if facing==2 else 0,96,96),"flip":BACK_FLIP[phase] if facing==2 else FRONT_FLIP[phase],"phase":phase}
static func draw_actor(canvas:Node2D,facing:int,time:float,height:float,origin:Vector2) -> void:
	var frame:=sample(facing,time)
	var scale:=height/96.0
	canvas.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	canvas.draw_set_transform(origin,0,Vector2(-1 if frame.flip else 1,1))
	canvas.draw_texture_rect_region(frame.texture,Rect2(Vector2(-48,-96)*scale,Vector2(96,96)*scale),frame.region)
	canvas.draw_set_transform(Vector2.ZERO)
