extends RefCounted
## Ribeira floor plan shared by the illustration, movement and companion.
const SIZE:=Vector2(1500,900)
const GROUND_PATH:="res://assets/art/ferro-lisbon/lisbon-ground-refined-v3.png"
const SPAWN:=Vector2(264,566)
const COMPANION_SPAWN:=Vector2(236,582)
# A recessed teal house and a forward workshop open distinct working courts.
const BUILDINGS:=[Rect2(138,354,250,76),Rect2(421,262,174,60),Rect2(805,283,258,79),Rect2(1090,350,236,78)]
const BUILDING_KEYS:=["house_limestone","house_teal","warehouse","workshop"]
const BUILDING_SIZES:=[Vector2(285,301),Vector2(204,301),Vector2(300,300),Vector2(285,260)]
# Low boundaries join the building plots while leaving the working courts open.
const COURTYARD_WALLS:=[Rect2(587,318,219,44),Rect2(80,340,75,15),Rect2(1320,340,100,20)]
const CARGO:=[Rect2(441,473,64,45),Rect2(505,494,31,24),Rect2(786,451,64,48),Rect2(800,499,64,34),Rect2(1060,489,84,33)]
# Each column is sorted by its ground foot; upper crates never claim floor space.
const CARGO_PILES:=[
	[Vector2(456,492),2],[Vector2(488,492),1],[Vector2(456,516),1],[Vector2(488,516),2],[Vector2(520,516),1],
	[Vector2(801,474),2],[Vector2(833,474),2],[Vector2(815,498),1],[Vector2(847,498),1],[Vector2(831,531),1],
	[Vector2(1076,509),2],[Vector2(1108,509),1],[Vector2(1128,521),1]]
const SHIPYARD:=Rect2(66,451,113,34)
const TIMBER:=Rect2(205,441,170,40)
const ROPEWALK:=Rect2(388,400,222,36)
const MARKET:=Rect2(687,520,86,27)
const DOCKS:=[Rect2(80,610,76,87),Rect2(1322,610,76,87)]
const DOCK_DRAW:=[Rect2(58,597,120,122),Rect2(1300,597,120,122)]
const PROPS:=[
	["bench",Vector2(631,345),Vector2(61,31),Vector2(48,10)],
	["pots",Vector2(794,376),Vector2(23,29),Vector2.ZERO],
	["nets",Vector2(225,495),Vector2(48,29),Vector2.ZERO],
	["nets",Vector2(346,498),Vector2(43,26),Vector2.ZERO],
	["nets",Vector2(593,509),Vector2(43,26),Vector2.ZERO],
	["barrel",Vector2(395,495),Vector2(26,32),Vector2(18,12)],
	["barrel",Vector2(565,498),Vector2(26,32),Vector2(18,12)],
	["barrel",Vector2(705,498),Vector2(26,32),Vector2(18,12)],
	["pots",Vector2(374,442),Vector2(29,32),Vector2.ZERO],
	["pots",Vector2(585,334),Vector2(29,32),Vector2.ZERO],
	["cart",Vector2(742,615),Vector2(73,59),Vector2(54,14)],
	["crate",Vector2(1290,465),Vector2(28,26),Vector2(22,16)],
	["barrel",Vector2(1329,473),Vector2(26,32),Vector2(18,12)],
	# Shared illustrated kit, with bases authored for this working waterfront.
	["net_rack",Vector2(211,604),Vector2(96,68),Vector2(76,16)],
	["market_goods",Vector2(785,553),Vector2(54,34),Vector2(46,15)],
	["market_goods",Vector2(1157,487),Vector2(42,27),Vector2(36,12)]]

