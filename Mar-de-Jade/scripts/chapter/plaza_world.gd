@tool
extends "res://scripts/world.gd"
## Dense click navigation for this tutorial; physics uses the same authored footprints.
const CLEARANCE := 14.0 # Approved 12px actor radius plus contact margin.
const STEP := 16.0
var navigation := AStarGrid2D.new()

func rebuild_navigation() -> void:
	blockers.clear()
	interactions.clear()
	_collect_authored_nodes(sorted_world)
	_build_navigation()

func point_clear(point: Vector2) -> bool:
	if not is_walkable_point(point):
		return false
	for direction in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
		if not is_walkable_point(point+direction*CLEARANCE):
			return false
	for polygon in blockers:
		if Geometry2D.is_point_in_polygon(point,polygon):
			return false
		for edge in polygon.size():
			var closest_point = Geometry2D.get_closest_point_to_segment(point,polygon[edge],polygon[(edge+1)%polygon.size()])
			if point.distance_to(closest_point) < CLEARANCE:
				return false
	return true

func segment_clear(start: Vector2, end: Vector2) -> bool:
	var steps = maxi(1,ceili(start.distance_to(end)/6.0))
	for i in range(steps+1):
		if not point_clear(start.lerp(end,float(i)/steps)):
			return false
	return true

func _build_navigation() -> void:
	var bounds := Rect2(terrain.map_to_local(terrain.get_used_cells()[0]),Vector2.ZERO)
	for cell in cells:
		bounds = bounds.expand(terrain.map_to_local(cell))
	bounds = bounds.grow(64)
	navigation.region = Rect2i(Vector2i.ZERO,Vector2i(ceili(bounds.size.x/STEP)+1,ceili(bounds.size.y/STEP)+1))
	navigation.cell_size = Vector2.ONE*STEP
	navigation.offset = bounds.position
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	navigation.update()
	for y in navigation.region.size.y:
		for x in navigation.region.size.x:
			var id := Vector2i(x,y)
			navigation.set_point_solid(id,not point_clear(navigation.get_point_position(id)))

func _nearest_id(point: Vector2) -> Vector2i:
	var base := Vector2i(((point-navigation.offset)/STEP).round())
	var best := Vector2i(-1,-1)
	var distance := INF
	for y in range(-3,4):
		for x in range(-3,4):
			var id := base+Vector2i(x,y)
			if not navigation.region.has_point(id) or navigation.is_point_solid(id):
				continue
			var candidate = navigation.get_point_position(id)
			if point.distance_to(candidate) < distance and segment_clear(point,candidate):
				best = id
				distance = point.distance_to(candidate)
	return best

func walk_to(point: Vector2) -> void:
	if not player.enabled or not point_clear(point):
		return
	var start = _nearest_id(player.position)
	var end = _nearest_id(point)
	if start.x < 0 or end.x < 0:
		return
	var path = navigation.get_point_path(start,end)
	if path.is_empty():
		return
	path.append(point)
	var simplified := PackedVector2Array()
	var cursor: Vector2 = player.position
	var index := 0
	while index < path.size():
		var farthest := index
		for candidate in range(index,path.size()):
			if segment_clear(cursor,path[candidate]):
				farthest = candidate
			else:
				break
		simplified.append(path[farthest])
		cursor = path[farthest]
		index = farthest+1
	player.follow_path(simplified)
	click_mark = point
	click_time = 1.1
