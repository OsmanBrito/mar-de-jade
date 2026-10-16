extends SubViewportContainer
## Presentation only: the existing 2D chart remains the authority for the voyage.
const Sea = preload("res://scripts/navigation/voyage_sea.gd")
const Wake = preload("res://scripts/navigation/voyage_wake.gd")
var game
var viewport: SubViewport
var world: Node3D
var camera: Camera3D
var player: Node3D
var water_material: ShaderMaterial
var near_water: MeshInstance3D
var near_material: ShaderMaterial
var actors: Dictionary = {}
var signals: Dictionary = {}
var sail_panels: Array[Node3D] = []
var wake: Array[MeshInstance3D] = []
var wake_material: ShaderMaterial
var camera_heading := 0.0
var camera_ready := false
var last_position := Vector2.ZERO
var materials: Dictionary = {}
var trail: Array[Dictionary] = []
var spray: Array[Dictionary] = []
var last_crest := 0.0
var last_impact_time := -10.0
var last_sea_time := -1.0
var splash_serial := 0
var impact_strength := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE; stretch = true
	size = game.get_viewport_rect().size
	viewport = SubViewport.new(); viewport.size = Vector2i(size); viewport.own_world_3d = true
	viewport.handle_input_locally = false; viewport.msaa_3d = Viewport.MSAA_2X; add_child(viewport)
	world = Node3D.new(); viewport.add_child(world)
	var environment := WorldEnvironment.new(); var settings := Environment.new()
	settings.background_mode = Environment.BG_SKY
	var sky := Sky.new(); var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("4c809d"); sky_material.sky_horizon_color = Color("b4cbd0")
	sky_material.ground_horizon_color = Color("b4cbd0"); sky_material.ground_bottom_color = Color("3e6873")
	sky_material.sky_curve = 0.2; sky.sky_material = sky_material; settings.sky = sky
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("c6d5cd"); settings.ambient_light_energy = 0.75
	settings.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	settings.fog_enabled = true; settings.fog_density = 0.00012
	settings.fog_light_color = Color("b4cbd0"); settings.fog_sky_affect = 0.0
	environment.environment = settings; world.add_child(environment)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-32,-55,0)
	sun.light_color = Color("fff0d5"); sun.light_energy = 1.15
	sun.light_specular = 0.32
	world.add_child(sun)
	var ocean := MeshInstance3D.new(); var plane := PlaneMesh.new(); plane.size = Vector2(140000,140000)
	# Slight overlap under the near mesh avoids a sparkling gap at its moving edge.
	ocean.mesh = plane; ocean.position = Vector3(18000,-3,14500)
	water_material = ShaderMaterial.new(); water_material.shader = load("res://assets/shaders/navigation_perspective_ocean.gdshader")
	Sea.configure(water_material)
	ocean.material_override = water_material; world.add_child(ocean)
	near_water = MeshInstance3D.new(); var near_plane := PlaneMesh.new()
	near_plane.size = Vector2(4096,4096); near_plane.subdivide_width = 160; near_plane.subdivide_depth = 160
	near_water.mesh = near_plane; near_material = water_material.duplicate()
	near_material.set_shader_parameter("detailed_mesh",true)
	near_water.material_override = near_material; world.add_child(near_water)
	for island in game.model.chart.land: make_land(island)
	player = make_ship(Color("b48b57"),Color("eee0b8"),true); world.add_child(player)
	for entry in game.model.chart.places:
		var actor: Node3D
		if entry.kind in ["hostile","boss","merchant","fisher"]:
			actor = make_ship(Color("70513d") if entry.kind in ["hostile","boss"] else Color("a78b63"),Color("594744") if entry.kind in ["hostile","boss"] else Color("d2cbb1"))
			if entry.kind=="boss": actor.scale = Vector3.ONE*1.45
		else: actor = make_place(entry)
		world.add_child(actor); actors[entry.id] = actor
	for sign_info in game.model.chart.get("signals",[]):
		var sign_root := Node3D.new(); var at: Vector2 = game.model.point(sign_info.pos)
		sign_root.position = Vector3(at.x,0,at.y); world.add_child(sign_root); signals[sign_info.id] = sign_root
		var target: Vector2 = game.model.point(game.model.place(sign_info.leads_to).pos)
		sign_root.rotation.y = -(target-at).angle()
		for i in (7 if sign_info.kind=="birds" else 10):
			if sign_info.kind=="birds":
				var bird := Node3D.new(); bird.position = Vector3(i*37,75+sin(i*2.1)*17,sin(i*3.1)*90); sign_root.add_child(bird)
				rod(bird,Vector3(0,0,0),Vector3(-3,2,-8),0.8,Color("e6e3cc"))
				rod(bird,Vector3(0,0,0),Vector3(-3,2,8),0.8,Color("e6e3cc"))
			elif sign_info.kind=="drift": box(sign_root,Vector3(i*45-180,0,sin(i*2.7)*46),Vector3(15+i%3*5,3,3),Color("a39068"))
			else: box(sign_root,Vector3(i*40-180,-0.5,sin(i*1.3)*74),Vector3(27,0.2,2),Color("75a4a3"))
	wake_material = ShaderMaterial.new(); wake_material.shader = load("res://assets/shaders/navigation_wake.gdshader")
	for i in 3:
		var foam := MeshInstance3D.new(); foam.mesh = ArrayMesh.new()
		foam.material_override = wake_material; foam.visible = false
		world.add_child(foam); wake.append(foam)
	for i in 24:
		var drop := MeshInstance3D.new(); var sphere := SphereMesh.new()
		sphere.radius = 0.7; sphere.height = 1.4; sphere.radial_segments = 6; sphere.rings = 3
		drop.mesh = sphere; drop.material_override = material(Color("c0ddd2"),true)
		drop.visible = false; world.add_child(drop)
		spray.append({"node":drop,"origin":Vector3.ZERO,"velocity":Vector3.ZERO,"start":-10.0,"duration":0.8})
	camera = Camera3D.new(); camera.fov = 67; camera.near = 2; camera.far = 65000
	world.add_child(camera); camera.current = true
	update_view(0,true)

