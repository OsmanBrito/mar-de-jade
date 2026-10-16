extends RefCounted
## Three continuous foam ribbons follow actual historical poses, not current yaw.
const Sea = preload("res://scripts/navigation/voyage_sea.gd")
const LIFETIME := 7.0
const SAMPLE_INTERVAL := 0.05
const MAX_POINTS := 160
const STRIDE := 3
static func append_sample(trail: Array[Dictionary],at: Vector2,heading: float,time: float,speed: float) -> void:
	if trail.is_empty() or time-float(trail[-1].time)>=SAMPLE_INTERVAL-0.0001:
		trail.append({"at":at,"heading":heading,"time":time,"speed":speed})
	while trail.size()>MAX_POINTS or (not trail.is_empty() and time-float(trail[0].time)>LIFETIME): trail.pop_front()
static func ribbons(trail: Array[Dictionary],time: float,roughness: float) -> Array[ArrayMesh]:
	var result: Array[ArrayMesh] = []
	for band in [-1,0,1]:
		var vertices := PackedVector3Array(); var uvs := PackedVector2Array(); var ages := PackedVector2Array(); var colours := PackedColorArray()
		var previous: Array = []
		for i in range(trail.size()-1,-1,-STRIDE):
			var sample: Dictionary = trail[i]
			var age := time-float(sample.time)
			var speed := clampf(float(sample.speed)/90,0,1)
			if speed<0.07: previous = []; continue
			var forward := Vector2.from_angle(sample.heading); var side := forward.orthogonal()
			var centre: Vector2 = sample.at-forward*48+side*band*(20+age*11)
			var width := (14+age*6) if band==0 else (3.5+age*2.5)
			width *= lerpf(0.4,1.0,speed)
			var left := centre-side*width; var right := centre+side*width
			var section := [Vector3(left.x,Sea.height(left,time,roughness)-1.25,left.y),Vector3(right.x,Sea.height(right,time,roughness)-1.25,right.y)]
			var life := clampf(age/LIFETIME,0,1)
			var alpha := speed*(1.0-life)*(0.55 if band==0 else 0.38)*smoothstep(0,0.22,age)
			var colour := Color(1,1,1,alpha)
			if not previous.is_empty():
				for point in [[previous[0],0.0,previous[2],previous[3]],[previous[1],1.0,previous[2],previous[3]],[section[1],1.0,life,colour],[previous[0],0.0,previous[2],previous[3]],[section[1],1.0,life,colour],[section[0],0.0,life,colour]]:
					vertices.append(point[0]); uvs.append(Vector2(point[1],point[2])); ages.append(Vector2(point[2],0)); colours.append(point[3])
			previous = [section[0],section[1],life,colour]
		var mesh := ArrayMesh.new()
		if vertices.size()>0:
			var arrays := []; arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = vertices; arrays[Mesh.ARRAY_TEX_UV] = uvs; arrays[Mesh.ARRAY_TEX_UV2] = ages; arrays[Mesh.ARRAY_COLOR] = colours
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		result.append(mesh)
	return result
