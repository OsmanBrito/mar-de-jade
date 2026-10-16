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
static func attacking(pose: String) -> bool: return pose in ["attack","thrust","crush","shoot","sweep","punch"]
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
