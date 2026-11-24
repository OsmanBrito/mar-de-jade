extends SceneTree
## Player-facing journal states, spatial menu navigation and live text sizing.
var checks := 0
var failures: Array[String] = []
var game
func _initialize() -> void: call_deferred("run")
func frames(n: int = 12) -> void:
	for i in n: await process_frame
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func texts(node: Node) -> String:
	var result: String = node.text+"\n" if node is Label or node is Button else ""
	for child in node.get_children(): result += texts(child)
	return result
func cards(menu,title: String) -> int:
	var count := 0
	for node in menu.listing.get_children():
		if node is Button and node.text.begins_with(title+"\n"): count += 1
	return count
func press_key(code: int) -> void:
	var event := InputEventKey.new(); event.physical_keycode = code; event.keycode = code; event.pressed = true; root.push_input(event)
	await frames(3); event.pressed = false; root.push_input(event); await frames(3)
func press_pad(code: int) -> void:
	var event := InputEventJoypadButton.new(); event.button_index = code; event.pressed = true; root.push_input(event)
	await frames(3); event.pressed = false; root.push_input(event); await frames(3)
func shot(name: String) -> void:
	if DisplayServer.get_name()=="headless" or not OS.get_cmdline_user_args().has("--capture"): return
	DirAccess.make_dir_recursive_absolute("res://.qa-runtime/first-map-journal")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.qa-runtime/first-map-journal/"+name+".png")
