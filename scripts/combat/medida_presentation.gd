extends RefCounted
## Presentation only: no combat state, damage, cost or movement is changed here.
const Feel=preload("res://scripts/combat/portugal_motion.gd")
static var cache: Dictionary={}
static func profiles() -> Dictionary:
	if cache.is_empty(): cache=JSON.parse_string(FileAccess.get_file_as_string("res://data/medida_presentation.json")).profiles
	return cache
static func group(id: String) -> String: return profiles().get(id,{}).get("motion","")
static func pose(id: String,style: String,fallback: String) -> String:
	var kind:=group(id)
	if kind in ["guard","watch","escort","sidestep"]: return "firearm_guard" if style=="FO" else "guard"
	if style=="FO":
		if kind in ["focus","aimed","finisher","cover_shot"]: return "shoot_prepared"
		return "shoot_passage" if kind=="passage" else "shoot_measured"
	return fallback
static func sample(id: String,time: float,style: String,aim: Vector2) -> Dictionary:
	var kind:=group(id); var extend:=Feel.extension(style,time); var anticipate:=Feel.anticipation(style,time)
	var result: Dictionary={"frame":Feel.frame(style,time),"body":Feel.body_offset(style,time),"tilt":Feel.tilt(style,time),"axis":Feel.weapon_axis(style,time),"lunge":Feel.profile(style).step*extend}
	match kind:
		"guard","watch","sidestep":
			result.frame=6; result.body=Vector2(0,smoothstep(0,.35,time)*.7); result.tilt=0.0; result.axis=Vector2.from_angle(-.8 if kind=="guard" else -.12); result.lunge=0.0
		"escort":
			result.frame=1+posmod(int(time/.15),2) if time>.12 and time<.65 else 6
			result.body=Vector2(0,sin(time*20)*.4);result.tilt=0.0;result.axis=Vector2.from_angle(-.45);result.lunge=0.0
		"precision","pierce":
			result.body=Vector2(extend*1.3,0);result.tilt=.018*extend;result.axis=Vector2(absf(aim.x),aim.y).normalized();result.lunge=extend*5
		"feint":
			result.body=Vector2(0,anticipate*.6);result.tilt=sin(time*16)*anticipate*.025;result.axis=Vector2.from_angle(-.25+sin(time*13)*anticipate*.45);result.lunge=extend*4
		"disarm":
			result.body=Vector2(extend,0);result.tilt=-.025*extend;result.axis=Vector2.from_angle(-.55+extend*.65);result.lunge=extend*3
		"sweep","projection":
			result.axis=Vector2.from_angle(lerp_angle(-1.8,.85,smoothstep(.24,.65,time)));result.tilt=.045*extend;result.lunge=extend*6
		"cleave","finisher":
			result.body=Vector2(0,-anticipate*2.5+extend*2.4);result.tilt=.07*extend-.025*anticipate;result.lunge=extend*7
		"push": result.axis=Vector2.from_angle(-.06);result.body=Vector2(extend*1.5,0);result.lunge=extend*5
		"retreat": result.lunge=extend*2
		"approach": result.lunge=extend*3
		"focus","aimed","cover_shot": result.body=Vector2(-Feel.kick(time),0);result.tilt=-.018*Feel.kick(time);result.lunge=0.0
		"volley":
			var second: float=Feel.kick(maxf(0,time-.045))
			result.body=Vector2(-Feel.kick(time)-second*.6,0);result.tilt=-.018*(Feel.kick(time)+second*.6);result.lunge=0.0
	if style=="FO" and kind not in ["guard","watch"]:
		var firearm: Dictionary=Feel.firearm_sample(Feel.firearm_skill(pose(id,style,"shoot")),time)
		result.body=firearm.body;result.tilt=firearm.lean;result.lunge=0.0
		if kind=="volley": result.body.x-=Feel.kick(maxf(0,time-.045))*.6
	return result
