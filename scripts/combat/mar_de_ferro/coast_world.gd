extends RefCounted
## Sheltered coastal passage with independent scenery and a continuous floor.
const SIZE:=Vector2(1500,900)
const GROUND_PATH:="res://assets/scenery/coast-ground-refined-v1.png"
const SPAWN := Vector2(140,430)
const NADIRA := Vector2(420,430)
const CONVOY := Vector2(790,430)
const YUSUF := Vector2(1320,430)
const ROCKS := [Rect2(85,325,230,55),Rect2(605,310,180,55),Rect2(980,305,245,60),Rect2(1050,565,160,55)]
const BUILDINGS:=[Rect2(355,330,185,55),Rect2(1260,310,135,60)]
const BUILDING_KEYS:=["ceuta-workshop","watchtower"]
const BUILDING_SIZES:=[Vector2(250,195),Vector2(215,300)]
const SHELTER_FOOT:=Vector2(470,555)
const SHELTER_SIZE:=Vector2(220,150)
const SHELTER_POSTS:=[Vector2(379,528),Vector2(528,551),Vector2(566,506),Vector2(435,480)]
const DOCK:=Rect2(740,650,120,120)
const DOCK_DRAW:=Rect2(718,638,164,165)
const TREES:=[[Vector2(310,540),.69],[Vector2(910,326),.72],[Vector2(1390,570),.62]]
const FAMILIES:=[Vector2(385,584),Vector2(550,595),Vector2(715,586)]
const PROPS:=[
	["barrel",Vector2(578,398),Vector2(26,32),Vector2(18,12)],
	["crate",Vector2(598,485),Vector2(30,28),Vector2(22,16)],
	["crate",Vector2(625,485),Vector2(30,28),Vector2(22,16)],
	["barrel",Vector2(585,513),Vector2(26,32),Vector2(18,12)],
	["bench",Vector2(404,606),Vector2(65,40),Vector2(52,12)],
	["nets",Vector2(563,622),Vector2(40,24),Vector2.ZERO],
	["nets",Vector2(894,636),Vector2(46,28),Vector2.ZERO],
	["barrel",Vector2(912,599),Vector2(26,32),Vector2(18,12)],
	["crate",Vector2(1330,535),Vector2(30,28),Vector2(22,16)],
	["barrel",Vector2(1360,535),Vector2(26,32),Vector2(18,12)]]

static func walkable(p: Vector2) -> bool:
	if DOCK.has_point(p): return true
	if not Rect2(75,220,1420,430).has_point(p): return false
	for r in ROCKS+BUILDINGS:
		if r.has_point(p): return false
	for point in SHELTER_POSTS:
		if p.distance_to(point)<5: return false
	for tree in TREES:
		if p.distance_to(tree[0])<9*tree[1]: return false
	for prop in PROPS:
		var base: Vector2=prop[3]
		if base!=Vector2.ZERO and Rect2(prop[1]-Vector2(base.x/2,base.y),base).has_point(p): return false
	return true

static func ground_uv(p: Vector2) -> Vector2:
	return p/SIZE

static func camera_target(p: Vector2) -> Vector2:
	var framing:=lerpf(405,292,smoothstep(650,745,p.y))
	return Vector2(clampf(p.x-480,0,540),clampf(p.y-framing,35,360))

static func clear_segment(a: Vector2,b: Vector2) -> bool:
	var steps:=maxi(1,ceili(a.distance_to(b)/4))
	for i in range(steps+1):
		if not walkable(a.lerp(b,float(i)/steps)): return false
	return true

static func restore_position(p: Vector2) -> Vector2:
	if walkable(p): return p
	for radius in range(8,129,8):
		for side in 32:
			var nearby:=p+Vector2.RIGHT.rotated(side*TAU/32)*radius
			if walkable(nearby): return nearby
	return SPAWN

static func nearby(p: Vector2, flags: Dictionary) -> String:
	if p.distance_to(SPAWN)<50: return "coast_return"
	if p.distance_to(NADIRA)<55:
		return "coast_agreement" if flags.coast_yusuf and not flags.coast_resolved else "coast_nadira"
	if p.distance_to(Vector2(470,580))<50: return "albergaria"
	if p.distance_to(Vector2(560,430))<45: return "regional_shop"
	if p.distance_to(CONVOY)<55 and not flags.coast_convoy: return "coast_convoy"
	if (p.distance_to(Vector2(800,610))<48 or DOCK.has_point(p)) and flags.coast_resolved: return "storm_depart"
	if p.distance_to(YUSUF)<55 and flags.coast_convoy and not flags.coast_yusuf: return "coast_yusuf"
	return ""

static func draw(host: Node2D, art, t: float, flags: Dictionary) -> void:
	art.regional.draw(9,t,flags)

	art.actor(NADIRA,"nadira",t)
	art.actor(Vector2(560,430),"merchant",t)
	art.actor(FAMILIES[0],"civilian",t)
	art.actor(FAMILIES[1],"tome",t,false,true)
	art.actor(FAMILIES[2],"beatriz",t)
	if not flags.coast_convoy: art.actor(CONVOY,"guard",t)
	if flags.coast_convoy and not flags.coast_yusuf: art.actor(YUSUF,"yusuf",t)
	host.world_marker(Vector2(150,370),"CAMINHO DE CEUTA",host.MUTED)
	host.world_marker(Vector2(413,373),"NADIRA",host.JADE)
	host.world_marker(Vector2(565,373),"PROVISÕES",host.GOLD)
	host.world_marker(Vector2(470,615),"ABRIGO · DESCANSO",host.JADE)
	host.world_marker(Vector2(790,373),"BATEL A SALVO" if flags.coast_convoy else "RETIRADA CIVIL",host.JADE if flags.coast_convoy else host.GOLD)
	if flags.coast_resolved: host.world_marker(Vector2(800,580),"EMBARQUE · MAR ABERTO",host.JADE)
	host.world_marker(Vector2(1320,373),"PASSAGEM LIVRE" if flags.coast_yusuf else "PASSAGEM DO SINAL",host.JADE if flags.coast_yusuf else host.GOLD)

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

