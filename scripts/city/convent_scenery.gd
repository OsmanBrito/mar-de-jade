extends Node2D
const Plan = preload("res://scripts/city/convent_plan.gd")
const City = preload("res://scripts/city/lisbon_scenery.gd")
const Furniture = preload("res://scripts/chapter/furniture_art.gd")
const Prop = preload("res://scripts/city/lisbon_prop.gd")
const Order = preload("res://scripts/chapter/order_house.gd")
const Materials = preload("res://scripts/city/place_materials.gd")
const Finish = preload("res://scripts/city/convent_finish.gd")
var world
static var pieces: Dictionary = {}
static func piece(map: Node2D,name: String,file: String,foot: Vector2,width: float) -> Node2D:
	var piece := Prop.new(); piece.name = name; piece.world = map; piece.position = foot
	if not pieces.has(file):
		var original: Texture2D = load(file)
		var image := original.get_image(); var bounds := image.get_used_rect()
		image.fix_alpha_edges(); image.generate_mipmaps()
		var filtered := CanvasTexture.new(); filtered.diffuse_texture = ImageTexture.create_from_image(image)
		filtered.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var cropped := AtlasTexture.new(); cropped.atlas = filtered; cropped.region = bounds; cropped.filter_clip = true
		pieces[file] = cropped
	var atlas: AtlasTexture = pieces[file]
	piece.texture = atlas; piece.size = atlas.get_size()*width/atlas.get_width()
	map.sorted_world.add_child(piece); return piece
static func box(map: Node2D,rect: Rect2) -> void:
	City.body(map.sorted_world,PackedVector2Array([rect.position,rect.position+Vector2(rect.size.x,0),rect.end,rect.position+Vector2(0,rect.size.y)]))
static func install(map: Node2D) -> void:
	var floor := Node2D.new(); floor.set_script(load("res://scripts/city/convent_scenery.gd")); floor.name = "ConventStoneAndGarden"; floor.world = map; floor.z_index = -4; map.add_child(floor)
	box(map,Plan.GARDEN.grow(10))
	# Rendering and collision share the same western church opening.
	for band in Plan.NORTH_WALLS: box(map,band)
	for row in Plan.ARCADE_ROWS:
		piece(map,"ArcadaDoClaustro","res://assets/art/order/cloister-arcade-v2.png",Vector2(0,row),720)
		for x in Plan.PIER_CENTERS:
			box(map,Rect2(Vector2(x-Plan.PIER_SIZE.x/2,row-25),Plan.PIER_SIZE))
	for at in [Vector2(-105,475),Vector2(100,565)]:
		City.prop(map,"OliveiraDoClaustro","bruma-v2-tree.png",at,Vector2(125,155))
	City.prop(map,"CisternaDoClaustro","roman-well-refined-v1.png",Plan.CISTERN,Vector2(115,165))
	box(map,Plan.CISTERN_FOOTPRINT)
	Finish.install(map)
	for at in [Vector2(-220,745),Vector2(220,745),Vector2(415,350),Vector2(910,700)]:
		City.prop(map,"VasosDoConvento","bruma-v2-pots.png",at,Vector2(42,50))
	var desk := Furniture.place(map.sorted_world,"table",Vector2(-290,390),Vector2(100,85)); desk.name = "MesaDaRegra"
	for at in [Vector2(-145,-25),Vector2(145,-25),Vector2(-145,95),Vector2(145,95)]:
		Furniture.place(map.sorted_world,"bench",at+Plan.CHAPEL_OFFSET,Vector2(105,85))
	piece(map,"AbsideDaCapela","res://assets/art/order/chapel-apse-v1.png",Vector2(0,-220)+Plan.CHAPEL_OFFSET,570)
	box(map,Rect2(Vector2(-250,-420)+Plan.CHAPEL_OFFSET,Vector2(500,200)))
	for at in [Vector2(520,395),Vector2(730,395),Vector2(895,625)]:
		Furniture.place(map.sorted_world,"bed",at,Vector2(130,120))
	Furniture.place(map.sorted_world,"washstand",Vector2(445,715),Vector2(90,90))
	Furniture.place(map.sorted_world,"shelf",Vector2(900,315),Vector2(95,110))
	Furniture.place(map.sorted_world,"table",Vector2(600,545),Vector2(100,90))
	for at in [Vector2(-880,430),Vector2(-680,430),Vector2(-880,650)]: Furniture.place(map.sorted_world,"bed",at,Vector2(130,120))
	Furniture.place(map.sorted_world,"cupboard",Vector2(-600,640),Vector2(95,135))
	for x in [560,800]:
		var table := Furniture.place(map.sorted_world,"table",Vector2(x,-80),Vector2(150,120))
		var serving := Node2D.new(); serving.set_script(preload("res://scripts/city/house_work_surface.gd")); serving.position.y = -25; table.add_child(serving)
		for y in [-195,30]: Furniture.place(map.sorted_world,"bench",Vector2(x,y),Vector2(115,85))
	var preparation:=Furniture.place(map.sorted_world,"table",Vector2(1190,60),Vector2(120,95));preparation.name="MesaDasPorcoes"
	piece(map,"LareiraDaCozinha","res://assets/art/order/kitchen-hearth-v1.png",Vector2(1260,-160),230)
	box(map,Rect2(1145,-235,230,90))
	install_service_rooms(map)
	var attendant = preload("res://scripts/chapter/actor_proxy.gd").new(); attendant.name="IrmaoDaEnfermaria";attendant.npc_id = "order_brother"; attendant.position = Vector2(810,445); map.sorted_world.add_child(attendant)
	City.body(attendant,PackedVector2Array([Vector2(-9,-6),Vector2(9,-6),Vector2(9,7),Vector2(-9,7)]))
