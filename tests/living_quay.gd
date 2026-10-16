extends SceneTree
var failures: Array[String] = []
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func frames(n: int) -> void:
	for i in n: await process_frame
func capture(path: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
func run() -> void:
	var game = load("res://scenes/art/composed_quay_study.tscn").instantiate(); root.add_child(game)
	await frames(10)
	var world = game.world
	check(world.point_clear(world.player.position),"Spawn clear of authored footprints")
	var city: TileMapLayer = world.get_node("CityGround")
	for cell in [Vector2i(1,4),Vector2i(7,-2),Vector2i(7,18)]:
		check(city.get_cell_source_id(cell)>=0,"City continues beyond the exploration boundary: "+str(cell))
	check(city.get_cell_source_id(Vector2i(21,4))<0,"River remains on the waterfront side of the continuous bank")
	var residents: Array = []
	for child in world.sorted_world.get_children():
		if child.get_script()==preload("res://scripts/chapter/quay_resident.gd"):
			residents.append(child)
			check(world.point_clear(child.position),"Resident starts on clear ground: "+str(child.name))
			for point in child.route:
				check(world._nearest_id(point).x>=0,"Resident workstation reachable: "+str(child.name)+" "+str(point))
	Engine.time_scale = 4.0
	for i in 180: await physics_frame
	var moved := 0
	for npc in residents:
		if npc.distance_walked>25: moved += 1
		else: print("RESIDENT_STALLED ",npc.name," ",npc.position," route ",npc.route_index," distance ",npc.distance_walked)
		check(world.is_walkable_point(npc.position),"Ambient movement stays on land: "+str(npc.name))
	check(moved==residents.size(),"Every resident performs an errand: "+str(moved)+"/"+str(residents.size()))
	Engine.time_scale = 1.0
	game.set_overview(true); await frames(5); await capture("res://docs/cais-vivo-overview.png")
	game.set_overview(false); world.player.position = Vector2(420,760); world.player.camera.reset_smoothing(); await frames(5); await capture("res://docs/cais-vivo-rua.png")
	world.player.position = world.get_node("Spawn").position
	Engine.time_scale = 4.0
	for target in [Vector2(502,877),Vector2(407,929.5),Vector2(612,752),Vector2(1002,1037)]:
		world.walk_to(target)
		check(not world.player.destination_path.is_empty(),"Click route exists to "+str(target))
		for i in 800:
			await physics_frame
			if world.player.destination_path.is_empty(): break
		check(world.player.position.distance_to(target)<14,"Player physically reaches "+str(target)+" at "+str(world.player.position))
	check(world.player.camera.offset.y>30,"Walking onto the pier reframes towards the boat and the waterline")
	world.player.enabled = false
	world.player.camera.offset = Vector2(120,65)
	for i in 10: await physics_frame
	check(world.player.camera.offset==Vector2(120,65),"Dialogue framing is preserved while movement is locked")
	check(not world.point_clear(Vector2(1600,1400)),"River cannot be selected as walkable ground")
	game.free(); await frames(2)
	print("LIVING_QUAY_RESULT "+JSON.stringify({"checks":checks,"failures":failures,"moving_residents":moved}))
	quit(0 if failures.is_empty() else 1)
