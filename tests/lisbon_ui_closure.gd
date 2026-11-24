extends SceneTree
## Real campaign controls: mouse access, persistent purpose and completed requests.
var checks := 0
var failures: Array[String] = []
var game
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func frames(n: int = 12) -> void:
	for i in n: await process_frame
func texts(node: Node) -> String:
	var result: String = node.text+"\n" if node is Label or node is Button else ""
	for child in node.get_children(): result += texts(child)
	return result
func shot(name: String) -> void:
	if DisplayServer.get_name()=="headless" or not OS.get_cmdline_user_args().has("--capture"): return
	DirAccess.make_dir_recursive_absolute("res://.qa-runtime/lisbon-ui")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.qa-runtime/lisbon-ui/"+name+".png")
func run() -> void:
	root.size = Vector2i(960,600)
	var p = root.get_node("ChapterProgress"); p.auto_save = false; p.reset(); p.flags.delivery_pending = true
	var prefs = root.get_node("GamePreferences"); prefs.persist_enabled = false; prefs.set_text_scale(1.2)
	root.get_node("CampaignProfile").hero_name = "Inês de Albuquerque"
	game = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate(); root.add_child(game); await frames()
	check(game.phase=="roaming" and game.view.exploration_actions.visible,"Playable Lisbon exposes pointer controls for notebook and menu")
	check(root.get_visible_rect().encloses(game.view.exploration_actions.get_global_rect()),"Exploration buttons fit a small window at 120 percent text")
	check(not game.view.exploration_actions.get_global_rect().intersects(game.view.exploration_back.get_global_rect()),"Exploration buttons leave the objective readable")
	await shot("01-percurso")
	if DisplayServer.get_name()!="headless" and OS.get_cmdline_user_args().has("--capture"):
		root.size = Vector2i(1440,900); await frames(20); await shot("01b-percurso-1440")
		root.size = Vector2i(960,600); await frames(20)
	var cursor: int = game.event_index; var feet: Vector2 = game.world.player.position
	game.view.exploration_actions.get_child(0).pressed.emit(); await frames()
	check(paused and game.menu_open and game.player_menu.page=="Pedidos","Caderno button opens the real paused mission journal")
	game.player_menu.mission_category = "Concluídas"; game.player_menu.refresh(); await frames()
	check(texts(game.player_menu.listing).contains("Ainda não concluíste pedidos"),"Empty completed mission tab explains where finished requests will appear")
	await shot("02-caderno")
	p.flags.house_adult_done = true; game.player_menu.mission_category = "Em curso"; game.player_menu.refresh()
	check(not texts(game.player_menu.listing).contains("A água da casa"),"Completed water service does not remain in active missions")
	game.player_menu.mission_category = "Concluídas"; game.player_menu.refresh()
	check(texts(game.player_menu.listing).contains("A água da casa"),"Completed water service is available in finished missions")
	game._menu(); await frames()
	check(not paused and game.event_index==cursor and game.world.player.position==feet,"Closing notebook preserves feet and narrative cursor")
	game.view.exploration_actions.get_child(1).pressed.emit(); await frames()
	check(paused and game.player_menu.page=="Sistema","Menu button opens system options directly")
	game._menu(); await frames()
	# Legacy shore leave shares the same HUD contract as the continuous routes.
	game.routes.stop(); game.scene_index = 3
	p.flags.patient_helped = true; p.flags.erase("injured"); p.flags.erase("embarked")
	game.harbor.begin(); await frames()
	check(game.view.independent_exploration_hud and game.view.objective_label.visible,"Shore leave keeps a persistent objective without requiring a tracked request")
	var objective: String = game.view.exploration_objective
	game.world.player.position = game.harbor.merchant.approach; game.harbor.update(); await frames()
	check(game.view.exploration_objective==objective and game.view.exploration_prompt.contains("negociar"),"Merchant prompt does not replace the reason for visiting Lisbon")
	p.local_requests["C01-LIS-01"] = "inspect"; p.choices.tracked_request = "C01-LIS-01"
	game.harbor.update(); await frames()
	check(game.view.exploration_objective.contains("Pedido acompanhado") and game.view.exploration_objective.contains("Duarte"),"Tracked request and main commitment remain visible together")
	await shot("03-comerciante")
	game.harbor.request_boarding(); await frames()
	# Explicit dialogue state also verifies that staged scenes have no spare HUD buttons.
	game.view.panel.show(); await frames()
	check(not game.view.exploration_actions.visible,"Exploration buttons disappear during a conversation")
	game.routes.active = true; game.harbor.active = false
	game.routes.load_area("convent",Vector2(390,-545)); game.routes.resume()
	var order = load("res://scripts/chapter/order_campaign.gd")
	game.routes.inspect(order.talk(game.world,p,"grandmaster")); await frames(20)
	check(game.options_box.get_child_count()>=4,"Leader conversation exposes the authored personal topics")
	check(game.view.status.text.is_empty() and game.view.hint.text.contains("escolher"),"Leader dialogue clears stale exploration prompts and shows choice controls")
	check(root.get_visible_rect().encloses(game.view.panel.get_global_rect()),"Leader dialogue with all topics fits the small window")
	await shot("04-audiencia-960")
	var final_action: Control = game.options_box.get_child(game.options_box.get_child_count()-1)
	final_action.grab_focus(); await frames(20)
	check(game.view.content_scroll.scroll_vertical>0 or game.view.content_scroll.get_global_rect().encloses(final_action.get_global_rect()),"Controller focus reaches the last leader topic through the scroll area")
	await shot("05-audiencia-960-opcoes")
	if DisplayServer.get_name()!="headless" and OS.get_cmdline_user_args().has("--capture"):
		root.size = Vector2i(1440,900); await frames(20); await shot("06-audiencia-1440")
	game.free(); await frames()
	var standalone = load("res://scripts/chapter/dialogue_view.gd").new(); root.add_child(standalone)
	standalone.panel.hide(); standalone.next_button.hide(); await frames()
	check(not standalone.exploration_actions.visible,"Unconnected childhood and review views never show dead buttons")
	standalone.free(); prefs.set_text_scale(1)
	print("LISBON_UI_CLOSURE_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
