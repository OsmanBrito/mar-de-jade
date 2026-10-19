extends SceneTree
const Walk = preload("res://tests/lisbon_walk_driver.gd")
const CombatDriver = preload("res://tests/chapter_driver.gd")
var game
var failures: Array[String] = []
var checks := 0
var captured: Dictionary = {}
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func frames(n: int = 2) -> void:
	for i in n: await process_frame
func walk(point: Vector2,radius: float = 58) -> bool:
	for offset in [Vector2.ZERO,Vector2(-40,30),Vector2(40,30),Vector2(0,45)]:
		if not game.world.point_clear(point+offset): continue
		game.world.walk_to(point+offset)
		for i in 1800:
			await physics_frame
			if game.world.player.position.distance_to(point)<radius: return true
			if game.world.player.destination_path.is_empty(): break
	return game.world.player.position.distance_to(point)<radius
func capture(name: String) -> void:
	if DisplayServer.get_name()=="headless" or not "--capture" in OS.get_cmdline_user_args() or captured.has(name): return
	captured[name] = true; DirAccess.make_dir_recursive_absolute("res://.qa-runtime/city-preview")
	await frames(5); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.qa-runtime/city-preview/"+name+".png")
func run() -> void:
	Engine.time_scale = 3.0; root.size = Vector2i(1440,900)
	var p = root.get_node("ChapterProgress"); p.auto_save = false; p.reset(); p.flags.delivery_pending = true
	root.get_node("CampaignProfile").hero_name = "Miguel"
	game = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate(); root.add_child(game); await frames()
	check(game.map_kind=="room" and game.phase=="roaming","The playable adult journey starts at the convent")
	var exterior_id := 0; var was_outside := false; var exterior_reloads := 0
	var approach_restored := false
	var driver = CombatDriver.new(); var encounters: Array[String] = []
	for step in 8000:
		var outside: bool = game.world.has_meta("continuous_lisbon")
		if outside and was_outside and exterior_id!=game.world.get_instance_id(): exterior_reloads += 1
		if outside: exterior_id = game.world.get_instance_id()
		was_outside = outside
		if game.routes.active and game.routes.safe_city() and p.flags.get("patient_helped",false): break
		if game.busy: await physics_frame; continue
		match game.phase:
			"dialogue","block_end": game.advance()
			"choice": game.choose(game.choice_event.options[0].id)
			"delivery_choice": game._deliver(true)
			"roaming":
				if not approach_restored and game.routes.state.kind=="block" and int(game.routes.state.target)==1:
					approach_restored = true; game.routes.save()
					check(p.save_to("res://.qa-runtime/city-state.json")==OK,"The walk towards the accident saves before the encounter")
					check(p.load_from("res://.qa-runtime/city-state.json")==OK,"The approach reloads with its narrative checkpoint")
					game._load_block(p.checkpoint,false,true); await frames()
					check(game.actors.has("Trabalhador ferido") and game.actors["Trabalhador ferido"].visible and game.actors.Duarte.visible,"Resuming the approach keeps Duarte and the accident visible before interaction")
				if game.routes.continuous():
					if game.routes.area()=="cais": await capture("ribeira")
					else: await capture("convento")
				var reached: bool = await Walk.new().reach(game)
				check(reached,"Walks to the actual commitment: "+str(game.routes.state.get("kind",game.phase)))
				if not reached: break
			"task":
				var reached: bool = await walk(game.props.marker)
				check(reached,"Physical approach to "+game.task_id)
				if not reached: break
				game.interact_task()
			"battle":
				if not encounters.has(game.battle_host.combat.mode): encounters.append(game.battle_host.combat.mode)
				driver.drive(game.battle_host)
		await frames(1)
	check(p.flags.get("delivery_finished",false),"The kitchen delivery completes in the new city")
	check(p.flags.get("knot",false),"Returning to the same courtyard preserves the child's approved knot task")
	check(p.flags.get("cargo_freed",false) and p.flags.get("fetch_tome",false) and p.flags.get("patient_helped",false),"The player frees the worker, fetches Tomé and completes ordinary treatment")
	check(encounters.is_empty(),"Delivery and rescue proceed without mandatory training with Duarte")
	check(exterior_reloads==0,"Outdoor story changes retain the same city instance; interiors remain separate")
	check(p.coins==40 and p.payments==["cais_service"],"The rescue payment remains single and shared")
	check(game.routes.active and game.routes.safe_city() and not game.harbor.city.residents.is_empty(),"The same Ribeira opens its residents, requests and shop after treatment")
	await capture("socorro-concluido")
	check(p.save_to("res://.qa-runtime/city-state.json")==OK,"The continuous route can be saved")
	var expected: Dictionary = p.snapshot(); p.reset()
	check(p.load_from("res://.qa-runtime/city-state.json")==OK and p.snapshot()==expected,"City location, objective, flags and economy round-trip")
	game.queue_free(); await frames()
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists("res://.qa-runtime/city-state.json"+suffix): DirAccess.remove_absolute("res://.qa-runtime/city-state.json"+suffix)
	print("LISBON_CITY_CAMPAIGN_RESULT ",JSON.stringify({"checks":checks,"failures":failures,"exterior_reloads":exterior_reloads,"encounters":encounters}))
	quit(0 if failures.is_empty() else 1)
