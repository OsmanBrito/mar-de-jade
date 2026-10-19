extends SceneTree
const Requests = preload("res://scripts/chapter/local_request_state.gd")
const Items = preload("res://scripts/chapter/player_items.gd")
const FIXTURE := "res://tests/lisbon-request-state.json"
var checks := 0
var failures: Array[String] = []
var game
var p
var user_hashes: Dictionary = {}

func _initialize() -> void: call_deferred("run")
func frames(n: int = 3) -> void:
	for i in n: await process_frame
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func key(code: int) -> void:
	var event := InputEventKey.new(); event.keycode = code; event.physical_keycode = code; event.pressed = true
	root.push_input(event); await frames(2); event.pressed = false; root.push_input(event); await frames(2)
func pad(code: int) -> void:
	var event := InputEventJoypadButton.new(); event.button_index = code; event.pressed = true
	root.push_input(event); await frames(2); event.pressed = false; root.push_input(event); await frames(2)
func read_all() -> void:
	for i in 30:
		if game.phase!="local_dialogue" or game.harbor.city.cursor>=game.harbor.city.lines.size(): return
		game.advance(); await frames(1)
func choose(action: String, controller: bool = false) -> void:
	await read_all()
	var city = game.harbor.city
	for i in city.actions.size():
		if city.actions[i][1]==action:
			game.options_box.get_child(i).grab_focus()
			if controller: await pad(JOY_BUTTON_A)
			else: await key(KEY_ENTER)
			for step in 240:
				if not game.busy: break
				await physics_frame
			return
	check(false,"Available action "+action)

func walk(id: String) -> bool:
	var city = game.harbor.city
	var target: Vector2 = city.approach(id)
	if not game.world.point_clear(target):
		check(false,"Clear interaction approach for "+id+" at "+str(target)); return false
	game.world.walk_to(target)
	for i in 1200:
		await physics_frame
		if game.world.player.position.distance_to(target)<10: break
		if game.world.player.destination_path.is_empty(): break
	var ok: bool = game.world.player.position.distance_to(target)<12 and city.near(id)
	check(ok,"Real walk reaches "+id+" from city streets; feet="+str(game.world.player.position))
	return ok

func talk(id: String) -> bool:
	if not await walk(id): return false
	await key(KEY_E)
	check(game.phase=="local_dialogue" and not game.world.player.enabled,"E starts conversation with "+id)
	return game.phase=="local_dialogue"

