extends SceneTree
var checks := 0
var failures: Array[String] = []
var game
var p
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func frames(n: int = 3) -> void:
	for i in n: await process_frame
func key(code: int) -> void:
	var event := InputEventKey.new(); event.keycode = code; event.physical_keycode = code; event.pressed = true; root.push_input(event)
	await frames(); event.pressed = false; root.push_input(event); await frames()
func pad(code: int) -> void:
	var event := InputEventJoypadButton.new(); event.button_index = code; event.pressed = true; root.push_input(event)
	await frames(); event.pressed = false; root.push_input(event); await frames()
func click_world(point: Vector2) -> void:
	var event := InputEventMouseButton.new(); event.button_index = MOUSE_BUTTON_LEFT; event.pressed = true
	event.position = game.world.get_global_transform_with_canvas()*point; event.global_position = event.position
	var motion := InputEventMouseMotion.new(); motion.position = event.position; motion.global_position = event.position; root.push_input(motion,true)
	root.push_input(event,true); await frames(1); event.pressed = false; root.push_input(event,true)
func run() -> void:
	Engine.time_scale = 3.0
	p = root.get_node("ChapterProgress"); p.auto_save = false; p.reset()
	root.get_node("CampaignProfile").hero_name = "Joana"
	p.flags = {"recovered":true,"packed":true,"pack":true,"harbor_pause":true,"leonor_departed":true,"patient_helped":true}
	p.inventory["PT-W01"] = 1; p.equipment.weapon = "PT-W01"; p.tested_styles.assign(["ES"])
	load("res://scripts/chapter/player_items.gd").pay_service(p)
	game = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate(); game.start_block = 15; root.add_child(game); await frames(5)
	var visit = game.harbor
	check(game.phase=="roaming" and game.map_kind=="room","Legacy shore leave now begins with walking from the shelter")
	check(await load("res://tests/lisbon_walk_driver.gd").new().reach(game,"cais"),"Player walks through the square to the market")
	check(game.world.player.enabled and game.world.player.is_physics_processing(),"Player can walk during shore leave")
	check(game.actors.Duarte.visible and (not game.actors.has("Leonor") or not game.actors.Leonor.visible) and (not game.actors.has("Trabalhador ferido") or not game.actors["Trabalhador ferido"].visible),"Duarte waits at the pier; departed Leonor and the patient never return")
	check(is_instance_valid(visit.merchant) and game.world.sorted_world.get_node("BancaDePeixe").texture!=null,"Physical civilian and illustrated stocked stall installed")
	check(not game.world.sorted_world.has_node("BancaDePeixe/Provisoes"),"Inventory thumbnails stay in the shop instead of floating on the world counter")
	check(game.world.point_clear(game.world.player.position),"Harbor spawn is on clear ground")
	check(game.world.point_clear(visit.merchant.approach),"Counter has a physically clear approach")
	check(not game.world.point_clear(visit.merchant.position),"Merchant footprint blocks navigation and physics")
	var start: Vector2 = game.world.player.position
	await click_world(visit.merchant.approach)
	check(not game.world.player.destination_path.is_empty(),"Click route from arrival to merchant exists")
	# Actually traverse the authored collision geometry, rather than teleporting.
	for i in 480:
		if game.world.player.destination_path.is_empty(): break
		await physics_frame
	check(game.world.player.position.distance_to(visit.merchant.approach) < 12,"Player reaches counter by real movement")
	await frames(); check(visit.near_merchant() and visit.merchant.highlighted,"Nearby merchant shows contextual interaction prompt")
	var feet: Vector2 = game.world.player.position; var event_index: int = game.event_index
	await key(KEY_E)
	check(paused and game.menu_open and game.player_menu.page == "Loja de Lisboa","E opens the actual store from the world")
	check(game.player_menu.shop_reason().is_empty(),"World visit uses the same usable shop")
	game.player_menu.select_item("PT-V03"); game.player_menu.action_button.grab_focus(); await pad(JOY_BUTTON_A)
	check(p.coins == 24 and p.inventory.get("PT-V03",0) == 1,"Controller purchase transfers one item for 16 gold")
	game.player_menu.switch_page("Equipamento"); game.player_menu.select_item("PT-V03")
	game.player_menu.action_button.grab_focus(); await key(KEY_ENTER)
	check(p.equipment.get("feet","") == "PT-V03","Bought boots equip during the visit")
	await pad(JOY_BUTTON_B)
	check(not paused and game.phase == "roaming" and not game.menu_open,"B closes the shop to city walking")
	check(game.world.player.position == feet and game.event_index == event_index,"Closing store preserves exact feet and narrative position")
	check(game.world.player.destination_path.is_empty(),"Closing store cannot resume an old click route")
	await pad(JOY_BUTTON_A); check(game.menu_open,"A also interacts with nearby merchant")
	await key(KEY_ESCAPE)
	game.world.player.position = visit.START; await key(KEY_E)
	check(not game.menu_open and game.phase == "roaming","Interaction at a distance cannot open shop or board")
	var water: Vector2 = visit.merchant.position+Vector2(240,200)
	if not game.world.point_clear(water):
		game.world.walk_to(water); check(game.world.player.destination_path.is_empty(),"Click into water is rejected")
	await click_world(visit.GATE+Vector2(-55,20))
	check(not game.world.player.destination_path.is_empty(),"Route from market street to Duarte's pier exists")
	for i in 720:
		if game.world.player.destination_path.is_empty(): break
		await physics_frame
	check(visit.near_gate(),"Real walking reaches Duarte without crossing shoreline")
	await key(KEY_E)
	check(game.phase == "boarding" and not game.world.player.enabled,"Departure requires a deliberate confirmation")
	await key(KEY_ESCAPE)
	check(game.phase == "roaming" and game.world.player.enabled,"Esc cancels boarding and returns control")
	await pad(JOY_BUTTON_A); check(game.phase == "boarding","Controller A opens boarding review")
	await pad(JOY_BUTTON_B); check(game.phase == "roaming","Controller B cancels boarding review")
	await pad(JOY_BUTTON_A)
	game.options_box.get_child(0).grab_focus(); await key(KEY_ENTER)
	check(game.phase == "roaming","Default boarding option keeps exploring")
	# Economic changes and the pause survive saves; reload does not repeat packing.
	check(p.save_to("res://tests/harbor-state.json") == OK,"Visit checkpoint writes")
	var coins_before: int = p.coins; var supplies_before: Dictionary = p.inventory.duplicate()
	p.reset(); check(p.load_from("res://tests/harbor-state.json") == OK,"Visit checkpoint loads")
	game._load_block(p.checkpoint,false,true); await frames(4); visit = game.harbor
	check(game.phase == "roaming" and p.coins == coins_before and p.inventory == supplies_before,"Reload resumes city walking with stock and purchases intact")
	check(game.scene_index == 15 and game.event_index == -1,"Reload never replays the packing dialogue/task")
	game.routes.review_boarding()
	game.options_box.get_child(1).grab_focus(); await key(KEY_ENTER)
	check(game.map_kind=="deck" and game.scene_index==15 and game.phase=="roaming","Gangplank enters the deck without starting the captain's scene")
	check(await load("res://tests/lisbon_walk_driver.gd").new().reach(game,"cais"),"Player can walk back down to the same pier before meeting the captain")
	check(game.world.player.position.distance_to(preload("res://scripts/city/lisbon_layout.gd").BOAT_ENTRY-Vector2(0,45))<=64 and game.world.point_clear(game.world.player.position),"Returning from the vessel arrives on clear ground beside its gangplank, not across town")
	var captain_reached:bool=await load("res://tests/lisbon_walk_driver.gd").new().reach(game)
	check(captain_reached,"Player climbs aboard and walks to the captain")
	check(game.scene_index == 16 and game.map_kind == "deck" and game.view.body.text == "Dizem-me que sabes fazer perguntas.","Confirmed boarding reaches the first approved captain line once")
	check(not p.flags.get("harbor_pause",false) and not visit.active,"Boarding closes the shore visit")
	game._menu("Loja de Lisboa"); check(not game.player_menu.shop_reason().is_empty(),"Store is unavailable after boarding")
	game._menu(); game.queue_free(); await frames()
	for path in ["res://tests/harbor-state.json","res://tests/harbor-state.json.bak"]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	print("HARBOR_VISIT_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
