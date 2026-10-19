extends RefCounted
## One coordinate system: the existing Jade square above Ferro's real Ribeira.
const Ferro = preload("res://scripts/city/ferro_lisbon.gd")
const SCALE := 1.6
const OFFSET := Vector2(-680,120)
const BOUNDS := Rect2(-1200,-600,3020,2000)
const VIEW_BOUNDS := Rect2(-1450,-850,3500,2550)
const ROOM_ENTRY := preload("res://scripts/city/convent_plan.gd").PORTARIA
const CONVENT_ENTRY := preload("res://scripts/city/convent_plan.gd").ARCADE
const ROOM_RETURN := Vector2(-690,145)
const UPPER := [Vector2(-1100,-100),Vector2(480,-100),Vector2(650,290),Vector2(515,550),Vector2(480,650),Vector2(300,650),Vector2(250,540),Vector2(-500,520),Vector2(-1050,290)]
const RIBEIRA_PAVING := Rect2(-552,512,2144,590)
const RIBEIRA_SURFACE := [Vector2(-2400,440),Vector2(-1500,440),Vector2(-950,480),Vector2(650,480),Vector2(2100,440),Vector2(3600,440),Vector2(3600,1102),Vector2(-2400,1102)]
static var paved_outline := PackedVector2Array()
const WEST_STREET := [Vector2(-850,340),Vector2(-900,430),Vector2(-900,820),Vector2(-650,965),Vector2(-485,1000)]
const EAST_STREET := [Vector2(480,300),Vector2(735,360),Vector2(1645,450),Vector2(1660,965),Vector2(1480,1025)]
const STREET_WIDTH := 124.0
static var street_surfaces: Array[PackedVector2Array] = []
static func streets() -> Array[PackedVector2Array]:
	if street_surfaces.is_empty():
		for path in [WEST_STREET,EAST_STREET]:
			street_surfaces.append_array(Geometry2D.offset_polyline(PackedVector2Array(path),STREET_WIDTH*.5,Geometry2D.JOIN_ROUND,Geometry2D.END_ROUND))
	return street_surfaces
static func paving_surface() -> PackedVector2Array:
	if paved_outline.is_empty():
		var joined := Geometry2D.merge_polygons(PackedVector2Array(UPPER),PackedVector2Array(RIBEIRA_SURFACE))
		assert(joined.size()==1,"Lisbon paving must connect the forecourt and Ribeira")
		paved_outline = joined[0]
	return paved_outline
const WORKSHOP := Vector2(1360,925)
const CART_HOME := Vector2(1190,963)
const CART_FIXED := Vector2(1260,987)
const DOCK := Vector2(1540,1025)
const BOAT_ENTRY := Vector2(1496,1165)

static func source_point(p: Vector2) -> Vector2: return (p-OFFSET)/SCALE
static func point(p: Vector2) -> Vector2: return OFFSET+p*SCALE
static func area(p: Vector2) -> String: return "cais" if p.y>660 else "square"
static func contains(p: Vector2,childhood: bool = false) -> bool:
	if Geometry2D.is_point_in_polygon(p,PackedVector2Array(UPPER)): return true
	if childhood: return false
	for street in streets():
		if Geometry2D.is_point_in_polygon(p,street): return true
	var q := source_point(p)
	for dock in Ferro.DOCKS:
		if dock.has_point(q): return true
	if q.x<80 or q.x>1420 or q.y<245 or q.y>616: return false
	for wall in Ferro.COURTYARD_WALLS:
		# A visible open gate joins the convent descent to the working waterfront.
		if q.x>=670 and q.x<=745: continue
		if q.x>=wall.position.x and q.x<=wall.end.x and absf(q.y-Ferro.wall_base_y(wall,q.x))<=7: return false
	for rect in Ferro.BUILDINGS+[Ferro.CARGO[0],Ferro.CARGO[1],Ferro.CARGO[4],Ferro.SHIPYARD,Ferro.TIMBER,Ferro.MARKET]:
		if rect.has_point(q): return false
	for item in Ferro.PROPS:
		if item[0]=="cart": continue # The repairable Jade cart has its own current footprint.
		var foot: Vector2 = item[3]
		if foot!=Vector2.ZERO and Rect2(item[1]-Vector2(foot.x/2,foot.y),foot).has_point(q): return false
	return true

static func stock_positions() -> Dictionary:
	return {"workshop":WORKSHOP,"dock":DOCK,"fisher":Vector2(650,1030),"neighbor":Vector2(315,955)}
