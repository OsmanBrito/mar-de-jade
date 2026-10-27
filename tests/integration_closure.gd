extends SceneTree
const Launch = preload("res://scripts/navigation/voyage_launch.gd")
const Bridge = preload("res://scripts/navigation/shore_bridge.gd")
const Content = preload("res://scripts/chapter/arc_content.gd")
const Party = preload("res://scripts/chapter/party_progress.gd")
const Items = preload("res://scripts/chapter/player_items.gd")
var checks := 0
var failures: Array[String] = []
func _initialize(): call_deferred("run")
func check(ok: bool,message: String):
	checks+=1
	if not ok: failures.append(message);push_error(message)
func frames(n: int=5):
	for i in n: await process_frame
func mount_voyage(resume: bool=false):
	Launch.mode="campaign";Launch.resume_requested=resume
	var game=load("res://scenes/navigation/voyage.tscn").instantiate()
	game.auto_save=false;root.add_child(game);await frames();game.clear_overlay()
	return game
func capture(id: String):
	if DisplayServer.get_name()=="headless": return
	DirAccess.make_dir_recursive_absolute("res://.qa-runtime/integration-close/captures")
	await frames(12);await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.qa-runtime/integration-close/captures/"+id+".png")
func run():
	root.size=Vector2i(1280,800)
	var p=root.get_node("ChapterProgress");p.auto_save=false;p.reset()
	root.get_node("CampaignProfile").hero_name="Miguel"
	p.completed=true;p.checkpoint=16;p.entry_scene="res://scenes/chapter_01/chapter_flow.tscn"
	p.flags={"recovered":true,"embarked":true,"patient_helped":true,"patient_stable":true,"packed":true,"perfect_defense":true}
	p.tested_styles.assign(["ES","PU"]);p.learn("ES07");p.learn("DP01");Party.recruit_duarte(p)
	p.inventory={"PT-Q01":1,"PT-W01":1,"PT-C01":2,"PT-C03":3};p.equipment={"weapon":"PT-W01"}
	p.childhood_hunt={"stage":9,"position":[180,850],"notes":["shelter"]};p.flags.lisbon_tide_read=true
	p.coins=40;p.vitals={"hp":80,"qi":7,"posture":75};p.companion_vitals={"duarte":{"hp":90,"qi":4,"posture":70}}
	check(Content.data().items.size()==27 and Content.data().skills.size()==68,"The arc scope inventories all 27 items and 68 catalogue skills, including all 65 Medida techniques")
	check(Content.executable("DU01") and not Content.executable("DU02") and not Content.executable("C01-DEMO-ES-01"),"Executable skills and temporary exercises are distinguished")
	p.learn("C01-DEMO-ES-01");p.learn("DU02");p.learn("unknown")
	check(not p.skills.has("DU02") and not p.skills.has("unknown"),"Catalogue-only skills and unknown IDs cannot be newly learned")
	check(Content.data().items.all(func(id): return Items.items().has(id)) and Items.items().size()==Content.data().items.size(),"The playable item manifest exactly matches the runtime catalogue")
	var journal=preload("res://scripts/chapter/campaign_journal.gd")
	check(journal.notes(p).filter(func(row):return not row.id.begins_with("story:")).size()==2 and journal.notes(p).any(func(row): return row.id=="forest:shelter"),"The shared journal includes only observed forest and city discoveries")
	var hero: Dictionary=Party.member(p,"hero");var duarte: Dictionary=Party.member(p,"duarte")
	check(hero.skills.has("ES07") and not hero.skills.has("DU01") and duarte.skills==["DU01"],"Learning belongs to stable member IDs")
	check(duarte.equipment_policy=="fixed_story_kit" and duarte.equipment=={"story_kit":"duarte"},"Duarte's own kit cannot consume the protagonist's equipment")
	var game=await mount_voyage()
	game.model.dock("madeira")
	game.model.hull=73;game.model.supplies=62;game.model.coins=211
	check(game.model.made_landfall and game.model.campaign_state.coins==40,"Madeira landfall retains personal and ship wallets separately")
	game.current_enemy=game.model.place("patrol");game.begin_boarding()
	var battle=game.battle_host.combat
	battle.units[0].hp=60;battle.units[0].qi=2;battle.units[0].posture=55
	battle.units[1].hp=68;battle.units[1].qi=1;battle.units[1].posture=43
	battle.progress_override.inventory["PT-C01"]=1
	game._boarding_completed(true);game.clear_overlay()
	check(p.vitals.hp==60 and p.companion_vitals.duarte.hp==68 and p.inventory["PT-C01"]==1,"Actual boarding completion updates both people and the shared bag")
	game.model.dock("lisboa")
	var ship: Dictionary=game.model.snapshot()
	var wrong_port: String=game.model.port;game.model.port="madeira"
	check(Bridge.enter(game.model,Launch.save_path(true))==ERR_UNAVAILABLE,"The Lisbon bridge cannot replace a different port's scene")
	game.model.port=wrong_port
	check(Bridge.enter(game.model,Launch.save_path(true))==OK,"Lisbon shore leave parks a valid voyage checkpoint")
	game.free();await frames()
	var city=load("res://scenes/chapter_01/chapter_flow.tscn").instantiate();root.add_child(city);await frames()
	check(city.phase=="roaming" and city.completed and city.events.is_empty() and city.routes.state.kind=="port_visit","Returning opens the real city without replaying the departure")
	check(city.world.has_meta("continuous_lisbon") and city.world.point_clear(city.world.player.position),"The returning character lands on a clear city position")
	check(city.player_menu.shop_reason().is_empty(),"Lisbon services reopen during the return visit")
	await capture("lisbon-return")
	var before: int=p.coins;Items.buy(p,"PT-C01");Items.use(p,"PT-C03","duarte")
	check(p.coins==before-6 and p.inventory["PT-C01"]==2 and p.companion_vitals.duarte.qi==6,"Shore purchases and companion supplies affect the same identities")
	city.world.walk_to(Vector2(1480,1025))
	for i in 500:
		await physics_frame
		if city.world.player.position.distance_to(Vector2(1480,1025))<15: break
	city.routes.save()
	check(p.save_to()==OK,"Saving shore leave updates the parked voyage and chapter")
	var parked=load("res://scripts/navigation/voyage_model.gd").new()
	check(parked.load_from(Launch.save_path(true))==OK and Bridge.is_visit(parked.campaign_state),"A process restart can identify the saved city visit")
	var stored: Dictionary=parked.campaign_state.duplicate(true)
	check(stored.coins==34 and stored.shop_stock["PT-C01"]==5 and stored.companion_vitals.duarte.qi==6,"The voyage carries shore inventory, stock, wallet and companion resources")
	p.coins=3
	check(p.load_from()==OK and p.coins==34,"Loading on shore uses the parked voyage checkpoint instead of stale land data")
	city.free();await frames();p.reset();check(p.restore(stored)==OK,"City state reloads through the chapter validator")
	city=load("res://scenes/chapter_01/chapter_flow.tscn").instantiate();root.add_child(city);await frames()
	check(city.phase=="roaming" and city.world.player.position.distance_to(Vector2(stored.journey.position[0],stored.journey.position[1]))<2,"Reload restores the shore position and objective")
	var hash_before:=FileAccess.get_sha256(Launch.save_path(true))
	var wrong: Dictionary=p.snapshot();wrong.run_id="00000000000000000000000000000000"
	check(Bridge.sync(wrong)==ERR_INVALID_DATA and FileAccess.get_sha256(Launch.save_path(true))==hash_before,"A different campaign cannot overwrite the parked ship")
	var bad: Dictionary=p.snapshot();bad.completed=false
	check(p.restore(bad)==ERR_INVALID_DATA,"A shore visit cannot fabricate an unfinished chapter")
	city.world.player.position=city.routes.goal;city.routes.arrive()
	check(city.phase=="shore_return" and city.options_box.get_child_count()==2,"The physical pier offers exploration or reboarding without a story replay")
	check(Bridge.embark(p)==OK and p.journey.is_empty(),"Reboarding commits city changes before changing scenes")
	city.free();await frames()
	game=await mount_voyage(true)
	check(preload("res://scripts/chapter/campaign_journal.gd").notes(game.model.campaign_state).filter(func(row):return not row.id.begins_with("story:")).size()==2,"Discoveries remain readable aboard after the return cycle")
	check(game.model.phase=="port" and game.model.port=="lisboa" and not Bridge.is_visit(game.model.campaign_state),"Reboarding resumes the original voyage")
	check(game.model.hull==ship.hull and game.model.coins==ship.coins and game.model.supplies==ship.supplies and game.model.resolved==ship.resolved,"Shore leave does not reset ship resources, encounters or rewards")
	check(game.model.campaign_state.coins==34 and p.companion_vitals.duarte.qi==6 and p.skills.has("DU01"),"Reboarding carries identity, learning and personal economy forward")
	game.open_personal("journal");await capture("journal-aboard");game.clear_overlay()
	game.leave_stage()
	check(game.model.phase=="sea" and game.model.made_landfall,"The original voyage continues after the return")
	game.free();await frames()
	print("INTEGRATION_CLOSURE_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
