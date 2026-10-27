extends SceneTree
var game
func _initialize():
	ProjectSettings.set_setting("application/config/custom_user_dir_name","Mar-de-Jade-QA-order-capture-"+str(Time.get_ticks_usec()))
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir())
	call_deferred("run")
func frames(n := 6):
	for i in n: await process_frame
func capture(name: String):
	await frames(); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/"+name+".png")
func run():
	root.size = Vector2i(1280,800)
	var p = root.get_node("ChapterProgress"); p.auto_save = false; p.reset()
	root.get_node("GamePreferences").persist_enabled = false
	root.get_node("CampaignProfile").hero_name = "Miguel"
	game = load("res://scenes/chapter_01/adult_opening.tscn").instantiate(); root.add_child(game)
	await capture("ordem-primeira-impressao")
	game.free(); await frames(); p.flags.order_intro_started = true
	game = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate(); root.add_child(game); await frames()
	for i in 12:
		if game.phase=="styles": break
		game.advance()
	game._choose_lesson_weapon("FO")
	await capture("ordem-reserva-inicial")
	game.options_box.get_child(0).pressed.emit()
	await capture("ordem-preparar-tecnicas")
	game.options_box.get_child(game.options_box.get_child_count()-1).pressed.emit()
	for i in 4:
		if game.routes.active: break
		game.advance()
	game.routes.load_area("convent",Vector2(540,650)); game.routes.resume()
	game.world.player.position = game.routes.goal+Vector2(0,30)
	game.routes.interact("goal")
	await capture("ordem-enfermaria")
	game.free(); await frames()
	p.flags.patient_helped = true; p.flags.order_check_done = true; p.flags.order_reported = true; p.flags.house_adult_review = true; p.flags.house_adult_done = true; p.choices.order_service = "linen"
	game = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate(); game.start_block=3; root.add_child(game); await frames()
	game.event_index = game.events.size()-1; game.current_event = game.events[game.event_index]
	load("res://scripts/chapter/first_order_service.gd").help_offer(game)
	await capture("ordem-pedido-acompanhado")
	game.options_box.get_child(0).pressed.emit()
	p.local_requests["C01-LIS-01"] = "inspect"; p.choices.tracked_request = "C01-LIS-01"
	game._menu("Pedidos")
	await capture("ordem-caderno-pedidos")
	game.free(); paused=false; await frames()
	p.learn("DU01")
	game = load("res://scenes/art/combat_study.tscn").instantiate(); game.encounter = "duarte_support"; game.style = "FO"; root.add_child(game); await frames()
	game.host.set_process(false); await capture("ordem-duarte-combate")
	game.free(); await frames()
	print("ORDER_CAPTURE_RESULT: seven native views, personal saves disabled")
	quit()
