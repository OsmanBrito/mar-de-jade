extends SceneTree
const Errands = preload("res://scripts/chapter/lisbon_errands.gd")
const Items = preload("res://scripts/chapter/player_items.gd")
var checks := 0
var failures: Array[String] = []
var game
var p
var saves: Dictionary = {}
var prefs
var old_options: Dictionary
var old_bindings: Dictionary
var old_levels: Dictionary
var old_scale: float
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func frames(n: int = 3) -> void:
	for i in n: await process_frame
func key(code: int) -> void:
	var event := InputEventKey.new(); event.physical_keycode = code; event.keycode = code; event.pressed = true
	root.push_input(event); await frames(); event.pressed = false; root.push_input(event); await frames()
func shot(name: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await frames(3); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://previews/revision-"+name+".png")
func walk(target: Vector2) -> bool:
	for offset in [Vector2.ZERO,Vector2(-32,16),Vector2(32,16)]:
		if not game.world.point_clear(target+offset): continue
		game.world.walk_to(target+offset)
		for i in 1000:
			if game.world.player.position.distance_to(target)<45: return true
			await physics_frame
			if game.world.player.destination_path.is_empty(): break
	return false
func talk(id: String) -> bool:
	check(await walk(game.harbor.city.approach(id)),"Real walking reaches "+id)
	if not game.harbor.city.near(id): return false
	await key(KEY_E); check(game.phase=="local_dialogue","E opens conversation with "+id); return game.phase=="local_dialogue"
func select(action: String) -> void:
	for i in 12:
		if game.harbor.city.cursor>=game.harbor.city.lines.size(): break
		game.harbor.city.advance(); await frames(1)
	game.harbor.city.choose(action); await frames()
func run() -> void:
	for path in ["user://capitulo-01.json","user://campanha-perfil.json","user://navegacao.json","user://preferencias.cfg"]:
		saves[path] = FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "absent"
	prefs = root.get_node("GamePreferences"); prefs.persist_enabled = false
	old_options = prefs.options.duplicate(); old_bindings = prefs.bindings.duplicate(); old_levels = prefs.levels.duplicate(); old_scale = prefs.text_scale
	prefs.bindings = prefs.DEFAULT_BINDINGS.duplicate()
	prefs.options = {"wide_timing":false,"difficulty":"normal","reduced_fx":false,"fast_combat":false}; prefs.commit()
	p = root.get_node("ChapterProgress"); p.auto_save = false; p.reset(); p.flags = {"recovered":true,"packed":true}; p.coins = 40
	root.get_node("CampaignProfile").hero_name = "Miguel"
	game = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate(); game.start_block = 15; root.add_child(game); await frames()
	game.harbor.begin(); await frames()
	if not await talk("fisher"): await finish(); return
	await select("account_accept"); await select("close")
	check(Errands.stage(p,Errands.ACCOUNT)=="dock" and p.coins==40,"Discovery starts information request without payment")
	if not await talk("dock"): await finish(); return
	await select("account_dock"); await select("close")
	check(Errands.stage(p,Errands.ACCOUNT)=="kitchen","Dock evidence requires independent confirmation")
	if not await talk("neighbor"): await finish(); return
	await select("account_kitchen"); await select("close")
	if not await talk("fisher"): await finish(); return
	await select("account_wrong")
	check(Errands.stage(p,Errands.ACCOUNT)=="reconcile" and p.coins==40,"Wrong conclusion does not grant completion or silently charge money")
	await select("account_reconcile")
	check(Errands.stage(p,Errands.ACCOUNT)=="completed" and p.coins==48,"Reconciliation grants exactly eight gold")
	check(game.world.sorted_world.get_node("BancaDePeixe").has_node("DeliveryRecord"),"Account correction leaves a visible record")
	await shot("account-settled"); await select("account_reconcile"); check(p.coins==48,"Duplicate callback cannot duplicate reward"); await select("close")
	if not await talk("dock"): await finish(); return
	await select("kit_accept"); await select("close")
	if not await talk("dock"): await finish(); return
	await select("kit_finish"); check(Errands.stage(p,Errands.KIT)=="prepare","Missing supplies leave optional preparation unfinished"); await select("close")
	Items.buy(p,"PT-C01"); Items.buy(p,"PT-C03")
	var count_before: Dictionary = p.inventory.duplicate(); var money_before: int = p.coins
	if not await talk("dock"): await finish(); return
	await select("kit_finish"); await select("close")
	check(Errands.stage(p,Errands.KIT)=="completed" and p.coins==money_before+3 and p.inventory==count_before,"Preparation rewards once and keeps the personal reserve")
	check(p.save_to("res://tests/revision-fixture.json")==OK,"Concurrent local requests save")
	var saved: Dictionary = p.snapshot(); p.reset()
	check(p.load_from("res://tests/revision-fixture.json")==OK and p.snapshot()==saved,"Multi-request schema round-trips without losing the other request")
	var invalid := saved.duplicate(true); invalid.local_requests[Errands.ACCOUNT] = "return"
	FileAccess.open("res://tests/revision-invalid.json",FileAccess.WRITE).store_string(JSON.stringify(invalid))
	check(p.load_from("res://tests/revision-invalid.json")==ERR_INVALID_DATA and p.snapshot()==saved,"Invalid request stage rejected before mutation")
	var event_index: int = game.event_index; var history_count: int = game.view.history.size()
	game._menu("Conversas"); await frames(); await shot("history")
	check(paused and history_count>8,"Conversation consultation pauses the active world and contains real seen lines")
	game._menu(); check(game.event_index==event_index and p.snapshot()==saved,"Reading history changes no task, reward or scene")
	if DisplayServer.get_name()!="headless": root.size = Vector2i(1024,640)
	game._menu("Sistema"); prefs.set_text_scale(1.2); game.player_menu.refresh(); await frames(); await shot("settings-120")
	check(game.player_menu.listing.find_children("wide_timing","CheckButton",true,false).size()==1,"System exposes combat timing preference")
	game._menu()
	if DisplayServer.get_name()!="headless": root.size = Vector2i(1280,800)
	check(prefs.bind_key("interact",KEY_V)=="Comando atualizado.","Player can rebind interaction")
	var preferences_path: String = prefs.path; prefs.path = "res://tests/preferences-fixture.cfg"
	check(prefs.save_settings()==OK,"Preferences save independently of campaign progress")
	prefs.bindings = prefs.DEFAULT_BINDINGS.duplicate(); prefs.text_scale = 1.0; prefs.load_settings(); prefs.apply_bindings()
	check(prefs.bindings.interact==KEY_V and is_equal_approx(prefs.text_scale,1.2),"Key and text-size preferences survive a reload")
	prefs.path = preferences_path
	game._begin_task({"id":"input_probe","caption":"Input regression"}); game.props.marker = game.world.player.position
	await key(KEY_E); check(not p.flags.get("input_probe",false),"Old interaction key does not bypass remapping")
	await key(KEY_V); check(p.flags.get("input_probe",false),"New interaction key executes the real task")
	prefs.bindings = prefs.DEFAULT_BINDINGS.duplicate(); prefs.apply_bindings()
	game._begin_battle("duel"); var host = game.battle_host
	host.tactical.phase = "timing_attack"; var narrow: Vector2 = host.tactical.timing_windows()
	prefs.set_option("wide_timing",true)
	check(host.tactical.timing_windows().x>narrow.x,"Timing preference changes actual campaign windows")
	host.paused = true; host.pause_selection = 2; await key(KEY_ENTER)
	check(prefs.options.reduced_fx and host.progress.data.options.reduced_fx,"Battle pause changes the real reduced-effects option")
	await key(KEY_ESCAPE); check(not host.paused,"Escape resumes the same battle")
	game.battle_container.hide(); host.active = false
	game._load_block(4); await frames(); await shot("meal")
	game._load_block(7)
	for i in 180:
		if not game.busy: break
		await physics_frame
	await shot("same-bench")
	game._load_block(1); await frames()
	for i in 12:
		if game.phase=="task": break
		game.advance(); await frames(1)
	check(await walk(game.props.marker),"Real route approaches the rescue support"); game.interact_task()
	for i in 150:
		if not game.busy: break
		await physics_frame
	check(game.task_step==1 and not p.flags.get("cargo_freed",false),"Support placement alone does not release the trapped worker")
	await shot("rescue-supported")
	check(await walk(game.props.marker),"Real route reaches Duarte's lifting position"); game.interact_task()
	for i in 420:
		if not game.busy: break
		await physics_frame
	check(p.flags.get("cargo_freed",false) and game.staging.beats.has("worker_freed"),"Coordinated lift precedes perception")
	await shot("rescue-perception")
	p.flags.delivery_pending = true; p.flags.delivery_finished = false
	game._load_block(0); await frames()
	check(game.phase=="roaming" and game.map_kind=="room","Adult handoff leaves the player in the shelter before the delivery")
	check(await load("res://tests/lisbon_walk_driver.gd").new().reach(game),"Walk through the square to the delivery receiver")
	check(await walk(game.props.marker),"Real route reaches the kitchen receiver")
	await key(KEY_E); check(game.phase=="delivery_choice","Delivery requires checking the recipient and storage")
	game._deliver(false); check(not p.flags.delivery_finished,"Wet fish stall does not complete flour delivery")
	game._deliver(true); check(p.flags.delivery_finished and not p.flags.delivery_pending,"Correct delivery completes once without a payment")
	game.advance()
	check(await load("res://tests/lisbon_walk_driver.gd").new().reach(game),"Walk back to Duarte after delivery")
	for i in 90:
		if not game.busy: break
		await physics_frame
	check(game.map_kind=="courtyard" and game.view.body.text=="O apoio saiu antes do golpe.","Delivered goods lead to Duarte's approved short repetition")
	await shot("delivery-return")
	game.free(); game = null; await frames()
	var launch = load("res://scripts/navigation/voyage_launch.gd"); launch.mode = "campaign"; launch.resume_requested = false
	p.vitals = {"hp":80,"qi":8,"posture":90}; p.flags.recovered = true; p.inventory["PT-C01"] = 1; p.inventory["PT-C03"] = 1
	p.learn("ES07")
	game = load("res://scenes/navigation/voyage.tscn").instantiate(); game.auto_save = false; root.add_child(game); await frames(); game.clear_overlay()
	var personal_money: int = p.coins; game.current_enemy = game.model.place("patrol"); game.begin_boarding()
	var b = game.battle_host.combat
	b.current_id = 0; b.units[0].hp = 60; b.units[0].qi = 2; b.units[0].posture = 44
	check(b.commands(0).has(1) and b.commands(0).has(-1),"Boarding exposes the learned action and the bag in distinct slots" if p.skills.has(b.FIRST[p.style]) else "Boarding exposes bag without replacing basic")
	var result: Dictionary = b.perform(6,b.units[0].cell,1)
	check(not result.has("error") and b.units[0].hp==85,"Personal bandage restores its advertised 25 HP")
	game._boarding_completed(true)
	check(not game.model.boarding_profile.inventory.has("PT-C01") and game.model.boarding_profile.vitals.hp==85 and game.model.boarding_profile.vitals.qi==2,"Victory persists consumed supplies, health and energy")
	check(p.coins==personal_money and game.model.coins==250,"Crew reward and initial fund do not mutate personal chapter wallet")
	game.current_enemy = game.model.place("patrol"); game.begin_boarding()
	check(game.battle_host.combat.units[0].hp==85 and game.battle_host.combat.units[0].qi==2 and game.battle_host.combat.potions==0,"Next boarding starts with the actual remaining kit")
	game.battle_container.hide(); game.battle_host.active = false; game.model.phase = "sea"; game.clear_overlay()
	game.model.tutorials = {"sail":true,"turn":true,"stop":true}; var sea: Dictionary = game.model.snapshot()
	var model = load("res://scripts/navigation/voyage_model.gd").new()
	check(model.restore(sea) and model.tutorials==game.model.tutorials,"Navigation guidance progression survives reload")
	sea.tutorials = {"unexpected":true}; check(not model.restore(sea),"Invalid guidance state rejected")
	await finish()
func finish() -> void:
	paused = false
	if is_instance_valid(game): game.free()
	prefs.options = old_options; prefs.bindings = old_bindings; prefs.levels = old_levels; prefs.text_scale = old_scale; prefs.apply_bindings(); prefs.commit()
	await frames()
	for path in saves: check(saves[path]==(FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "absent"),"User state preserved: "+path)
	print("ARC_REVISION_RESULT ",JSON.stringify({"checks":checks,"failures":failures,"rendered":DisplayServer.get_name()!="headless"}))
	quit(0 if failures.is_empty() else 1)
