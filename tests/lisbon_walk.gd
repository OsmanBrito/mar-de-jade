extends SceneTree
var game
var p
var checks := 0
var failures: Array[String] = []
var originals: Dictionary = {}
func _initialize() -> void: call_deferred("run")
func frames(count: int = 3) -> void:
	for i in count: await process_frame
func check(value: bool,message: String) -> void:
	checks += 1
	if not value: failures.append(message); push_error(message)
func press() -> void:
	var event := InputEventKey.new(); event.physical_keycode = KEY_E; event.keycode = KEY_E; event.pressed = true
	root.push_input(event); await frames(); event.pressed = false; root.push_input(event); await frames()
func walk(point: Vector2) -> bool:
	game.world.walk_to(point)
	for i in 1800:
		if game.world.player.position.distance_to(point)<12 and game.world.segment_clear(game.world.player.position,point): return true
		await physics_frame
		if game.world.player.destination_path.is_empty(): break
	return game.world.player.position.distance_to(point)<12 and game.world.segment_clear(game.world.player.position,point)
func passage(to: String) -> void:
	if game.routes.continuous() and to in ["square","cais"]:
		var same_world: int = game.world.get_instance_id()
		var point := Vector2(-130,350) if to=="square" else Vector2(350,1030)
		check(await walk(point),"Player walks continuously to district: "+to)
		check(game.routes.area()==to and game.world.get_instance_id()==same_world,"District crossing retains the same exterior instance: "+to)
		return
	for exit in game.routes.exits:
		if exit.to!=to: continue
		check(game.world.point_clear(exit.point),"Passage is physically clear: "+to)
		check(await walk(exit.point),"Player walks through collisions to passage: "+to)
		await press(); check(game.routes.area()==to,"E crosses the actual passage: "+to); return
	check(false,"Passage exists to "+to)
func goal() -> void:
	check(await walk(game.routes.goal),"Player reaches the meeting using real movement")
	await press()
func capture(label: String) -> void:
	if DisplayServer.get_name()=="headless" or not OS.get_cmdline_user_args().has("--capture"): return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.qa-runtime/walk-"+label+".png")
