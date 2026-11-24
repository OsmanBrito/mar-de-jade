@tool
extends Node2D
const Layout = preload("res://scripts/city/lisbon_layout.gd")
const Ferro = preload("res://scripts/city/ferro_lisbon.gd")
const Prop = preload("res://scripts/city/lisbon_prop.gd")
const ROOT := "res://assets/art/ferro-lisbon/"
const Materials = preload("res://scripts/city/place_materials.gd")
const Ground = preload("res://scripts/city/lisbon_ground.gd")
static var art: Dictionary = {}
var world
var paving_aprons: Array[PackedVector2Array] = []
func _ready() -> void:
	for surface in [Layout.paving_surface()]+Layout.streets(): paving_aprons.append(surface)
static func texture(file: String,crop: bool = true) -> Texture2D:
	var key := file+str(crop)
	if art.has(key): return art[key]
	var original: Texture2D = load(file if file.begins_with("res://") else ROOT+file)
	var image := original.get_image()
	var bounds := image.get_used_rect()
	if crop:
		var low := image.get_size(); var high := Vector2i.ZERO
		for x in range(0,image.get_width(),4):
			for y in range(0,image.get_height(),4):
				if image.get_pixel(x,y).a>.2:
					low = Vector2i(mini(low.x,x),mini(low.y,y)); high = Vector2i(maxi(high.x,x),maxi(high.y,y))
		bounds = Rect2i(low,high-low+Vector2i.ONE).grow(4).intersection(Rect2i(Vector2i.ZERO,image.get_size()))
	image.fix_alpha_edges(); image.generate_mipmaps()
	var filtered := CanvasTexture.new(); filtered.diffuse_texture = ImageTexture.create_from_image(image)
	filtered.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if file in ["bruma-paving-refined.png","bruma-grass-refined.png"]: filtered.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	if crop:
		var atlas := AtlasTexture.new(); atlas.atlas = filtered; atlas.region = bounds; atlas.filter_clip = true; art[key] = atlas
	else: art[key] = filtered
	return art[key]

static func body(parent: Node2D,polygon: PackedVector2Array) -> void:
	var physical := StaticBody2D.new(); physical.collision_mask = 0; parent.add_child(physical)
	var shape := CollisionPolygon2D.new(); shape.polygon = polygon; physical.add_child(shape)

static func prop(map: Node2D,name: String,file: String,at: Vector2,box: Vector2,solid: Rect2 = Rect2()) -> Node2D:
	var piece := Prop.new(); piece.name = name; piece.world = map; piece.position = at; piece.texture = texture(file)
	var native := piece.texture.get_size(); piece.size = native*minf(box.x/native.x,box.y/native.y)
	map.sorted_world.add_child(piece)
	# Contact stays under the artwork and uses its actual base, without changing
	# the illustrated proportions or the collision used by walking routes.
	if not name.begins_with("Batel"):
		var shadow := preload("res://scripts/chapter/contact_shadow.gd").new()
		shadow.footprint = Vector2(minf(piece.size.x*.35,solid.size.x*.6) if solid.size.x>0 else piece.size.x*.22,minf(15,piece.size.y*.055))
		shadow.center = Vector2(0,-3); shadow.show_behind_parent = true
		piece.add_child(shadow)
	if solid.size!=Vector2.ZERO:
		body(piece,PackedVector2Array([solid.position,solid.position+Vector2(solid.size.x,0),solid.end,solid.position+Vector2(0,solid.size.y)]))
	return piece