static func path_position(points: Array,fraction: float) -> Vector2:
	if points.is_empty(): return Vector2.ZERO
	if points.size()==1: return Vector2(points[0])
	var progress: float=clampf(fraction,0,1)*(points.size()-1); var index: int=mini(points.size()-2,floori(progress))
	return Vector2(points[index]).lerp(Vector2(points[index+1]),clampf(progress-index,0,1))
static func movement_fraction(id: String,time: float) -> float:
	match group(id):
		"approach": return smoothstep(.05,Feel.IMPACT,time)
		"escort": return smoothstep(.12,Feel.IMPACT,time)
		"passage","retreat","sidestep": return smoothstep(Feel.IMPACT+.10,1.05,time)
	return 0.0
static func draw_effect(view,id: String) -> void:
	var kind:=group(id)
	if kind.is_empty(): return
	var canvas=view.host; var time: float=view.clock; var reduced: bool=canvas.progress.data.options.reduced_fx
	var strength: float=.45 if reduced else 1.0
	var point: Vector2=view.unit_position(0)+Vector2(0,-30)
	var envelope: float=smoothstep(.05,.3,time)*(1.0-smoothstep(.65,1.05,time))
	var gold:=Color("e6cb8d");gold.a=envelope*.7*strength
	var jade:=Color("78c5af");jade.a=envelope*.8*strength
	if kind in ["guard","watch","sidestep"]:
		var count:=3 if id in ["ES57","MC57"] else 2 if id=="ES09" else 1
		var offsets: Array=[-1,0,1] if count==3 else [0,1] if count==2 else [0]
		for i in count:
			var facing: Vector2i=view.model.DIRECTIONS[posmod(int(view.model.units[0].face)+int(offsets[i]),4)]
			var direction:=Vector2(facing.x-facing.y,(facing.x+facing.y)*.5).normalized()
			var angle: float=direction.angle()
			canvas.draw_arc(point,19+i*2,angle-.35,angle+.35,12,jade,2,true)
		if kind=="watch": canvas.draw_line(point,point+view.strike_direction(0)*24,gold,1.5,true)
	elif kind=="escort":
		for unit in view.model.heroes:
			if unit.id==0 or unit.hp<=0: continue
			var partner: Vector2=view.unit_position(unit.id)+Vector2(0,-26)
			if view.model.distance(view.model.units[0].cell,unit.cell)<=2:
				canvas.draw_line(point,partner,jade,1.5,true);canvas.draw_arc(partner,15,-PI*.85,-PI*.15,16,jade,2,true);break
	elif kind in ["feint","disarm","pierce"] and view.model.inside(view.selected_cell):
		var target: Vector2=view.screen(view.selected_cell)+Vector2(0,-30)
		canvas.draw_arc(target,10,-1.3+time,1.2+time,14,gold,1.5,true)
	elif kind in ["sweep","projection"]:
		var direction: Vector2=view.strike_direction(0); var spread: float=.9 if kind=="sweep" else .55
		canvas.draw_arc(point+direction*15,17,direction.angle()-spread,direction.angle()+spread,20,gold,1.8,true)
	elif kind=="focus" and view.result.get("impacted",false) and view.model.inside(view.selected_cell):
		var target: Vector2=view.screen(view.selected_cell)+Vector2(0,-32)
		canvas.draw_polyline(PackedVector2Array([target+Vector2(0,-9),target+Vector2(8,0),target+Vector2(0,9),target+Vector2(-8,0),target+Vector2(0,-9)]),gold,1.5,true)
	elif kind=="volley" and time>=Feel.RELEASE and time<Feel.IMPACT:
		var muzzle: Vector2=view.weapon_tips.get(0,point)
		for i in mini(2,view.result.get("cells",[]).size()):
			var target: Vector2=view.screen(view.result.cells[i])+Vector2(0,-30)
			var progress: float=clampf((time-Feel.RELEASE-i*.035)/(Feel.IMPACT-Feel.RELEASE-i*.035),0,1)
			canvas.draw_line(muzzle,muzzle.lerp(target,progress),gold,1.4,true)
