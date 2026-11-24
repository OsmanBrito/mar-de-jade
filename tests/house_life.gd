extends SceneTree
const House = preload("res://scripts/city/house_life.gd")
const Plan = preload("res://scripts/city/convent_plan.gd")
const SAVE := "user://qa-house-life.json"
var game
var young := false
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func frames(n: int = 3) -> void:
	for i in n: await process_frame
func walk(at: Vector2) -> bool:
	game.world.walk_to(at)
	for i in 2200:
		await physics_frame
		if game.world.player.position.distance_to(at)<12: return true
		if game.world.player.destination_path.is_empty(): break
	return false
func talk(id: String) -> String:
	check(await walk(House.rows(game.world)[id].at),"Actual walk to house task: "+id)
	if id=="porter":
		var event := InputEventMouseButton.new(); event.button_index = MOUSE_BUTTON_LEFT; event.pressed = true
		event.position = game.world.get_global_transform_with_canvas()*(House.rows(game.world)[id].at+Vector2(0,-30))
		root.push_input(event); await frames(1); event.pressed = false; root.push_input(event); await frames(2)
	elif young: game.roam.interact()
	else: game.routes.interact()
	await frames()
	check(game.phase==("childhood_note" if young else "order_inspection"),"Physical interaction opens house dialogue: "+id)
	var text: String = game.view.body.text
	if young: game.advance()
	else: game.options_box.get_child(0).pressed.emit()
	await frames(); return text
func door(area: String) -> bool:
	if young:
		if area=="convent":
			if not await walk(Plan.ARCADE): return false
		else:
			if not await walk(Vector2(0,870)): return false
		game.roam.interact(); await frames(); return game.roam.inside()==(area=="convent")
	for exit in game.routes.exits:
		if exit.to==area:
			if not await walk(exit.point): return false
			game.routes.interact(); await frames(); return game.routes.area()==area
	return false
func capture(name: String) -> void:
	if DisplayServer.get_name()=="headless": return
	DirAccess.make_dir_recursive_absolute("res://.qa-runtime/house-preview")
	await frames(20); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.qa-runtime/house-preview/"+name+".png")
func task(progress) -> void:
	await talk("water")
	check(House.stage(progress,young)=="","Water cannot be taken before a service request")
	await talk("steward"); check(House.stage(progress,young)=="asked","The optional request begins in the forecourt")
	await talk("water"); check(House.stage(progress,young)=="carrying","Water is collected through an actual interaction")
	check(game.world.player.presentation.carries_cup,"The player visibly carries the service vessel")
	if not young:
		game._menu("Pedidos"); await frames()
		var words := ""
		for label in game.player_menu.listing.find_children("*","Label",true,false): words += label.text
		var aside := ""
		for label in game.player_menu.details.find_children("*","Label",true,false): aside += label.text
		check(words.contains("A água da casa") and words.contains("Leva a água") and not aside.contains("Duarte espera"),"The journal shows the actual optional stage without a later departure prompt")
		await capture("diario"); game._menu(); await frames()
	check(progress.save_to(SAVE)==OK and progress.load_from(SAVE)==OK,"Task stage and journey survive save/load")
	check(await door("convent"),"The water reaches the convent through a real doorway")
	await talk("ward"); check(House.stage(progress,young)=="delivered","Only the infirmary accepts the delivery")
	check(not game.world.player.presentation.carries_cup,"The vessel is put down after delivery")
	await capture("enfermaria")
	var returned := await door("square"); await frames()
	check(returned and (DisplayServer.get_name()=="headless" or game.world.get_node("HouseAmbience").wind.playing),"The return journey restores the forecourt and its ambience")
	await talk("steward"); check(House.stage(progress,young)=="done","The recipient confirms completion in the forecourt")
	await talk("steward"); check(House.stage(progress,young)=="done","Repeating the conversation does not restart the task")
func run() -> void:
	Engine.time_scale = 3; root.size = Vector2i(1440,900)
	var p = root.get_node("ChapterProgress"); p.auto_save = false; p.reset(); p.flags.delivery_pending = true
	root.get_node("CampaignProfile").hero_name = "Miguel"
	game = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate(); root.add_child(game); await frames()
	check(await door("square"),"The adult enters the occupied forecourt")
	check(game.world.point_clear(game.world.sorted_world.get_node("AprendizDoAdro").position),"The pupil starts inside the usable forecourt")
	var bell := preload("res://scripts/city/house_ambience.gd").make_bell()
	check(bell.data.size()==22050*4*2 and bell.mix_rate==22050 and not bell.stereo,"The local bell is a complete four-second mono stream")
	if DisplayServer.get_name()!="headless":
		check(game.world.get_node("HouseAmbience").water.bus==root.get_node("GamePreferences").ambience_bus,"Local sounds respect the player's ambience volume bus")
	var stock: Dictionary = p.shop_stock.duplicate(); var inventory: Dictionary = p.inventory.duplicate()
	var text := await talk("porter")
	check(text.contains("Tomé") and text.contains("poente") and text.contains("nascente"),"The porter explains the actual entrances and plan")
	await capture("adro")
	await task(p)
	check(p.coins==0 and p.inventory==inventory and p.shop_stock==stock and p.skills.is_empty(),"House service does not alter campaign rewards, stock or combat skills")
	check(game.routes.state.kind=="delivery" and not p.flags.get("patient_helped",false),"The house request leaves the approved campaign commitment intact")
	game.free(); await frames(); p.reset(); young = true
	game = load("res://scenes/chapter_01/plaza.tscn").instantiate(); root.add_child(game); await frames()
	await task(p)
	check(House.stage(p,false)=="" and p.coins==0 and p.skills.is_empty(),"Childhood service never completes the adult task or grants adult rewards")
	game.free(); await frames(); young = false; p.journey = {}; p.flags.delivery_pending = true
	game = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate(); root.add_child(game); await frames()
	check(await door("square"),"The grown protagonist returns to the same portaria")
	text = await talk("porter")
	check(text.contains("desde a infância"),"The adult conversation remembers completed childhood service")
	game.free(); await frames()
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(SAVE+suffix): DirAccess.remove_absolute(SAVE+suffix)
	print("HOUSE_LIFE_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
