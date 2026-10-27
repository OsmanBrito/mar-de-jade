extends SceneTree
var checks := 0
var failures: Array[String]=[]
var game
var p
var Order
func _initialize():call_deferred("run")
func check(ok: bool,message: String):
	checks+=1
	if not ok:failures.append(message);push_error(message)
func frames(n:=3):
	for i in n:await process_frame
func capture(id: String):
	if DisplayServer.get_name()=="headless" or not "--capture" in OS.get_cmdline_user_args():return
	DirAccess.make_dir_recursive_absolute("res://.qa-runtime/order-completion")
	await frames(12);await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.qa-runtime/order-completion/"+id+".png")
func walk(at: Vector2) -> bool:
	game.world.walk_to(at)
	for i in 2600:
		await physics_frame
		if game.world.player.position.distance_to(at)<15:return true
		if game.world.player.destination_path.is_empty():break
	return false
func visit(id: String):
	game.routes.resume()
	var rows: Dictionary=load("res://scripts/city/house_life.gd").rows(game.world)
	check(await walk(rows[id].at),"Actual walk reaches "+id)
	game.routes.interact("house:"+id)
	check(game.phase=="order_inspection","Nearby interaction opens "+id)
func door(to: String):
	game.routes.resume()
	if to=="convent" and game.world.has_meta("continuous_lisbon"):
		check(await walk(load("res://scripts/city/lisbon_layout.gd").CONVENT_ENTRY),"Walks from the Ribeira to the convent forecourt")
		game.routes.update(0);await frames()
	for exit in game.routes.exits:
		if exit.to==to:
			check(await walk(exit.point),"Actual walk reaches door "+to);game.routes.interact("exit:"+to);await frames();return
	check(false,"Missing door "+to)
