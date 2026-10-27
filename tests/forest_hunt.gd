extends SceneTree
var game
var failures: Array[String] = []
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func frames(n: int) -> void:
	for i in n: await process_frame
func drain() -> void:
	for i in 80:
		if game.phase!="dialogue": break
		game.advance()
func walk(at: Vector2) -> void:
	print("FOREST_WALK ",at," from ",game.world.player.position)
	game.world.walk_to(at)
	for i in 2500:
		if game.world.player.position.distance_to(at)<40: break
		await physics_frame
		if game.world.player.destination_path.is_empty(): break
	check(game.world.player.position.distance_to(at)<60,"Reachable by navigation: "+str(at))
	print("FOREST_ARRIVED ",game.world.player.position)
func stage() -> void:
	await walk(game.Plan.GOALS[int(game.state.stage)])
	game.interact(); drain()
	for i in 240:
		if game.phase!="separating":break
		await physics_frame
func capture(id: String) -> void:
	if DisplayServer.get_name()=="headless": return
	game.world.player.camera.reset_smoothing(); game.world.player.camera.force_update_scroll()
	game.battle_host.queue_redraw(); await frames(2)
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://.qa-runtime/forest-preview")
	root.get_texture().get_image().save_png("res://.qa-runtime/forest-preview/"+id+".png")
func battle(skill: int) -> void:
	var host = game.battle_host; var b = host.combat; var v = host.tactical
	var saw_cutin := false
	host.set_process(false)
	for step in 2500:
		if game.phase!="battle": break
		if v.phase=="choose" and b.current_id==0:
			if b.current().acted: v.start_facing(); v.confirm()
			else: v.select_skill(skill); v.select_cell(b.units[2].cell); v.confirm()
		elif v.phase.begins_with("timing"): v.commit_timing(1)
		if v.phase=="cutin" and not saw_cutin:
			saw_cutin = true; check(v.cutin.body_portrait and v.cutin.actor_name=="Leonor criança","Supreme introduction shows child Leonor")
			v.cutin.elapsed = .8; await capture("suprema")
		v.update(.1)
		if host.ending.running(): host.update_ending(.1)
	check(game.phase=="dialogue","Battle hands back to narrative through ending transition")
	host.set_process(true)
func write_fixture(data: Dictionary) -> void:
	var file := FileAccess.open("user://forest-test.json",FileAccess.WRITE); file.store_string(JSON.stringify(data)); file.close()
