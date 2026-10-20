extends RefCounted
## Original pose atlases, stable feet and measured grip anchors, using Mar de Ferro impact times.
const Motion = preload("res://scripts/combat/mar_de_ferro/actor_motion.gd")
const Feel = preload("res://scripts/combat/portugal_motion.gd")
static var manifest: Dictionary = {}
static var textures: Dictionary = {}
static func data() -> Dictionary:
	if manifest.is_empty():
		manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/combat/portugal/frames.json"))
		manifest.entries.hero_firearm = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/combat/portugal/firearm-frames.json"))
	return manifest.entries
static func identity(model,unit: Dictionary) -> String:
	if unit.kind in ["wolf","bear"]: return unit.kind
	if model.encounter=="portugal_child_bear" and unit.id==0: return "leonor_child"
	var child: bool = model.encounter.begins_with("portugal_child")
	if unit.id==0: return "hero_child" if child else "hero"
	if unit.kind=="leonor": return "leonor_child" if child else "leonor"
	if unit.kind=="duarte" or unit.name=="Duarte": return "duarte"
	return "tome"
static func pose_frame(pose: String,time: float,style: String = "ES") -> int:
	match pose:
		"walk": return 1+posmod(int(time/Motion.WALK_STEP),2)
		"hurt": return 7
		"kneel": return 8
		"parry","guard","brace","cover": return 6
		"attack","thrust","crush","shoot","sweep","punch": return Feel.frame(style,time)
	return 0
static func draw_actor(canvas: CanvasItem,id: String,point: Vector2,face_left: bool,pose: String,time: float,style: String,wooden: bool,flash: float = 0,reduced: bool = false,aim: Vector2 = Vector2.RIGHT,size_multiplier: float = 1.0) -> Vector2:
	if id in ["wolf","bear"]:
		return preload("res://scripts/city/forest_animal.gd").paint(canvas,id,point,(62 if id=="wolf" else 102)*size_multiplier,face_left,pose,time,flash)
	if id=="hero" and style=="FO": id = "hero_firearm"
	var info: Dictionary = data()[id]
	if not textures.has(id):
		var source: Texture2D = load(info.source) if ResourceLoader.exists(info.source) else ImageTexture.create_from_image(Image.load_from_file(info.source))
		var image := source.get_image(); image.fix_alpha_edges(); image.generate_mipmaps()
		var filtered := CanvasTexture.new(); filtered.diffuse_texture = ImageTexture.create_from_image(image); filtered.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		textures[id] = filtered
	var frame := pose_frame(pose,time,style)
	if id=="hero_firearm" and (Feel.attacking(pose) or pose=="firearm_guard"): frame = Feel.firearm_sample(Feel.firearm_skill(pose),time).frame
	var r: Array = info.frames[frame]; var pivot: Array = info.pivots[frame]; var grip: Array = info.get("grips",info.pivots)[frame]
	var scale_factor: float = float(info.height)/float(info.reference_height)*size_multiplier
	var body := Feel.body_offset(style,time) if Feel.attacking(pose) else Vector2(0,Motion.body_drop(pose,time)*0.45)
	var lean := Feel.tilt(style,time) if Feel.attacking(pose) else 0.0
	if id=="hero_firearm" and (Feel.attacking(pose) or pose=="firearm_guard"):
		var sample := Feel.firearm_sample(Feel.firearm_skill(pose),time)
		body = sample.body; lean = sample.lean
	if reduced: body *= 0.45; lean = 0
	canvas.draw_set_transform(point,0,Vector2(1,0.36)); canvas.draw_circle(Vector2.ZERO,15 if not id.ends_with("_child") else 11,Color(0.06,0.08,0.05,0.27)); canvas.draw_set_transform(Vector2.ZERO)
	canvas.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if face_left: body.x = -body.x
	canvas.draw_set_transform(point+body,lean*(-1 if face_left else 1),Vector2(-1 if face_left else 1,1))
	var tint := Color.WHITE.lerp(Color("f0b3a4"),flash*0.40)
	var tip := point
	var artwork: Texture2D = textures[id]
	if id=="duarte": artwork = preload("res://scripts/chapter/order_livery.gd").texture(canvas,artwork,info,true)
	canvas.draw_texture_rect_region(artwork,Rect2(Vector2(-pivot[0],-pivot[1])*scale_factor,Vector2(r[2],r[3])*scale_factor),Rect2(r[0],r[1],r[2],r[3]),tint)
	if id in ["hero","hero_child"]:
		preload("res://scripts/chapter/hero_eyes.gd").draw(canvas,"combat" if id=="hero" else "combat_child",frame,r,pivot,scale_factor,false,face_left)
	if id=="hero_firearm":
		var muzzle: Array = info.muzzles[frame]
		var local_tip := Vector2(muzzle[0]-pivot[0],muzzle[1]-pivot[1])*scale_factor
		if face_left: local_tip.x = -local_tip.x
		tip = point+body+local_tip.rotated(lean*(-1 if face_left else 1))
	elif frame not in [7,8] and style!="PU":
		var hand := Vector2(grip[0]-pivot[0],grip[1]-pivot[1])*scale_factor
		var axis := Motion.weapon_axis("guard",time) if frame==6 else (Feel.weapon_axis(style,time) if frame in [3,4,5] else Vector2(0.50,-0.86))
		if Feel.attacking(pose) and frame in [3,4,5,6]:
			var local_aim := Vector2(absf(aim.x),aim.y).normalized()
			if style=="FO": axis = local_aim.rotated(-lean)
			elif style=="LA": axis = axis.rotated(local_aim.angle()*Feel.extension(style,time))
		draw_weapon(canvas,hand,axis,style,wooden,0.78 if id.ends_with("_child") else 1.0)
		if style=="FO":
			var muzzle := hand+axis*33
			if face_left: muzzle.x = -muzzle.x
			tip = point+body+muzzle.rotated(lean*(-1 if face_left else 1))
		# The fingers overlap the weapon shaft at the measured source point.
		var patch := Rect2(grip[0]-6,grip[1]-6,12,12)
		canvas.draw_texture_rect_region(artwork,Rect2((Vector2(patch.position)-Vector2(pivot[0],pivot[1]))*scale_factor,patch.size*scale_factor),Rect2(Vector2(r[0],r[1])+patch.position,patch.size),tint)
	canvas.draw_set_transform(Vector2.ZERO)
	return tip
