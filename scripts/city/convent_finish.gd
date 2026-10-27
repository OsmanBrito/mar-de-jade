extends RefCounted
## Shared oblique masonry, four-sided galleries and quiet wall-mounted wayfinding.
const Plan = preload("res://scripts/city/convent_plan.gd")
const Materials = preload("res://scripts/city/place_materials.gd")
const Furniture = preload("res://scripts/chapter/furniture_art.gd")
static var pier_texture: AtlasTexture
static func install(map: Node2D) -> void:
	if pier_texture==null:
		pier_texture = AtlasTexture.new(); pier_texture.atlas = load("res://assets/art/order/cloister-arcade-v2.png")
		pier_texture.region = Rect2(75,525,190,180); pier_texture.filter_clip = true
	for at in Plan.SIDE_PIERS:
		var pier := preload("res://scripts/city/lisbon_prop.gd").new()
		pier.name = "PilarDaGaleria"; pier.texture = pier_texture; pier.size = Vector2(68,180.0*68/190); pier.position = at; pier.world = map
		map.sorted_world.add_child(pier)
		# Lateral galleries use cutaway plinths so their columns never hide the path.
		var cap := Polygon2D.new(); var top: float = -pier.size.y
		cap.polygon = PackedVector2Array([Vector2(-22,top+3),Vector2(6,top-6),Vector2(26,top+3),Vector2(-2,top+10)])
		cap.color = Color("c6b899"); pier.add_child(cap)
		preload("res://scripts/city/convent_scenery.gd").box(map,Rect2(at-Vector2(24,25),Vector2(48,30)))
	for at in [Vector2(-300,745),Vector2(300,745)]:
		var seat := Furniture.place(map.sorted_world,"bench",at,Vector2(90,52)); seat.name = "BancoDaGaleria"
static func paving(canvas: CanvasItem,points: PackedVector2Array,tint: Color) -> void:
	var uv := PackedVector2Array()
	for at in points: uv.append(Vector2(.5*at.x+at.y,-.22*at.x+at.y)/118.0)
	canvas.draw_polygon(points,PackedColorArray([tint]),uv,Materials.texture("limestone-floor"))
static func area(canvas: CanvasItem,rect: Rect2,tint: Color) -> void:
	paving(canvas,PackedVector2Array([rect.position,rect.position+Vector2(rect.size.x,0),rect.end,rect.position+Vector2(0,rect.size.y)]),tint)
static func spaces(canvas: CanvasItem) -> void:
	# One world-space material continues across rooms and doorways.
	for band in [Rect2(-340,330,155,470),Rect2(185,330,155,470),Rect2(-340,200,680,140),Rect2(-340,655,680,230)]:
		area(canvas,band,Color("c9c4ad"))
	area(canvas,Plan.INFIRMARY,Color("c9cbb8"))
	area(canvas,Plan.REFECTORY,Color("d0c0a2"))
	for side in [-1,1]:
		var x: float = side*178.0
		canvas.draw_line(Vector2(x,350),Vector2(x,635),Color(.43,.42,.32,.25),3,true)
	# Short pier shadows ground the galleries without obscuring the corridor.
	for at in Plan.SIDE_PIERS:
		canvas.draw_colored_polygon(PackedVector2Array([at+Vector2(-24,-6),at+Vector2(24,-6),at+Vector2(47,15),at+Vector2(0,15)]),Color(.15,.17,.12,.13))
static func garden(canvas: Node2D) -> void:
	var garden: Rect2 = Plan.GARDEN
	area(canvas,garden.grow(9),Color("b9ad8c"))
	var points := PackedVector2Array([garden.position,garden.position+Vector2(garden.size.x,0),garden.end,garden.position+Vector2(0,garden.size.y)])
	var uv := PackedVector2Array()
	for at in points: uv.append(Vector2(.5*at.x+at.y,-.22*at.x+at.y)/240)
	canvas.draw_polygon(points,PackedColorArray([Color("88916c")]),uv,preload("res://scripts/city/lisbon_scenery.gd").texture("bruma-grass-refined.png",false))
	# Narrow maintenance gaps separate planted beds; the enclosing curb has no gate.
	for row in 2:
		for column in 2:
			var bed := Rect2(-147+column*155,403+row*105,137,87)
			var soil := PackedVector2Array([bed.position,bed.position+Vector2(bed.size.x,0),bed.end,bed.position+Vector2(0,bed.size.y)])
			Materials.polygon(canvas,soil,"limewash-wall",Color("72765b"),170)
			canvas.draw_rect(bed.grow(-4),Color("89866a"),false,2)
			for y in 3:
				for x in 5:
					var at := bed.position+Vector2(16+x*25,17+y*25)
					canvas.draw_set_transform(at,0,Vector2(1,.5))
					canvas.draw_circle(Vector2.ZERO,8,Color("4f6847")); canvas.draw_circle(Vector2(-3,-2),5,Color("6b8055"))
					canvas.draw_line(Vector2(-4,-1),Vector2(3,-4),Color("94a475"),2,true)
					canvas.draw_set_transform(Vector2.ZERO)
	canvas.draw_set_transform(Vector2.ZERO)
	canvas.draw_line(garden.position,garden.position+Vector2(garden.size.x,0),Color("dbceb0"),3,true)
	canvas.draw_line(garden.position+Vector2(0,garden.size.y),garden.end,Color("8a8065"),5,true)
static func threshold(canvas: CanvasItem,at: Vector2,width: float = 86) -> void:
	area(canvas,Rect2(at-Vector2(width*.5,8),Vector2(width,16)),Color("c7c1aa"))
static func plaque(canvas: CanvasItem,at: Vector2,words: String,width: float = 84) -> void:
	# Position is on masonry, never a signpost standing in the public corridor.
	canvas.draw_style_box(plate(),Rect2(at-Vector2(width*.5,10),Vector2(width,20)))
	var font := ThemeDB.fallback_font
	var text_width := font.get_string_size(words,HORIZONTAL_ALIGNMENT_LEFT,-1,11).x
	canvas.draw_string(font,at+Vector2(-text_width*.5,4),words,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("e4d8b7"))
static func plate() -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color = Color("605e4d"); style.border_color = Color("a79776")
	style.set_border_width_all(1); style.set_corner_radius_all(2); return style
static func signs(canvas: CanvasItem) -> void:
	for row in [[Vector2(-135,110),"Capela",72.0],[Vector2(548,175),"Enfermaria",94.0],[Vector2(-750,214),"Dormitório",94.0],[Vector2(680,-416),"Refeitório",94.0],[Vector2(1240,-416),"Cozinha",78.0],[Vector2(145,-406),"Secretaria",86.0],[Vector2(-905,740),"Armaria",78.0]]:
		plaque(canvas,row[0],row[1],row[2])
