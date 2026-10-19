extends Node2D
const Plan = preload("res://scripts/city/forest_plan.gd")
const City = preload("res://scripts/city/lisbon_scenery.gd")
const Materials = preload("res://scripts/city/place_materials.gd")
const OAK := "res://assets/art/forest/cork-oak-v1.png"
const UNDERGROWTH := "res://assets/art/forest/undergrowth-v1.png"
var world
static var soil: CanvasTexture
static var water: CanvasTexture
static var timber: CanvasTexture
static func grain_texture(wood: bool) -> CanvasTexture:
	if wood and timber!=null: return timber
	if not wood and water!=null: return water
	var noise := FastNoiseLite.new(); noise.seed = 518 if wood else 817
	noise.frequency = .045 if wood else .022; noise.fractal_octaves = 3
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color("796044"),Color("b29a70")]) if wood else PackedColorArray([Color("3e665e"),Color("719287")])
	var source := NoiseTexture2D.new(); source.width = 256; source.height = 256
	source.noise = noise; source.color_ramp = gradient; source.seamless = true; source.generate_mipmaps = true
	var result := CanvasTexture.new(); result.diffuse_texture = source
	result.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED; result.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if wood: timber = result
	else: water = result
	return result

func river_bank(bank: PackedVector2Array,left: bool) -> void:
	var outer := PackedVector2Array(); var shore := PackedVector2Array()
	for i in bank.size():
		var at := bank[i]
		var margin := Vector2((-1 if left else 1)*(12+4*sin(at.y*.037)),0)
		outer.append(at+margin); shore.append(at)
	for i in bank.size()-1:
		soil_polygon(PackedVector2Array([shore[i],shore[i+1],outer[i+1],outer[i]]),PackedColorArray([Color(.65,.7,.52,.9),Color(.65,.7,.52,.9),Color(1,1,1,0),Color(1,1,1,0)]))
	draw_polyline(bank,Color(.18,.29,.23,.42),3,true)

func bridge_deck() -> void:
	# Footprint and rail heights stay aligned with the existing playable crossing.
	draw_rect(Rect2(1360,798,200,12),Color("493c2c"))
	draw_set_transform(Vector2(1460,812),0,Vector2(1,.25))
	for ring in range(5,0,-1): draw_circle(Vector2.ZERO,95+ring*5,Color(0,0,0,.025))
	draw_set_transform(Vector2.ZERO)
	draw_rect(Plan.BRIDGE,Color("594d38"))
	for n in 12:
		var x := 1360+n*(200.0/12)
		var board := PackedVector2Array([Vector2(x+1,642),Vector2(x+16,642),Vector2(x+16,798),Vector2(x+1,798)])
		var uv := PackedVector2Array()
		for at in board: uv.append(at/Vector2(36,310))
		var light := .93+.07*sin(n*4.7)
		draw_polygon(board,PackedColorArray([Color(light,light,light)]),uv,grain_texture(true))
		draw_line(Vector2(x+1,644),Vector2(x+1,796),Color(.88,.78,.57,.45),1,true)
		for y in [652,788]: draw_circle(Vector2(x+8,y),1.4,Color("4a4435"))
	for y in [642]:
		draw_line(Vector2(1350,y),Vector2(1570,y),Color("5e4d36"),6,true)
		draw_line(Vector2(1350,y-2),Vector2(1570,y-2),Color("af9870"),2,true)
		for x in [1360,1550]:
			draw_line(Vector2(x,y),Vector2(x,y-25),Color("70583d"),7,true)
			draw_circle(Vector2(x,y-26),4,Color("b4a17a"))
static func soil_texture() -> CanvasTexture:
	if soil!=null: return soil
	var noise := FastNoiseLite.new(); noise.seed = 518; noise.frequency = .035; noise.fractal_octaves = 4
	var gradient := Gradient.new(); gradient.colors = PackedColorArray([Color("92805c"),Color("aa9872")])
	var texture := NoiseTexture2D.new(); texture.width = 256; texture.height = 256; texture.noise = noise; texture.color_ramp = gradient; texture.seamless = true
	soil = CanvasTexture.new(); soil.diffuse_texture = texture; soil.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED; soil.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return soil
func soil_polygon(points: PackedVector2Array,colors: PackedColorArray) -> void:
	var uv := PackedVector2Array()
	for point in points: uv.append(point/Vector2(190,145))
	draw_polygon(points,colors,uv,soil_texture())
