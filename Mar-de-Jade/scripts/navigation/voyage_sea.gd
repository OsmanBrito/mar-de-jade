extends RefCounted
## One wave spectrum drives displacement, normals, flotation, spray and foam ribbons.
const WAVES := [Vector4(0.011,0.007,0.95,5.2),Vector4(-0.017,0.022,1.45,2.1),Vector4(0.045,-0.031,2.1,0.75),Vector4(0.0034,-0.0022,0.36,3.1)]
const PHASES := Vector4(0,1.3,0.8,2.4)
const CHOP := 0.16
static func configure(material: ShaderMaterial) -> void:
	material.set_shader_parameter("wave_parameters",PackedVector4Array(WAVES))
	material.set_shader_parameter("wave_phases",PHASES)
	material.set_shader_parameter("wave_chop",CHOP)
static func height(at: Vector2,time: float,roughness: float = 0.0) -> float:
	var total := 0.0
	for i in WAVES.size():
		var wave: Vector4 = WAVES[i]
		var phase := at.dot(Vector2(wave.x,wave.y))-time*wave.z+PHASES[i]
		total += (sin(phase)+CHOP*sin(phase*2))*wave.w
	return total*(1+clampf(roughness,0,1)*1.4)
static func gradient(at: Vector2,time: float,roughness: float = 0.0) -> Vector2:
	var total := Vector2.ZERO
	for i in WAVES.size():
		var wave: Vector4 = WAVES[i]; var k := Vector2(wave.x,wave.y)
		var phase := at.dot(k)-time*wave.z+PHASES[i]
		total += k*(cos(phase)+CHOP*2*cos(phase*2))*wave.w
	return total*(1+clampf(roughness,0,1)*1.4)
static func crest(at: Vector2,time: float) -> float:
	return sin(at.dot(Vector2(WAVES[0].x,WAVES[0].y))-time*WAVES[0].z)
static func slope(at: Vector2,time: float,heading: float,roughness: float = 0.0) -> Vector2:
	var forward := Vector2.from_angle(heading); var right := forward.orthogonal()
	var pitch := atan2(height(at+forward*40,time,roughness)-height(at-forward*40,time,roughness),80)
	var roll := atan2(height(at+right*17,time,roughness)-height(at-right*17,time,roughness),34)
	return Vector2(clampf(pitch,-0.09,0.09),clampf(roll,-0.11,0.11))
