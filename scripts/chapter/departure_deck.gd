extends Node2D
## The Botafogo at the quay: the painted caravel from the living quay, mirrored so
## its bow points away from Lisbon, with the walkable area fitted to its waist deck.
const SHIP := preload("res://assets/art/living-quay/caravela-clean-v2.png")
const SIZE := Vector2(1536,1024)
const SCALE := 1.45
## World position of the mirrored image's top-left pixel.
const ORIGIN := Vector2(-1125,-643)
## Walkable waist deck, in the original (unmirrored) image pixels.
const DECK := [Vector2(1091,750),Vector2(1024,707),Vector2(860,650),Vector2(647,588),Vector2(397,532),Vector2(388,540),
	Vector2(388,650),Vector2(397,652),Vector2(522,684),Vector2(710,734),Vector2(860,759),Vector2(1024,784),Vector2(1091,788)]
## Painted fittings that block walking: [image point, half width].
const FITTINGS := [[Vector2(391,575),24.0]] # capstan by the sterncastle
## Mast shafts drawn again in the sorted layer so actors can pass behind them:
## [image region, base point in the image].
const MASTS := [[Rect2(556,300,46,316),Vector2(579,612)],[Rect2(1083,470,36,262),Vector2(1101,728)]]
static var outline_cache := PackedVector2Array()
var departure_progress := 0.0:
	set(value): departure_progress = value; queue_redraw()
var rope_owner: Node2D
var rope_secured := false

static func to_world(image_point: Vector2) -> Vector2:
	return ORIGIN+Vector2(SIZE.x-image_point.x,image_point.y)*SCALE

static func outline() -> PackedVector2Array:
	if outline_cache.is_empty():
		for point in DECK: outline_cache.append(to_world(point))
	return outline_cache

func _process(_delta: float) -> void:
	if is_instance_valid(rope_owner) or has_meta("debug"): queue_redraw()

static func install(world: Node2D) -> void:
	world.set_meta("departure_deck",true)
	world.terrain.hide()
	var ship := Sprite2D.new(); ship.name = "Caravela"; ship.texture = SHIP
	ship.centered = false; ship.flip_h = true; ship.position = ORIGIN; ship.scale = Vector2.ONE*SCALE
	ship.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS; ship.z_index = 1
	world.add_child(ship)
	var deck := Node2D.new(); deck.set_script(load("res://scripts/chapter/departure_deck.gd"))
	deck.name = "ConvesDaBotafogo"; deck.z_index = 1; world.add_child(deck)
	for mast in MASTS:
		var region: Rect2 = mast[0]; var base: Vector2 = mast[1]
		var shaft := Sprite2D.new(); shaft.name = "Mastro"
		var atlas := AtlasTexture.new(); atlas.atlas = SHIP
		atlas.region = region
		shaft.texture = atlas; shaft.flip_h = true; shaft.centered = false; shaft.scale = Vector2.ONE*SCALE
		var anchor := to_world(base)
		shaft.position = to_world(Vector2(region.end.x,region.position.y))-anchor
		shaft.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var holder := Node2D.new(); holder.position = anchor; holder.add_child(shaft)
		holder.set_meta("no_cast_shadow",true) # the painted ship already shades its masts
		world.sorted_world.add_child(holder)
		_footprint(holder,22.0)
	for fitting in FITTINGS:
		var holder := Node2D.new(); holder.name = "Cabrestante"; holder.position = to_world(fitting[0])
		world.sorted_world.add_child(holder); _footprint(holder,fitting[1])

static func _footprint(holder: Node2D,half: float) -> void:
	var body := StaticBody2D.new(); body.collision_mask = 0; holder.add_child(body)
	var shape := CollisionPolygon2D.new()
	shape.polygon = PackedVector2Array([Vector2(-half,0),Vector2(0,-half*0.45),Vector2(half,0),Vector2(0,half*0.45)])
	body.add_child(shape)

static func contains(point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(point,outline())

func _draw() -> void:
	if departure_progress>0:
		# The wake trails from the stern, opposite to the bow's heading.
		var stern := to_world(Vector2(200,640))
		for side in [-1,1]:
			var wake := PackedVector2Array()
			for i in 8:
				var trail := float(i)/7
				wake.append(stern+Vector2(150*trail,-58*trail+side*(10+trail*22))*departure_progress)
			draw_polyline(wake,Color(0.80,0.90,0.86,departure_progress*0.35),2.5,true)
	for origin in [Vector2(-60,290),Vector2(50,290)]:
		# The blue mooring line is the same painted coil, dyed.
		preload("res://scripts/chapter/story_prop_art.gd").draw_world(self,"PT-T01",origin+Vector2(0,9),44,Color(0.62,0.8,1.0) if origin.x<0 else Color.WHITE)
	if is_instance_valid(rope_owner) or rope_secured:
		var end: Vector2 = to_local(rope_owner.global_position)+Vector2(0,-30) if is_instance_valid(rope_owner) else Vector2(-140,330)
		var curve := PackedVector2Array()
		for i in 17:
			var weight := float(i)/16
			curve.append(Vector2(-60,290).lerp(end,weight)+Vector2(0,sin(weight*PI)*10))
		draw_polyline(curve,Color("436b79"),3.5,true)
		draw_polyline(curve,Color("8eb5bd"),1.1,true)
	if has_meta("debug"):
		var font := ThemeDB.fallback_font
		for x in range(-600,601,50):
			draw_line(Vector2(x,0),Vector2(x,600),Color(1,1,1,0.25 if x%100 else 0.5),1)
			if x%100==0: draw_string(font,Vector2(x+2,12),str(x),HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color.WHITE)
		for y in range(0,601,50):
			draw_line(Vector2(-600,y),Vector2(600,y),Color(1,1,1,0.25 if y%100 else 0.5),1)
			if y%100==0: draw_string(font,Vector2(-598,y-2),str(y),HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color.WHITE)
		var edge := outline(); edge.append(edge[0])
		draw_polyline(edge,Color.RED,2)
		for p in [Vector2(-80,360),Vector2(-140,360),Vector2(120,300),Vector2(200,310),Vector2(-60,290),Vector2(50,290),Vector2(-140,330),Vector2(40,365),Vector2(-170,395),Vector2(-140,385)]:
			draw_circle(p,5,Color.YELLOW)
