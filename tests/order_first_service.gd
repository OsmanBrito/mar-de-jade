extends SceneTree
var checks := 0
var failures: Array[String] = []
var game
var p
var Order
var Guide = preload("res://scripts/chapter/request_guide.gd")
func _initialize(): call_deferred("run")
func frames(n := 3):
	for i in n: await process_frame
func check(ok: bool,text: String):
	checks += 1
	if not ok: failures.append(text); push_error(text)
func walk(at: Vector2) -> bool:
	game.world.walk_to(at)
	for step in 1800:
		if game.world.player.position.distance_to(at)<35 and game.world.segment_clear(game.world.player.position,at): return true
		await physics_frame
		if game.world.player.destination_path.is_empty(): break
	return game.world.player.position.distance_to(at)<55 and game.world.segment_clear(game.world.player.position,at)
func drain():
	var city = game.harbor.city
	for i in 20:
		if game.phase!="local_dialogue" or city.cursor>=city.lines.size(): break
		city.advance()
func talk(id: String,action: String):
	var city = game.harbor.city
	if game.phase=="local_dialogue": city.close()
	check(await walk(city.approach(id)),"Real navigation reaches request target "+id)
	check(city.interact(id),"Nearby interaction opens "+id)
	drain()
	check(city.actions.any(func(a):return a[1]==action),"Expected request decision is offered: "+action)
	await city.choose(action)
	drain()
