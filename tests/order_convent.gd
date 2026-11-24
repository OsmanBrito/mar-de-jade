extends SceneTree
const Plan = preload("res://scripts/city/convent_plan.gd")
const SAVE := "user://qa-convent.json"
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
func walk(point: Vector2) -> bool:
	game.world.walk_to(point)
	for i in 1600:
		await physics_frame
		if game.world.player.position.distance_to(point)<15: return true
		if game.world.player.destination_path.is_empty(): break
	return game.world.player.position.distance_to(point)<20
func go(area: String) -> bool:
	for exit in game.routes.exits:
		if exit.to!=area: continue
		var reached: bool = await walk(exit.point)
		check(reached,"Actual walk to door: "+area)
		if not reached: return false
		game.routes.interact(); await frames()
		check(game.routes.area()==area,"Door interaction enters: "+area)
		return game.routes.area()==area
	check(false,"Missing door to "+area); return false
func capture(name: String) -> void:
	if DisplayServer.get_name()=="headless" or not "--capture" in OS.get_cmdline_user_args(): return
	DirAccess.make_dir_recursive_absolute("res://.qa-runtime/convent-preview")
	await frames(20); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.qa-runtime/convent-preview/"+name+".png")
func run() -> void:
	Engine.time_scale = 3; root.size = Vector2i(1440,900)
	p = root.get_node("ChapterProgress"); p.auto_save = false; p.reset(); p.flags.delivery_pending = true
	root.get_node("CampaignProfile").hero_name = "Miguel"
	game = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate(); root.add_child(game); await frames()
	if not await go("convent"): await finish(); return
	check(game.routes.state.kind=="delivery" and game.scene_index==0,"A convent visit preserves the active delivery and narrative checkpoint")
	var interior: int = game.world.get_instance_id()
	for id in ["water","rule","chapel","linen","attendant"]:
		var point: Vector2 = Plan.NOTES[id].point
		check(game.world.point_clear(point),"Discovery stands on clear ground: "+id)
		var reached: bool = await walk(point); check(reached,"Walk through the real cloister to: "+id)
		if not reached: await finish(); return
		game.routes.interact(); await frames()
		check(game.phase=="order_inspection" and game.view.speaker.text==Plan.NOTES[id].title,"E reads the correct discovery: "+id)
		var feet: Vector2 = game.world.player.position
		game.options_box.get_child(0).pressed.emit(); await frames()
		check(game.phase=="roaming" and game.world.player.position==feet,"Closing the discovery restores the same location: "+id)
		if id in ["water","chapel","linen"]: await capture(id)
	check(game.world.get_instance_id()==interior,"Cloister, chapel and infirmary share one walkable interior")
	check(p.coins==0 and p.skills.is_empty() and not p.flags.get("patient_helped",false),"Exploration does not pay, heal or complete the rescue")
	check(root.get_node("ChapterMusic").context_for(game)=="shelter","Convent exploration uses the house soundtrack")
	game.routes.save(); var saved_position: Array = p.journey.position.duplicate()
	check(p.save_to(SAVE)==OK,"Adult convent location saves")
	check(p.load_from(SAVE)==OK,"Adult convent location passes save validation")
	game._load_block(p.checkpoint,false,true); await frames()
	check(game.routes.area()=="convent" and game.world.player.position==Vector2(saved_position[0],saved_position[1]) and game.routes.state.kind=="delivery","Adult reload preserves room, feet and the pending commitment")
	if not await go("room"): await finish(); return
	check(game.actors.has("Tomé") and game.phase=="roaming","The west door returns to Tomé without starting a later event")
	if not await go("convent") or not await go("square"): await finish(); return
	check(game.routes.continuous() and game.routes.state.kind=="delivery","The portaria returns to the same Lisbon objective")
	game.routes.stop(); game._load_block(1)
	for i in game.events.size():
		if game.events[i].get("id","")=="fetch_tome": game.event_index = i; game.current_event = game.events[i]; break
	game._begin_task(game.current_event)
	game.routes.load_area("convent",Plan.SPAWN); game.routes.resume(); await frames()
	if not await go("room"): await finish(); return
	check(await walk(game.routes.goal),"The cloister route still leads to Tomé during the urgent search")
	game.routes.interact(); await frames()
	check(game.routes.state.kind=="fetch_return","Speaking with Tomé still starts the return to the worker")
	if not await go("convent"): await finish(); return
	check(game.actors.has("Tomé") and game.actors["Tomé"].visible,"Tomé accompanies the player through the convent")
	if not await go("square"): await finish(); return
	check(game.actors.has("Tomé") and game.actors["Tomé"].visible and not p.flags.get("fetch_tome",false) and not p.flags.get("patient_helped",false),"Returning to Lisbon with Tomé does not complete treatment at a distance")
	game.free(); await frames(); p.reset()
	game = load("res://scenes/chapter_01/plaza.tscn").instantiate(); root.add_child(game); await frames()
	check(await walk(Plan.ARCADE),"The child reaches the arcades by actual movement")
	game.roam.interact(); await frames()
	check(game.world.has_meta("order_convent") and game.world.player.presentation.identity=="hero_child","The same convent is accessible with the approved child identity")
	check(await walk(Plan.NOTES.chapel.point),"The child can walk to the chapel")
	game.roam.interact(); await frames(); check(game.phase=="childhood_note","Childhood discovery opens without starting Leonor's lesson")
	game.advance(); game.roam.save()
	check(p.save_to(SAVE)==OK,"Childhood convent location saves")
	var before: Dictionary = p.snapshot()
	game.free(); await frames(); p.reset()
	check(p.load_from(SAVE)==OK,"Childhood convent location loads")
	game = load("res://scenes/chapter_01/plaza.tscn").instantiate(); root.add_child(game); await frames()
	check(game.world.has_meta("order_convent") and game.phase=="childhood_explore" and game.world.player.position==Vector2(before.journey.position[0],before.journey.position[1]),"Reopening the childhood restores the correct interior and position")
	check(p.coins==0 and p.skills.is_empty() and p.inventory=={"PT-Q01":1},"The childhood visit grants no adult rewards or lessons")
	var invalid := before.duplicate(true); invalid.journey.position = [0,480]
	FileAccess.open(SAVE,FileAccess.WRITE).store_string(JSON.stringify(invalid))
	check(p.load_from(SAVE)==ERR_INVALID_DATA and p.snapshot()==before,"A forged interior location cannot place the child in the planted cistern bed")
	var old := before.duplicate(true); old.schema_version = 5
	FileAccess.open(SAVE,FileAccess.WRITE).store_string(JSON.stringify(old))
	check(p.load_from(SAVE)==ERR_INVALID_DATA and p.snapshot()==before,"A pre-convent schema cannot forge the new interior")
	old = before.duplicate(true); old.schema_version = 5; old.journey.area = "square"; old.journey.position = [-250,190]
	FileAccess.open(SAVE,FileAccess.WRITE).store_string(JSON.stringify(old))
	check(p.load_from(SAVE)==OK and p.journey.area=="square","Existing v5 childhood saves retain compatibility")
	check(await walk(Vector2(0,870)),"The child walks to the convent exit")
	game.roam.interact(); await frames()
	check(game.world==game.get_node("Praca") and game.phase=="childhood_explore","Returning reuses the original square and Leonor")
	check(await walk(Vector2(80,400)),"Leonor's original bank remains reachable after the visit")
	game.roam.interact(); check(game.phase=="bank" and p.journey.is_empty(),"Only interacting with Leonor starts the approved lesson")
	await finish()
func finish() -> void:
	if is_instance_valid(game): game.free()
	await frames()
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(SAVE+suffix): DirAccess.remove_absolute(SAVE+suffix)
	print("ORDER_CONVENT_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
