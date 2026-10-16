extends RefCounted
## Peaceful home grounds share one stable layout across testimony, wedding and epilogue.
const SIZE:=Vector2(1500,900)
const GROUND_PATH:="res://assets/scenery/order-ground-refined-v1.png"
# Measured UV rows align the painted clearings with the preserved story sites.
const GROUND_ROWS:=[Vector2(0,0),Vector2(300,190),Vector2(700,590),Vector2(900,900)]
const SPAWN:=Vector2(300,580)
const HOME:=Vector2(650,430)
const BENCH:=Vector2(960,580)
const LETTER:=Vector2(1180,430)
const HALL_BASE:=Rect2(500,310,300,80)
const HALL_FOOT:=Vector2(650,390)
const HALL_SIZE:=Vector2(360,280)
const LETTER_FOOT:=Vector2(1180,405)
const MEMORIAL_FOOT:=Vector2(960,550)
const GARDEN:=[Vector2(100,350),Vector2(300,290),Vector2(1400,290),Vector2(1460,400),Vector2(1430,650),Vector2(1320,680),Vector2(300,680),Vector2(100,620)]
static var garden_polygon:=PackedVector2Array(GARDEN)
const SOLIDS:=[HALL_BASE,Rect2(1150,382,60,23),Rect2(920,538,80,12),Rect2(505,508,70,12),Rect2(725,508,70,12),Rect2(1250,563,60,12),Rect2(725,442,50,18)]
const TREES:=[
	[Vector2(210,440),Vector2(150,185)],
	[Vector2(370,300),Vector2(115,145)],
	[Vector2(1050,430),Vector2(150,185)],
	[Vector2(1140,280),Vector2(120,150)],
	[Vector2(1380,560),Vector2(145,180)]]
const POTS:=[Vector2(454,410),Vector2(842,410),Vector2(898,550),Vector2(1240,415),Vector2(1335,635)]
const SEATS:=[Vector2(540,520),Vector2(760,520),Vector2(1280,575)]

static func walkable(p: Vector2) -> bool:
	if not Geometry2D.is_point_in_polygon(p,garden_polygon): return false
	for solid in SOLIDS:
		if solid.has_point(p): return false
	for tree in TREES:
		if Rect2(tree[0]-Vector2(10,13),Vector2(20,13)).has_point(p): return false
	for foot in POTS:
		if Rect2(foot-Vector2(12,10),Vector2(24,10)).has_point(p): return false
	return true

static func camera_target(p: Vector2) -> Vector2:
	return Vector2(clampf(p.x-480,0,540),clampf(p.y-350,45,310))

static func ground_uv(p: Vector2) -> Vector2:
	for i in range(1,GROUND_ROWS.size()):
		if p.y<=GROUND_ROWS[i].x:
			var start: Vector2=GROUND_ROWS[i-1]; var end: Vector2=GROUND_ROWS[i]
			return Vector2(p.x/SIZE.x,lerpf(start.y,end.y,inverse_lerp(start.x,end.x,p.y))/SIZE.y)
	return p/SIZE

static func clear_segment(a: Vector2,b: Vector2) -> bool:
	if not walkable(a) or not walkable(b): return false
	# The garden boundary is convex. Test furniture continuously: sparse samples
	# can miss a bench corner and make the follower alternate routes forever.
	for solid in SOLIDS:
		if crosses_rect(a,b,solid): return false
	for tree in TREES:
		if crosses_rect(a,b,Rect2(tree[0]-Vector2(10,13),Vector2(20,13))): return false
	for foot in POTS:
		if crosses_rect(a,b,Rect2(foot-Vector2(12,10),Vector2(24,10))): return false
	return true

static func crosses_rect(a: Vector2,b: Vector2,rect: Rect2) -> bool:
	var direction:=b-a
	var near:=0.0; var far:=1.0
	for axis in 2:
		if absf(direction[axis])<.00001:
			if a[axis]<=rect.position[axis] or a[axis]>=rect.end[axis]: return false
		else:
			var first: float=(rect.position[axis]-a[axis])/direction[axis]
			var last: float=(rect.end[axis]-a[axis])/direction[axis]
			near=maxf(near,minf(first,last)); far=minf(far,maxf(first,last))
			if far<=near: return false
	return far>near

static func restore_position(p: Vector2) -> Vector2:
	if walkable(p): return p
	for radius in range(8,129,8):
		for side in 32:
			var nearby:=p+Vector2.RIGHT.rotated(side*TAU/32)*radius
			if walkable(nearby): return nearby
	return SPAWN

static func draw(host,art,t: float,f: Dictionary) -> void:
	art.regional.draw(11,t,f)
	art.actor(Vector2(705,440),"rui",t)
	art.actor(Vector2(570,440),"samira",t)
	art.actor(Vector2(465,465),"beatriz",t)
	if f.final_wedding and not f.epilogue_seen:
		art.actor(Vector2(825,470),"tome",t)
		art.actor(Vector2(492,552),"leonor",t)
	host.world_marker(Vector2(650,315),"ORDEM · REABERTA" if f.final_testimony else "ORDEM DAS MARÉS",host.JADE)
	if f.final_testimony: host.world_marker(Vector2(1180,340),"CARTA DE NADIRA",host.JADE)
	if f.epilogue_seen: host.world_marker(Vector2(960,495),"O BANCO DE MARTIM",host.MUTED)

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

