extends RefCounted
## Madeira pilot: one authored plan shared by art, routes, actors and saves.
const REVISION := 1
const SIZE := Vector2(1600,1600)
const GROUND_PATH := "res://assets/scenery/madeira-ground-polished-v2.png"
const SPAWN := Vector2(320,1180)
const INN := Vector2(390,650)
const MARKET := Vector2(790,890)
const RUI := Vector2(970,755)
const MARTIM := Vector2(675,1070)
const VIGIA := Vector2(1380,1165)
const CARGO := Vector2(1040,1200)
const REFUGE := Vector2(1170,1190)
const LOOKOUT := Vector2(1100,400)
const MEMORIAL := Vector2(650,1040)
const CHART_TABLE := Vector2(970,810)
const MARKER_VIEW := Rect2(20,78,920,393)
const BEACH_FACE := [Vector2(370,1112),Vector2(420,1120),Vector2(520,1135),Vector2(620,1148),Vector2(720,1160),Vector2(810,1173),Vector2(870,1188),Vector2(920,1190),Vector2(975,1197),Vector2(985,1230),Vector2(950,1250),Vector2(870,1240),Vector2(810,1225),Vector2(720,1213),Vector2(620,1207),Vector2(520,1200),Vector2(420,1173),Vector2(380,1145)]
# Key, ground anchor, illustration size, solid contact footprint (zero = soft detail).
const WORK_PROPS := [
	["pots",Vector2(295,614),Vector2(37,40),Vector2(18,10)],
	["pots",Vector2(452,610),Vector2(37,40),Vector2(18,10)],
	["pots",Vector2(820,455),Vector2(37,40),Vector2(18,10)],
	["pots",Vector2(1222,815),Vector2(37,40),Vector2(18,10)],
	["crate",Vector2(559,1010),Vector2(32,30),Vector2(22,16)],
	["crate",Vector2(590,1027),Vector2(32,30),Vector2(22,16)],
	["crate",Vector2(1070,1190),Vector2(32,30),Vector2(22,16)],
	["crate",Vector2(1100,1205),Vector2(32,30),Vector2(22,16)],
	["barrel",Vector2(374,1056),Vector2(26,32),Vector2(18,12)],
	["barrel",Vector2(414,1064),Vector2(26,32),Vector2(18,12)],
	["barrel",Vector2(1310,1190),Vector2(26,32),Vector2(18,12)],
	["nets",Vector2(480,1055),Vector2(65,36),Vector2.ZERO],
	["cart",Vector2(1178,810),Vector2(80,64),Vector2(58,15)],
	["bench",Vector2(1060,470),Vector2(84,52),Vector2(76,14)],
	["nets",Vector2(533,1245),Vector2(46,28),Vector2.ZERO],
	["nets",Vector2(1120,1125),Vector2(48,28),Vector2.ZERO],
	["crate",Vector2(610,850),Vector2(28,26),Vector2(22,16)],
	["bench",MEMORIAL+Vector2(-15,0),Vector2(86,55),Vector2(76,14)],
	["chart-table",CHART_TABLE,Vector2(86,61),Vector2(72,18)]
]

static func marker_bounds(at: Vector2,width: float) -> Rect2:
	return Rect2(at-Vector2(width/2+7,14),Vector2(width+14,32))

static func marker_fits(at: Vector2,width: float) -> bool:
	return MARKER_VIEW.encloses(marker_bounds(at,width))
