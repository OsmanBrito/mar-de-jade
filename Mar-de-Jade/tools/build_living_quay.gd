extends SceneTree
## Bake editable art, footprints and ambient routes. Re-run after intentional layout changes.
const SHIFT := Vector2(192,352)
var map: Node2D
var sorted: Node2D
var scenery: Node2D
var buildings: Texture2D
var props: Texture2D
var details: Texture2D
var frames: Dictionary
func p(u: float,v: float) -> Vector2: return Vector2(u-v,(u+v)*0.5)+SHIFT
func authored(node: Node,parent: Node) -> void:
	parent.add_child(node); node.owner = map
func footprint(parent: Node, polygon: PackedVector2Array) -> void:
	var body := StaticBody2D.new(); body.name = "Body"; body.collision_mask = 0; authored(body,parent)
	var shape := CollisionPolygon2D.new(); shape.name = "Footprint"; shape.polygon = polygon; authored(shape,body)
func building(label: String,index: int,rect: Rect2,tint: Color = Color.WHITE,background: bool = false) -> void:
	var r: Array = frames.buildings.frames[index]
	var node := Node2D.new(); node.name = label; node.set_script(load("res://scripts/map_prop.gd"))
	node.sloped_depth = true; node.object_id = StringName("cais_vivo/"+label); node.y_sort_enabled = true
	node.position = p(rect.end.x,rect.end.y); authored(node,scenery if background else sorted)
	var poly := PackedVector2Array()
	for corner in [rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]: poly.append(p(corner.x,corner.y)-node.position)
	footprint(node,poly)
	if background: node.get_node("Body").collision_layer = 0
	var factor: float = (rect.size.x+rect.size.y+16)/float(r[2])
	for strip_rect in frames.buildings.strips[index]:
		var x: float = strip_rect[0]; var y: float = strip_rect[1]
		var tex := AtlasTexture.new(); tex.atlas = buildings; tex.region = Rect2(r[0]+x,r[1]+y,strip_rect[2],strip_rect[3])
		var strip := Sprite2D.new(); strip.centered = false; strip.texture = tex; strip.scale = Vector2.ONE*factor
		strip.position = Vector2(-rect.size.x-8+x*factor,(-r[3]+y)*factor+6); strip.modulate = tint; authored(strip,node)
func detail(label: String,index: int,u: float,v: float,width: float,radius: Vector2) -> void:
	var r: Array = frames.details.frames[index]
	var node := Node2D.new(); node.name = label; node.position = p(u,v); authored(node,sorted)
	var factor: float = width/r[2]
	for region in frames.details.strips[index]:
		var texture := AtlasTexture.new(); texture.atlas = details; texture.region = Rect2(r[0]+region[0],r[1]+region[1],region[2],region[3])
		var sprite := Sprite2D.new(); sprite.centered = false; sprite.texture = texture; sprite.scale = Vector2.ONE*factor; sprite.position = Vector2(-width/2+region[0]*factor,(-r[3]+region[1])*factor+radius.y*0.5); authored(sprite,node)
	if radius.x>0: footprint(node,PackedVector2Array([Vector2(-radius.x,0),Vector2(0,-radius.y),Vector2(radius.x,0),Vector2(0,radius.y)]))
func prop(label: String,index: int,u: float,v: float,width: float,radius: Vector2) -> void:
	var r: Array = frames.props.frames[index]
	var node := Node2D.new(); node.name = label; node.position = p(u,v); authored(node,sorted)
	var tex := AtlasTexture.new(); tex.atlas = props; tex.region = Rect2(r[0],r[1],r[2],r[3])
	var sprite := Sprite2D.new(); sprite.texture = tex; sprite.scale = Vector2.ONE*width/float(r[2]); sprite.position.y = -r[3]*sprite.scale.y*0.5+radius.y*0.5; authored(sprite,node)
	if radius.x>0: footprint(node,PackedVector2Array([Vector2(-radius.x,0),Vector2(0,-radius.y),Vector2(radius.x,0),Vector2(0,radius.y)]))
