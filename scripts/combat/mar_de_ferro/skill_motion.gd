extends RefCounted
## Presentation-only trajectories. Combat still resolves once at ActorMotion.IMPACT.
const IMPACT=preload("res://scripts/combat/mar_de_ferro/actor_motion.gd").IMPACT
const PROJECTILE_RELEASE=preload("res://scripts/combat/mar_de_ferro/actor_motion.gd").PROJECTILE_RELEASE

static func release(time: float, start:=0.30) -> float:
	return smoothstep(start,IMPACT,time)

static func dash(time: float) -> float:
	return smoothstep(0.12,IMPACT,time)

static func projectile(time: float) -> float:
	return clampf((time-PROJECTILE_RELEASE)/(IMPACT-PROJECTILE_RELEASE),0,1)

static func contact(time: float) -> float:
	if time<IMPACT: return 0.0
	return 1.0-smoothstep(IMPACT,IMPACT+0.24,time)

static func settling(time: float) -> float:
	return smoothstep(IMPACT,1.12,time)

static func recoil(kind: String, time: float) -> float:
	var prepare:=smoothstep(0,0.16,time)*(1.0-smoothstep(0.27,IMPACT,time))
	var strike:=release(time)*(1.0-smoothstep(0.56,1.02,time))
	if kind in ["line","cut","bleed","sweep","hook"]:
		return -prepare*3.0+strike*(9.0 if kind in ["sweep","line"] else 14.0)
	return 0.0

static func path_window(time: float, start:=0.30, finish:=0.60, reduced:=false) -> Vector2:
	var head:=clampf((time-start)/(finish-start),0,1)
	var tail:=maxf(0,head-(0.28 if reduced else 0.46))
	return Vector2(tail,head)

static func trail_alpha(time: float, finish:=0.82) -> float:
	return smoothstep(0.29,0.34,time)*(1.0-smoothstep(0.56,finish,time))

static func slash_path(kind: String, centre: Vector2, direction: Vector2, radius:=30.0) -> PackedVector2Array:
	var points:=PackedVector2Array()
	var side: float=-1 if direction.x<0 else 1
	for i in 25:
		var t:=i/24.0
		var x:=lerpf(-radius,radius,t)*side
		var y:=lerpf(radius*0.65,-radius*0.65,t) if kind=="bleed" else lerpf(-radius*0.65,radius*0.65,t)
		points.append(centre+Vector2(x,y+sin(t*PI)*(-6 if kind=="bleed" else 6)))
	return points

static func subpath(points: PackedVector2Array, window: Vector2) -> PackedVector2Array:
	var shown:=PackedVector2Array()
	if points.size()<2 or window.y<=window.x: return shown
	var last:=points.size()-1
	var a:=clampf(window.x,0,1)*last
	var b:=clampf(window.y,0,1)*last
	shown.append(points[int(a)].lerp(points[mini(int(a)+1,last)],a-int(a)))
	for i in range(int(a)+1,int(b)+1): shown.append(points[i])
	shown.append(points[int(b)].lerp(points[mini(int(b)+1,last)],b-int(b)))
	return shown