static func walkable(p: Vector2) -> bool:
	for dock in DOCKS:
		if dock.has_point(p): return true
	if p.x<80 or p.x>1420 or p.y<245 or p.y>616: return false
	# Low cordage on the floor can be stepped over; it is not an invisible wall.
	for wall in COURTYARD_WALLS:
		if p.x>=wall.position.x and p.x<=wall.end.x and absf(p.y-wall_base_y(wall,p.x))<=7: return false
	for area in BUILDINGS+CARGO+[SHIPYARD,TIMBER,MARKET]:
		if area.has_point(p): return false
	for prop in PROPS:
		var base: Vector2=prop[3]
		if base!=Vector2.ZERO and Rect2(prop[1]-Vector2(base.x/2,base.y),base).has_point(p): return false
	return true

static func wall_base_y(area: Rect2,x: float) -> float:
	return lerpf(area.position.y,area.end.y,clampf((x-area.position.x)/area.size.x,0,1))

static func camera_target(p: Vector2) -> Vector2:
	# On the street, show the architecture above the heroes. On either pier,
	# smoothly return to the central framing so boats and footings stay visible.
	var screen_y:=lerpf(415,292,smoothstep(610,665,p.y))
	return Vector2(clampf(p.x-480,0,540),clampf(p.y-screen_y,40,360))

static func clear_segment(a: Vector2,b: Vector2) -> bool:
	var steps:=maxi(1,ceili(a.distance_to(b)/4))
	for i in range(steps+1):
		if not walkable(a.lerp(b,float(i)/steps)): return false
	return true

static func restore_position(p: Vector2) -> Vector2:
	if walkable(p): return p
	for radius in range(8,97,8):
		for direction in 32:
			var candidate:=p+Vector2.RIGHT.rotated(direction*TAU/32)*radius
			if walkable(candidate): return candidate
	return SPAWN

var navigation: AStarGrid2D
var follow_path:=PackedVector2Array()
var follow_target:=Vector2.INF

func build_navigation() -> void:
	if navigation!=null: return
	navigation=AStarGrid2D.new(); navigation.region=Rect2i(0,0,150,90)
	navigation.cell_size=Vector2(10,10); navigation.offset=Vector2(5,5)
	navigation.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_NEVER; navigation.update()
	for x in 150:
		for y in 90:
			var point:=Vector2(x*10+5,y*10+5); var supported:=walkable(point)
			for offset in [Vector2(-4,0),Vector2(4,0),Vector2(0,-4),Vector2(0,4)]: supported=supported and walkable(point+offset)
			navigation.set_point_solid(Vector2i(x,y),not supported)

func nearest_cell(p: Vector2) -> Vector2i:
	build_navigation()
	var centre:=Vector2i(floori(p.x/10),floori(p.y/10))
	var best:=Vector2i(-1,-1); var distance:=INF
	for dx in range(-3,4):
		for dy in range(-3,4):
			var cell:=centre+Vector2i(dx,dy)
			if navigation.is_in_boundsv(cell) and not navigation.is_point_solid(cell):
				var point:=navigation.get_point_position(cell)
				if point.distance_squared_to(p)<distance and clear_segment(p,point): best=cell; distance=point.distance_squared_to(p)
	return best

func route(a: Vector2,b: Vector2) -> PackedVector2Array:
	var start:=nearest_cell(a); var goal:=nearest_cell(b)
	if start.x<0 or goal.x<0: return PackedVector2Array()
	return navigation.get_point_path(start,goal)

func follow(from: Vector2,to: Vector2,delta: float) -> Vector2:
	if from.distance_to(to)<=30: return from
	if clear_segment(from,to):
		follow_path.clear()
		return from.move_toward(to,minf(delta*140,from.distance_to(to)-30))
	if follow_path.is_empty() or follow_target.distance_to(to)>35:
		follow_path=route(from,to); follow_target=to
	while not follow_path.is_empty() and from.distance_to(follow_path[0])<2: follow_path.remove_at(0)
	if follow_path.is_empty(): return from
	var next:=from.move_toward(follow_path[0],delta*140)
	return next if clear_segment(from,next) else from
