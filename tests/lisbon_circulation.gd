extends SceneTree
const Layout = preload("res://scripts/city/lisbon_layout.gd")
const District = preload("res://scripts/chapter/lisbon_district.gd")
const Errands = preload("res://scripts/chapter/lisbon_errands.gd")
const SAVE := "user://qa-circulation.json"
var game
var p
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func frames(n: int = 4) -> void:
	for i in n: await process_frame
func walk(at: Vector2) -> bool:
	game.world.walk_to(at)
	for i in 2600:
		await physics_frame
		if game.world.player.position.distance_to(at)<15: return true
		if game.world.player.destination_path.is_empty(): break
	return false
func drain() -> void:
	for i in 100:
		if game.phase!="local_dialogue" or game.harbor.city.cursor>=game.harbor.city.lines.size(): break
		game.advance()
func interact(id: String) -> void:
	check(await walk(game.harbor.city.approach(id)),"Real walk reaches "+id)
	check(game.harbor.city.interact(id),"Physical proximity opens "+id)
	drain(); await frames(1)
func choose(action: String) -> void:
	game.harbor.city.choose(action)
	for i in 500:
		if not game.busy: break
		await physics_frame
	drain(); await frames()
func close() -> void:
	game.harbor.city.close()
	await frames()
func capture(id: String) -> void:
	if DisplayServer.get_name()=="headless": return
	DirAccess.make_dir_recursive_absolute("res://.qa-runtime/circulation-preview")
	game.world.player.camera.reset_smoothing()
	await frames(8); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.qa-runtime/circulation-preview/"+id+".png")
func mount(restored: bool = false) -> void:
	game = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate(); game.start_block = 3; root.add_child(game); await frames()
	if not restored: game.routes.begin("block",4)
	check(game.routes.active and game.phase=="roaming","The optional activities share the normal free city route")
func run() -> void:
	Engine.time_scale = 3; root.size = Vector2i(1440,900)
	p = root.get_node("ChapterProgress"); p.auto_save = false; p.reset()
	root.get_node("CampaignProfile").hero_name = "Miguel"
	p.flags.patient_helped = true; p.flags.recovered = true; p.flags.meal = false
	await mount()
	var world = game.world
	var main_goal: String = game.routes.goal_label
	check(Layout.paving_surface().size()>8 and Layout.streets().size()==2,"Paving includes two connected alternative streets")
	for path in [Layout.WEST_STREET,Layout.EAST_STREET]:
		for at in path:
			check(world.point_clear(at),"Street centre has real character clearance: "+str(at))
	# Walk the western descent, front quay and eastern return: one actual loop.
	for at in Layout.WEST_STREET: check(await walk(at),"Actual western street walk: "+str(at))
	await capture("west-street")
	check(await walk(Vector2(650,1030)),"The western street reconnects to the market")
	var east: Array = Layout.EAST_STREET.duplicate(); east.reverse()
	for at in east: check(await walk(at),"Actual eastern street return: "+str(at))
	await capture("east-street")
	check(game.world==world and game.routes.goal_label==main_goal and not p.flags.meal,"Alternative streets do not reload the exterior or advance the meal")
	# Observations can be collected in either order, before accepting the request.
	await interact("mooring"); await close()
	check(Errands.stage(p,Errands.BATEL)=="" and p.flags.lisbon_rope_read,"An observation does not silently accept a request")
	await interact("keeper"); await choose("district_accept"); await close()
	check(Errands.stage(p,Errands.BATEL)=="observe","The pier request starts with observation")
	await interact("tide"); await close()
	check(Errands.stage(p,Errands.BATEL)=="solve","The two independent clues unlock a decision")
	await interact("mooring"); await choose("district_tighten")
	check(Errands.stage(p,Errands.BATEL)=="solve" and p.coins==0,"An incorrect interpretation explains itself without granting rewards")
	await close(); await interact("mooring")
	var boat_before: Vector2 = world.sorted_world.get_node("Batel").position
	await choose("district_finish")
	check(Errands.stage(p,Errands.BATEL)=="completed" and p.coins==6,"The pier activity completes and pays exactly once at the object")
	check(world.sorted_world.get_node("Batel").position.distance_to(boat_before)>100,"The batel visibly leaves its tight berth")
	await capture("batel-completed")
	await close(); await interact("mooring"); await choose("district_finish")
	check(p.coins==6,"Repeating a completed interaction cannot duplicate its reward")
	await close()
	p.local_requests[Errands.ACCOUNT] = "dock"
	await interact("manifest"); await capture("warehouse-receipt"); await choose("district_receipt"); await close()
	check(Errands.stage(p,Errands.ACCOUNT)=="reconcile","A physical pair of receipts replaces the repeated NPC trip")
	await interact("fisher"); await choose("account_reconcile"); await close()
	check(p.coins==14 and Errands.stage(p,Errands.ACCOUNT)=="completed","The existing request keeps its original resolution and unique reward")
	p.local_requests[Errands.KIT] = "prepare"; p.local_requests["C01-LIS-01"] = "inspect"
	check(p.local_requests.size()==4 and p.save_to(SAVE)==OK,"All four Lisbon requests coexist in the same save")
	var saved: Dictionary = p.snapshot(); game.free(); await frames(); p.reset()
	check(p.load_from(SAVE)==OK and p.snapshot()==saved,"New route positions, observations, choices and rewards round trip")
	await mount(true); world = game.world
	check(world.sorted_world.get_node("Batel").position.distance_to(boat_before)>100,"Returning to the city reapplies the completed physical consequence")
	check(await walk(District.TARGETS.manifest.approach),"The eastern warehouse receipt is reachable after loading")
	game._menu("Pedidos"); await frames()
	var text := ""
	for label in game.player_menu.listing.find_children("*","Label",true,false): text += label.text
	check(text.contains("A maré e a amarra") and text.contains("Lugares conhecidos · Ribeira"),"The journal includes the new request and reusable observations")
	game._menu(); game.free(); await frames()
	var child = load("res://scenes/maps/praca_infancia.tscn").instantiate(); child.childhood = true; root.add_child(child); await frames()
	check(not child.is_walkable_point(Vector2(-900,700)) and not child.is_walkable_point(Vector2(1660,700)),"Childhood cannot escape to the new adult streets")
	check(not child.sorted_world.get_node("MarinheiroDoBatel").visible,"The adult pier activity does not populate the childhood route")
	child.free(); await frames()
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(SAVE+suffix): DirAccess.remove_absolute(SAVE+suffix)
	print("LISBON_CIRCULATION_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
