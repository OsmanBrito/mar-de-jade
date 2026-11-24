extends SceneTree
const Plan = preload("res://scripts/city/convent_plan.gd")
var checks := 0
var failures: Array[String] = []
var game
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func frames(n: int = 5) -> void:
	for i in n: await process_frame
func walk(at: Vector2) -> bool:
	game.world.walk_to(at)
	for step in 2000:
		await physics_frame
		if game.world.player.position.distance_to(at)<12: return true
		if game.world.player.destination_path.is_empty(): break
	return false
func run() -> void:
	Engine.time_scale = 3; root.size = Vector2i(1440,900)
	var progress = root.get_node("ChapterProgress"); progress.auto_save = false; progress.reset(); progress.flags.delivery_pending = true
	root.get_node("GamePreferences").persist_enabled = false; root.get_node("CampaignProfile").hero_name = "Miguel"
	game = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate(); root.add_child(game); await frames()
	game.routes.load_area("convent",Plan.SPAWN); game.routes.resume(); await frames()
	var ring := [Vector2(245,760),Vector2(245,660),Vector2(245,520),Vector2(245,350),Vector2(0,350),Vector2(-245,350),Vector2(-245,520),Vector2(-245,660),Vector2(-245,760),Plan.SPAWN]
	for at in ring:
		check(game.world.point_clear(at),"Gallery ring has character clearance: "+str(at))
		check(await walk(at),"Real movement completes the next gallery segment: "+str(at))
	for at in Plan.SIDE_PIERS: check(not game.world.point_clear(at),"Cutaway pier has a physical base: "+str(at))
	check(not game.world.point_clear(Plan.CISTERN),"The relocated cistern cannot be walked through")
	check(await walk(Plan.NOTES.water.point),"The cistern approach is reachable from the gallery")
	check(game.world.sorted_world.get_node("CisternaDoClaustro").position.distance_to(Plan.NOTES.water.point)<70,"The water observation belongs to the nearby physical cistern")
	var water_icon: Node2D
	for discovery in game.routes.discoveries:
		if discovery.id=="water": water_icon = discovery.marker.get_child(0)
	check(water_icon!=null and water_icon.global_position.y-float(water_icon.get("icon_height"))<game.world.player.global_position.y-92,"Focused cistern cue stays above the adult player's face")
	for at in [Vector2(-240,190),Vector2(-240,230),Vector2(-750,770),Vector2(260,-390),Vector2(1000,0),Vector2(370,505)]:
		var focus: Vector2 = Plan.camera_focus(at)
		check(absf(focus.x-at.x)<520 and absf(focus.y-at.y)<350,"Room transition framing retains the player: "+str(at))
	for at in [Plan.CHAPEL_ENTRY,Plan.NOTES.linen.point,Vector2(680,70),Vector2(1340,55),Vector2(230,75),Vector2(265,-395)]:
		check(await walk(at),"The new gallery remains connected to its rooms: "+str(at))
	check(progress.coins==0 and not progress.flags.get("patient_helped",false) and game.routes.state.kind=="delivery","Walking does not advance the story, consume provisions or grant rewards")
	game.free(); await frames()
	print("CONVENT_DIRECTION_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