static func install(map: Node2D) -> void:
	if map.has_node("FerroRibeira"): return
	var floor := Node2D.new(); floor.name = "FerroRibeira"; floor.set_script(load("res://scripts/city/lisbon_scenery.gd")); floor.world = map; floor.z_index = -4
	map.add_child(floor)
	var landmarks := preload("res://scripts/city/city_landmarks.gd").new(); landmarks.name="StreetLandmarks";map.sorted_world.add_child(landmarks)
	var finish := preload("res://scripts/city/lisbon_finish.gd").new(); finish.name = "WorkingGround"; finish.z_index = -3; map.add_child(finish)
	# Irregular groups frame the streets; a repeated row made the district look
	# like a board with scenery pasted around its perimeter.
	for at in [Vector2(-1210,-300),Vector2(-1330,80),Vector2(-1180,470),Vector2(-1030,960),Vector2(1840,190),Vector2(1820,740),Vector2(1850,1060)]:
		prop(map,"OlivalDoLimite","bruma-v2-tree.png",at,Vector2(210,250)*(1.0+sin(at.x*.07)*.14))
	var river := Sprite2D.new(); river.name = "Shoreline"; river.texture = texture("lisbon-ground-refined-v3.png",false); river.centered = false
	river.position = Layout.OFFSET; river.scale = Vector2.ONE*(Ferro.SIZE.x*Layout.SCALE/river.texture.get_width())
	var material := ShaderMaterial.new(); var shader := Shader.new()
	# Keep only the retaining stones and water from the source painting. Its baked
	# cobbles used to dissolve over a second, incompatible paving underneath.
	shader.code = "shader_type canvas_item; void fragment(){float wet=smoothstep(.68,.77,UV.y);vec2 uv=UV;uv.x+=sin(UV.y*130.0+TIME*.8)*.0007*wet;uv.y+=sin(UV.x*190.0+TIME*.65)*.0004*wet;vec4 p=texture(TEXTURE,uv);p.rgb+=sin(UV.x*270.0+UV.y*120.0+TIME*.9)*.012*wet;COLOR=vec4(p.rgb,p.a*smoothstep(.635,.650,UV.y));}"
	material.shader = shader; river.material = material; floor.add_child(river)
	# The river continues beyond the playable district, rather than ending in a
	# rectangular grass cut beside each pier. Mirror the adjoining shore segments.
	for side in [-1,1]:
		var extension := Sprite2D.new(); extension.name = "ShoreContinuation"+str(side)
		extension.texture = river.texture; extension.centered = false
		extension.scale = river.scale; extension.material = material; extension.flip_h = true
		extension.position = Layout.OFFSET+Vector2(side*Ferro.SIZE.x*Layout.SCALE,0)
		floor.add_child(extension)
	# A shared, full-resolution floor material is repeated at its own scale.
	for i in Ferro.BUILDINGS.size():
		var area: Rect2 = Ferro.BUILDINGS[i]
		var file: String = "bruma-v2-"+Ferro.BUILDING_KEYS[i]+".png"
		var at: Vector2 = Layout.point(Vector2(area.get_center().x,area.end.y))
		var building := prop(map,"Ferro_"+Ferro.BUILDING_KEYS[i],file,at,Ferro.BUILDING_SIZES[i]*Layout.SCALE,Rect2((area.position-Vector2(area.get_center().x,area.end.y))*Layout.SCALE,area.size*Layout.SCALE))
		building.tint = Color("f1eee5")
	# Preserve source walls in depth slices, opening a readable northern gate.
	for wall in Ferro.COURTYARD_WALLS:
		var whole := texture("lisbon-courtyard-wall-refined-v1.png") as AtlasTexture
		var factor: float = wall.size.x*Layout.SCALE/whole.region.size.x
		var image := whole.atlas.get_image()
		var origin := Layout.point(Vector2(wall.position.x,wall.end.y))-Vector2(0,whole.region.size.y*factor)
		for section in 8:
			var left: float = wall.position.x+wall.size.x*section/8.0
			var right: float = wall.position.x+wall.size.x*(section+1)/8.0
			if right>670 and left<745: continue
			# Integer crop boundaries avoid fractional atlas seams. Each slice keeps
			# the original painting's geometry and sorts at its own visible ground.
			var x0 := int(whole.region.size.x*section/8)
			var x1 := int(whole.region.size.x*(section+1)/8)
			var top := int(whole.region.size.y); var bottom := 0
			for x in range(x0,x1,2):
				for y in range(int(whole.region.size.y)):
					if image.get_pixelv(Vector2i(whole.region.position)+Vector2i(x,y)).a>.2:
						top = mini(top,y); bottom = maxi(bottom,y+1)
			if bottom<=top: continue
			var slice := AtlasTexture.new(); slice.atlas = whole.atlas
			slice.region = Rect2(whole.region.position+Vector2(x0,top),Vector2(x1-x0,bottom-top)); slice.filter_clip = true
			var item := Prop.new(); item.texture = slice; item.world = map
			item.name = "MuroIlustrado_%d_%d" % [int(wall.position.x),section]
			item.size = slice.region.size*factor
			item.position = origin+Vector2((x0+x1)*.5,bottom)*factor
			map.sorted_world.add_child(item)
			body(item,PackedVector2Array([Vector2(-item.size.x/2,-9),Vector2(item.size.x/2,-9),Vector2(item.size.x/2,9),Vector2(-item.size.x/2,9)]))
	prop(map,"Estaleiro","lisbon-shipyard-refined-v1.png",Layout.point(Vector2(123,485)),Vector2(160,90)*Layout.SCALE)
	prop(map,"MadeiraDoEstaleiro","lisbon-timber-refined-v1.png",Layout.point(Vector2(Ferro.TIMBER.get_center().x,Ferro.TIMBER.end.y)),Vector2(170,62)*Layout.SCALE)
	prop(map,"BancaDePeixe","bruma-market.png",Layout.point(Vector2(730,547)),Vector2(115,110)*Layout.SCALE)
	for pile in Ferro.CARGO_PILES:
		# This source cargo cluster becomes Jade's playable accident, with its own art.
		if pile[0].x>780 and pile[0].x<870: continue
		var stack := Node2D.new(); stack.name = "PilhaDeCarga"; stack.position = Layout.point(pile[0]); map.sorted_world.add_child(stack)
		for level in int(pile[1]):
			var crate := prop(map,"Cargo","bruma-crate.png",stack.position,Vector2(31,30)*Layout.SCALE)
			crate.reparent(stack); crate.position = Vector2(0,-22*level*Layout.SCALE)
			crate.fade = false # The column sorts once at its ground foot.
	for item in Ferro.PROPS:
		if item[0]=="cart": continue
		var file: String = "bruma-v2-"+item[0]+".png" if item[0] in ["pots"] else "regional-bench-illustrated-v1.png" if item[0]=="bench" else "bruma-"+item[0]+".png"
		if item[0]=="net_rack": file = "bruma-net-rack-illustrated-v1.png"
		if item[0]=="market_goods": file = "bruma-market-goods-illustrated-v1.png"
		var foot: Vector2 = item[3]*Layout.SCALE
		prop(map,"FerroProp",file,Layout.point(item[1]),item[2]*Layout.SCALE,Rect2(Vector2(-foot.x/2,-foot.y),foot))
	for i in Ferro.DOCK_DRAW.size():
		var dock: Rect2 = Ferro.DOCK_DRAW[i]
		var pier := Sprite2D.new(); pier.texture = texture("bruma-pier-directed-v1.png"); pier.centered = false
		# Match the authored deck height; preserve width instead of squeezing it.
		pier.scale = Vector2.ONE*(dock.size.y*Layout.SCALE/pier.texture.get_height())
		pier.position = Layout.point(dock.position)+Vector2((dock.size.x*Layout.SCALE-pier.texture.get_width()*pier.scale.x)*.5,0)
		pier.name = "Pontao"+str(i); floor.add_child(pier)
		prop(map,"Batel","bruma-boat.png",Layout.point(Vector2(173 if i==0 else 1410,761)),Vector2(125,100)*Layout.SCALE)
	prop(map,"CarroDaOficina","bruma-v2-cart.png",Layout.CART_HOME,Vector2(105,85),Rect2(-35,-16,70,24))
	# Keep the approved Jade residents, now placed at their real workplaces.
	var template = load("res://scenes/maps/cais_vivo.tscn").instantiate()
	var names := {"OficialDaOficina":"workshop","TrabalhadorDoPontao":"dock","Pescadora":"fisher","Vizinha":"neighbor"}
	var positions := Layout.stock_positions()
	for name in names:
		var person = template.get_node("ActorsAndProps/"+name); person.get_parent().remove_child(person)
		person.owner = null
		if name=="Vizinha": person.npc_id = "dock_woman"
		person.position = positions[names[name]]; person.route = PackedVector2Array([person.position]); map.sorted_world.add_child(person)
	template.free()
	# Remove the obsolete pixel-art blockout cargo as well as the old tree proxies.
	for old_tree in ["pine_01","pine_02","Obstacle"]:
		var tree = map.sorted_world.get_node_or_null(old_tree)
		if tree!=null: tree.free()
	var convent := Node2D.new(); convent.name = "PracaDeLisboa"; map.add_child(convent)
	preload("res://scripts/chapter/order_house.gd").install_exterior(map,convent)
	# Pots and independent trees give the convent forecourt volume without rescaling a painting.
	for p in [Vector2(-540,340),Vector2(560,315)]: prop(map,"Oliveira","bruma-v2-tree.png",p,Vector2(210,240),Rect2(-18,-14,36,28))
	for p in [Vector2(-400,130),Vector2(310,130)]: prop(map,"Vasos","bruma-v2-pots.png",p,Vector2(50,60))
	for p in [Vector2(-580,85)]:
		prop(map,"ArvoreDoLimite","bruma-v2-tree.png",p,Vector2(205,245),Rect2(-16,-14,32,28))
	for row in [[Vector2(-945,160),"Acolhimento",true],[Vector2(370,230),"Claustro",false],[Vector2(550,455),"Ribeira",true],[Vector2(-950,405),"Estaleiro",false],[Vector2(1715,895),"Botafogo",true]]:
		var signpost := preload("res://scripts/city/lisbon_sign.gd").new()
		signpost.name = "Placa"+str(row[1]); signpost.position = row[0]; signpost.caption = row[1]; signpost.right = row[2]
		signpost.scale = Vector2.ONE*.78
		map.sorted_world.add_child(signpost)
	map.set_meta("portugal_quay_art",true)
	map.set_meta("continuous_lisbon",true)
	load("res://scripts/city/house_life.gd").install(map)
	load("res://scripts/chapter/lisbon_district.gd").install(map)
	load("res://scripts/city/lisbon_composition.gd").install(map)