func soil_patch(at: Vector2,radius: Vector2) -> void:
	var inner := PackedVector2Array(); var outer := PackedVector2Array()
	for i in 33:
		var angle := i*TAU/32; var direction := Vector2(cos(angle),sin(angle))
		inner.append(at+direction*radius*.65); outer.append(at+direction*radius*(1+.06*sin(angle*5)))
	soil_polygon(inner,PackedColorArray([Color.WHITE]))
	for i in 32: soil_polygon(PackedVector2Array([inner[i],inner[i+1],outer[i+1],outer[i]]),PackedColorArray([Color.WHITE,Color.WHITE,Color(1,1,1,0),Color(1,1,1,0)]))
static func smooth_path(points: Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for i in points.size()-1:
		var a: Vector2 = points[maxi(0,i-1)]; var b: Vector2 = points[i]; var c: Vector2 = points[i+1]; var d: Vector2 = points[mini(points.size()-1,i+2)]
		for j in 12:
			var t := float(j)/12
			result.append(.5*((2*b)+(-a+c)*t+(2*a-5*b+4*c-d)*t*t+(-a+3*b-3*c+d)*t*t*t))
	result.append(points[-1]); return result
func trail(points: Array,width: float) -> void:
	var path := smooth_path(points)
	for end in [path[0],path[-1]]: soil_patch(end,Vector2(width,width*.75))
	var inner_left := PackedVector2Array(); var inner_right := PackedVector2Array(); var outer_left := PackedVector2Array(); var outer_right := PackedVector2Array()
	for i in path.size():
		var normal := (path[mini(i+1,path.size()-1)]-path[maxi(0,i-1)]).normalized().orthogonal()
		var radius := width*(1+.10*sin(i*.21))
		inner_left.append(path[i]+normal*radius*.63); inner_right.append(path[i]-normal*radius*.63)
		outer_left.append(path[i]+normal*radius); outer_right.append(path[i]-normal*radius)
	for i in path.size()-1:
		for side in [-1,1]:
			var inner: PackedVector2Array = inner_left if side==1 else inner_right
			var outer: PackedVector2Array = outer_left if side==1 else outer_right
			var fade := PackedVector2Array([inner[i],inner[i+1],outer[i+1],outer[i]])
			soil_polygon(fade,PackedColorArray([Color.WHITE,Color.WHITE,Color(1,1,1,0),Color(1,1,1,0)]))
		var core := PackedVector2Array([inner_right[i],inner_right[i+1],inner_left[i+1],inner_left[i]])
		soil_polygon(core,PackedColorArray([Color.WHITE]))
static func install(map: Node2D) -> void:
	var floor := Node2D.new(); floor.set_script(load("res://scripts/city/forest_scenery.gd")); floor.name = "ForestGround"; floor.world = map; floor.z_index = -4; map.add_child(floor)
	var life := preload("res://scripts/city/forest_life.gd").new(); life.world = map; life.z_index = -3; map.add_child(life)
	var rng := RandomNumberGenerator.new(); rng.seed = 51803
	# A wooded perimeter makes the playable clearing boundary visible.
	for edge in Plan.LAND.size():
		var a: Vector2 = Plan.LAND[edge]; var b: Vector2 = Plan.LAND[(edge+1)%Plan.LAND.size()]
		var count := maxi(1,int(a.distance_to(b)/110))
		for n in count:
			var at := a.lerp(b,float(n)/count)
			at += (at-Vector2(1450,850)).normalized()*60
			City.prop(map,"LimiteDoBosque",OAK if at.x>1750 else "bruma-v2-tree.png",at,Vector2(230,275)*rng.randf_range(.9,1.2))
	for i in 85:
		var at := Vector2(rng.randf_range(-150,3000),rng.randf_range(50,1550))
		var near_path := false
		if Plan.distance_to_trails(at)<100: near_path = true
		for place in Plan.DISCOVERIES.values():
			if at.distance_to(place.at)<100: near_path = true
		if near_path or Plan.RIVER.grow(100).has_point(at): continue
		City.prop(map,"ArvoreDoBosque",OAK if at.x>1650 else "bruma-v2-tree.png",at,Vector2(205,240)*rng.randf_range(.85,1.3),Rect2(-13,-10,26,20))
	# Layered low vegetation frames paths instead of covering their centre.
	for i in 130:
		var at := Vector2(rng.randf_range(30,2800),rng.randf_range(150,1480))
		if not Plan.contains(at) or Plan.distance_to_trails(at)<65: continue
		var near_discovery := false
		for place in Plan.DISCOVERIES.values():
			if at.distance_to(place.at)<62: near_discovery = true
		if near_discovery: continue
		City.prop(map,"VegetacaoDoBosque",UNDERGROWTH,at,Vector2(100,52)*rng.randf_range(.65,1.2))
	for i in 24:
		var y := rng.randf_range(200,1450)
		if y>580 and y<870: continue
		var left := rng.randf()<.5
		var bank := preload("res://scripts/city/forest_life.gd").bank_at(y,left)
		City.prop(map,"VegetacaoDaMargem",UNDERGROWTH,bank+Vector2(-38 if left else 38,10),Vector2(84,42)*rng.randf_range(.8,1.3))
	City.prop(map,"RaizesDoAbrigo",OAK,Vector2(674,483),Vector2(215,255),Rect2(-13,-10,26,20))
	var rail := preload("res://scripts/city/forest_bridge_rail.gd").new(); rail.position = Vector2(1460,798); map.sorted_world.add_child(rail)
	City.body(rail,PackedVector2Array([Vector2(-104,-4),Vector2(104,-4),Vector2(104,4),Vector2(-104,4)]))
	var landmarks := preload("res://scripts/city/forest_landmarks.gd").new(); landmarks.z_index = -2; map.add_child(landmarks)
func _draw() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	var back := PackedVector2Array([Vector2(-1800,-1500),Vector2(4800,-1500),Vector2(4800,3000),Vector2(-1800,3000)])
	var uv := PackedVector2Array()
	for p in back: uv.append(p/Vector2(260,195))
	draw_polygon(back,PackedColorArray([Materials.GRASS_TINT]),uv,City.texture("bruma-grass-refined.png",false))
	for id in Plan.DISCOVERIES: trail(Plan.discovery_path(id),24)
	trail(Plan.TRAIL,43)
	soil_patch(Vector2(2280,1100),Vector2(140,98)); soil_patch(Vector2(2350,350),Vector2(95,70))
	if is_instance_valid(world):
		for item in world.sorted_world.get_children():
			if not str(item.name).begins_with("ArvoreDoBosque") and not str(item.name).begins_with("RaizesDoAbrigo"): continue
			draw_set_transform(item.position+Vector2(26,15),.18,Vector2(1,.43))
			for ring in range(6,0,-1): draw_circle(Vector2.ZERO,48+ring*7,Color(.07,.14,.08,.025))
			draw_set_transform(Vector2.ZERO)
	var left_bank := smooth_path(Plan.WATER.slice(0,8)); var right_bank := smooth_path(Plan.WATER.slice(8,16))
	var river := left_bank.duplicate(); river.append_array(right_bank)
	var river_colors := PackedColorArray()
	var water_uv := PackedVector2Array()
	for i in river.size():
		river_colors.append(Color("c0cbb2") if i<left_bank.size() else Color("e0e3c9"))
		water_uv.append(river[i]/Vector2(170,300))
	draw_polygon(river,river_colors,water_uv,grain_texture(false))
	river_bank(left_bank,true); river_bank(right_bank,false)
	bridge_deck()
	# Clues are visible in the landscape before their interaction marker appears.
	for n in 7:
		var at := Vector2(560+n*12,1040-n*6)
		draw_set_transform(at,-.3,Vector2(1,.6)); draw_circle(Vector2(-3,0),2.5,Color("655942")); draw_circle(Vector2(3,0),2.5,Color("655942")); draw_set_transform(Vector2.ZERO)
	draw_line(Vector2(982,700),Vector2(1012,693),Color("776344"),5,true)
	draw_line(Vector2(1000,698),Vector2(1008,681),Color("bcb08a"),3,true)
	for n in 16:
		var angle := n*TAU/16
		var at := Vector2(1090,1290)+Vector2(cos(angle)*55,sin(angle)*30)
		draw_circle(at,8,Color("5d5d4c")); draw_circle(at-Vector2(1,2),5,Color("96947a"))
	draw_set_transform(Vector2(1090,1290),0,Vector2(1,.5)); draw_circle(Vector2.ZERO,42,Color("4b4c3b")); draw_set_transform(Vector2.ZERO)
	for n in 5:
		var at := Vector2(1870+n*15,1190+n*8)
		draw_set_transform(at,0,Vector2(1,.65)); draw_circle(Vector2.ZERO,6,Color("655942")); draw_set_transform(Vector2.ZERO)
	Materials.sign(self,Vector2(105,875),"Lisboa",false)