const LAND := [Vector2(530,145),Vector2(1065,145),Vector2(1110,225),Vector2(1160,180),Vector2(1220,140),Vector2(1440,140),Vector2(1470,390),Vector2(1400,540),Vector2(1480,760),Vector2(1470,1040),Vector2(1475,1100),Vector2(1435,1275),Vector2(1395,1290),Vector2(1295,1240),Vector2(1110,1215),Vector2(1010,1280),Vector2(950,1330),Vector2(795,1390),Vector2(690,1410),Vector2(550,1390),Vector2(385,1320),Vector2(280,1280),Vector2(200,1190),Vector2(140,1120),Vector2(120,980),Vector2(135,770),Vector2(100,655),Vector2(115,450),Vector2(205,390),Vector2(310,390),Vector2(415,430),Vector2(480,440),Vector2(485,245)]
# Ground footprints exclude the roof and upper floors. The larger facades rise
# above these bases rather than blocking the entire height of their illustration.
const BUILDINGS := [Rect2(220,483,230,92),Rect2(475,518,190,72),Rect2(658,344,164,76),Rect2(845,328,240,92),Rect2(1072,695,236,85),Rect2(573,785,94,40),Rect2(740.5,813,104,42),Rect2(350,933,195,72)]
const BUILDING_KEYS := ["house_limestone","workshop","house_teal","house_limestone","warehouse","market","market","workshop"]
# Visible size, after transparent margins are excluded. Doors were measured in
# the original cutouts; a 51–54px adult fits beneath a 58–67px domestic doorway.
const BUILDING_SIZES := [Vector2(285,301),Vector2(220,178),Vector2(204,301),Vector2(285,301),Vector2(275,234),Vector2(105,100),Vector2(115,110),Vector2(220,178)]
const ACTOR_HEIGHTS := {"duarte":54.0,"ines":52.0,"civilian":52.0,"worker":54.0,"merchant":52.0,"sailor":54.0,"rui":53.0,"martim":51.0}
# Opaque head-to-sole heights in idle frame 0, excluding external equipment.
const ACTOR_SOURCE_HEIGHTS := {"duarte":193.0,"ines":196.0,"civilian":206.0,"worker":202.0,"merchant":193.0,"sailor":203.0,"rui":204.0,"martim":205.0}

static func actor_scale(kind: String, fallback: float) -> float:
	return ACTOR_HEIGHTS[kind]/(ACTOR_SOURCE_HEIGHTS[kind]*0.15) if ACTOR_HEIGHTS.has(kind) else fallback
const LEDGES := [Rect2(558,200,20,310),Rect2(580,510,120,25),Rect2(795,510,345,25),Rect2(1220,510,105,25)]
const GARDENS := [Rect2(275,700,165,82),Rect2(1030,895,158,84)]
const DOCKS := [Rect2(270,1250,75,185),Rect2(1340,1190,75,185),Rect2(990,1185,75,185)]
const STAIRS := [Rect2(700,465,95,95),Rect2(1140,465,80,95)]
const FOREST := [Vector2(1230,135),Vector2(1440,165),Vector2(1470,435),Vector2(1360,615),Vector2(1230,545),Vector2(1170,340)]
const PATHS := [
	[68,[Vector2(320,1360),SPAWN,Vector2(365,1040),Vector2(480,890),Vector2(505,700),INN]],
	[72,[INN,Vector2(565,650),Vector2(655,680),Vector2(725,910),MARKET,Vector2(935,880),RUI]],
	[60,[Vector2(505,700),Vector2(570,600),Vector2(740,560),Vector2(747,480),Vector2(845,465),Vector2(1065,450),LOOKOUT]],
	[50,[Vector2(1065,450),Vector2(1180,530),Vector2(1210,610),Vector2(1280,830),Vector2(1305,1000),VIGIA,Vector2(1385,1240)]],
	[68,[MARKET,Vector2(810,1030),Vector2(730,1110),Vector2(890,1140),CARGO,REFUGE,Vector2(1260,1180),VIGIA]],
	[45,[Vector2(365,1040),Vector2(490,1095),MARTIM,Vector2(730,1110)]],
	[46,[RUI,Vector2(1040,835),Vector2(1170,835),Vector2(1280,830)]],
	[42,[Vector2(740,560),Vector2(660,620),Vector2(655,680)]]
]
const TREES := [
	[Vector2(190,550),1.2],[Vector2(205,420),.9],[Vector2(155,670),1.1],[Vector2(235,840),.73],
	[Vector2(540,225),1.2],[Vector2(605,260),.83],[Vector2(580,335),.87],
	[Vector2(1210,208),1.3],[Vector2(1300,235),1.1],[Vector2(1400,210),1.22],[Vector2(1460,290),.93],
	[Vector2(1250,345),1.1],[Vector2(1330,367),1.35],[Vector2(1440,393),1.13],[Vector2(1270,475),.8],
	[Vector2(1330,560),1.22],[Vector2(1420,527),1.05],[Vector2(1380,680),.97],
	[Vector2(169,776),1.15],[Vector2(220,845),.85],[Vector2(325,851),.72],
	[Vector2(944,634),.9],[Vector2(877,667),.73],[Vector2(984,988),.85],[Vector2(1052,1030),.65],
	[Vector2(1230,990),.84],[Vector2(1290,1040),.66],[Vector2(420,1290),.81]
]

