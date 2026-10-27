extends RefCounted
## Presentation profiles only. Every hit still resolves at the inherited 0.45 s.
const IMPACT := preload("res://scripts/combat/mar_de_ferro/actor_motion.gd").IMPACT
const RELEASE := preload("res://scripts/combat/mar_de_ferro/actor_motion.gd").PROJECTILE_RELEASE
const PROFILES := {
	"ES":{"release":0.25,"strike":0.34,"follow":0.61,"recover":1.08,"step":10.0,"drawback":2.5,"tilt":0.038,"pause":0.065},
	"LA":{"release":0.32,"strike":0.38,"follow":0.57,"recover":1.02,"step":14.0,"drawback":1.8,"tilt":0.025,"pause":0.045},
	"MC":{"release":0.30,"strike":0.38,"follow":0.72,"recover":1.24,"step":5.0,"drawback":3.5,"tilt":0.060,"pause":0.105},
	"FO":{"release":RELEASE,"strike":RELEASE,"follow":0.58,"recover":1.12,"step":0.0,"drawback":0.0,"tilt":0.028,"pause":0.050},
	"PU":{"release":0.34,"strike":0.39,"follow":0.53,"recover":0.88,"step":11.0,"drawback":1.5,"tilt":0.030,"pause":0.040}
}
static func profile(style: String) -> Dictionary: return PROFILES.get(style,PROFILES.ES)
static func attacking(pose: String) -> bool: return pose in ["attack","thrust","crush","shoot","sweep","punch","shoot_measured","shoot_prepared","shoot_passage"]
static func extension(style: String,time: float) -> float:
	var p := profile(style)
	return smoothstep(p.release,IMPACT,time)*(1.0-smoothstep(p.follow,p.recover,time))
static func anticipation(style: String,time: float) -> float:
	return smoothstep(0,0.16,time)*(1.0-smoothstep(profile(style).release,IMPACT,time))
static func kick(time: float) -> float:
	return smoothstep(RELEASE,RELEASE+0.045,time)*(1.0-smoothstep(RELEASE+0.045,0.73,time))
static func actor_offset(style: String,time: float,direction: Vector2,reduced: bool) -> Vector2:
	var p := profile(style)
	var step: float = extension(style,time)*p.step-anticipation(style,time)*p.drawback
	if style=="FO": step = -kick(time)*3.5
	return direction*step*(0.45 if reduced else 1.0)
static func body_offset(style: String,time: float) -> Vector2:
	if style=="MC": return Vector2(0,-anticipation(style,time)*1.8+extension(style,time)*2.0)
	if style=="FO": return Vector2(-kick(time)*1.5,0)
	return Vector2(0,anticipation(style,time)*0.4+extension(style,time)*0.6)
static func tilt(style: String,time: float) -> float:
	if style=="FO": return -kick(time)*profile(style).tilt
	return (extension(style,time)-anticipation(style,time)*0.6)*profile(style).tilt
static func frame(style: String,time: float) -> int:
	var p := profile(style)
	if style=="FO" and time<p.follow: return 6 # Hold the stock through the shot; recoil moves the braced body.
	if time<p.strike: return 3
	if time<p.follow: return 4
	if time<p.recover: return 5
	return 0
static func weapon_axis(style: String,time: float) -> Vector2:
	if style=="FO": return Vector2.from_angle(-0.04-kick(time)*0.055)
	var p := profile(style)
	var ready := -1.02
	var back: float = {"ES":-2.2,"LA":-0.38,"MC":-1.92}.get(style,-1.02)
	var contact: float = {"ES":-0.10,"LA":-0.07,"MC":0.88}.get(style,0)
	var follow: float = {"ES":0.65,"LA":-0.07,"MC":1.26}.get(style,0)
	var angle := lerp_angle(ready,back,smoothstep(0,0.16,time))
	angle = lerp_angle(angle,contact,smoothstep(p.release,IMPACT,time))
	angle = lerp_angle(angle,follow,smoothstep(IMPACT,p.follow,time))
	angle = lerp_angle(angle,ready,smoothstep(p.follow,p.recover,time))
	return Vector2.from_angle(angle)
