extends RefCounted
## Shared timing preserves the illustrated sources and their grip anchors.
const IMPACT := 0.45
const RECOVER := 1.12
const PROJECTILE_RELEASE := 0.28
const WALK_STEP := 0.125

static func frame(kind: String, pose: String, time: float) -> int:
	if pose == "walk": return 1 + posmod(int(maxf(0,time) / WALK_STEP),2)
	if kind in preload("res://scripts/combat/mar_de_ferro/actor_art_catalog.gd").CIVILIAN_KINDS: return 0
	if pose == "hurt": return 5
	if time >= RECOVER: return 0
	if pose in ["guard","breathe","cast","shoot"]: return 3
	if pose in ["attack","thrust","sweep","crush","draw_cut","step"]:
		return 4 if time >= 0.25 and time < 0.7 else 3
	return 0

static func strike_weight(time: float) -> float:
	# Full extension meets the shared simulation impact, then eases back to guard.
	return smoothstep(0.12,IMPACT,time) * (1.0-smoothstep(IMPACT,0.86,time))

static func hurt_weight(time: float) -> float:
	return (1.0-smoothstep(0,0.25,time)) if time >= 0 else 0.0

static func weapon_axis(pose: String, time: float) -> Vector2:
	var rest:=atan2(-12.0,7.0)
	var angles: Vector3=Vector3(rest,rest,rest)
	match pose:
		"attack": angles=Vector3(-2.2,-0.12,0.65)
		"sweep": angles=Vector3(-2.75,0.18,1.15)
		"thrust": angles=Vector3(-0.55,-0.12,-0.05)
		"crush": angles=Vector3(-1.75,1.20,1.50)
		"draw_cut": angles=Vector3(0.7,-0.5,-1.15)
		"guard": angles=Vector3(-0.9,-0.9,-0.9)
		"cast": angles=Vector3(-1.57,-1.57,-1.57)
		"breathe": angles=Vector3(-2.9,-2.9,-2.9)
		"step": angles=Vector3(-2.6,-0.2,0.45)
		"shoot": angles=Vector3(rest,rest,rest)
	var angle:=lerp_angle(rest,angles.x,smoothstep(0,0.16,time))
	angle=lerp_angle(angle,angles.y,smoothstep(0.30,IMPACT,time))
	angle=lerp_angle(angle,angles.z,smoothstep(IMPACT,0.58,time))
	angle=lerp_angle(angle,rest,smoothstep(0.64,RECOVER,time))
	return Vector2.from_angle(angle)

static func body_drop(pose: String, time: float) -> float:
	var prepare:=smoothstep(0,0.16,time)*(1-smoothstep(0.30,IMPACT,time))
	var strike:=smoothstep(0.30,IMPACT,time)*(1-smoothstep(0.58,RECOVER,time))
	match pose:
		"crush": return -prepare*3.0+strike*2.0
		"attack","draw_cut": return prepare*0.5+strike*0.9
		"sweep","thrust","step": return prepare*1.0-strike*0.5
		"guard": return smoothstep(0,0.18,time)*(1-smoothstep(0.70,RECOVER,time))*1.5
		"cast","breathe": return -sin(clampf(time/RECOVER,0,1)*PI)*1.4
	return 0.0