func _draw() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	# Gardens and low boundary walls make the limits of the upper town visible.
	draw_rect(Rect2(-2400,-1600,6000,3400),Color("72735a"))
	var grass := PackedVector2Array([Vector2(-2400,-1600),Vector2(3600,-1600),Vector2(3600,1800),Vector2(-2400,1800)])
	var grass_uv := PackedVector2Array()
	for p in grass: grass_uv.append(p/Vector2(470,300))
	draw_polygon(grass,PackedColorArray([Color("828b70")]),grass_uv,texture("bruma-grass-refined.png",false))
	var surface := Layout.paving_surface()
	# A worn verge shares the exact paving UVs; no rectangular texture patches.
	for apron in paving_aprons: Materials.verge(self,apron)
	Ground.surface(self,surface)
	# Opaque pieces use the exact same global UVs and tint at their junctions.
	# Keeping the loops separate preserves the gardens enclosed by the streets.
	for street in Layout.streets(): Ground.surface(self,street)
	Ground.edging(self,paving_aprons)
	# The descending processional path points to the real opening in Ferro's wall.
	# The descent is already part of the joined floor; drawing it twice darkened
	# the material at the gate and produced another visible seam.
	for edge in [[Vector2(-1100,-100),Vector2(-1050,290)],[Vector2(-1050,290),Vector2(-925,343)],[Vector2(-794,398),Vector2(-505,520)]]:
		Materials.wall(self,edge[0],edge[1],27)
	# Entrances use the illustrated stone steps and contextual interaction cue.
	# No detached floor bars or plaques are painted in front of the door.
	# Preserve the source's working ropewalk rather than turning it into a barrier.
	for y in [402,414,426]:
		var rope := PackedVector2Array()
		for i in 25: rope.append(Layout.point(Vector2(392+i*210.0/24,y+i/24.0*6+sin(i/24.0*PI)*5)))
		draw_polyline(rope,Color("9c8054"),2,true)
	if is_instance_valid(world) and world.childhood:
		for gate in [[Vector2(-925,343),Vector2(-794,398)],[Vector2(648,294),Vector2(615,360)]]:
			draw_line(gate[0]-Vector2(0,22),gate[1]-Vector2(0,22),Color("a3895b"),5,true)
			for step in 6:
				var post: Vector2 = gate[0].lerp(gate[1],float(step)/5)
				draw_line(post,post-Vector2(0,38),Color("776245"),5,true)
		for x in range(300,501,28):
			draw_line(Vector2(x,625),Vector2(x,593),Color("776245"),5,true)
		draw_line(Vector2(300,605),Vector2(500,605),Color("a3895b"),4,true)
