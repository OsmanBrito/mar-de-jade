extends Node2D
## Three composed public places connected by one continuous street.
const Blocks = preload("res://scripts/city/lisbon_blocks.gd")
const Ground = preload("res://scripts/city/lisbon_ground.gd")
const Scenery = preload("res://scripts/city/lisbon_scenery.gd")
const Urban = preload("res://scripts/city/lisbon_urban_plan.gd")
var world
static func install(map: Node2D) -> void:
	if map.has_node("FerroRibeira/LisbonComposition"): return
	var ground := Node2D.new(); ground.set_script(load("res://scripts/city/lisbon_composition.gd"))
	ground.name = "LisbonComposition"; ground.world = map; ground.z_index = 0; map.get_node("FerroRibeira").add_child(ground); ground.get_parent().move_child(ground,0)
	for polygon in Blocks.PARCELS:
		var parcel := Node2D.new(); parcel.name = "QuintalFechado"; map.sorted_world.add_child(parcel)
		Scenery.body(parcel,PackedVector2Array(polygon))
	for polygon in Urban.BLOCKS:
		var block := Node2D.new(); block.name = "QuarteiraoHabitado"; map.sorted_world.add_child(block)
		Scenery.body(block,PackedVector2Array(polygon))
	# Build actual street frontage, including collision, before navigation is baked.
	for row in Urban.FRONTAGES:
		var area := Urban.footprint(row)
		var house := Scenery.prop(map,row[0],"bruma-v2-"+row[1]+".png",row[2],row[3],Rect2(area.position-row[2],area.size))
		house.tint = Color("f1eee5")
		house.set_meta("urban_frontage",true)
	for at in [Vector2(-390,598),Vector2(-185,592)]:
		Scenery.prop(map,"OliveiraDoQuintal","bruma-v2-tree.png",at,Vector2(154,182))
	for row in Blocks.WALLS+Urban.WALLS:
		var count := maxi(1,ceili(row[0].distance_to(row[1])/48.0))
		for i in count:
			var a: Vector2 = row[0].lerp(row[1],float(i)/count)
			var b: Vector2 = row[0].lerp(row[1],float(i+1)/count)
			var wall := preload("res://scripts/city/lisbon_block_wall.gd").new()
			wall.name = "MuroDoQuarteirao"; wall.position = (a+b)*.5; wall.across = b-a; wall.height = row[2]
			map.sorted_world.add_child(wall)
			# New party walls meet the closed plot edge; their visible thickness
			# and physical footprint are identical on the public side.
			if row in Urban.WALLS:
				var normal := (b-a).normalized().orthogonal()*5
				Scenery.body(wall,PackedVector2Array([-wall.across*.5+normal,wall.across*.5+normal,wall.across*.5-normal,-wall.across*.5-normal]))
	# The second stall and a shaded resting edge frame the market at the foot
	# of the descent. The quay stays clear for loading and the merchant approach.
	var baskets := Scenery.prop(map,"BancaDosCestos","bruma-market.png",Urban.MARKET_STALL,Vector2(150,145),Rect2(-52,-18,104,26))
	baskets.tint = Color("d5dbc4")
	Scenery.prop(map,"CestosDaBanca","bruma-v2-pots.png",Urban.MARKET_GOODS,Vector2(45,48),Rect2(-14,-12,28,18))
	Scenery.prop(map,"OliveiraDoLargo","bruma-v2-tree.png",Urban.MARKET_TREE,Vector2(175,205),Rect2(-16,-12,32,24))
	Scenery.prop(map,"BancoDoLargo","regional-bench-illustrated-v1.png",Urban.MARKET_BENCH,Vector2(112,58),Rect2(-39,-9,78,17))
	# Domestic use is confined to the frontage; these never occupy the street axis.
	for at in [Vector2(720,143),Vector2(1015,193),Vector2(1300,250),Vector2(1195,510),Vector2(355,533),Vector2(535,554)]:
		Scenery.prop(map,"VasoDaDescida","bruma-v2-pots.png",at,Vector2(42,52),Rect2(-12,-10,24,15))
	var mast := Node2D.new(); mast.name = "MarcoDoEmbarque"; mast.position = Vector2(1582,1040)
	mast.set_script(load("res://scripts/city/lisbon_waterfront_marker.gd")); map.sorted_world.add_child(mast)
	Scenery.body(mast,PackedVector2Array([Vector2(-5,-5),Vector2(5,-5),Vector2(5,5),Vector2(-5,5)]))
func _draw() -> void:
	for polygon in Urban.BLOCKS:
		Ground.surface(self,PackedVector2Array(polygon),Color("aaa48e"))
	for polygon in Blocks.PARCELS:
		var points := PackedVector2Array(polygon)
		var uv := PackedVector2Array()
		for at in points: uv.append(at/Vector2(310,205))
		if polygon==Blocks.WEST_GARDEN:
			draw_polygon(points,PackedColorArray([Color("8a8d6d")]),uv,Scenery.texture("bruma-grass-refined.png",false))
		else: Ground.surface(self,points,Color("aaa48e"))
	Ground.surface(self,PackedVector2Array(Urban.SERVICE_YARD),Color("aaa48e"))
	for y in [565,590,615]:
		for x in range(-480,-215,25):
			var at := Vector2(x,y+sin(x*.12)*3)
			draw_set_transform(at,0,Vector2(1,.42))
			draw_circle(Vector2.ZERO,9,Color("5e704e")); draw_circle(Vector2(-2,-2),5,Color("8c9670"))
	draw_set_transform(Vector2.ZERO)
	# A narrow worn street has actual frontage on both sides. Enclosed yards and
	# thresholds distinguish land use without adding ornamental road stripes.
	var street := Geometry2D.offset_polyline(PackedVector2Array(Urban.NEIGHBORHOOD_WALK),53,Geometry2D.JOIN_ROUND,Geometry2D.END_ROUND)
	for polygon in street: Ground.surface(self,polygon,Color("b9b09a"))
	Ground.surface(self,PackedVector2Array(Blocks.MARKET_APRON),Color("c8c0aa"))
	Ground.surface(self,PackedVector2Array(Blocks.PIER_APRON),Color("c6bfaa"))
	# Worn paving follows actual bends, rather than an arrow painted on the map.
	for path in [Blocks.MAIN_WALK.slice(0,6),Blocks.MAIN_WALK.slice(5,9)]:
		var surfaces := Geometry2D.offset_polyline(PackedVector2Array(path),31,Geometry2D.JOIN_ROUND,Geometry2D.END_ROUND)
		for polygon in surfaces: Ground.surface(self,polygon,Color("c5beaa"))
	for interval in [[-390,390],[810,1390]]:
		for x in range(interval[0],interval[1],24):
			draw_line(Vector2(x,1080),Vector2(x+20,1080),Color("97947d"),5,true)
			draw_line(Vector2(x,1078),Vector2(x+20,1078),Color("b6b39b"),1,true)
	for at in [Vector2(1404,1060),Vector2(1560,1072)]:
		draw_set_transform(at,0,Vector2(1,.5)); draw_arc(Vector2.ZERO,12,0,TAU,24,Color("8b8975"),2,true)
	draw_set_transform(Vector2.ZERO)
