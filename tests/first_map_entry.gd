extends SceneTree
## Both saved continuations must remain reachable before starting another campaign.
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func frames(n: int = 8) -> void:
	for i in n: await process_frame
func tab() -> void:
	var event := InputEventKey.new(); event.keycode = KEY_TAB; event.physical_keycode = KEY_TAB; event.pressed = true
	root.push_input(event); await frames(2); event.pressed = false; root.push_input(event); await frames(2)
func shot(name: String) -> void:
	if DisplayServer.get_name()=="headless" or not OS.get_cmdline_user_args().has("--capture"): return
	DirAccess.make_dir_recursive_absolute("res://.qa-runtime/first-map-entry")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.qa-runtime/first-map-entry/"+name+".png")
func run() -> void:
	var p = root.get_node("ChapterProgress"); p.auto_save = false; p.reset()
	var prefs = root.get_node("GamePreferences"); prefs.persist_enabled = false
	root.get_node("CampaignProfile").hero_name = "Inês"
	check(p.save_to()==OK,"Isolated chapter continuation is available")
	var ship = load("res://scripts/navigation/voyage_model.gd").new()
	check(ship.save_to("user://navegacao.json")==OK,"Isolated voyage continuation is available")
	var chapter_hash := FileAccess.get_sha256("user://capitulo-01.json")
	var voyage_hash := FileAccess.get_sha256("user://navegacao.json")
	root.content_scale_size = Vector2i(960,600); root.size = Vector2i(960,600)
	prefs.set_text_scale(1.0)
	var entry = load("res://scenes/chapter_01/name_entry.tscn").instantiate(); root.add_child(entry); await frames()
	var brand: Control = entry.entry_content.get_node("Brand")
	check(entry.entry_scroll.scroll_vertical==0 and entry.entry_scroll.get_global_rect().encloses(brand.get_global_rect()),"Initial focus keeps the game title visible at 100 percent")
	check(entry.name_field.has_focus(),"The visible initial name field keeps keyboard focus")
	await shot("960-100-inicio")
	var actions: Array[Button] = []
	for child in entry.confirm_button.get_parent().get_children():
		if child is Button: actions.append(child)
	check(actions.any(func(button): return button.text=="Continuar viagem guardada") and actions.any(func(button): return button.text=="Continuar capítulo guardado"),"Entry presents both existing continuations")
	var card: Control = entry.get_node("Center/Card")
	var scroll: ScrollContainer = entry.entry_scroll
	entry.name_field.text = "Inês"; entry.name_field.text_changed.emit(entry.name_field.text)
	for size in [Vector2i(960,600),Vector2i(1440,900)]:
		root.content_scale_size = size; root.size = size
		for scale in [1.0,1.2]:
			prefs.set_text_scale(scale); await frames(12)
			check(root.get_visible_rect().encloses(card.get_global_rect()),"Entry card fits both saves at "+str(size)+" and reading scale "+str(scale))
			check(entry.name_field.get_theme_font_size("font_size")==prefs.font_size(24),"Entry applies current reading scale to the name field")
			entry.name_field.grab_focus(); await frames()
			check(scroll.get_global_rect().encloses(entry.name_field.get_global_rect()),"Returning to the name field brings it into view")
			await shot(str(size.x)+"-"+str(roundi(scale*100))+"-nome")
			var last: Button = actions[actions.size()-1]
			for i in 12:
				if last.has_focus(): break
				await tab()
			check(last.has_focus(),"Keyboard focus reaches the final saved continuation")
			check(scroll.get_global_rect().encloses(last.get_global_rect()),"Focus scrolls the final continuation fully into view")
			if size.y==600: check(scroll.scroll_vertical>0,"Short entry scrolls instead of clipping the continuations")
			await shot(str(size.x)+"-"+str(roundi(scale*100))+"-continuar")
	check(FileAccess.get_sha256("user://capitulo-01.json")==chapter_hash and FileAccess.get_sha256("user://navegacao.json")==voyage_hash,"Opening and navigating the entry preserves both saved campaigns")
	entry.free(); await frames()
	root.content_scale_size = Vector2i(960,600); root.size = Vector2i(960,600); prefs.set_text_scale(1.2)
	entry = load("res://scenes/chapter_01/name_entry.tscn").instantiate(); root.add_child(entry); await frames()
	brand = entry.entry_content.get_node("Brand")
	check(entry.entry_scroll.scroll_vertical==0 and entry.entry_scroll.get_global_rect().encloses(brand.get_global_rect()),"Initial focus keeps the game title visible at 120 percent")
	check(entry.name_field.has_focus(),"Enlarged initial entry keeps keyboard focus on the name")
	await shot("960-120-inicio")
	entry.free(); await frames()
	print("FIRST_MAP_ENTRY_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