func run() -> void:
	Engine.time_scale = 3
	root.get_node("ChapterProgress").auto_save = false
	root.get_node("CampaignProfile").hero_name = "Inês"
	game = load("res://scenes/chapter_01/forest_hunt.tscn").instantiate(); root.add_child(game)
	await frames(8)
	check(game.world.point_clear(game.world.player.position),"Spawn is walkable")
	check(game.world.has_node("ForestGround"),"Forest scenery script installed")
	check(not game.world.point_clear(Vector2(1460,798)) and game.world.point_clear(Vector2(1460,730)),"Near bridge rail blocks its edge while leaving the crossing clear")
	check(game.state.stage==0,"Quest begins before departure")
	drain(); await stage()
	check(game.phase=="choice","Departure offers an actual choice")
	game.choose("departure","signs"); drain()
	for id in game.Plan.DISCOVERIES:
		await walk(game.Plan.DISCOVERIES[id].at); game.interact("note:"+id); drain()
	check(game.state.notes.size()==3,"Optional discoveries recorded by actual exploration")
	await stage(); await stage(); await stage()
	check(game.phase=="choice" and game.state.stage==3,"Bridge reached across the actual trail")
	game.choose("bridge","trust"); drain()
	var p = root.get_node("ChapterProgress")
	game.save(); check(p.save_to("user://forest-test.json")==OK and p.load_from("user://forest-test.json")==OK,"Forest checkpoint round trips")
	var saved: Dictionary = p.snapshot()
	var invalid: Dictionary = saved.duplicate(true); invalid.childhood_hunt.position = [1460,1000]; write_fixture(invalid)
	check(p.load_from("user://forest-test.json")==ERR_INVALID_DATA and p.snapshot()==saved,"Water position rejected without mutating live campaign")
	invalid = saved.duplicate(true); invalid.checkpoint = 5; write_fixture(invalid)
	check(p.load_from("user://forest-test.json")==ERR_INVALID_DATA,"Active childhood quest cannot occupy adult checkpoint")
	game.free(); await frames(2)
	game = load("res://scenes/chapter_01/forest_hunt.tscn").instantiate(); root.add_child(game); await frames(3); drain()
	check(game.state.stage==4 and game.state.notes.size()==3,"Reload resumes quest and optional discoveries")
	check(root.get_visible_rect().has_point(game.world.get_global_transform_with_canvas()*game.world.player.position),"Reload immediately frames the saved character")
	await capture("bridge")
	await stage()
	check(game.state.stage==5 and not game.leonor.visible,"Leonor briefly leaves before the wolf")
	await stage()
	check(game.phase=="battle" and game.battle_kind=="wolf","Wolf uses actual turn battle")
	var rules = game.battle_host.combat
	check(rules.current_id==0,"Hero acts first against wolf")
	await capture("wolf")
	await battle(0)
	check(game.state.stage==6 and rules.units[2].hp<=0 and rules.units[0].hp>0,"Hero kills wolf through actual turns and enemy defense")
	game.save(); check(p.save_to("user://forest-test.json")==OK and p.load_from("user://forest-test.json")==OK,"Between-battle checkpoint saves")
	game.free(); await frames(2)
	game = load("res://scenes/chapter_01/forest_hunt.tscn").instantiate(); root.add_child(game); await frames(3); drain()
	check(game.phase=="battle" and game.battle_kind=="bear" and game.battle_host.combat.current().name=="Leonor criança","Reload after wolf leads directly to playable Leonor")
	await capture("leonor")
	await battle(12); drain()
	check(game.state.stage==7 and p.flags.get("hunt_bear",false),"Supreme technique completes bear battle")
	await stage(); check(game.phase=="choice","Finding rare animal offers observation or approach")
	await frames(3)
	check(game.view.status.get_global_rect().position.x>=0 and game.view.status.get_global_rect().end.x<=root.get_visible_rect().size.x,"Dialogue objective stays inside the viewport after exploration")
	await capture("deer"); game.choose("deer","observe"); drain()
	await stage()
	check(game.completed and game.phase=="complete" and game.state.stage==9,"Whole story returns to Lisbon without teleporting")
	check(p.coins==0 and p.skills.is_empty() and p.passives.is_empty(),"Leonor preview does not unlock adult skills or give currency")
	check(p.choices.hunt_departure=="signs" and p.choices.hunt_bridge=="trust" and p.choices.hunt_deer=="observe","Three shared decisions persist")
	rules = preload("res://scripts/combat/forest_rules.gd").new()
	for skill in preload("res://scripts/combat/forest_rules.gd").LEONOR_SKILLS:
		rules.start_hunt("bear","Inês")
		check(rules.available(skill),"Leonor can select technique "+str(skill))
		var result: Dictionary = rules.perform(skill,rules.units[2].cell,2)
		check(not result.has("error"),"Leonor technique executes: "+str(skill)+" "+str(result.get("error","")))
		check(rules.units[2].hp<=0,"Leonor overwhelms bear: "+str(skill))
	check(preload("res://scripts/city/convent_plan.gd").surfaces().size()==1,"Connected convent uses one merged floor")
	game.free(); await frames(2); p.reset()
	var legacy: Dictionary = p.snapshot(); legacy.schema_version = 7; legacy.erase("childhood_hunt"); write_fixture(legacy)
	check(p.load_from("user://forest-test.json")==OK and p.childhood_hunt.is_empty(),"Version 7 saves remain supported")
	p.reset()
	var training = load("res://scenes/chapter_01/training.tscn").instantiate(); root.add_child(training); current_scene = training; await frames(2)
	training.phase = "complete"; training.advance()
	for i in 120:
		await frames(1)
		if current_scene.get_script().resource_path.ends_with("forest_hunt_director.gd"):break
	check(current_scene.get_script().resource_path.ends_with("forest_hunt_director.gd"),"Training hands off to forest in the real scene tree")
	game = current_scene; game.complete()
	# Let the covered arrival finish before requesting another scene transfer.
	await frames(30);game.advance()
	for i in 120:
		await frames(1)
		if current_scene.get_script().resource_path.ends_with("promise_director.gd"):break
	check(current_scene.get_script().resource_path.ends_with("promise_director.gd"),"Completed hunt continues to the approved childhood promise")
	check(p.save_to("user://forest-test.json")==OK and p.load_from("user://forest-test.json")==OK,"Completed quest remains loadable after leaving the forest")
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists("user://forest-test.json"+suffix): DirAccess.remove_absolute("user://forest-test.json"+suffix)
	print("FOREST_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
