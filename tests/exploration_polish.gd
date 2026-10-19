extends SceneTree
const Plan = preload("res://scripts/city/convent_plan.gd")
const SAVE := "user://qa-exploration-polish.json"
var game
var p
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func frames(n: int = 3) -> void:
	for i in n: await process_frame
func click(point: Vector2) -> void:
	var event := InputEventMouseButton.new(); event.button_index = MOUSE_BUTTON_LEFT; event.pressed = true
	event.position = game.world.get_global_transform_with_canvas()*point; root.push_input(event)
	await frames(1); event.pressed = false; root.push_input(event); await frames(1)
func wait_for(condition: Callable) -> bool:
	for i in 1400:
		if condition.call(): return true
		await physics_frame
	return condition.call()
func walk(point: Vector2) -> bool:
	game.world.walk_to(point)
	return await wait_for(func(): return game.world.player.position.distance_to(point)<16)
func capture(name: String) -> void:
	if DisplayServer.get_name()=="headless" or not "--capture" in OS.get_cmdline_user_args(): return
	DirAccess.make_dir_recursive_absolute("res://.qa-runtime/polish-preview")
	await frames(20); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.qa-runtime/polish-preview/"+name+".png")
func run() -> void:
	Engine.time_scale = 3; root.size = Vector2i(1440,900)
	p = root.get_node("ChapterProgress"); p.auto_save = false; p.reset(); p.flags.delivery_pending = true
	root.get_node("CampaignProfile").hero_name = "Miguel"
	var prefs = root.get_node("GamePreferences"); prefs.persist_enabled = false; prefs.bindings = prefs.DEFAULT_BINDINGS.duplicate(); prefs.apply_bindings()
	game = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate(); root.add_child(game); await frames()
	check(game.phase=="roaming","The adult delivery begins in exploration")
	var door := Vector2.ZERO
	for exit in game.routes.exits:
		if exit.to=="convent": door = exit.point
	await click(door)
	check(not game.routes.intent.pending.is_empty(),"A real mouse click queues approach to the selected door")
	check(await wait_for(func(): return game.routes.area()=="convent"),"Approaching the door automatically enters the convent")
	check(game.scene_index==0 and game.routes.state.kind=="delivery","Click traversal preserves the current story commitment")
	await click(Plan.NOTES.water.point)
	check(await wait_for(func(): return game.phase=="order_inspection"),"Clicking a discovery walks to it before opening the text")
	check(Plan.observed(p,"water") and p.coins==0 and p.skills.is_empty(),"Observation records knowledge without currency or combat unlocks")
	var feet: Vector2 = game.world.player.position
	game.options_box.get_child(0).pressed.emit(); await frames()
	check(game.phase=="roaming" and game.world.player.position==feet,"Closing a discovery retains the player's feet")
	check(game.view.exploration_layout and not game.view.brand.visible,"Exploration uses the quiet location and objective header")
	await capture("claustro")
	prefs.controller = true; await frames()
	check(game.view.hint.text.contains("Analógico") and not game.view.hint.text.contains("Clique"),"Controller hints describe only the available controller actions")
	check(game.view.status.text.begins_with("A ·"),"The focused interaction uses the controller button")
	prefs.controller = false; prefs.bindings.interact = KEY_F; prefs.apply_bindings(); await frames()
	check(game.view.status.text.begins_with("F ·"),"Rebinding interact updates the focused prompt")
	prefs.bindings.interact = KEY_E; prefs.apply_bindings(); await frames()
	check(await walk(Plan.CHAPEL_ENTRY+Vector2(0,40)),"The remodelled cloister connects to the western chapel opening")
	await click(Plan.NOTES.chapel.point)
	check(await wait_for(func(): return game.phase=="order_inspection"),"Clicking the chapel discovery respects the physical approach")
	check(Plan.observed(p,"chapel"),"The chapel observation persists separately")
	game.options_box.get_child(0).pressed.emit(); await frames()
	await capture("capela")
	game.routes.save(); check(p.save_to(SAVE)==OK and p.load_from(SAVE)==OK and Plan.observed(p,"water") and Plan.observed(p,"chapel"),"Save/load preserves both observations and the current journey")
	game._menu("Pedidos"); await frames()
	var found := false
	for node in game.player_menu.listing.get_children():
		if node is Button and node.text==Plan.NOTES.chapel.title: node.pressed.emit(); found = true; break
	check(found,"The journal lists discoveries already observed")
	var words := ""
	for node in game.player_menu.details.get_children():
		if node is Label: words += node.text
	check(words.contains(Plan.NOTES.chapel.text),"The journal lets the player reread the actual discovery")
	await capture("diario")
	game._menu(); await frames()
	for size in [Vector2i(960,600),Vector2i(1440,900),Vector2i(1920,1080)]:
		root.size = size; await frames(6)
		var visible_size := root.get_visible_rect().size
		check(game.view.caption_label.get_global_rect().end.x<=visible_size.x and game.view.status.get_global_rect().end.x<=visible_size.x,"Location and objective remain inside viewport: "+str(size))
		check(game.view.hint.get_global_rect().position.x>=0 and game.view.hint.get_global_rect().end.x<=visible_size.x and game.view.hint.get_global_rect().end.y<=visible_size.y,"Control hints fit the viewport: "+str(size))
	root.size = Vector2i(1440,900); await frames()
	check(await walk(Vector2(-260,650)),"The cloister exit remains reachable")
	await click(Vector2(0,870))
	check(not game.routes.intent.pending.is_empty(),"A new click queues the exit")
	Input.action_press("move_left"); await physics_frame; await physics_frame; Input.action_release("move_left"); await frames()
	check(game.routes.intent.pending.is_empty() and game.routes.area()=="convent","Manual movement cancels click intent before a doorway can trigger")
	await click(Vector2(0,870))
	check(await wait_for(func(): return game.routes.continuous()),"A later click exits normally after cancellation")
	check(game.scene_index==0 and game.routes.state.kind=="delivery","Neither observation nor cancellation advances the campaign")
	game.free(); await frames(); p.reset()
	game = load("res://scenes/chapter_01/plaza.tscn").instantiate(); root.add_child(game); await frames()
	await click(Plan.ARCADE)
	check(await wait_for(func(): return game.roam.inside()),"Childhood uses the same click-and-approach door control")
	await click(Plan.NOTES.water.point)
	check(await wait_for(func(): return game.phase=="childhood_note"),"Childhood click opens an optional observation")
	check(Plan.observed(p,"water") and not p.flags.get("patient_helped",false),"Childhood knowledge does not complete adult story events")
	game.advance(); await frames()
	check(game.phase=="childhood_explore" and not game.view.caption_label.text.contains("\n"),"Childhood exploration keeps a single readable location line")
	await capture("infancia")
	game.free(); await frames()
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(SAVE+suffix): DirAccess.remove_absolute(SAVE+suffix)
	print("EXPLORATION_POLISH_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
