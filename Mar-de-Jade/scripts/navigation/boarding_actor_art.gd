extends RefCounted
## Mar de Ferro's actual illustrated combat strips, measured grips and weapon art.
const Assets = preload("res://scripts/navigation/boarding_assets.gd")
const Motion = preload("res://scripts/combat/mar_de_ferro/actor_motion.gd")
const Feel = preload("res://scripts/combat/portugal_motion.gd")
const WEAPONS := {"sword":{"file":"ines-sword.svg","size":Vector2(8,22),"pivot":Vector2(0.5,0.86)},"saber":{"file":"npc-saber.svg","size":Vector2(10,22),"pivot":Vector2(0.45,0.86)}}
static func frame(kind: String,pose: String,time: float) -> int:
	if pose=="parry": pose = "guard"
	if kind in ["sailor","worker"] and pose!="walk": return 0
	if pose=="kneel": return 5 # Original stagger/surrender pose; never compress an upright body.
	return Motion.frame(kind,pose,time)
static func draw_actor(canvas: Node2D,kind: String,point: Vector2,left: bool,pose: String,time: float,reaction: float = 0,reduced: bool = false,armed: bool = true) -> Vector2:
	var entry: Dictionary = Assets.data().actors[kind]
	var index := frame(kind,pose,time)
	var r: Array = entry.frames[index]; var pivot: Array = entry.pivots[index]
	var factor: float = float(entry.height)/float(entry.reference_height)
	var attacking := Feel.attacking(pose)
	var body := Feel.body_offset("ES",time) if attacking else Vector2(0,Motion.body_drop(pose,time)*0.45)
	var lean := Feel.tilt("ES",time) if attacking else 0.0
	if pose=="kneel": body = Vector2(0,2); lean = 0.10
	if reduced: body *= 0.45; lean = 0
	if left: body.x = -body.x
	canvas.draw_texture_rect(Assets.contact_shadow(),Rect2(point+Vector2(-17,-4),Vector2(34,10)),false)
	var mirror := -1.0 if left else 1.0
	canvas.draw_set_transform(point+body,lean*mirror,Vector2(mirror,1))
	var texture := Assets.texture(entry.source.get_file())
	var tint := Color.WHITE.lerp(Color("f0b3a4"),reaction*0.4)
	canvas.draw_texture_rect_region(texture,Rect2(Vector2(-pivot[0],-pivot[1])*factor,Vector2(r[2],r[3])*factor),Rect2(r[0],r[1],r[2],r[3]),tint)
	var tip := point+body
	if armed and not entry.weapon.is_empty() and pose not in ["hurt","kneel"]:
		var grip: Array = entry.grips[index]
		var hand := (Vector2(grip[0],grip[1])-Vector2(pivot[0],pivot[1]))*factor
		var axis := Motion.weapon_axis("guard",time) if pose in ["parry","guard"] else (Feel.weapon_axis("ES",time) if attacking else Vector2(0.5,-0.86).normalized())
		var weapon: Dictionary = WEAPONS[entry.weapon]
		# Same weapon/body ratio as the source game's illustrated actor renderer.
		var size: Vector2 = weapon.size*(factor/0.15)
		var rect := Rect2(-size*weapon.pivot,size)
		var points := PackedVector2Array([rect.position,rect.position+Vector2(size.x,0),rect.end,rect.position+Vector2(0,size.y)])
		for i in 4: points[i] = hand+points[i].rotated(axis.angle()+PI/2)
		canvas.draw_polygon(points,PackedColorArray([Color.WHITE]),PackedVector2Array([Vector2.ZERO,Vector2.RIGHT,Vector2.ONE,Vector2.DOWN]),Assets.texture(weapon.file))
		# Original fingers cover the hilt; the sword never floats above an empty fist.
		canvas.draw_texture_rect_region(texture,Rect2((Vector2(grip[0],grip[1])-Vector2(pivot[0],pivot[1])-Vector2(8,8))*factor,Vector2(16,16)*factor),Rect2(Vector2(r[0]+grip[0]-8,r[1]+grip[1]-8),Vector2(16,16)),tint)
		var local_tip: Vector2 = hand+axis*size.y*weapon.pivot.y
		local_tip.x *= mirror
		tip = point+body+local_tip.rotated(lean*mirror)
	canvas.draw_set_transform(Vector2.ZERO)
	return tip
