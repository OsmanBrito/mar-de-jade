extends SceneTree
const Blocks = preload("res://scripts/city/lisbon_blocks.gd")
class RouteDirector extends RefCounted:
	var world
var checks := 0
var failures: Array[String] = []
var world
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func frames(n: int = 4) -> void:
	for i in n: await process_frame
func walk(at: Vector2) -> bool:
	world.walk_to(at)
	for i in 2400:
		await physics_frame
		if world.player.position.distance_to(at)<12: return true
		if world.player.destination_path.is_empty(): break
	return false
func run() -> void:
	Engine.time_scale = 3.0
	var progress = root.get_node("ChapterProgress"); progress.auto_save = false; progress.reset()
	root.get_node("GamePreferences").persist_enabled = false
	root.get_node("CampaignProfile").hero_name = "Miguel"
	world = load("res://scenes/maps/praca_infancia.tscn").instantiate(); world.childhood = false
	root.add_child(world); await frames()
	world.player.enabled = true; world.player.set_physics_process(true); world.player.position = Blocks.MAIN_WALK[0]
	for at in Blocks.MAIN_WALK:
		check(world.point_clear(at),"Public route has character clearance at "+str(at))
		check(await walk(at),"Actual walking reaches the next place at "+str(at))
	check(world.player.position.distance_to(preload("res://scripts/city/lisbon_layout.gd").BOAT_ENTRY)<12,"The composed route ends on the embarkation pier")
	var director := RouteDirector.new(); director.world = world
	var routes = load("res://scripts/chapter/lisbon_routes.gd").new(director)
	# The service yard is now shallower: its former north strip is the public
	# doorstep lane of the new residential frontage, rather than a closed plot.
	check(world.point_clear(Vector2(1420,570)),"The reduced yard leaves the residential doorstep lane open")
	for at in [Vector2(-350,570),Vector2(1420,630)]:
		check(not world.is_walkable_point(at) and not world.point_clear(at),"Enclosed private parcels block navigation and physics")
		var old_visit := {"kind":"port_visit","target":16,"event":-1,"stage":"","area":"cais","position":[at.x,at.y]}
		check(preload("res://scripts/chapter/lisbon_journey_state.gd").valid(old_visit,16,{"embarked":true,"recovered":true}),"A saved shore visit on the former ground still validates")
		check(world.point_clear(routes.clear_point(at)),"Loading resolves an old private-plot position onto clear public ground")
	var from: Vector2i = world._nearest_id(world.player.position)
	for at in [Vector2(-770,65),Vector2(238,140),Vector2(650,1030),Vector2(492,927),Vector2(1318,960),Vector2(1645,650)]:
		var target: Vector2i = world._nearest_id(at)
		check(world.point_clear(at) and from.x>=0 and target.x>=0 and not world.navigation.get_point_path(from,target).is_empty(),"Campaign services and return remain reachable: "+str(at))
	world.childhood = true; world.rebuild_navigation()
	check(not world.is_walkable_point(Vector2(650,1030)),"The childhood boundary still restricts the waterfront")
	world.player.position = Vector2(-300,300)
	check(await walk(Vector2(-770,65)) and await walk(Vector2(238,140)),"Childhood still connects both house entrances")
	world.free(); await frames()
	print("LISBON_COMPOSITION_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
