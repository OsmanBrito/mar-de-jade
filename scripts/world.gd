@tool
extends Node2D
## A disposable map presentation; campaign state is owned by the session.
signal interaction_requested(definition: Dictionary)
const Player = preload("res://scripts/player.gd")
@export var map_id: String = "cais"
@export var player_scene: PackedScene
var spec: Dictionary
var terrain: TileMapLayer
var sorted_world: Node2D
var player: CharacterBody2D
var interactions: Array[Node2D] = []
var closest: Node2D
var cells: Dictionary = {}
var blockers: Array[PackedVector2Array] = []
var astar = AStar2D.new()
var point_ids: Dictionary = {}
var click_mark: Vector2 = Vector2.ZERO
var click_time: float = 0.0
var sea: ColorRect
var map_ready: bool = false

func _ready() -> void:
	spec = JSON.parse_string(FileAccess.get_file_as_string("res://data/%s.json"%map_id))
	_build_backdrop()
	terrain = get_node("Ground")
	sorted_world = get_node("ActorsAndProps")
	_refresh_ground()
	if map_id == "abrigo_adulto":
		preload("res://scripts/chapter/shelter_details.gd").install(self)
	_collect_authored_nodes(sorted_world)
	if Engine.is_editor_hint():
		terrain.changed.connect(_refresh_ground)
		queue_redraw()
		return
	player = player_scene.instantiate() if player_scene != null else Player.new()
	player.name = "Traveller"
	player.world = self
	player.position = get_node("Spawn").position
	sorted_world.add_child(player)
	_build_navigation()
	map_ready = true
	queue_redraw()

func cell_position(cell: Array) -> Vector2:
	return terrain.map_to_local(Vector2i(int(cell[0]),int(cell[1])))

func _refresh_ground() -> void:
	cells.clear()
	for cell in terrain.get_used_cells():
		var atlas = terrain.get_cell_atlas_coords(cell)
		cells[cell] = atlas.x+atlas.y*2
	queue_redraw()

func _build_backdrop() -> void:
	sea = ColorRect.new()
	sea.position = Vector2(-5000,-4000)
	sea.size = Vector2(10000,8000)
	sea.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sea.z_index = -20
	var shader = Shader.new()
	shader.code = """
shader_type canvas_item;
uniform bool exterior = true;
void fragment() {
  vec2 p = UV * vec2(10000.0,8000.0);
  float swell = sin(p.x*0.009+p.y*0.015+TIME*0.32);
  float ripples = sin(p.x*0.08-p.y*0.11+TIME*0.8)*sin(p.y*0.07+TIME*0.25);
  float streak = pow(max(0.0,sin(p.x*0.021+p.y*0.12+TIME*0.55)),18.0);
  vec3 deep = vec3(0.07,0.23,0.25);
  vec3 jade = vec3(0.19,0.40,0.38);
  vec3 ocean = mix(deep,jade,0.48+swell*0.18+ripples*0.05);
  ocean += vec3(0.20,0.25,0.18)*streak*0.12;
  COLOR = vec4(exterior ? ocean : vec3(0.085,0.105,0.095),1.0);
}
"""
	var material = ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("exterior",spec["exterior"])
	sea.material = material
	add_child(sea)

func _collect_authored_nodes(node: Node) -> void:
	# Navigation reads the same edited polygons used by the physics bodies.
	if node is CollisionPolygon2D:
		var polygon = PackedVector2Array()
		for vertex in node.polygon:
			polygon.append(to_local(node.to_global(vertex)))
		blockers.append(polygon)
	if node.get_script() == preload("res://scripts/interaction.gd"):
		interactions.append(node)
	for child in node.get_children():
		_collect_authored_nodes(child)

func _build_navigation() -> void:
	var id = 0
	for cell in cells:
		var point = terrain.map_to_local(cell)
		var blocked = false
		for polygon in blockers:
			if Geometry2D.is_point_in_polygon(point,polygon):
				blocked = true
		if not blocked:
			point_ids[cell] = id
			astar.add_point(id,point)
			id += 1
	for cell in point_ids:
		for offset in [Vector2i(1,0),Vector2i(0,1)]:
			var neighbor = cell+offset
			if point_ids.has(neighbor):
				# Reject segments through a footprint, even when both cell centres are free.
				var start = terrain.map_to_local(cell)
				var end = terrain.map_to_local(neighbor)
				var clear = true
				for step in range(1,8):
					var check = start.lerp(end,float(step)/8.0)
					for polygon in blockers:
						if Geometry2D.is_point_in_polygon(check,polygon):
							clear = false
				if clear:
					astar.connect_points(point_ids[cell],point_ids[neighbor])

