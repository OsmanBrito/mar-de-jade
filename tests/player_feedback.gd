extends SceneTree
var game
var p
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func frames(n: int = 4) -> void:
	for i in n: await process_frame
func idle() -> void:
	for i in 1200:
		if not game.busy: return
		await physics_frame
	check(false,"Choreography finishes")
func walk(at: Vector2) -> void:
	game.world.walk_to(at)
	for i in 2000:
		if game.world.player.position.distance_to(at)<35: break
		await physics_frame
		if game.world.player.destination_path.is_empty(): break
	check(game.world.player.position.distance_to(at)<65,"Real navigation reaches "+str(at))
func capture(id: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await frames(10); await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://.qa-runtime/feedback-preview")
	root.get_texture().get_image().save_png("res://.qa-runtime/feedback-preview/"+id+".png")
func mount(index: int) -> void:
	game = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate(); game.start_block = index; root.add_child(game); await frames()
func run() -> void:
	Engine.time_scale = 3; root.size = Vector2i(1440,900)
	p = root.get_node("ChapterProgress"); p.auto_save = false; p.reset()
	root.get_node("CampaignProfile").hero_name = "Miguel"
	await mount(4)
	check(game.world.has_meta("order_convent") and game.phase=="task" and game.task_id=="meal","Meal starts in the existing convent kitchen")
	var room: int = game.world.get_instance_id()
	check(game.world.sorted_world.has_node("Table") and not game.world.sorted_world.has_node("MesaDeLeonor"),"Meal uses the permanent convent furniture")
	await walk(game.props.marker); game.interact_task()
	check(game.task_step==1 and game.props.carrying,"Cook hands over the portions before they are carried")
	await walk(game.props.marker); game.interact_task(); await idle(); await frames()
	check(game.world.player.presentation.posture=="seated" and p.flags.get("meal",false),"Hero sits only after delivering the portions")
	check(game.staging.beats.has("seated_in_existing_refectory"),"Seating is staged in the refectory")
	check(game.view.portrait_id=="leonor_adult" and game.view.portrait_frame.visible,"Leonor has her own dialogue portrait")
	await capture("refectory-leonor")
	game.advance(); await frames()
	check(game.view.portrait_id=="hero_adult" and game.view.portrait_image.texture.get_width()>500,"Hero speech uses the detailed adult portrait")
	await capture("hero-eyes")
	for i in 120:
		if game.routes.active and game.routes.state.kind=="rest": break
		if game.busy: await idle()
		elif game.phase=="choice": game.choose(game.choice_event.options[0].id)
		else: game.advance()
		await frames(1)
	check(game.routes.active and game.routes.state.kind=="rest","Conversation leads to an explicit return to the shelter")
	check(game.world.get_instance_id()==room,"The refectory stays in the same physical map across the conversation")
	check(game.world.player.presentation.posture=="standing" and not game.world.player.presentation.seat_support,"Free movement never retains the seated pose or a carried chair")
	await walk(Vector2(1310,20)); await capture("standing-after-meal")
	check(p.save_to("user://feedback.json")==OK and p.load_from("user://feedback.json")==OK,"Return route from refectory saves and loads")
	game.free(); await frames(); p.reset(); p.flags.recovered = true; p.coins = 200
	await mount(14); game.phase = "block_end"; game._menu("Loja de Lisboa"); await frames()
	for window in [Vector2i(960,600),Vector2i(1440,900),Vector2i(1920,1080)]:
		root.size = window; game.player_menu.switch_page("Loja de Lisboa"); await frames(10)
		var menu = game.player_menu
		await capture("shop-controls-"+str(window.x))
		for row in menu.listing.get_children():
			if not row is HBoxContainer: continue
			for button in row.get_children():
				if button is Button: check(button.size.x>=45 and button.size.y<=96,"Shop control has usable dimensions at "+str(window)+": "+button.text)
		menu.select_item("PT-C03"); await frames(6)
		check(menu.action_button.get_global_rect().end.x<=menu.screen.get_global_rect().end.x and menu.action_button.size.x>=100,"Purchase action fits the stretched game viewport: "+str(window))
		await capture("shop-"+str(window.x))
	var before: int = p.coins; game.player_menu.action_button.pressed.emit(); await frames()
	check(p.coins==before-3,"Visible purchase action changes actual currency once")
	game._menu(); game.free(); await frames(); p.reset()
	var old: Dictionary = p.snapshot(); old.schema_version = 8; old.checkpoint = 1; old.entry_scene = "res://scenes/chapter_01/chapter_flow.tscn"
	old.journey = {"kind":"fetch_return","target":1,"event":13,"stage":"","area":"cais","position":[492,927]}
	var file := FileAccess.open("user://feedback.json",FileAccess.WRITE); file.store_string(JSON.stringify(old)); file.close()
	check(p.load_from("user://feedback.json")==OK,"Version 8 rescue saves migrate to the clarified rescue")
	var events: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_01/chapter_flow.json")).scenes[1].events
	check(events[int(p.journey.event)].get("id","")=="fetch_tome","Migrated save resumes the medical fetch objective")
	var eyes = preload("res://scripts/chapter/hero_eyes.gd")
	check(eyes.iris_color("walk",0,0)==eyes.BLUE and eyes.iris_color("walk",0,1)==eyes.JADE,"Front view has anatomical right blue and left green")
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists("user://feedback.json"+suffix): DirAccess.remove_absolute("user://feedback.json"+suffix)
	print("PLAYER_FEEDBACK_RESULT ",JSON.stringify({"checks":checks,"failures":failures})); quit(0 if failures.is_empty() else 1)