func run():
	Order = load("res://scripts/chapter/first_order_service.gd")
	Engine.time_scale = 6.0
	p = root.get_node("ChapterProgress"); p.auto_save = false; p.reset()
	root.get_node("GamePreferences").persist_enabled = false
	root.get_node("CampaignProfile").hero_name = "Miguel"
	p.vitals.hp = 64; p.vitals.qi = 3
	check(not Order.grant_supply(p,"missing"),"Invalid reserve is rejected")
	check(Order.grant_supply(p,"endurance") and p.inventory.has("PT-V02") and p.inventory.has("PT-C03"),"Travel reserve grants the described cloak and water")
	check(p.vitals.hp==64 and p.vitals.qi==3,"Receiving and equipping the reserve never heals")
	var inventory: Dictionary = p.inventory.duplicate()
	check(not Order.grant_supply(p,"protection") and p.inventory==inventory,"Changing or repeating reserve selection cannot duplicate rewards")
	p.reset(); p.flags.order_intro_started = true
	game = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate(); root.add_child(game); await frames()
	for i in 10:
		if game.phase=="styles": break
		game.advance()
	check(game.phase=="styles" and game.scene_index==0,"The first Order service teaches weapon choice before the quay")
	game._choose_lesson_weapon("FO")
	check(game.phase=="order_supply" and ["FO07","FO01","FO08","FO09"].all(func(id):return p.skills.has(id)),"Early firearm choice teaches all four techniques and opens service supplies")
	check(p.inventory.has("PT-W04") and p.equipment.weapon=="PT-W04","The chosen real weapon is owned and equipped")
	game.options_box.get_child(0).pressed.emit()
	check(p.flags.order_kit_received and p.equipment.outfit=="PT-V01","Protection reserve equips the advertised outfit")
	game._menu("Evolução"); await frames()
	check(game.player_menu.development_safe(),"Preparation allows organizing the six-slot repertoire")
	game._menu()
	game.options_box.get_child(game.options_box.get_child_count()-1).pressed.emit()
	for i in 5:
		if game.routes.active: break
		game.advance()
	check(game.routes.active and game.routes.state.kind=="order_check","The preparation leads to a physical visit to the infirmary")
	var walker = load("res://tests/lisbon_walk_driver.gd").new()
	check(await walker.reach(game),"Walks through the portaria and cloister to the infirmary without teleportation")
	check(game.phase=="order_inspection","Reaching the supplies opens a real service decision")
	game.routes.save(); var saved: Dictionary = p.snapshot()
	check(p.restore(saved,false)==OK,"An infirmary journey is a valid persistent checkpoint")
	saved.flags.order_delivery_prefix = true; saved.flags.delivery_finished = true; saved.flags.delivery_pending = false; saved.journey.event += 3
	check(p.restore(saved)==OK,"Completed flour delivery preserves the three leading events in new-service saves")
	game._load_block(0,false,true); await frames()
	check(game.routes.active and game.routes.state.kind=="order_check" and game.events[game.event_index].type=="order_check","Reload restores the same service event and place")
	game.routes.interact()
	Order.finish_check(game,"linen")
	check(p.flags.get("order_check_done",false) and p.choices.get("order_service","")=="linen","The performed check records the player's service choice")
	check(game.routes.active and game.routes.state.kind=="order_report","Inspection requires a separate return and report to Duarte")
	check(await walker.reach(game),"Walks back to Duarte in the exterior courtyard")
	check(p.flags.get("order_reported",false),"Duarte receives the report before the rescue story begins")
	check(p.flags.get("house_adult_done",false) and p.flags.get("house_adult_review",false),"The first service fulfils the adult house review instead of offering the same chore twice")
	check(not Order.notes(p).is_empty(),"The service and the house's role remain readable in the journal")
	game.free(); await frames()
	p.flags.patient_helped = true
	game = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate(); game.start_block = 3; root.add_child(game); await frames()
	game.event_index = game.events.size()-1; game.current_event = game.events[game.event_index]
	Order.help_offer(game); game.options_box.get_child(0).pressed.emit()
	check(game.routes.state.kind=="order_help" and Order.help_target(game).id=="workshop","Duarte introduces the optional request at its actual giver")
	check(game.routes.objective().contains("opcional") or game.routes.objective().contains("retomar"),"The guided request explains how to resume the main mission")
	await talk("workshop","accept")
	check(Guide.target_id(p,"C01-LIS-01")=="cart","Accepted request tracks inspection of the cart")
	await talk("cart","diagnose")
	check(Guide.target_id(p,"C01-LIS-01")=="dock","Diagnosis tracks the worker who owns the missing part")
	await talk("dock","take_part")
	check(Guide.target_id(p,"C01-LIS-01")=="cart","Receiving the part tracks the repair site")
	await talk("cart","repair")
	await game.harbor.city.choose("finish_repair"); drain()
	check(Guide.target_id(p,"C01-LIS-01")=="workshop","The repaired cart still requires returning to its giver")
	await talk("workshop","claim")
	check(Order.Requests.stage(p)=="completed" and Guide.target_id(p,"C01-LIS-01").is_empty(),"Claimed reward clears the completed request's guidance")
	game.harbor.city.close()
	check(Order.help_target(game).id=="duarte","Duarte becomes the return target after the optional service")
	check(await walk(game.routes.goal),"The report point remains physically reachable after repairing the cart")
	game.routes.interact("goal")
	check(p.flags.get("order_help_reported",false),"The optional service receives a return report")
	check(not p.choices.has("tracked_request"),"Returning to the main mission clears secondary guidance")
	check(game.phase=="order_report_dialogue" and game.view.body.text.contains("O carro voltou"),"Duarte visibly acknowledges the finished service before continuing")
	game.options_box.get_child(0).pressed.emit()
	var after: Dictionary = p.inventory.duplicate(); var coins: int = p.coins
	check(not Order.Requests.claim(p) and p.inventory==after and p.coins==coins,"Completed secondary reward is not repeatable")
	p.local_requests["C01-LIS-02"]="kitchen"
	check(Guide.target_id(p,"C01-LIS-02")=="neighbor","Delivery-account guidance points to the cook for its current stage")
	p.local_requests["C01-LIS-03"]="prepare"; p.inventory.erase("PT-C03")
	check(Guide.target_id(p,"C01-LIS-03")=="shop","Missing kit supplies point to the shop")
	p.inventory["PT-C03"]=1
	check(Guide.target_id(p,"C01-LIS-03")=="dock","A complete kit points back to its inspector")

	# Leaving the accompanied request never deletes its progress or keeps its arrow active.
	p.local_requests["C01-LIS-01"] = "parts"; p.flags.erase("order_help_reported")
	game._load_block(3); game.event_index = game.events.size()-1; game.current_event = game.events[game.event_index]
	Order.help_offer(game); game.options_box.get_child(0).pressed.emit()
	p.choices.tracked_request = "C01-LIS-01"; game.routes.save()
	check(p.restore(p.snapshot(),false)==OK,"The accompanied secondary saves its actual event and position")
	var corrupt: Dictionary = p.snapshot(); corrupt.journey.event = 90
	check(p.restore(corrupt,false)==ERR_INVALID_DATA,"A forged service cursor cannot skip into another story event")
	game._menu("Pedidos"); game.player_menu.stop_tracking()
	check(game.phase=="order_report_dialogue" and p.local_requests["C01-LIS-01"]=="parts","Deferring preserves the missing-part stage and gives an explicit Duarte reply")
	game.options_box.get_child(0).pressed.emit()
	check(not p.choices.has("tracked_request") and game.routes.active and game.routes.state.kind=="block","Continuing switches guidance back to the main mission")
	var npc = load("res://scripts/npcs/lisbon_npc_library.gd").data().duarte
	var battle = load("res://scripts/combat/portugal_actor_art.gd").data().duarte
	check(npc.source.ends_with("duarte-order-v2.png") and npc.frames.size()==20,"Exploration uses twenty newly illustrated Order costume poses")
	check(battle.source.ends_with("duarte-order-v2.png") and battle.frames.size()==9,"Combat uses its own nine new Order costume poses")
	var portrait = load("res://scripts/chapter/dialogue_portraits.gd").portrait("duarte")
	check(portrait!=null and portrait.atlas!=null,"Duarte has a matching Order costume portrait")
	game.free(); await frames()
	p.reset(); p.flags.delivery_finished=true
	game = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate(); root.add_child(game); await frames()
	check(not game.events.any(func(e):return e.type=="order_check"),"An older in-progress save without the intro flag preserves its original event indices")
	game.free(); await frames()
	print("ORDER_FIRST_SERVICE_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
