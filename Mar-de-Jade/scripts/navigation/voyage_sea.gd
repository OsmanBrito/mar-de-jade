extends RefCounted
## Shared wave field: mesh, flotation and hull impact use the same phase.
const K0 := Vector2(0.011,0.007)
const K1 := Vector2(-0.017,0.022)
const K2 := Vector2(0.045,-0.031)
static func height(at: Vector2,time: float,roughness: float = 0.0) -> float:
	return (sin(at.dot(K0)-time*0.95)*2.5+sin(at.dot(K1)-time*1.45+1.3)*1.2+sin(at.dot(K2)-time*2.1)*0.55)*(1+clampf(roughness,0,1)*1.6)
static func crest(at: Vector2,time: float) -> float:
	return sin(at.dot(K0)-time*0.95)
static func slope(at: Vector2,time: float,heading: float,roughness: float = 0.0) -> Vector2:
	var forward := Vector2.from_angle(heading); var right := forward.orthogonal()
	var pitch := atan2(height(at+forward*40,time,roughness)-height(at-forward*40,time,roughness),80)
	var roll := atan2(height(at+right*17,time,roughness)-height(at-right*17,time,roughness),34)
	return Vector2(clampf(pitch,-0.09,0.09),clampf(roll,-0.11,0.11))