func run():
	Order=load("res://scripts/chapter/order_campaign.gd");Engine.time_scale=6
	p=root.get_node("ChapterProgress");p.auto_save=false;p.reset();p.flags.delivery_pending=true;p.flags.house_adult_done=true
	root.get_node("GamePreferences").persist_enabled=false;root.get_node("CampaignProfile").hero_name="Miguel"
	game=load("res://scenes/chapter_01/chapter_flow.tscn").instantiate();root.add_child(game);await frames()
	game.routes.load_area("convent",Vector2(0,825));game.routes.resume();await frames()
	var original_event: int=game.event_index
	# Free combat is available after learning a weapon, before the audience.
	p.learn("ES07")
	await visit("services")
	Order.act(game,"services","order:training_track")
	check(game.phase=="roaming" and p.choices.get("tracked_request","")=="ORDER-PRACTICE","Services can guide the player to free combat without an audience")
	check(game.routes.guide_target()==Vector2(-850,920) and game.routes.objective().contains("Treino livre"),"Training guidance and objective point to the actual armory")
	check(p.save_to("user://leadership.json")==OK and p.load_from("user://leadership.json")==OK,"Training destination survives save and reload")
	await visit("armory")
	var early_resources: Dictionary=p.vitals.duplicate()
	var early_xp: int=p.development.members.hero.xp
	load("res://scripts/city/order_house_hub.gd").act(game,"armory","practice");await frames()
	check(game.order_practice_return and game.battle_host.combat.mode=="practice" and not p.flags.get("order_audience_done",false),"Nearby armory button starts real combat before institutional permission")
	check(not p.choices.has("tracked_request"),"Arriving at free combat clears its temporary guidance")
	game._practice_aborted();await frames()
	check(game.phase=="roaming" and p.vitals==early_resources and p.development.members.hero.xp==early_xp and game.event_index==original_event,"Leaving early combat preserves resources, XP and the story cursor")
	await visit("registry")
	game.begin_order_practice()
	check(not game.order_practice_return and game.phase=="order_inspection","Free combat cannot be invoked remotely from another station")
	await visit("grandmaster")
	check(game.world.sorted_world.get_node("GraoMestre").npc_id=="order_grandmaster","Grand Master uses original costume")
	game.options_box.get_child(0).pressed.emit()
	check(p.flags.get("order_audience_done",false),"Audience button authorizes studies")
	var before_topics: Dictionary=p.snapshot()
	for offered in Order.leader_topics(p):
		var topic: String=offered[1].trim_prefix("order:voice:")
		Order.act(game,"grandmaster","order:voice:"+topic)
		check(game.view.body.text==Order.LEADER_TOPICS[topic].text,"Grand Master speaks authored topic "+topic)
	var after_topics: Dictionary=p.snapshot()
	before_topics.erase("dialogue_history"); after_topics.erase("dialogue_history")
	check(after_topics==before_topics,"Talking to leader only records dialogue without advancing quests or awarding resources")
	Order.act(game,"grandmaster","order:back")
	check(not Order.talk(game.world,p,"grandmaster").actions.any(func(action):return action[1]=="order:cargo_accept") and not game.view.body.text.contains("depois do socorro"),"Before the rescue the audience does not reveal or offer the later emergency delivery")
	Order.act(game,"grandmaster","order:cargo_accept")
	check(Order.cargo_stage(p).is_empty(),"An unoffered future delivery cannot be accepted by invoking its action")
	p.flags.patient_helped=true
	Order.act(game,"grandmaster","order:cargo_accept")
	check(Order.cargo_stage(p)=="ledger" and p.choices.tracked_request=="ORDER-CARGO","Mission starts with physical archive objective")
	var original_coins: int=p.coins
	Order.act(game,"grandmaster","order:cargo_report")
	check(p.coins==original_coins and not p.flags.get("order_cargo_done",false),"Report without evidence grants nothing")
	await visit("order_ledger");Order.act(game,"order_ledger","order:ledger")
	check(Order.cargo_stage(p)=="manifest","Archive advances objective to dock manifest")
	check(p.save_to("user://leadership.json")==OK and p.load_from("user://leadership.json")==OK,"Chapter-room position and institutional progress survive save/load")
	await door("square")
	await visit("order_manifest");Order.act(game,"order_manifest","order:manifest")
	check(game.world.sorted_world.has_node("OrderCargoManifest/Documents"),"Dock manifest has a visible desk and documents instead of an empty marker")
	check(game.view.speaker.text==Order.CITY_ROWS.order_manifest.title,"Mission response identifies its physical station instead of the studies menu")
	await capture("manifesto-no-pontao")
	check(Order.cargo_stage(p)=="recipient","Manifest points to actual recipient")
	await visit("order_recipient");Order.act(game,"order_recipient","order:recipient")
	check(Order.cargo_stage(p)=="report","Three sources unlock report")
	await door("convent");await visit("commander")
	Order.act(game,"commander","order:cargo_replace")
	check(Order.cargo_stage(p)=="report" and p.coins==original_coins and game.view.body.text.contains("retirou o pedido"),"Duplicate resupply is refused using the recipient's evidence and can be reconsidered")
	Order.act(game,"commander","order:cargo_accuse")
	check(Order.cargo_stage(p)=="report" and p.coins==original_coins,"Unsupported accusation explains evidence without rewarding")
	Order.act(game,"commander","order:cargo_report")
	check(Order.cargo_stage(p)=="done" and p.coins==original_coins+40,"Commander accepts correct report and grants forty gold")
	await capture("entrega-urgente-confirmada")
	var snapshot: Dictionary=p.snapshot();Order.act(game,"commander","order:cargo_report")
	check(p.snapshot()==snapshot,"Repeated report does not duplicate reward")
	check(not p.choices.has("tracked_request"),"Completed investigation clears tracked destination")
	p.learn("ES07")
	await visit("registry")
	Order.act(game,"registry","order:catalog")
	check(game.menu_open and game.player_menu.page=="Técnicas","Catalogue opens the unified technique menu")
	game._menu()
	Order.act(game,"registry","order:view:ES09")
	check(game.view.speaker.text=="Guarda Cruzada","Legacy technique detail remains available")
	Order.act(game,"registry","order:purchase:ES09")
	check(not Order.purchased(p,"ES09"),"Purchase without confirmation is rejected")
	Order.act(game,"registry","order:confirm:ES09")
	game.options_box.get_child(0).pressed.emit()
	check(Order.purchased(p,"ES09") and p.coins==original_coins+10 and not p.skills.has("ES09"),"Confirmed purchase deducts thirty and records an unlearned manual")
	snapshot=p.snapshot();Order.act(game,"registry","order:purchase:ES09")
	check(p.snapshot()==snapshot,"Stale confirmation cannot charge twice")
	await visit("armory")
	Order.act(game,"armory","order:learn:ES09")
	check(not p.skills.has("ES09"),"Manual alone cannot bypass orientation exercise")
	var resources: Dictionary=p.vitals.duplicate();var journey: Dictionary=game.routes.state.duplicate(true)
	Order.act(game,"armory","order:trial");await frames()
	check(game.order_trial_return and game.battle_host.combat.mode=="order_trial","Physical trainer starts real orientation battle")
	game._practice_aborted();await frames()
	check(game.phase=="roaming" and p.vitals==resources and game.routes.state==journey and not p.flags.get("order_trial_done",false),"Abort returns with resources and mission intact")
	await visit("armory");Order.act(game,"armory","order:trial");await frames()
	var c=game.battle_host.combat;game.battle_host.set_process(false);c.obstacles.clear()
	check(not c.move_to(Vector2i(4,4)).is_empty() and c.order_trial_positioned,"Real move reaches protected position")
	c.move_to(Vector2i(4,5));c.units[0].acted=false
	var result: Dictionary=c.perform(0,c.units[2].cell,1)
	check(not result.has("error") and c.valid_hits>0,"Chosen weapon lands an actual valid hit")
	c.end_turn(1);c.current_id=2
	var plan: Dictionary=c.ai_plan()
	check(plan.kind=="attack" and plan.targets.has(0),"Instructor makes an actual controlled attack")
	c.resolve_enemy(plan,{0:1})
	check(c.order_trial_defended and c.lesson_result().finished,"Good frontal response completes exercise without Perfect requirement")
	game._battle_finished(true);await frames();game.battle_host.set_process(true)
	check(p.flags.get("order_trial_done",false) and p.vitals==resources and game.routes.state==journey,"Completion grants finite study access without story/resource changes")
	await visit("armory")
	var slots: Array=p.development.members.hero.active_skills.duplicate()
	Order.act(game,"armory","order:learn:ES09")
	check(p.skills.has("ES09") and p.development.members.hero.active_skills==slots,"Studying learns executable skill while preserving prepared repertoire")
	p.learn("LA07");await visit("registry")
	Order.act(game,"registry","order:free:LA09");game.options_box.get_child(0).pressed.emit()
	check(Order.purchased(p,"LA09") and p.flags.order_voucher_used and p.coins==original_coins+10,"First study voucher replaces payment exactly once")
	check(not Order.purchase_reason(p,"MC09",true).is_empty(),"Used voucher cannot purchase another study")
	check(p.save_to("user://leadership.json")==OK and p.load_from("user://leadership.json")==OK,"Paid/unused manuals, learned technique and consumed voucher persist")
	check(game.event_index==original_event,"All optional services preserve the main narrative cursor")
	var bad: Dictionary=p.snapshot();bad.flags.order_trial_done=false;snapshot=p.snapshot()
	check(p.restore(bad,false)!=OK and p.snapshot()==snapshot,"Invalid voucher/training dependency is rejected atomically")
	Order.act(game,"armory","order:learn:LA09")
	check(not p.skills.has("LA09"),"Learning cannot be invoked remotely from the registry")
	p.learn("PU07");p.coins=60
	Order.act(game,"registry","order:confirm:PU09");Order.act(game,"registry","order:catalog");game._menu();Order.act(game,"registry","order:purchase:PU09")
	check(not Order.purchased(p,"PU09") and p.coins==60,"Cancelling the catalogue invalidates a stale purchase quote")
	game.paused=true;snapshot=p.snapshot();Order.act(game,"registry","order:confirm:PU09")
	check(p.snapshot()==snapshot and not game.has_meta("order_confirmation"),"Paused dialogue cannot open or commit purchase")
	game.paused=false;p.completed=true;await frames()
	check(not Order.rows(game.world).has("grandmaster") and Order.rows(game.world).has("commander"),"After departure, the commander remains available without a ghost Grand Master interaction")
	check(not game.world.sorted_world.get_node("GraoMestre").visible and not game.world.sorted_world.get_node("DuarteNaAudiencia").visible,"Absent leaders and Duarte are hidden during a return visit")
	game.free();await frames();print("ORDER_LEADERSHIP_RESULT ",JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
