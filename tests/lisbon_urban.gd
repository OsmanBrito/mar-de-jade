extends SceneTree
## Physical traversal of the new city block, every public frontage, both docks
## and original service destinations. No screenshot-quality assertions.
const Urban = preload("res://scripts/city/lisbon_urban_plan.gd")
const Layout = preload("res://scripts/city/lisbon_layout.gd")
const Access = preload("res://scripts/city/lisbon_access.gd")
var checks := 0
var failures: Array[String] = []
var world
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func walk(at: Vector2) -> bool:
	if not world.point_clear(at): return false
	world.walk_to(at)
	for i in 3000:
		await physics_frame
		if world.player.position.distance_to(at)<12: return true
		if world.player.destination_path.is_empty(): break
	return false
func run() -> void:
	Engine.time_scale = 3
	root.get_node("ChapterProgress").auto_save = false
	root.get_node("ChapterProgress").reset()
	root.get_node("GamePreferences").persist_enabled = false
	world = load("res://scenes/maps/praca_infancia.tscn").instantiate(); world.childhood = false
	root.add_child(world)
	for i in 5: await process_frame
	world.player.enabled = true; world.player.position = Vector2(180,420)
	check(await walk(Layout.CONVENT_ENTRY),"Civic entrance connects to the new street")
	for at in Urban.NEIGHBORHOOD_WALK:
		check(await walk(at),"Actual traversal of the residential street: "+str(at))
	for row in Urban.FRONTAGES:
		var house = world.sorted_world.get_node(row[0])
		check(not world.point_clear(row[2]-Vector2(0,20)),"The visible building base is solid: "+str(row[0]))
		var query := PhysicsPointQueryParameters2D.new(); query.position = row[2]-Vector2(0,20); query.collision_mask = 1
		check(not world.get_world_2d().direct_space_state.intersect_point(query).is_empty(),"Physical collision agrees with the logical base: "+str(row[0]))
		var native: Vector2 = house.texture.get_size()
		check(is_equal_approx(house.size.x/house.size.y,native.x/native.y),"Native architectural aspect ratio: "+str(row[0]))
		# The first two houses are behind the closed northern block, approached
		# from its private court. Every public-facing door has a real public route.
		if row not in Urban.FRONTAGES.slice(0,2):
			check(await walk(row[2]+Vector2(0,35)),"Public door is physically reachable: "+str(row[0]))
	for id in Access.rows(false):
		check(await walk(Access.ROWS[id].at),"Original door access survives: "+str(id))
	for at in [Vector2(650,1030),Vector2(492,927),Layout.WORKSHOP,Layout.CART_HOME+Vector2(0,45),Vector2(1645,650),Layout.BOAT_ENTRY,Vector2(-485,1185),Vector2(-465,1055),Vector2(-900,570)]:
		check(await walk(at),"Market, harbor and return remain connected: "+str(at))
	world.childhood = true; world.rebuild_navigation(); world.player.position = Vector2(180,420)
	check(not world.is_walkable_point(Vector2(950,305)),"New neighborhood does not bypass the childhood boundary")
	check(await walk(Layout.ROOM_ENTRY) and await walk(Layout.CONVENT_ENTRY),"Both childhood entrances survive the city enclosure")
	world.free()
	print("LISBON_URBAN_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