static func hit_pause(style: String,result: Dictionary,reduced: bool,child: bool) -> float:
	var pause := 0.0
	for hit in result.get("hits",[]):
		if hit.get("damage",0)>0: pause = maxf(pause,profile(style).pause)
		elif hit.get("damage",0)==0 and hit.get("resource","").is_empty():
			pause = maxf(pause,0.09 if int(result.get("defense_grades",{}).get(hit.id,0))==2 else 0.05)
		if hit.get("breaks",false): pause = maxf(pause,0.12)
	if child: pause = minf(pause,0.065)
	return minf(pause,0.025) if reduced else pause

# Technique presentation shares the exact release/impact clocks with combat and audio.
static func firearm_pose(skill: int) -> String:
	if skill==100:return "shoot_prepared"
	return {0:"shoot",1:"shoot_measured",2:"shoot_prepared",3:"shoot_passage",8:"firearm_guard"}.get(skill,"shoot")
static func firearm_skill(pose: String) -> int:
	return {"shoot":0,"shoot_measured":1,"shoot_prepared":2,"shoot_passage":3,"firearm_guard":8}.get(pose,0)
static func firearm_sample(skill: int,time: float) -> Dictionary:
	var recoil := kick(time)
	var settle := 1.0-smoothstep(0.72,1.12,time)
	var frame := 3 if time<RELEASE else 4 if time<0.58 else 5 if time<1.12 else 0
	var body := Vector2(-recoil*1.5,0)
	var lean := -recoil*0.028
	var displacement := -recoil*3.5
	match skill:
		1: # Raise deliberately, short controlled recoil, lower early.
			frame = 0 if time<0.10 else 3 if time<RELEASE else 4 if time<0.49 else 5 if time<0.85 else 0
			body = Vector2(-recoil*0.8,smoothstep(0.06,0.2,time)*settle*0.6)
			lean = -recoil*0.014; displacement = -recoil*2.0
		2: # Plant the stock, shoulder and hold through the heavier report.
			frame = 6 if time<0.14 else 3 if time<RELEASE else 4 if time<0.68 else 5 if time<1.12 else 0
			body = Vector2(-recoil*2.3,smoothstep(0,0.15,time)*settle*1.4)
			lean = -0.018*smoothstep(0,0.14,time)*settle-recoil*0.035
			displacement = -recoil*5.0
		3: # Quick shoulder, compact recovery; the view performs the real side step.
			frame = 2 if time<0.09 else 3 if time<RELEASE else 4 if time<0.49 else 5 if time<0.76 else 1+posmod(int((time-0.76)/0.14),2) if time<1.12 else 0
			body = Vector2(-recoil, -sin(clampf(time/0.76,0,1)*PI)*0.8)
			lean = -recoil*0.020; displacement = -recoil*2.5
		8: # Lift the barrel across the body and settle; never a firing frame.
			frame = 0 if time<0.10 else 6
			body = Vector2(0,smoothstep(0.08,0.24,time)*1.2)
			lean = 0.025*smoothstep(0.08,0.24,time); displacement = 0.0
	return {"frame":frame,"body":body,"lean":lean,"displacement":displacement}
static func firearm_offset(skill: int,time: float,direction: Vector2,reduced: bool) -> Vector2:
	return direction*float(firearm_sample(skill,time).displacement)*(0.45 if reduced else 1.0)

# Distinct artwork rows: upright precision, supported kneeling, low lateral lunge, barrel block.
static func firearm_art_frame(skill: int,time: float) -> int:
	var row: int = {1:0,2:1,3:2,8:3}.get(skill,0)
	var contact := RELEASE if skill!=8 else 0.20
	var recovery: float = {1:0.60,2:0.72,3:0.76,8:0.62}.get(skill,0.60)
	return row*3+(0 if time<contact else 1 if time<recovery else 2)