func _draw() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	# The cutaway sits inside a building mass, not over an empty backdrop.
	Materials.polygon(self,PackedVector2Array([Vector2(-2500,-2200),Vector2(3500,-2200),Vector2(3500,2800),Vector2(-2500,2800)]),"limewash-wall",Color("41453b"),800)
	# One floor and one outer foundation: corridors never receive overlapping frames.
	for surface in Plan.surfaces():
		var boundary := surface.duplicate(); boundary.append(surface[0])
		draw_polyline(boundary,Color("81755d"),24,true)
		Finish.paving(self,surface,Materials.INTERIOR_STONE)
		draw_polyline(boundary,Color("ac9977"),4,true)
	Finish.spaces(self)
	for band in [Rect2(Plan.CHAPEL.position,Vector2(Plan.CHAPEL.size.x,18))]+Plan.NORTH_WALLS+[Rect2(360,230,240,18),Rect2(750,230,220,18)]:
		Materials.wall(self,band.position,band.position+Vector2(band.size.x,0))
	for at in [Vector2(475,200),Vector2(875,200)]:
		Materials.window(self,at,44,72)
	for band in [Rect2(-1000,270,500,18),Rect2(430,-360,500,18),Rect2(1050,-360,400,18)]: Materials.wall(self,band.position,band.position+Vector2(band.size.x,0))
	for edge in [Rect2(-360,240,16,380),Rect2(-360,740,16,170),Rect2(344,185,16,230),Rect2(344,580,16,330),Rect2(954,235,16,565),Rect2(-550,-420,14,660),Rect2(56,-420,14,600),Rect2(-1000,270,14,480),Rect2(-514,270,14,350),Rect2(430,-360,14,510),Rect2(1436,-360,14,510)]:
		Materials.paving(self,edge,Color("8a795e"),200)
		draw_line(edge.position,edge.position+Vector2(0,edge.size.y),Color("dfcda7"),3,true)
	for row in Plan.ARCADE_ROWS:
		for x in Plan.PIER_CENTERS:
			var foot := Vector2(x,row)
			draw_colored_polygon(PackedVector2Array([foot+Vector2(-24,-6),foot+Vector2(24,-6),foot+Vector2(55,24),foot+Vector2(7,24)]),Color(.13,.16,.11,.12))
	Finish.garden(self)
	for at in [Vector2(-330,200),Vector2(330,200),Vector2(400,260)]:
		Order.banner(self,at+Vector2(0,-65),Vector2.RIGHT)
	# The chapel's central aisle has a woven runner, leaving seats to either side.
	draw_rect(Rect2(Vector2(-44,-200)+Plan.CHAPEL_OFFSET,Vector2(88,330)),Color("814e43")); draw_rect(Rect2(Vector2(-38,-197)+Plan.CHAPEL_OFFSET,Vector2(76,324)),Color("ad8c62"),false,2)
	for y in range(-180,125,18):
		draw_line(Vector2(-34,y)+Plan.CHAPEL_OFFSET,Vector2(34,y)+Plan.CHAPEL_OFFSET,Color(.8,.65,.43,.11),1,true)
	for at in [Vector2(0,880),Vector2(-325,680),Vector2(370,505),Plan.CHAPEL_ENTRY]:
		Finish.threshold(self,at)
	Materials.wall(self,Vector2(80,-350),Vector2(210,-350),120)
	Materials.wall(self,Vector2(320,-350),Vector2(390,-350),120)
	Materials.wall(self,Vector2(-1000,790),Vector2(-820,790),90)
	Materials.wall(self,Vector2(-660,790),Vector2(-500,790),90)
	Finish.threshold(self,Vector2(260,180))
	Finish.threshold(self,Vector2(-740,780))
	Finish.signs(self)