static func land_polygon() -> PackedVector2Array: return PackedVector2Array(LAND)
static var ground_mask: Image
static func painted_land(p: Vector2) -> bool:
	if ground_mask==null:
		var terrain: Texture2D=load(GROUND_PATH)
		ground_mask=terrain.get_image()
	var pixel:=Vector2i(p/SIZE*Vector2(ground_mask.get_size()))
	if not Rect2i(Vector2i.ZERO,ground_mask.get_size()).has_point(pixel): return false
	return ground_mask.get_pixelv(pixel).a>.98
static func walkable(p: Vector2) -> bool:
	var on_land:=Geometry2D.is_point_in_polygon(p,land_polygon())
	var on_dock: bool=DOCKS.any(func(area): return area.has_point(p))
	if not on_land and not on_dock: return false
	if not on_dock and not painted_land(p): return false
	if p.x<105 or p.x>1495 or p.y<140 or p.y>1490: return false
	for area in BUILDINGS+LEDGES+GARDENS:
		if area.has_point(p): return false
	if Geometry2D.is_point_in_polygon(p,PackedVector2Array(BEACH_FACE)): return false
	for prop in WORK_PROPS:
		var base: Vector2=prop[3]
		if base!=Vector2.ZERO and Rect2(prop[1]-Vector2(base.x/2,base.y),base).has_point(p): return false
	for tree in TREES:
		if p.distance_to(tree[0])<9*tree[1]: return false
	return true

static func camera_target(p: Vector2) -> Vector2:
	# Show the village ahead of the traveller; the full adult stays above the HUD.
	var framing:=lerpf(350,415,smoothstep(500,700,p.y))
	# Ease the view towards the boats on the eastern waterfront, without a snap.
	var harbour:=smoothstep(1030,1200,p.y)*smoothstep(900,1050,p.x)
	framing=lerpf(framing,292,harbour)
	return Vector2(clampf(p.x-480,0,SIZE.x-960),clampf(p.y-framing,0,SIZE.y-540))

static func at_boarding(p: Vector2, dock_index: int, shore: Vector2, radius: float) -> bool:
	# The same journey is available beside its pilot and along its actual deck.
	return p.distance_to(shore)<radius or DOCKS[dock_index].has_point(p)

static func restore_position(p: Vector2) -> Vector2:
	if walkable(p): return p
	# Saves from the first pilot may stand on a newly solid rock face or prop.
	# Recover beside that spot instead of sending the traveller back to arrival.
	for radius in range(8,81,8):
		for side in 32:
			var nearby:=p+Vector2.RIGHT.rotated(side*TAU/32)*radius
			if walkable(nearby): return nearby
	return SPAWN

static func migrate_position(old: Vector2) -> Vector2:
	var anchors: Array=[[Vector2(245,420),INN],[Vector2(460,420),MARKET],[Vector2(610,485),RUI],[Vector2(700,572),MARTIM],[Vector2(950,620),CARGO],[Vector2(1190,615),REFUGE],[Vector2(1370,610),VIGIA],[Vector2(175,620),SPAWN]]
	var closest: Array=anchors[0]
	for pair in anchors:
		if old.distance_to(pair[0])<old.distance_to(closest[0]): closest=pair
	return closest[1]