func material(color: Color,unlit: bool = false) -> StandardMaterial3D:
	var key := str(color)+str(unlit)
	if not materials.has(key):
		var m := StandardMaterial3D.new(); m.albedo_color = color; m.roughness = 0.85
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		if color.a<1: m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		if unlit: m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		materials[key] = m
	return materials[key]
func box(parent: Node3D,at: Vector3,dimensions: Vector3,color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new(); var mesh := BoxMesh.new(); mesh.size = dimensions
	node.mesh = mesh; node.position = at; node.material_override = material(color); parent.add_child(node); return node
func rod(parent: Node3D,a: Vector3,b: Vector3,width: float,color: Color) -> void:
	var node := box(parent,(a+b)*0.5,Vector3(width,a.distance_to(b),width),color)
	if absf((b-a).normalized().dot(Vector3.UP))<0.999: node.look_at_from_position((a+b)*0.5,b,Vector3.UP); node.rotate_object_local(Vector3.RIGHT,PI*0.5)
func surface(parent: Node3D,vertices: PackedVector3Array,color: Color) -> MeshInstance3D:
	var mesh := ArrayMesh.new(); var arrays := []; arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var normals := PackedVector3Array()
	for i in range(0,vertices.size(),3):
		var normal := (vertices[i+1]-vertices[i]).cross(vertices[i+2]-vertices[i]).normalized()
		for j in 3: normals.append(normal)
	arrays[Mesh.ARRAY_NORMAL] = normals; mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var node := MeshInstance3D.new(); node.mesh = mesh; node.material_override = material(color)
	parent.add_child(node); return node
func make_ship(wood: Color,cloth: Color,is_player: bool = false) -> Node3D:
	var ship := Node3D.new()
	var outline := PackedVector2Array([Vector2(-48,-15),Vector2(-24,-22),Vector2(12,-21),Vector2(40,-12),Vector2(62,0),Vector2(40,12),Vector2(12,21),Vector2(-24,22),Vector2(-48,15)])
	var triangles := Geometry2D.triangulate_polygon(outline); var deck := PackedVector3Array(); var sides := PackedVector3Array()
	for index in triangles: deck.append(Vector3(outline[index].x,12,outline[index].y))
	for i in outline.size():
		var a := Vector3(outline[i].x,12,outline[i].y); var next := outline[(i+1)%outline.size()]
		var b := Vector3(next.x,12,next.y); var c := Vector3(b.x*0.82,-6,b.z*0.32); var d := Vector3(a.x*0.82,-6,a.z*0.32)
		sides.append_array(PackedVector3Array([a,b,c,a,c,d]))
	surface(ship,deck,Color("c4a373")); surface(ship,sides,wood)
	box(ship,Vector3(-34,20,0),Vector3(25,16,31),wood)
	box(ship,Vector3(-34,29,0),Vector3(28,3,34),Color("c4a373"))
	for z in [-10,0,10]: box(ship,Vector3(-47,22,z),Vector3(0.6,7,5),Color("394d4a"))
	box(ship,Vector3(-47.5,17,0),Vector3(1,2,29),Color("d6b879"))
	for z in [-1,1]:
		rod(ship,Vector3(-42,6,z*17),Vector3(20,6,z*18),1.4,Color("d6b879"))
	for i in outline.size():
		var a := outline[i]; var b := outline[(i+1)%outline.size()]
		rod(ship,Vector3(a.x,16,a.y),Vector3(b.x,16,b.y),2,Color("5b4834"))
	for x in [-20,13,38]:
		var height := 99.0 if x==13 else (84.0 if x==-20 else 66.0)
		rod(ship,Vector3(x,12,0),Vector3(x,height,0),2.4,Color("5b4834"))
		var half_span := 29.0 if x!=38 else 20.0
		rod(ship,Vector3(x,height-6,-half_span),Vector3(x,height-6,half_span),2,Color("685039"))
		var sail := Node3D.new(); ship.add_child(sail); sail.position = Vector3(x,0,0)
		var vertices := PackedVector3Array()
		for j in 6:
			var z1 := lerpf(-half_span,half_span,j/6.0); var z2 := lerpf(-half_span,half_span,(j+1)/6.0)
			var a := Vector3(0,height-8,z1); var b := Vector3(0,height-8,z2)
			var c := Vector3(10+cos(z2/half_span*PI*0.5)*5,height*0.43+absf(z2)*0.16,z2*0.85)
			var d := Vector3(10+cos(z1/half_span*PI*0.5)*5,height*0.43+absf(z1)*0.16,z1*0.85)
			vertices.append_array(PackedVector3Array([a,b,c,a,c,d]))
		surface(sail,vertices,cloth)
		if is_player and x==13:
			box(sail,Vector3(-0.6,68,0),Vector3(0.7,24,4),Color("a65341"))
			box(sail,Vector3(-0.7,71,0),Vector3(0.7,5,19),Color("a65341"))
		if is_player: sail_panels.append(sail)
		rod(ship,Vector3(x,height-5,0),Vector3(-43,15,-15),0.55,Color("5d5847"))
		rod(ship,Vector3(x,height-5,0),Vector3(-43,15,15),0.55,Color("5d5847"))
	rod(ship,Vector3(39,13,0),Vector3(83,26,0),2,Color("624a30"))
	surface(ship,PackedVector3Array([Vector3(13,100,0),Vector3(-9,97,3),Vector3(13,92,0)]),Color("a65340"))
	for z in [-1,1]:
		for x in [-10,4,20]: box(ship,Vector3(x,12,z*22),Vector3(5,4,7),Color("303b39"))
	return ship
func make_land(island: Dictionary) -> void:
	var points := PackedVector2Array(); var middle := Vector2.ZERO
	for p in island.points: var v: Vector2 = game.model.point(p); points.append(v); middle += v
	middle /= points.size()
	var base := PackedVector3Array(); var triangles := Geometry2D.triangulate_polygon(points)
	for index in triangles: base.append(Vector3(points[index].x,5,points[index].y))
	surface(world,base,Color("b9b38c"))
	# Concentric faceted slopes keep the real collision coastline and readable silhouettes.
	var rings := [0.0,0.07,0.23,0.48,0.77]
	var heights := [5.0,14.0,100.0,230.0,310.0] if island.name=="Madeira" else [5.0,10.0,65.0,125.0,170.0]
	for ring in range(rings.size()-1):
		var vertices := PackedVector3Array()
		for i in points.size():
			var j := (i+1)%points.size(); var a := points[i].lerp(middle,rings[ring]); var b := points[j].lerp(middle,rings[ring])
			var c := points[j].lerp(middle,rings[ring+1]); var d := points[i].lerp(middle,rings[ring+1])
			vertices.append_array(PackedVector3Array([Vector3(a.x,heights[ring],a.y),Vector3(b.x,heights[ring],b.y),Vector3(c.x,heights[ring+1],c.y),Vector3(a.x,heights[ring],a.y),Vector3(c.x,heights[ring+1],c.y),Vector3(d.x,heights[ring+1],d.y)]))
		surface(world,vertices,Color("b0ac85") if ring==0 else (Color("6b8967") if island.name in ["Portugal","Madeira"] else Color("9b9877")))
	var cap := PackedVector3Array()
	for index in triangles:
		var at := points[index].lerp(middle,rings[-1]); cap.append(Vector3(at.x,heights[-1],at.y))
	surface(world,cap,Color("6c8164"))
func make_place(entry: Dictionary) -> Node3D:
	var root := Node3D.new()
	match entry.kind:
		"port","island":
			var at: Vector2 = game.model.point(entry.pos); var coast := Vector2.ZERO; var best := INF
			for polygon in game.model.land_polygons:
				for i in polygon.size():
					var point := Geometry2D.get_closest_point_to_segment(at,polygon[i],polygon[(i+1)%polygon.size()])
					if at.distance_to(point)<best: coast = point; best = at.distance_to(point)
			root.rotation.y = -(coast-at).angle()
			box(root,Vector3(best*0.5,5,20),Vector3(best+30,8,22),Color("91734f"))
			for x in range(0,int(best)+30,35): box(root,Vector3(x,-1,20),Vector3(3,19,25),Color("66553e"))
			if entry.kind=="port":
				for i in 5:
					box(root,Vector3(best+35+i*32,24,65+i%2*43),Vector3(28,35+i%3*8,29),Color("d8c7a0"))
					box(root,Vector3(best+35+i*32,46+i%3*4,65+i%2*43),Vector3(33,9,34),Color("a37558"))
		"landmark":
			for i in 4: box(root,Vector3(i*18-30,1,0),Vector3(12,4,23),Color("8ba7a1"))
		"rescue":
			box(root,Vector3.ZERO,Vector3(40,3,15),Color("a78b63")); box(root,Vector3(0,6,0),Vector3(8,12,7),Color("bd9b72"))
		_:
			for i in 5: box(root,Vector3(i*13-28,2,sin(i*2.1)*15),Vector3(12,9,10),Color("a78b63"))
	return root
func update_view(delta: float,snap: bool = false) -> void:
	if camera==null: return
	var m = game.model
	visible = m.phase in ["sea","game_over"]
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if visible else SubViewport.UPDATE_DISABLED
	if not visible: camera_ready = false; return
	size = game.get_viewport_rect().size
	var jumped: bool = last_position.distance_to(m.position)>900 or m.elapsed<last_sea_time
	last_sea_time = m.elapsed
	if snap or jumped or not camera_ready:
		camera_heading = m.heading; camera_ready = true; trail.clear()
		last_crest = Sea.crest(m.position+Vector2.from_angle(m.heading)*52,m.elapsed)
		last_impact_time = m.elapsed-10
		impact_strength = 0
		for particle in spray: particle.start = -10.0
	else: camera_heading = lerp_angle(camera_heading,m.heading,1-exp(-delta*5.0))
	last_position = m.position
	var ship_at := Vector3(m.position.x,0,m.position.y)
	var risk := clampf(maxf(m.risk_at(m.position)*0.6,m.danger/100),0,1)
	var angles := Sea.slope(m.position,m.elapsed,m.heading,risk)
	player.position = ship_at+Vector3(0,Sea.height(m.position,m.elapsed,risk)*0.8,0)
	# Local X is the bow. Apply pitch/roll after yaw; camera stays level.
	player.basis = Basis(Vector3.UP,-m.heading)*Basis(Vector3.BACK,angles.x)*Basis(Vector3.RIGHT,-angles.y)
	var forward := Vector3(cos(camera_heading),0,sin(camera_heading))
	camera.position = ship_at-forward*330+Vector3(0,160,0)
	camera.look_at(ship_at+forward*255+Vector3(0,18,0))
	for i in sail_panels.size():
		# Furled canvas at anchor, half canvas for manoeuvring, all sails at speed.
		sail_panels[i].scale.y = [0.22,0.55,0.83,1.0][game.sail_level]
		# Keep the yard attached to the mast when furling.
		sail_panels[i].position.y = (1-sail_panels[i].scale.y)*([84.0,99.0,66.0][i]-8)
	for id in actors:
		var entry: Dictionary = m.place(id); var actor: Node3D = actors[id]
		var at: Vector2 = m.place_position(entry)
		actor.position = Vector3(at.x,0,at.y)
		actor.visible = not m.resolved.has(id) or entry.kind in ["port","island","landmark"]
		if entry.kind in ["hostile","boss","merchant","fisher"]:
			actor.rotation.y = -(at.direction_to(m.position).angle() if entry.kind in ["hostile","boss"] else 2.4)
			actor.position.y = Sea.height(at,m.elapsed,risk)*0.65
		elif entry.kind in ["wreck","rescue"]: actor.position.y = Sea.height(at,m.elapsed,risk)*0.85
	for sign_info in m.chart.get("signals",[]):
		var group: Node3D = signals[sign_info.id]
		group.visible = not m.resolved.has(sign_info.leads_to)
		if sign_info.kind=="birds":
			for i in group.get_child_count():
				var bird := group.get_child(i) as Node3D
				bird.position.x = fmod(m.elapsed*14+i*44,310)
				bird.position.y = 75+sin(m.elapsed*0.7+i)*12
				bird.rotation.x = sin(m.elapsed*4+i)*0.18
	if delta>0:
		Wake.append_sample(trail,m.position,m.heading,m.elapsed,m.velocity.length())
		var crest := Sea.crest(m.position+Vector2.from_angle(m.heading)*52,m.elapsed)
		if crest>0.72 and last_crest<=0.72 and m.elapsed-last_impact_time>1.5:
			last_impact_time = m.elapsed
			bow_impact(clampf(0.18+m.velocity.length()/150.0+risk*0.25,0,1))
		last_crest = crest
	var ribbons := Wake.ribbons(trail,m.elapsed,risk)
	for i in wake.size():
		wake[i].mesh = ribbons[i]; wake[i].visible = ribbons[i].get_surface_count()>0
	wake_material.set_shader_parameter("sea_time",m.elapsed)
	for particle in spray:
		var age: float = m.elapsed-float(particle.start); var drop: MeshInstance3D = particle.node
		drop.visible = age>=0 and age<float(particle.duration)
		if drop.visible:
			drop.position = particle.origin+particle.velocity*age+Vector3.DOWN*18*age*age
			drop.scale = Vector3.ONE*(1-age/float(particle.duration))*1.35
			drop.visible = drop.position.y>Sea.height(Vector2(drop.position.x,drop.position.z),m.elapsed,risk)-1.8
	var center: Vector2 = (m.position/128.0).floor()*128.0
	near_water.position = Vector3(center.x,-2,center.y)
	for shader in [water_material,near_material]:
		shader.set_shader_parameter("sea_time",m.elapsed); shader.set_shader_parameter("roughness",risk)
		shader.set_shader_parameter("patch_center",center)
		shader.set_shader_parameter("ship_position",m.position)
		shader.set_shader_parameter("ship_forward",Vector2.from_angle(m.heading))
		shader.set_shader_parameter("ship_speed",clampf(m.velocity.length()/90,0,1))
		shader.set_shader_parameter("hull_impact",impact_strength*maxf(0,1-(m.elapsed-last_impact_time)/0.9))
func bow_impact(strength: float) -> void:
	var m = game.model; var forward := Vector2.from_angle(m.heading); var right := forward.orthogonal()
	splash_serial += 1
	impact_strength = strength; last_impact_time = m.elapsed
	if game.ambience!=null: game.ambience.wave_hit(strength,splash_serial%2)
	if strength<0.3: return
	for i in spray.size():
		var side := -1 if i%2==0 else 1
		var at: Vector2 = m.position+forward*(42+sin(i*2.1)*8)+right*side*23
		spray[i].origin = Vector3(at.x,player.position.y+1,at.y)
		var push := right*side*(8+i%5*2)*strength+forward*(4+i%3*2)
		spray[i].velocity = Vector3(push.x,(14+i%7*1.8)*strength,push.y)
		spray[i].start = m.elapsed+i%4*0.025; spray[i].duration = 0.65+i%5*0.06
func screen_point(at: Vector2) -> Vector2:
	var p := Vector3(at.x,3,at.y)
	if camera.is_position_behind(p): return Vector2(-10000,-10000)
	return camera.unproject_position(p)
func sea_point(screen: Vector2) -> Vector2:
	var ray := camera.project_ray_normal(screen); var origin := camera.project_ray_origin(screen)
	if ray.y>=-0.015: return Vector2(-1,-1)
	var at := origin+ray*(-origin.y/ray.y)
	return Vector2(at.x,at.z)
func relative_direction(at: Vector2) -> Vector2:
	var relative: Vector2 = (at-game.model.position).rotated(-camera_heading)
	return Vector2(relative.y,-relative.x).normalized()
