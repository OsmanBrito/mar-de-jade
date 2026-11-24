extends SceneTree
var checks := 0
var failures: Array[String] = []
var game
var p
var prefs
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func frames(n: int = 4) -> void:
	for i in n: await process_frame
func key(code: int) -> void:
	var event := InputEventKey.new(); event.keycode = code; event.physical_keycode = code; event.pressed = true; root.push_input(event); await frames(1)
	event.pressed = false; root.push_input(event); await frames()
func pad(code: int) -> void:
	var event := InputEventJoypadButton.new(); event.button_index = code; event.pressed = true; root.push_input(event); await frames(1)
	event.pressed = false; root.push_input(event); await frames()
func words(menu) -> String:
	var result := ""
	for node in menu.column.get_children():
		if node is Label: result += node.text
	return result
func capture(id: String) -> void:
	if DisplayServer.get_name()=="headless": return
	DirAccess.make_dir_recursive_absolute("res://.qa-runtime/continuity-preview")
	await frames(8); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.qa-runtime/continuity-preview/"+id+".png")
func run() -> void:
	Engine.time_scale = 3; root.size = Vector2i(1440,900)
	p = root.get_node("ChapterProgress"); p.auto_save = false
	prefs = root.get_node("GamePreferences"); prefs.persist_enabled = false
	root.get_node("CampaignProfile").hero_name = "Miguel"
	for scene in ["opening","plaza","training","forest_hunt","promise"]:
		p.reset(); game = load("res://scenes/chapter_01/"+scene+".tscn").instantiate(); root.add_child(game); await frames()
		for i in 8:await physics_frame
		var menu = game.get_node("ChildhoodMenu")
		var snapshot: Dictionary = p.snapshot()
		var cursor: Variant = game.get("cursor") if scene=="forest_hunt" else game.get("event_index")
		await pad(JOY_BUTTON_START)
		check(menu.opened and game.paused and paused,"Start opens the shared pause in "+scene)
		await pad(JOY_BUTTON_B)
		check(not menu.opened and not game.paused and not paused,"B resumes the same scene in "+scene+" "+str([menu.opened,game.paused,paused,menu.previous_pause]))
		await pad(JOY_BUTTON_Y)
		check(menu.opened and menu.page=="journal" and words(menu).contains("Objetivo"),"Y opens an actual journal in "+scene)
		await pad(JOY_BUTTON_Y)
		check(not menu.opened and p.snapshot()==snapshot,"Reading never grants rewards or changes the scene checkpoint in "+scene)
		check((game.get("cursor") if scene=="forest_hunt" else game.get("event_index"))==cursor,"Journal does not advance a dialogue in "+scene)
		game.free(); await frames()
	p.reset(); game = load("res://scenes/chapter_01/forest_hunt.tscn").instantiate(); root.add_child(game); await frames()
	for i in 10:
		if game.phase!="dialogue": break
		game.advance()
	var menu = game.get_node("ChildhoodMenu")
	check(prefs.bind_key("interact",KEY_U)=="Comando atualizado." and prefs.bind_key("journal",KEY_H)=="Comando atualizado." and prefs.bind_key("quick_save",KEY_L)=="Comando atualizado.","Interact, journal and save can be rebound in childhood")
	prefs.apply_bindings(); prefs.controller = false; await frames()
	check(game.view.hint.text.contains("U") and game.view.hint.text.contains("H") and game.view.hint.text.contains("L"),"Forest hints show the bound keys: "+game.view.hint.text)
	await key(KEY_J); check(not menu.opened,"Old journal key no longer opens the notebook")
	await key(KEY_H); check(menu.opened and menu.page=="journal","Rebound notebook key opens the notebook")
	await key(KEY_ESCAPE)
	game.world.player.position = Vector2(340,780)
	await key(KEY_E); check(game.phase=="explore","Old interact key cannot bypass the binding: "+game.phase)
	await key(KEY_U); check(game.phase=="dialogue","Bound interaction reaches the actual forest objective")
	await key(KEY_ESCAPE); var cursor: int = game.cursor
	await key(KEY_SPACE); check(game.cursor==cursor,"Confirming a menu never advances the underlying conversation")
	if menu.opened: menu.close()
	menu.open("journal"); p.flags.house_child_asked = true; p.childhood_hunt.notes.append("shelter"); menu.refresh()
	check(words(menu).contains("A água da casa") and words(menu).contains("Um abrigo entre raízes"),"Notebook combines childhood task and forest discoveries")
	prefs.set_text_scale(1.2)
	for size in [Vector2i(960,600),Vector2i(1440,900),Vector2i(1920,1080)]:
		root.size = size; menu.refresh(); await frames(10)
		var viewport := root.get_visible_rect().size
		check(menu.sheet.get_global_rect().position.x>=0 and menu.sheet.get_global_rect().end.x<=viewport.x and menu.sheet.get_global_rect().end.y<=viewport.y,"Shared journal fits 120% text at "+str(size)+" "+str(menu.sheet.get_global_rect()))
		await capture("journal-"+str(size.x))
	menu.settings(); await frames()
	check(menu.settings_open and paused,"Preferences keep the world paused")
	await pad(JOY_BUTTON_B)
	check(menu.opened and not menu.settings_open and paused,"Closing settings returns to the paused menu")
	menu.close(); check(not paused,"Returning from settings releases the shared pause")
	await key(KEY_L); check(menu.opened and menu.message.contains("guardado"),"Rebound save opens its visible confirmation")
	menu.close(); game.free(); await frames()
	var previous_path: String = prefs.path
	prefs.path = "user://qa-old-controls.cfg"
	var legacy := ConfigFile.new()
	for action in prefs.DEFAULT_BINDINGS:
		if action not in ["journal","quick_save"]: legacy.set_value("keys",action,KEY_J if action=="interact" else prefs.DEFAULT_BINDINGS[action])
	legacy.save(prefs.path); prefs.load_settings()
	check(prefs.bindings.interact==KEY_J and prefs.bindings.journal!=KEY_J and prefs.bindings.quick_save==KEY_F5,"Legacy custom bindings survive introduction of notebook and save commands")
	DirAccess.remove_absolute(prefs.path); prefs.path = previous_path
	prefs.bindings = prefs.DEFAULT_BINDINGS.duplicate(); prefs.apply_bindings(); prefs.set_text_scale(1)
	print("CHILDHOOD_CONTROLS_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