static func install_service_rooms(map: Node2D) -> void:
	# Rooms sit along existing routes, with readable work clusters and clear approaches.
	for band in [Rect2(80,-350,130,14),Rect2(320,-350,70,14),Rect2(80,-350,14,500),Rect2(376,-350,14,500),Rect2(-1000,790,180,12),Rect2(-660,790,160,12)]:box(map,band)
	Furniture.place(map.sorted_world,"shelf",Vector2(125,-205),Vector2(90,135))
	Furniture.place(map.sorted_world,"shelf",Vector2(330,-155),Vector2(90,135))
	var registry:=Furniture.place(map.sorted_world,"table",Vector2(230,30),Vector2(150,100));registry.name="MesaDosRegistos"
	Furniture.place(map.sorted_world,"bench",Vector2(230,-60),Vector2(100,75))
	Furniture.place(map.sorted_world,"cupboard",Vector2(320,-285),Vector2(100,145))
	var armour:=Furniture.place(map.sorted_world,"table",Vector2(-850,875),Vector2(130,90));armour.name="BancadaDaArmaria"
	Furniture.place(map.sorted_world,"cupboard",Vector2(-555,875),Vector2(85,130))
	piece(map,"ArmasDePratica","res://assets/art/combat/portugal/training-rack-mar-de-ferro.png",Vector2(-660,855),150)
	box(map,Rect2(-710,830,100,25))
	for at in [Vector2(1410,-30),Vector2(1090,-260)]:City.prop(map,"ReservaDaCozinha","bruma-crate.png",at,Vector2(68,65))
	City.prop(map,"AguaDeServico","bruma-barrel.png",Vector2(1400,-220),Vector2(64,85))
	var notes:=Node2D.new();notes.set_script(load("res://scripts/city/order_service_props.gd"));notes.name="MesasDeTrabalho";map.sorted_world.add_child(notes)
	for key in ["MesaDosRegistos","BancadaDaArmaria","MesaDasPorcoes"]:
		var table=map.sorted_world.get_node(key)
		var work:=Node2D.new();work.set_script(load("res://scripts/city/order_service_props.gd"));work.kind={"MesaDosRegistos":"registry","BancadaDaArmaria":"armory","MesaDasPorcoes":"portions"}[key];table.add_child(work)