static func draw_weapon(canvas: CanvasItem,hand: Vector2,axis: Vector2,style: String,wooden: bool,factor: float) -> void:
	var normal := axis.orthogonal()
	var shaft := Color("96714b")
	var metal := Color("b6c5bf")
	var length := (43.0 if style=="LA" else 31.0 if style in ["MC","FO"] else 25.0)*factor
	if wooden: metal = Color("c9ab76")
	canvas.draw_line(hand-axis*9*factor,hand+axis*length,Color("403b2c"),3.2*factor,true)
	if style=="LA":
		canvas.draw_line(hand-axis*13*factor,hand+axis*(length-6),shaft,2.0*factor,true)
		canvas.draw_colored_polygon(PackedVector2Array([hand+axis*(length+4),hand+axis*(length-7)+normal*3,hand+axis*(length-7)-normal*3]),metal)
	elif style=="MC":
		canvas.draw_line(hand-axis*7,hand+axis*(length-4),shaft,2.1,true)
		var head := hand+axis*(length-4)
		canvas.draw_colored_polygon(PackedVector2Array([head-axis*5,head+normal*9-axis*4,head+normal*10+axis*6,head+axis*5]),metal)
	elif style=="FO":
		canvas.draw_line(hand-axis*8,hand+axis*length,shaft,4.0,true)
		canvas.draw_line(hand+axis*2-normal,hand+axis*(length+2)-normal,metal,2.0,true)
		canvas.draw_line(hand-axis*4,hand-axis*6+normal*4,shaft,4.0,true)
	else:
		canvas.draw_colored_polygon(PackedVector2Array([hand+axis*3-normal*1.8,hand+axis*(length-3)-normal*1.0,hand+axis*length,hand+axis*(length-3)+normal*1.0,hand+axis*3+normal*1.8]),metal)
		canvas.draw_line(hand+axis*2-normal*5*factor,hand+axis*2+normal*5*factor,Color("a68b52"),1.7,true)