func run() -> void:
	root.size = Vector2i(960,600)
	root.content_scale_size = Vector2i(960,600)
	var p = root.get_node("ChapterProgress"); p.auto_save = false; p.reset(); p.flags.delivery_pending = true
	var prefs = root.get_node("GamePreferences"); prefs.persist_enabled = false; prefs.set_text_scale(1)
	root.get_node("CampaignProfile").hero_name = "Miguel"
	game = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate(); root.add_child(game); await frames()
	p.flags.patient_helped = true
	game.routes.load_area("square",Vector2(0,400))
	game.routes.state.kind = "fetch_return"; game.routes.set_goal(); game.routes.resume(); await frames()
	game._menu("Pedidos"); await frames()
	var menu = game.player_menu
	p.local_requests["C01-LIS-02"] = "dock"
	menu.refresh(); await frames()
	var before: Dictionary = p.snapshot()
	menu.track_request("C01-LIS-02"); await frames()
	check(p.choices.tracked_request=="C01-LIS-02" and menu.mission_buttons["C01-LIS-02"].text.contains("A ACOMPANHAR"),"Tracking immediately identifies the active optional request on its card")
	check(root.gui_get_focus_owner()==menu.mission_buttons["C01-LIS-02"],"Tracking returns controller focus to the selected mission")
	check(p.coins==before.coins and p.inventory==before.inventory and p.local_requests==before.local_requests and p.payments==before.payments,"Browsing and tracking cannot grant rewards or change quest stages")
	var main: String = game.routes.main_objective()
	check(main.contains("Tomé") and main.contains("ferido") and preload("res://scripts/chapter/chapter_objectives.gd").current(game)==main,"The main return with Tomé remains the canonical objective while another request is tracked")
	check(game.routes.objective().contains(main) and game.routes.objective().contains("Pergunta no pontão"),"Exploration presents the main return and the optional delivery request together")
	check(game.routes.guide_target()==game.harbor.city.approach("dock"),"The direction guide still follows the deliberately selected optional request")
	menu.mission_buttons["STORY"].pressed.emit(); await frames()
	check(texts(menu.details).contains(game.routes.main_objective()) and not texts(menu.details).contains("Pergunta no pontão"),"The main story card retains its complete next action while a different request is tracked")
	menu.mission_category = "Arquivo"; menu.refresh(); await frames()
	check(texts(menu.listing).contains(game.routes.main_objective()),"The archive preserves the same detailed main commitment")
	menu.mission_category = "Em curso"; game.routes.state.kind = "order_help"
	p.local_requests["C01-LIS-01"] = "inspect"; p.choices.tracked_request = "C01-LIS-01"
	menu.refresh(); await frames()
	check(cards(menu,"A roda presa")==1,"An accepted accompanied workshop request appears once in the active journal")
	for flag in ["order_audience_done","order_cargo_asked","order_cargo_ledger","order_cargo_manifest","order_cargo_recipient","order_cargo_done","order_meal_asked","order_meal_prepared","order_meal_done"]: p.flags[flag] = true
	p.local_requests["C01-LIS-01"] = "completed"
	menu.mission_category = "Concluídas"; menu.refresh(); await frames()
	check(cards(menu,"A carga da Ordem")==1,"A completed cargo investigation has one result card")
	check(cards(menu,"A mesa de quem fica")==1,"The completed kitchen service remains visible among finished missions")
	menu.mission_buttons["ORDER-CARGO"].pressed.emit(); await frames()
	check(texts(menu.details).contains("Resultado") and not texts(menu.details).contains("Próximo passo") and not texts(menu.details).contains("Acompanhar missão"),"Completed missions present their outcome without a new objective or tracking action")
	await shot("01-resultados-960")
	menu.switch_page("Sistema"); await frames()
	var original_scale: Button = menu.text_scale_button
	var original_tab: Button = menu.tabs.Sistema
	original_scale.grab_focus(); original_scale.pressed.emit(); await frames()
	check(is_instance_valid(original_scale) and menu.text_scale_button==original_scale and root.gui_get_focus_owner()==original_scale,"Changing text size preserves the live size control and its focus")
	check(original_tab.get_theme_font_size("font_size")==prefs.font_size(17) and menu.wallet.get_theme_font_size("font_size")==prefs.font_size(21),"Persistent tabs and wallet adopt the new text size")
	check(original_scale.text.contains("110%"),"The existing size control announces the applied scale")
	prefs.set_text_scale(1.2); await frames()
	check(root.gui_get_focus_owner()==original_scale and original_tab.get_theme_font_size("font_size")==20,"An external preference change also preserves focus and scales the menu")
	var panel_rect: Rect2 = menu.screen.get_child(1).get_global_rect()
	check(panel_rect.end.x<=root.get_visible_rect().end.x-41 and panel_rect.position.x>=41,"The System panel preserves its side margins at 960 pixels and 120 percent text")
	check(menu.content.get_global_rect().end.x<=panel_rect.end.x-23,"System content stays inside the panel padding at enlarged text size")
	for node in menu.listing.get_children():
		if node is CheckButton:
			check(node.autowrap_mode==TextServer.AUTOWRAP_WORD_SMART and node.get_global_rect().end.x<=panel_rect.end.x-23,"System toggle wraps inside the page instead of widening the panel: "+node.name)
	await shot("02-sistema-120-960")
	menu.switch_page("Pedidos"); await frames()
	var filters = menu.listing.get_child(1)
	for category in filters.get_children():
		check(category.autowrap_mode==TextServer.AUTOWRAP_OFF and category.size.x>=category.get_minimum_size().x and root.get_visible_rect().encloses(category.get_global_rect()),"Mission filter stays whole and fits the 960-pixel viewport at 120 percent: "+category.text)
	check(menu.content.get_global_rect().end.x<=root.get_visible_rect().end.x,"The menu columns fit the 960-pixel viewport at 120 percent text")
	menu.tabs.Pedidos.grab_focus(); await press_key(KEY_DOWN)
	check(root.gui_get_focus_owner()==menu.tabs.Conversas,"Keyboard down follows the visible vertical tab order")
	await press_key(KEY_UP)
	check(root.gui_get_focus_owner()==menu.tabs.Pedidos,"Keyboard up returns through the tab column")
	await press_key(KEY_RIGHT)
	check(root.gui_get_focus_owner()!=null and menu.listing.is_ancestor_of(root.gui_get_focus_owner()),"Keyboard right enters the page content from the sidebar")
	menu.tabs.Pedidos.grab_focus(); await press_pad(JOY_BUTTON_DPAD_DOWN)
	check(root.gui_get_focus_owner()==menu.tabs.Conversas,"Controller down follows the same vertical tab order")
	await press_pad(JOY_BUTTON_DPAD_UP); await press_pad(JOY_BUTTON_DPAD_RIGHT)
	check(root.gui_get_focus_owner()!=null and menu.listing.is_ancestor_of(root.gui_get_focus_owner()),"Controller right enters the page content instead of selecting another tab")
	await shot("03-caderno-120-960")
	root.size = Vector2i(1440,900); root.content_scale_size = Vector2i(1440,900); await frames(); await shot("04-caderno-120-1440")
	game._menu(); game.free(); await frames(); prefs.set_text_scale(1)
	print("FIRST_MAP_JOURNAL_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