func run() -> void:
	Engine.time_scale = 3.0
	for path in ["user://capitulo-01.json","user://campanha-perfil.json","user://preferencias.cfg"]:
		originals[path] = FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "absent"
	p = root.get_node("ChapterProgress"); p.auto_save = false; p.reset(); p.flags.delivery_pending = true
	var prefs = root.get_node("GamePreferences"); prefs.persist_enabled = false
	prefs.bindings = prefs.DEFAULT_BINDINGS.duplicate(); prefs.apply_bindings()
	root.get_node("CampaignProfile").hero_name = "Miguel"
	game = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate(); root.add_child(game); await frames()
	check(game.phase=="roaming" and game.map_kind=="room","Adult delivery begins inside the shelter, not teleported to the quay")
	await capture("shelter")
	var before: int = game.event_index; game.advance()
	check(game.map_kind=="room" and game.event_index==before,"Continue cannot skip the walk")
	await passage("square"); await capture("square"); await passage("cais"); await capture("quay"); await goal()
	check(game.phase=="task" and game.task_id=="delivery","Arriving starts the delivery at the receiver")
	await press(); game._deliver(true); game.advance(); await frames()
	check(game.phase=="roaming" and game.map_kind=="cais" and game.routes.state.kind=="stage","Finishing delivery leaves the player on the quay to walk back")
	await passage("square"); await passage("room")
	check(game.routes.state.kind=="stage" and not p.flags.get("lever",false),"Player can enter the shelter on a detour without advancing the plot")
	game.routes.save(); DirAccess.make_dir_recursive_absolute("res://.qa-runtime")
	check(p.save_to("res://.qa-runtime/walk-state.json")==OK,"Journey saves with the chapter")
	var expected: Dictionary = p.snapshot(); p.reset()
	check(p.load_from("res://.qa-runtime/walk-state.json")==OK and p.snapshot()==expected,"Location and pending meeting survive reload")
	game._load_block(p.checkpoint,false,true); await frames()
	check(game.map_kind=="room" and game.phase=="roaming" and game.routes.state.stage=="delivery_return","Reload restores the detour, not a later conversation")
	await passage("square"); await goal()
	check(game.phase=="dialogue" and game.scene_index==0 and game.view.body.text=="O apoio saiu antes do golpe.","Only talking to Duarte begins his approved lesson")
	var invalid: Dictionary = expected.duplicate(true); invalid.journey.area = "unknown"
	FileAccess.open("res://.qa-runtime/walk-invalid.json",FileAccess.WRITE).store_string(JSON.stringify(invalid))
	var live: Dictionary = p.snapshot()
	check(p.load_from("res://.qa-runtime/walk-invalid.json")==ERR_INVALID_DATA and p.snapshot()==live,"Invalid city state cannot mutate the live campaign")
	invalid = expected.duplicate(true); invalid.journey.target = 16
	FileAccess.open("res://.qa-runtime/walk-invalid.json",FileAccess.WRITE).store_string(JSON.stringify(invalid))
	check(p.load_from("res://.qa-runtime/walk-invalid.json")==ERR_INVALID_DATA and p.snapshot()==live,"A forged destination cannot skip to the final chapter scene")
	var legacy: Dictionary = expected.duplicate(true); legacy.erase("journey")
	FileAccess.open("res://.qa-runtime/walk-invalid.json",FileAccess.WRITE).store_string(JSON.stringify(legacy))
	check(p.load_from("res://.qa-runtime/walk-invalid.json")==OK and p.journey.is_empty(),"Older saves without a pending journey remain compatible")
	game._load_block(1)
	for i in game.events.size():
		if game.events[i].get("id","")=="fetch_tome": game.event_index = i; game.current_event = game.events[i]; break
	game._begin_task(game.current_event); await frames()
	check(game.map_kind=="cais" and game.phase=="roaming","Fetching Tomé starts at the accident without an automatic interior cut")
	await passage("square"); await passage("room"); await goal()
	check(game.routes.state.kind=="fetch_return" and game.map_kind=="room","Talking to Tomé creates the return trip instead of teleporting to treatment")
	game.routes.save(); check(p.save_to("res://.qa-runtime/walk-state.json")==OK,"Return with Tomé can be saved")
	check(p.load_from("res://.qa-runtime/walk-state.json")==OK,"Return with Tomé passes semantic save validation")
	game._load_block(p.checkpoint,false,true); await frames()
	check(game.routes.state.kind=="fetch_return" and game.map_kind=="room","Reload does not teleport Tomé or start treatment early")
	await passage("square"); await passage("cais")
	check(game.actors.has("Tomé") and game.actors["Tomé"].visible,"Tomé is visible accompanying the return through each area")
	# A saved rest remains an explicit choice; reaching the room does not pass time.
	p.flags.patient_helped = true; p.flags.meal = true
	game.routes.stop(); game._load_block(5); game.routes.begin("rest",6)
	await passage("square"); await passage("room"); await goal()
	check(game.phase=="rest_confirm" and not p.flags.get("evaluation_morning",false),"Entering the shelter does not automatically skip the night")
	game.routes.resume(); check(not p.flags.get("evaluation_morning",false),"Player may postpone rest and keep exploring")
	await goal(); game.routes.rest()
	for i in 90:
		await physics_frame
		if not game.busy: break
	check(p.flags.get("evaluation_morning",false) and game.map_kind=="room" and game.routes.goal_area=="square","Rest starts morning inside the shelter; player must walk to the public demonstration")
	game.free(); await frames()
	for path in originals:
		check(originals[path]==(FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "absent"),"User state preserved: "+path)
	for path in ["res://.qa-runtime/walk-state.json","res://.qa-runtime/walk-state.json.bak","res://.qa-runtime/walk-invalid.json"]: DirAccess.remove_absolute(path)
	print("LISBON_WALK_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
