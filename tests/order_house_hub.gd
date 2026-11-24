extends SceneTree
var game
var p
var Hub
var checks := 0
var failures: Array[String] = []
func _initialize(): call_deferred("run")
func frames(n := 3):
	for i in n: await process_frame
func check(ok: bool,text: String):
	checks+=1
	if not ok: failures.append(text);push_error(text)
func walk(at: Vector2) -> bool:
	game.world.walk_to(at)
	for i in 2400:
		await physics_frame
		if game.world.player.position.distance_to(at)<15:return true
		if game.world.player.destination_path.is_empty():break
	return false
func visit(id: String):
	game.routes.resume()
	check(await walk(Hub.ROWS[id].at),"Physical navigation reaches "+id)
	game.routes.interact("house:"+id)
	check(game.phase=="order_inspection","Interaction opens "+id)
func run():
	Hub=load("res://scripts/city/order_house_hub.gd")
	Engine.time_scale=6
	p=root.get_node("ChapterProgress");p.auto_save=false;p.reset();p.flags.delivery_pending=true
	root.get_node("GamePreferences").persist_enabled=false
	root.get_node("CampaignProfile").hero_name="Miguel"
	game=load("res://scenes/chapter_01/chapter_flow.tscn").instantiate();root.add_child(game);await frames()
	game.routes.load_area("convent",Vector2(0,825));game.routes.resume();await frames()
	for id in Hub.ROWS:await visit(id)
	await visit("kitchen")
	game.options_box.get_child(0).pressed.emit()
	check(Hub.meal_stage(p)=="asked" and p.choices.tracked_request=="ORDER-MEAL","Kitchen button accepts and tracks service")
	await visit("preparation")
	Hub.act(game,"preparation","meal_short")
	check(Hub.meal_stage(p)=="asked","Incomplete preparation cannot advance")
	Hub.act(game,"refectory","meal_finish")
	check(Hub.meal_stage(p)=="asked","Remote delivery cannot grant reward")
	Hub.act(game,"preparation","meal_prepare")
	check(Hub.meal_stage(p)=="prepared","Four portions advance objective")
	check(p.save_to("user://hub-test.json")==OK and p.load_from("user://hub-test.json")==OK and Hub.meal_stage(p)=="prepared","Service stage and tracked objective survive reload")
	var before: int=p.inventory.get("PT-C02",0)
	var xp_before: int=p.development.members.hero.xp
	await visit("refectory")
	game.options_box.get_child(0).pressed.emit()
	check(Hub.meal_stage(p)=="done" and p.inventory.get("PT-C02",0)==before+1,"Delivery grants one ration")
	check(p.development.members.hero.xp==xp_before+25,"Service grants exactly 25 journey XP")
	var snapshot: Dictionary=p.snapshot()
	Hub.act(game,"refectory","meal_finish")
	check(p.snapshot()==snapshot,"Repeated delivery grants nothing")
	check(not p.choices.has("tracked_request"),"Completed service clears navigation")
	await visit("armory")
	var cursor: int=game.event_index
	game.options_box.get_child(0).pressed.emit();await frames()
	check(game.menu_open and game.player_menu.screen.visible and game.player_menu.development_safe(),"Armory equipment opens a safe preparation menu")
	game._menu();await frames()
	check(game.phase=="order_inspection" and game.event_index==cursor,"Closing equipment returns to the same inspection")
	p.learn("ES07")
	var route: Dictionary=game.routes.state.duplicate(true)
	var resources: Dictionary=p.vitals.duplicate()
	game.begin_order_practice();await frames()
	check(game.order_practice_return and game.battle_host.combat.mode=="practice","Armory starts borrowed practice")
	game._practice_aborted();await frames()
	check(not game.order_practice_return and game.phase=="roaming" and game.routes.state==route and p.vitals==resources,"Abort returns to same journey with personal resources")
	await visit("armory");game.begin_order_practice();await frames();game._battle_finished(true);await frames()
	check(game.phase=="roaming" and p.vitals==resources and game.routes.state==route,"Completed practice preserves resources and story")
	await visit("armory");p.flags.injured=true;game.begin_order_practice()
	check(not game.order_practice_return,"Injury prevents practice")
	game.free();await frames()
	print("ORDER_HOUSE_HUB_RESULT ",JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
