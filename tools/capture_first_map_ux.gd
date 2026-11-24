extends SceneTree
## Native before/after fixtures. Uses isolated campaign data; never the player's save.
var game
var output := "res://.qa-runtime/first-map-ux/after"
func _initialize() -> void:
	ProjectSettings.set_setting("application/config/custom_user_dir_name","Mar-de-Jade-QA-FirstMap-"+str(OS.get_process_id()))
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir())
	if OS.get_cmdline_user_args().has("--before"): output = "res://.qa-runtime/first-map-ux/before"
	if OS.get_cmdline_user_args().has("--comparison"): output = "res://.qa-runtime/first-map-ux/comparison"
	call_deferred("run")
func frames(count: int = 20) -> void:
	for i in count: await process_frame
func shot(name: String) -> void:
	await frames(); await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png(output+"/"+name+".png")
	if result!=OK: push_error("Capture failed: "+name); quit(1)
func run() -> void:
	root.size = Vector2i(960,600); root.content_scale_size = Vector2i(960,600); Engine.max_fps = 60
	if OS.get_cmdline_user_args().has("--comparison"): root.content_scale_size = Vector2i(1440,900)
	DirAccess.make_dir_recursive_absolute(output)
	var p = root.get_node("ChapterProgress"); p.auto_save = false; p.reset()
	var prefs = root.get_node("GamePreferences"); prefs.persist_enabled = false; prefs.set_text_scale(1.2)
	root.get_node("CampaignProfile").hero_name = "Miguel"
	change_scene_to_file("res://scenes/chapter_01/childhood_home.tscn"); await frames(60); game = current_scene
	await shot("01-abertura-960")
	for i in 4: game.advance()
	await shot("02-primeiro-movimento-960")
	game.get_node("ChildhoodMenu").open("journal"); await shot("03-caderno-infancia-960")
	game.get_node("ChildhoodMenu").close()
	p.reset(); p.flags.delivery_pending = true
	change_scene_to_file("res://scenes/chapter_01/chapter_flow.tscn"); await frames(60); game = current_scene
	# A safe return to the shelter and an independently accepted optional request.
	p.flags.patient_helped = true; p.local_requests["C01-LIS-01"] = "inspect"; p.choices.tracked_request = "C01-LIS-01"
	game.routes.begin("rest",7)
	game.routes.load_area("cais",Vector2(1100,850)); game.routes.resume()
	await shot("04-historia-e-pedido-960")
	root.size = Vector2i(1440,900); root.content_scale_size = Vector2i(1440,900); await shot("05-historia-e-pedido-1440")
	root.size = Vector2i(960,600); root.content_scale_size = Vector2i(960,600)
	game._menu("Pedidos"); await shot("06-caderno-objetivo-960")
	p.flags.order_audience_done = true; p.flags.order_cargo_done = true; p.flags.order_meal_done = true
	game.player_menu.mission_category = "Concluídas"; game.player_menu.refresh(); await shot("07-concluidas-960")
	game._menu()
	p.reset()
	change_scene_to_file("res://scenes/chapter_01/childhood_home.tscn"); await frames(60); game = current_scene
	if OS.get_cmdline_user_args().has("--hold"):
		print("FIRST_MAP_UX_READY_FOR_NATIVE_PLAYTEST"); return
	print("FIRST_MAP_UX_CAPTURE_OK ",output); quit()