func capture(label: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await frames(6); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://previews/lisbon-request-"+label+".png")

func reload_visit() -> bool:
	var expected: Dictionary = p.snapshot()
	check(p.save_to(FIXTURE)==OK,"Save request checkpoint")
	game.free(); await frames()
	p.reset()
	var error: int = p.load_from(FIXTURE)
	check(error==OK and p.snapshot()==expected,"Request and inventory round-trip together")
	if error!=OK: return false
	game = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate(); root.add_child(game); await frames(5)
	check(game.phase=="roaming" and game.scene_index==expected.checkpoint,"Reload returns to city walking, without repeating dialogue")
	return true

func run() -> void:
	Engine.time_scale = 3.0
	for path in ["user://capitulo-01.json","user://campanha-perfil.json","user://navegacao.json"]:
		user_hashes[path] = FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "absent"
	p = root.get_node("ChapterProgress"); p.auto_save = false; p.reset()
	root.get_node("CampaignProfile").hero_name = "Joana"
	p.flags = {"patient_helped":true,"patient_stable":true,"cargo_freed":true,"harbor_pause":true}
	Items.pay_service(p)
	game = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate(); game.start_block = 3; root.add_child(game); await frames(5)
	check(game.phase=="roaming" and game.routes.state.target==4,"City walking follows the rescue and points to the kitchen")
	check(not game.actors["Trabalhador ferido"].visible,"The treated patient does not return when city walking begins")
	check(["workshop","dock","fisher","neighbor"].all(func(id): return game.harbor.city.residents.has(id)),"Four existing city residents retain their interactions")
	var original_cart: Vector2 = game.harbor.city.cart.position
	if not await talk("neighbor"): await finish(); return
	check(game.view.body.text.contains("oficina"),"Resident points toward an actual city activity")
	await pad(JOY_BUTTON_B)
	check(game.phase=="roaming" and game.world.player.enabled,"Controller B closes local conversation without losing control")
	if not await talk("workshop"): await finish(); return
	await capture("offer"); await choose("close")
	check(Requests.stage(p).is_empty(),"Declining leaves the optional request undiscovered and repeatable")
	await key(KEY_E); await choose("accept",true)
	check(Requests.stage(p)=="inspect" and p.coins==40,"Acceptance starts the objective without granting a reward; stage="+Requests.stage(p)+" phase="+game.phase+" cursor="+str(game.harbor.city.cursor)+" conversation="+game.harbor.city.conversation)
	await choose("close")
	check(game.phase=="roaming" and game.world.player.enabled,"Closing acceptance returns control; phase="+game.phase)
	if not await talk("cart"): await finish(); return
	await capture("inspect"); await choose("wrong_rope")
	check(Requests.stage(p)=="inspect","Wrong diagnosis explains the clue without completing the step")
	await choose("inspect_again"); await choose("diagnose")
	check(Requests.stage(p)=="parts","Observation identifies the missing axle pin")
	await choose("close")
	if not await reload_visit(): await finish(); return
	if not await talk("dock"): await finish(); return
	await choose("take_part",true)
	check(Requests.stage(p)=="fit" and p.inventory.get(Requests.PART,0)==1,"Correct worker gives exactly one protected physical item")
	check(not Items.sell_reason(p,Requests.PART).is_empty(),"Quest part cannot be sold")
	await choose("close")
	if not await reload_visit(): await finish(); return
	check(p.inventory.get(Requests.PART,0)==1,"Reload retains the part without duplicating it")
	if not await talk("cart"): await finish(); return
	await choose("wrong_lift")
	check(Requests.stage(p)=="fit" and p.inventory.has(Requests.PART),"Unsafe plan preserves the part and requests cooperation")
	await choose("repair"); await choose("finish_repair")
	check(Requests.stage(p)=="return" and not p.inventory.has(Requests.PART),"Coordinated repair consumes the part once")
	check(game.harbor.city.cart.position!=original_cart,"Repair visibly moves the illustrated cart back to work")
	check(game.world.point_clear(original_cart),"Old cart footprint becomes walkable after navigation rebuild")
	await choose("close"); await capture("repaired")
	if not await talk("workshop"): await finish(); return
	await choose("claim")
	check(Requests.stage(p)=="completed" and p.coins==52 and p.inventory.get("PT-C02",0)==1,"Turn-in grants 12 gold and one ration")
	var rewarded: Dictionary = p.snapshot()
	check(not Requests.claim(p) and p.snapshot()==rewarded,"Reward cannot be claimed twice")
	await choose("close")
	if not await reload_visit(): await finish(); return
	check(game.harbor.city.cart.position!=original_cart,"Reload restores the changed world")
	if not await talk("workshop"): await finish(); return
	check(game.view.body.text.contains("continua firme"),"Returning NPC remembers the completed work")
	await choose("close")
	if not await talk("fisher"): await finish(); return
	check(game.view.body.text.contains("socorro"),"Fisher remembers the main rescue rather than repeating generic ambience")
	await choose("close")
	if not await talk("neighbor"): await finish(); return
	check(game.view.body.text.contains("passar outra vez"),"Neighbor reacts to the changed workshop")
	await choose("close")
	await key(KEY_J)
	check(paused and game.player_menu.page=="Pedidos","J opens the request journal")
	check(game.player_menu.listing.get_children().any(func(node): return node is Label and node.text=="A roda presa"),"Journal identifies the completed request")
	await capture("journal"); await pad(JOY_BUTTON_B)
	# Corrupt quest data must be rejected atomically, including item/state mismatch.
	var clean: Dictionary = p.snapshot()
	for patch in [{"local_requests":[]},{"local_requests":{"C01-LIS-01":"unknown"}},{"local_requests":{"other":"completed"}},{"local_requests":{"C01-LIS-01":"fit"}},{"local_requests":{"C01-LIS-01":1}}]:
		var bad := clean.duplicate(true); bad.merge(patch,true)
		FileAccess.open(FIXTURE,FileAccess.WRITE).store_string(JSON.stringify(bad))
		check(p.load_from(FIXTURE)==ERR_INVALID_DATA and p.snapshot()==clean,"Malformed request leaves current campaign intact: "+str(patch))
	var old := clean.duplicate(true); old.schema_version = 2; old.erase("local_requests")
	FileAccess.open(FIXTURE,FileAccess.WRITE).store_string(JSON.stringify(old))
	check(p.load_from(FIXTURE)==OK and p.local_requests.is_empty(),"Version 2 saves migrate with no invented quest completion")
	# Restore actual completed state and leave the early visit through the real gate.
	p.local_requests = clean.local_requests.duplicate()
	game.harbor.city.close()
	check(await load("res://tests/lisbon_walk_driver.gd").new().reach(game),"City route reaches the kitchen on foot")
	var at_meal: bool = game.phase=="task" and game.task_id=="meal"
	check(at_meal,"The kitchen begins the meal rather than accidental departure; phase="+game.phase)
	if not at_meal: await finish(); return
	check(game.scene_index==4 and game.map_kind=="service","Exploration resumes the exact approved meal scene")
	check(Requests.stage(p)=="completed","Entering the convent preserves the city request")
	# Revisit the final shore interval with the same completed request.
	p.flags.recovered = true; p.flags.packed = true; p.flags.harbor_pause = true
	game._load_block(15); await frames(5)
	check(game.phase=="roaming" and Requests.stage(p)=="completed","Final walk to the ship preserves the earlier completed request")
	check(await load("res://tests/lisbon_walk_driver.gd").new().reach(game,"cais"),"Final visit reaches the market through the city passages")
	for size in [Vector2i(1024,768),Vector2i(1280,800)]:
		root.size = size; game._menu("Pedidos"); await frames(6)
		for tab in game.player_menu.tabs.values(): check(root.get_visible_rect().encloses(tab.get_global_rect()),"Journal navigation stays inside "+str(size))
		await capture("journal-"+str(size.x))
		game._menu()
	await finish()

func finish() -> void:
	if is_instance_valid(game): game.free()
	await frames()
	for path in user_hashes:
		var after := FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "absent"
		check(after==user_hashes[path],"User save preserved: "+path)
	for path in [FIXTURE,FIXTURE+".bak",FIXTURE+".tmp"]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	print("LISBON_REQUESTS_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
