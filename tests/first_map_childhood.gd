extends SceneTree
## The first maps offer the same pointer access and contextual purpose as Lisbon.
const SAVE := "user://qa-first-map-childhood.json"
var checks := 0
var failures: Array[String] = []
var game
var progress

func _initialize() -> void: call_deferred("run")

func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)

func frames(count: int = 8) -> void:
	for i in count: await process_frame

func mount(scene: String) -> void:
	check(change_scene_to_file("res://scenes/chapter_01/"+scene+".tscn")==OK,"First map loads: "+scene)
	await frames()
	game = current_scene
	for i in 30: await physics_frame

func click(control: Control) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT; event.pressed = true
	event.position = control.get_global_rect().get_center()
	root.push_input(event); await frames(1)
	event.pressed = false; root.push_input(event); await frames()

func words(menu) -> String:
	var result := ""
	for node in menu.column.get_children():
		if node is Label: result += node.text+"\n"
	return result

func cursor() -> int:
	return int(game.get("event_index")) if game.scene_file_path.ends_with("plaza.tscn") else int(game.get("cursor"))

func pointer_access(scene: String) -> void:
	var menu = game.get_node("ChildhoodMenu")
	var actions: HBoxContainer = game.view.exploration_actions
	check(actions.visible and actions.get_child_count()==2,"Notebook and menu are visible during "+scene+" exploration")
	check(root.get_visible_rect().encloses(actions.get_global_rect()),"Pointer actions fit the small window in "+scene)
	check(not actions.get_global_rect().intersects(game.view.exploration_back.get_global_rect()),"Pointer actions leave the objective readable in "+scene)
	var feet: Variant = game.world.player.position
	var narrative_cursor: int = cursor()
	var snapshot: Dictionary = progress.snapshot()
	var notebook: Button = actions.get_child(0)
	notebook.grab_focus()
	await click(notebook)
	check(menu.opened and menu.page=="journal" and paused and game.paused,"A real notebook click pauses "+scene)
	var focus: Control = root.gui_get_focus_owner()
	check(focus!=null and menu.screen.is_ancestor_of(focus),"Notebook receives keyboard/controller focus in "+scene)
	check(words(menu).contains("História · Objetivo atual"),"The journal identifies the story objective in "+scene)
	await frames(12)
	check(game.world.player.position==feet and cursor()==narrative_cursor and progress.snapshot()==snapshot,"Reading keeps position, narrative cursor and campaign state in "+scene)
	menu.close(); await frames()
	check(not paused and not game.paused and root.gui_get_focus_owner()==notebook,"Closing returns focus to the notebook button in "+scene)
	await click(actions.get_child(1))
	check(menu.opened and menu.page=="pause" and paused,"A real Menu click opens the shared pause in "+scene)
	menu.close(); await frames()
	check(not paused and game.world.player.position==feet and cursor()==narrative_cursor,"Returning from Menu preserves exploration in "+scene)

func run() -> void:
	root.size = Vector2i(960,600)
	root.content_scale_size = Vector2i(960,600)
	progress = root.get_node("ChapterProgress"); progress.auto_save = false; progress.reset()
	var prefs = root.get_node("GamePreferences"); prefs.persist_enabled = false; prefs.set_text_scale(1.2)
	root.get_node("CampaignProfile").hero_name = "Miguel"
	await mount("childhood_home")
	for i in 8:
		if game.phase!="dialogue": break
		game.advance()
	await frames()
	await pointer_access("home")
	check(game.objective().contains("mesa com Tomé"),"The initial meal remains the first story objective")
	game.phase = "battle"
	game.get_node("ChildhoodMenu").open("journal")
	check(not game.get_node("ChildhoodMenu").opened and not paused,"World notebook access cannot interrupt a battle")
	game.phase = "explore"

	progress.reset(); progress.flags.home_meal = true
	await mount("plaza")
	await pointer_access("plaza")
	var menu = game.get_node("ChildhoodMenu")
	game.roam.visit(); await frames()
	var purpose: String = game.objective()
	check(purpose.contains("Regressa à praça") and purpose.contains("corredor sul"),"The convent gives the immediate exit step before Leonor's destination")
	check(game.view.exploration_objective==purpose,"The HUD uses the contextual childhood objective")
	menu.open("journal"); await frames()
	check(words(menu).contains(purpose),"The notebook shares the convent objective with the HUD")
	progress.flags.house_child_asked = true; menu.refresh()
	check(words(menu).contains("Serviço opcional · Em curso") and words(menu).contains("Recolhe água"),"An optional service has its own heading and current step")
	progress.flags.house_child_done = true; menu.refresh()
	check(words(menu).contains("Serviço opcional · Concluído") and not words(menu).contains("Serviço opcional · Em curso"),"Completed service is distinguished from active work")
	menu.close(); game.roam.leave(); await frames()
	check(game.objective().contains("Encontra a Leonor") and not game.objective().contains("corredor sul"),"Returning outside restores Leonor's objective")
	game.world.player.position = game.roam.PLACES.child.at
	game.roam.interact("child")
	check(game.phase=="childhood_note" and game.view.body.text.contains("Já comeste?") and not game.view.body.text.contains("esperar pela refeição"),"First child conversation remembers the meal")
	game.advance(); game.roam.interact("child")
	check(game.view.body.text.contains("ainda está à tua espera") and not game.view.body.text.contains("refeição"),"Repeated child conversation does not reset meal continuity")
	game.advance(); progress.flags.erase("home_meal"); progress.flags.erase("city_child_met")
	game.roam.interact("child")
	check(game.view.body.text==game.roam.PLACES.child.text,"Legacy entry without a meal keeps the established conversation")
	game.advance(); game.roam.interact("child")
	check(game.view.body.text.contains("vou esperar pela refeição"),"Legacy repeat remains available without the new meal flag")
	game.advance(); game.roam.save()
	var snapshot: Dictionary = progress.snapshot()
	check(progress.save_to(SAVE)==OK and progress.load_from(SAVE)==OK and progress.snapshot()==snapshot,"Childhood presentation changes preserve the existing save format and state")

	progress.reset(); progress.flags.child_forest_invited = true
	await mount("forest_hunt")
	await pointer_access("forest")
	game.dialogue([["Leonor criança","Vamos ver se deixou pegadas."]],"resume"); await frames()
	check(not game.view.exploration_actions.visible,"Pointer actions disappear while the story is speaking")
	game.advance(); game.advance(); await frames()
	check(game.view.exploration_actions.visible,"Exploration restores notebook access after conversation")
	prefs.set_text_scale(1)
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(SAVE+suffix): DirAccess.remove_absolute(SAVE+suffix)
	print("FIRST_MAP_CHILDHOOD_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