func walk_to(point: Vector2) -> void:
	var cell = terrain.local_to_map(point)
	if not point_ids.has(cell) or not is_walkable_point(point) or astar.get_point_count() == 0:
		return
	var start = astar.get_closest_point(player.position)
	var path = astar.get_point_path(start,point_ids[cell])
	if path.is_empty():
		return
	# A path can begin at a centre behind the player; skip that unnecessary backtrack.
	if path.size() > 1 and path[0].distance_to(player.position) < 55:
		path.remove_at(0)
	path.append(point)
	player.follow_path(path)
	click_mark = point
	click_time = 1.1

func is_walkable_point(point: Vector2) -> bool:
	return cells.has(terrain.local_to_map(point))

func safe_spawn(point: Vector2) -> Vector2:
	if is_walkable_point(point):
		var blocked = false
		for polygon in blockers:
			if Geometry2D.is_point_in_polygon(point,polygon):
				blocked = true
		if not blocked:
			return point
	return get_node("Spawn").position

func interact() -> void:
	_update_closest()
	if closest != null:
		interaction_requested.emit(closest.definition)

func _process(delta: float) -> void:
	if not map_ready:
		return
	_update_closest()
	click_time = maxf(0,click_time-delta)
	queue_redraw()

func _update_closest() -> void:
	closest = null
	var best_distance = INF
	for object in interactions:
		var distance = player.position.distance_to(object.position)
		if distance < best_distance and distance < object.interact_radius:
			closest = object
			best_distance = distance
	for object in interactions:
		object.highlighted = object == closest

func _draw() -> void:
	if terrain == null:
		return
	# Stone quay retaining walls / wooden pier edges, visible on exposed near edges.
	var city_ground := get_node_or_null("CityGround") as TileMapLayer
	for cell in ({} if has_meta("departure_deck") else cells):
		var pos = terrain.map_to_local(cell)
		var tile = int(cells[cell])
		for side in range(2):
			var neighbor = cell + (Vector2i(1,0) if side == 0 else Vector2i(0,1))
			if cells.has(neighbor):
				continue
			# An exploration boundary inside the city is not a shoreline or a raised platform.
			if city_ground != null and city_ground.get_cell_source_id(neighbor)>=0:
				continue
			var a = pos + (Vector2(64,0) if side == 0 else Vector2(0,32))
			var b = pos + (Vector2(0,32) if side == 0 else Vector2(-64,0))
			if has_meta("living_quay") and tile != 1:
				preload("res://scripts/chapter/quay_bank.gd").draw(self,a,b)
				continue
			var depth = 18.0 if tile != 1 else 9.0
			var color = Color("736653") if side == 0 else Color("544f43")
			if tile == 1:
				color = Color("5e4936")
			draw_colored_polygon(PackedVector2Array([a,b,b+Vector2(0,depth),a+Vector2(0,depth)]),color)
			draw_line(a+Vector2(0,depth),b+Vector2(0,depth),Color(0.24,0.43,0.40,0.6),3)
	if not spec.get("exterior",true):
		_draw_interior_walls()
	if click_time > 0:
		draw_set_transform(click_mark,0,Vector2(1,0.5))
		draw_arc(Vector2.ZERO,14+(1.1-click_time)*6,0,TAU,32,Color(0.95,0.85,0.6,click_time/1.1),1.5)
		draw_set_transform(Vector2.ZERO)

func _draw_interior_walls() -> void:
	if map_id == "abrigo_adulto":
		preload("res://scripts/chapter/shelter_details.gd").draw_walls(self,terrain,Vector2i(8,7))
		return
	var size = spec["land_size"]
	var corner = terrain.map_to_local(Vector2i(0,0))+Vector2(0,-32)
	var left = terrain.map_to_local(Vector2i(0,int(size[1])-1))+Vector2(-64,0)
	var right = terrain.map_to_local(Vector2i(int(size[0])-1,0))+Vector2(64,0)
	var height = Vector2(0,-125)
	draw_colored_polygon(PackedVector2Array([left,corner,corner+height,left+height]),Color("b8aa89"))
	draw_colored_polygon(PackedVector2Array([corner,right,right+height,corner+height]),Color("cbbd9a"))
	draw_line(left+height,corner+height,Color("695a40"),8)
	draw_line(corner+height,right+height,Color("776246"),8)
	for side in [left,right]:
		for i in range(1,5):
			var point = corner.lerp(side,float(i)/5)
			draw_line(point,point+height,Color("8b795b"),7)