# A companion must take the stairways and go around buildings on this larger map.
# The grid is built once. Short unobstructed stretches keep continuous movement.
var navigation: AStarGrid2D
var follow_path:=PackedVector2Array()
var follow_target:=Vector2(-1000,-1000)

func build_navigation() -> void:
	if navigation!=null: return
	navigation=AStarGrid2D.new()
	navigation.region=Rect2i(0,0,80,80)
	navigation.cell_size=Vector2(20,20); navigation.offset=Vector2(10,10)
	navigation.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_NEVER
	navigation.update()
	for x in 80:
		for y in 80:
			var p:=Vector2(x*20+10,y*20+10)
			var clear:=walkable(p)
			for offset in [Vector2(-7,0),Vector2(7,0),Vector2(0,-7),Vector2(0,7)]:
				clear=clear and walkable(p+offset)
			navigation.set_point_solid(Vector2i(x,y),not clear)

func nearest_cell(p: Vector2) -> Vector2i:
	build_navigation()
	var candidate:=Vector2i(floori(p.x/20),floori(p.y/20))
	var closest:=Vector2i(-1,-1); var distance:=INF
	for dx in range(-3,4):
		for dy in range(-3,4):
			var cell:=candidate+Vector2i(dx,dy)
			if navigation.is_in_boundsv(cell) and not navigation.is_point_solid(cell):
				var point:=navigation.get_point_position(cell)
				if point.distance_squared_to(p)<distance and clear_segment(p,point):
					closest=cell; distance=point.distance_squared_to(p)
	return closest

static func clear_segment(a: Vector2,b: Vector2) -> bool:
	var steps:=maxi(1,ceili(a.distance_to(b)/5))
	for i in range(steps+1):
		if not walkable(a.lerp(b,float(i)/steps)): return false
	return true

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

static func guide(canvas: Node2D) -> void:
	canvas.draw_rect(Rect2(Vector2.ZERO,SIZE),Color("277e96"))
	canvas.draw_colored_polygon(land_polygon(),Color("729356"))
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(270,1080),Vector2(470,1060),Vector2(640,1150),Vector2(880,1180),Vector2(990,1210),Vector2(970,1250),Vector2(760,1420),Vector2(560,1460),Vector2(370,1420),Vector2(220,1310)]),Color("dcc398"))
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(570,155),Vector2(1120,165),Vector2(1235,340),Vector2(1240,510),Vector2(575,510)]),Color("adc08e"))
	canvas.draw_colored_polygon(PackedVector2Array(FOREST),Color("436c44"))
	for area in LEDGES: canvas.draw_rect(area,Color("7e8370"))
	for area in STAIRS:
		canvas.draw_rect(area,Color("c7c7a9"))
		for y in range(int(area.position.y),int(area.end.y),12): canvas.draw_line(Vector2(area.position.x,y),Vector2(area.end.x,y),Color("898f78"),3)
	for spec in PATHS:
		var curve:=Curve2D.new(); curve.bake_interval=12
		for i in spec[1].size():
			var previous: Vector2=spec[1][maxi(i-1,0)]; var next: Vector2=spec[1][mini(i+1,spec[1].size()-1)]
			curve.add_point(spec[1][i],-(next-previous)/6,(next-previous)/6)
		canvas.draw_polyline(curve.get_baked_points(),Color("c0b296"),spec[0],true)
	canvas.draw_circle(MARKET+Vector2(0,20),120,Color("c8c1a0"))
	for area in BUILDINGS: canvas.draw_rect(area,Color("a39b77"))
	for area in GARDENS:
		canvas.draw_rect(area,Color("665c40"))
		for y in range(int(area.position.y)+10,int(area.end.y),18): canvas.draw_line(Vector2(area.position.x+8,y),Vector2(area.end.x-8,y),Color("64813f"),5)