func resident(label: String,id: String,route: Array,pause: float,posture: String = "standing") -> void:
	var npc := CharacterBody2D.new(); npc.name = label; npc.set_script(load("res://scripts/chapter/quay_resident.gd")); npc.npc_id = id; npc.pause_seconds = pause; npc.rest_posture = posture
	var points := PackedVector2Array()
	for point in route: points.append(p(point[0],point[1]))
	npc.route = points; npc.position = points[0]; authored(npc,sorted)
func _initialize() -> void:
	frames = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/living-quay/frames.json"))
	buildings = load(frames.buildings.path); props = load(frames.props.path); details = load(frames.details.path)
	map = Node2D.new(); map.name = "CaisVivo"; map.set_script(load("res://scripts/chapter/plaza_world.gd")); map.map_id = "cais"; map.set_meta("living_quay",true)
	map.y_sort_enabled = true
	var ground := TileMapLayer.new(); ground.name = "Ground"; ground.tile_set = load("res://data/terrain/ground.tres"); ground.z_index = -5; authored(ground,map)
	for u in range(-5,14):
		for v in range(-5,14): ground.set_cell(Vector2i(u+7,v+4),0,Vector2i.ZERO)
	for u in range(14,19):
		for v in range(3,6): ground.set_cell(Vector2i(u+7,v+4),0,Vector2i(1,0))
	# The visible continent extends far beyond exploration. Only the river-facing bank ends.
	var city_ground := TileMapLayer.new(); city_ground.name = "CityGround"; city_ground.tile_set = ground.tile_set; city_ground.z_index = -6; authored(city_ground,map)
	for u in range(-48,14):
		for v in range(-48,49): city_ground.set_cell(Vector2i(u+7,v+4),0,Vector2i.ZERO)
	scenery = Node2D.new(); scenery.name = "CityScenery"; scenery.y_sort_enabled = true; authored(scenery,map)
	sorted = Node2D.new(); sorted.name = "ActorsAndProps"; sorted.y_sort_enabled = true; authored(sorted,map)
	building("Abrigo",0,Rect2(40,45,180,140))
	building("ArmazemDeCarga",1,Rect2(300,35,235,150))
	building("Oficina",2,Rect2(40,390,200,160))
	building("CasaDoMercador",3,Rect2(350,400,185,145))
	# Neighbouring blocks frame the street and continue beyond the playable vignette.
	building("CasaDaEsquina",3,Rect2(-200,30,170,150),Color("e4ded0"))
	building("TelhadosDaCidade",0,Rect2(-190,-205,190,155),Color("d9d3c3"))
	building("ArmazemInterior",1,Rect2(80,-215,235,145),Color("d5cabc"))
	building("CasaInterior",3,Rect2(400,-205,175,145),Color("e4dccb"))
	building("ArmazemDaMargem",1,Rect2(615,-170,210,155))
	building("OficinaVizinha",2,Rect2(-220,400,180,155),Color("ded1b5"))
	building("CasaDasRedes",0,Rect2(50,650,180,140),Color("d9d6c3"))
	building("ArmazemSul",1,Rect2(350,650,225,150),Color("e8dcc6"))
	# Adjacent streets keep their full scale; roofs overlap naturally at the frame edges.
	for row in 4:
		var v := -490.0-row*275.0
		building("CidadeNorteCasa%d"%row,0 if row%2==0 else 3,Rect2(-190,v,180,150),Color("d6d0bc"),true)
		building("CidadeNorteOficina%d"%row,2,Rect2(70,v,205,150),Color("d6cab4"),true)
		building("CidadeNorteMercador%d"%row,3,Rect2(380,v,180,145),Color("ddd5bf"),true)
		building("CidadeNorteArmazem%d"%row,1,Rect2(650,v,210,150),Color("d3cab5"),true)
	for row in 7:
		var v := -490.0+row*280.0
		building("CidadeInterior%d"%row,3 if row%2==0 else 0,Rect2(-470,v,175,155),Color("dbd3bd"),true)
		building("CidadeInteriorLonge%d"%row,2 if row%2==0 else 1,Rect2(-760,v,210,155),Color("d0c5ad"),true)
	for row in 3:
		var v := 940.0+row*285.0
		building("CidadeSulCasa%d"%row,0 if row%2==0 else 3,Rect2(40,v,180,145),Color("e0d5ba"),true)
		building("CidadeSulOficina%d"%row,2,Rect2(350,v,210,155),Color("d4c4a9"),true)
		building("CidadeSulMargem%d"%row,1,Rect2(650,v,210,150),Color("dacdb4"),true)
	prop("CarroDaOficina",1,275,435,109,Vector2(31,16))
	prop("CargaArmazem",3,550,90,90,Vector2(26,15))
	prop("CargaRecolhida",3,760,455,103,Vector2(30,16))
	prop("SacosDeEmbarque",3,835,490,77,Vector2(22,13))
	prop("CargaDoPontao",3,1040,205,86,Vector2(24,13))
	prop("RedesDaMargem",2,850,125,100,Vector2(29,12))
	prop("RedesDoPescador",2,850,580,106,Vector2(31,13))
	prop("RedesDaOficina",2,265,525,84,Vector2(24,11))
	prop("AmarraNorte",0,880,175,53,Vector2(12,7))
	prop("AmarraSul",0,880,535,53,Vector2(12,7))
	prop("AmarraPontao",0,1145,350,54,Vector2(12,7))
	prop("CarroDaCarga",1,795,45,113,Vector2(32,16))
	detail("BancaDePeixe",0,820,460,145,Vector2(43,20))
	detail("BarrisDoArmazem",1,570,55,75,Vector2(24,13))
	detail("BarrisDeAgua",1,860,390,66,Vector2(21,11))
	detail("BarrisDaOficina",1,250,585,65,Vector2(20,11))
	detail("BarrisDoPontao",1,980,200,66,Vector2(20,11))
	detail("RoupaDoAbrigo",2,-20,140,154,Vector2(0,0))
	detail("OliveiraDaEsquina",3,-20,370,180,Vector2(17,9))
	detail("OliveiraDaRua",3,570,-35,162,Vector2(16,8))
	detail("OliveiraDoAbrigo",3,-100,-30,172,Vector2(16,8))
	detail("OliveiraDaMargem",3,815,685,153,Vector2(15,8))
	var crane = load("res://scenes/props/crane.tscn").instantiate(); crane.name = "GruaDeMadeira"; crane.position = p(815,65); crane.scale = Vector2.ONE*0.25; authored(crane,sorted)
	var boat := Sprite2D.new(); boat.name = "Caravela"; boat.texture = load("res://assets/art/living-quay/caravela-clean-v2.png"); boat.scale = Vector2.ONE*0.36; boat.position = p(1250,550)+Vector2(0,-175); boat.z_index = 2; authored(boat,sorted)
	resident("Carregador","worker",[[550,270],[805,285],[805,370]],3.2)
	resident("Pescadora","dock_woman",[[810,565],[800,350]],5.0)
	resident("Morador","observer",[[-40,295],[275,285],[550,300]],2.0)
	resident("Vizinha","family",[[270,360],[280,255],[60,265]],4.0)
	resident("OficialDaOficina","worker",[[290,485],[300,590]],6.0)
	resident("TrabalhadorDoPontao","worker",[[930,290],[1110,290]],4.0)
	resident("Servente","attendant",[[610,115],[680,130],[600,220]],5.0)
	var life := Node2D.new(); life.name = "Ambiente"; life.set_script(load("res://scripts/chapter/quay_life.gd")); authored(life,map)
	var spawn := Marker2D.new(); spawn.name = "Spawn"; spawn.position = p(125,280); authored(spawn,map)
	var packed := PackedScene.new(); var error := packed.pack(map)
	if error==OK: error = ResourceSaver.save(packed,"res://scenes/maps/cais_vivo.tscn")
	map.free(); print("LIVING_QUAY_BAKE ",error); quit(error)
