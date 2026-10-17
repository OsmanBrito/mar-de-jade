extends SceneTree
## Exercise actual scene beats, player interactions and the independent departure map.
var game
var p
var checks := 0
var failures: Array[String] = []
var shots: Dictionary = {}
var pause_checked := false
var save_hashes: Dictionary = {}

func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func frames(n: int = 3) -> void:
	for i in n: await process_frame
func key(code: int) -> void:
	var event := InputEventKey.new(); event.keycode = code; event.physical_keycode = code; event.pressed = true
	root.push_input(event); await frames(); event.pressed = false; root.push_input(event); await frames()
func shot(name: String) -> void:
	if DisplayServer.get_name()=="headless" or shots.has(name): return
	shots[name] = true; await frames(3); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://previews/staging-"+name+".png")
func idle() -> bool:
	for step in 1800:
		if not game.busy: return true
		var beat: String = game.staging.beat
		if beat in ["master_guard","master_disarmed_fighter","master_first_attempt","leonor_holds_point","water_lifted"]:
			await shot(beat)
		if beat=="fighter_attacks" and not pause_checked:
			pause_checked = true
			game._menu("Sistema")
			var feet: Vector2 = game.actors.Mestre.position
			await frames(15)
			check(paused and game.actors.Mestre.position==feet,"Pausing the performance freezes choreography")
			game._menu(); check(not paused and game.busy,"Resume continues the same performance")
		await physics_frame
	check(false,"Choreography finishes within its allotted time")
	return false
func walk(target: Vector2,radius: float = 68) -> bool:
	if game.world.player.position.distance_to(target)<=radius: return true
	for offset in [Vector2.ZERO,Vector2(-40,25),Vector2(40,25)]:
		if not game.world.point_clear(target+offset): continue
		game.world.walk_to(target+offset)
		for i in 900:
			await physics_frame
			if game.world.player.position.distance_to(target)<=radius: return true
			if game.world.player.destination_path.is_empty(): break
	return false

func run() -> void:
	for path in ["user://capitulo-01.json","user://campanha-perfil.json","user://navegacao.json"]:
		save_hashes[path] = FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "absent"
	p = root.get_node("ChapterProgress"); p.auto_save = false; p.reset()
	root.get_node("CampaignProfile").hero_name = "Miguel"
	game = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate(); game.start_block = 6
	root.add_child(game); await frames()
	if not await idle(): await finish(); return
	check(game.staging.audience.size()==6,"Public demonstration has six spectators")
	check(game.staging.beats.has("fighter_attacks") and game.staging.beats.has("master_answers"),"Master shows an exchange before defeating the first fighter")
	check(not game.actors.Combatente.carries_training_tool and game.actors.Mestre.carries_training_tool,"First disarm belongs to the master")
	check(game.actors.Mestre.position.distance_to(game.actors.Combatente.position)>70,"Master and defeated fighter retain separate ground positions")
	check(game.world.sorted_world.find_children("DroppedPracticeTool*","",true,false).size()==1,"First weapon visibly remains on the ground")
	check(game.view.body.text=="Conheces aquele homem?","First demonstration returns to the approved dialogue")
	for i in 8:
		if game.busy: break
		game.advance(); await frames(1)
	if not await idle(): await finish(); return
	var beats: Array = game.staging.beats
	check(beats.find("master_first_attempt")<beats.find("master_regroups") and beats.find("master_regroups")<beats.find("master_second_attempt"),"Master gets two attempts with a visible reset")
	check(beats.has("leonor_holds_point") and not game.actors.Mestre.carries_training_tool,"Leonor disarms the master and holds the point")
	check(game.actors.Leonor.carries_training_tool and game.actors.Leonor.posture=="standing","Leonor remains composed and armed")
	check(game.actors.Leonor.position.distance_to(game.actors.Mestre.position)>55,"Final evaluation pose does not overlap the two actors")
	check(game.world.sorted_world.find_children("DroppedPracticeTool*","",true,false).size()==2,"Both disarms leave visible instruments")
	check(game.view.speaker.text=="Mestre" and game.view.body.text=="Outra vez.","Demonstration preserves its approved aftermath")
	check(not p.flags.get("perfect_defense",false) and p.skills.is_empty(),"Watching Leonor does not teach the protagonist advanced combat")
	game._load_block(7); await frames()
	if not await idle(): await finish(); return
	check(game.staging.audience.is_empty() and not game.world.sorted_world.has_node("PublicAudience"),"Reserved evaluation has no inherited public crowd")
	await shot("private-square")
	p.flags.injured = true
	game._load_block(12); await frames()
	check(game.actors["Tomé"].position.distance_to(game.world.player.position)<110,"Tomé sits beside the patient rather than across the room")
	check(game.staging.camera.enabled and game.staging.camera.zoom.x>=1.9,"Recovery uses an intimate dedicated frame")
	await shot("recovery-conversation")
	for i in 15:
		if game.phase=="task": break
		game.advance(); await frames(1)
	check(game.task_id=="recovery_water" and game.world.player.presentation.posture=="seated","Player is asked to drink while seated at the bed")
	var event_index: int = game.event_index; game.advance()
	check(game.event_index==event_index,"Advancing dialogue cannot skip the water interaction")
	var vitals: Dictionary = p.vitals.duplicate()
	await key(KEY_E)
	if not await idle(): await finish(); return
	check(p.flags.get("recovery_water",false) and p.flags.get("injured",false),"Drinking water does not remove the narrative injury")
	check(p.vitals==vitals and not game.world.player.presentation.carries_cup,"Water gesture is not a magical heal and returns the cup")
	check(game.world.sorted_world.get_node("BedsideSupport").cup_available,"The cup is returned to the bedside support")
	game._load_block(13); await frames()
	if not await idle(): await finish(); return
	check(game.phase=="task" and game.task_id=="recovery_walk","Recovery leads into real controlled walking")
	check(game.world.point_clear(game.world.player.position),"Getting out of bed lands on clear walking ground")
	check(await walk(game.props.marker),"Real movement reaches the first recovery landmark")
	await key(KEY_E)
	check(game.task_step==1 and not p.flags.get("recovered",false),"Reaching the table does not immediately complete recovery")
	check(await walk(game.props.marker),"Player can walk back to Tomé's support")
	await key(KEY_E); await frames()
	check(p.flags.get("recovered",false) and game.map_kind=="room" and game.phase=="roaming","Recovery gives control in the shelter before the walk to practice")
	check(await load("res://tests/lisbon_walk_driver.gd").new().reach(game),"The player walks out to meet Tomé in the courtyard")
	game._load_block(16); await frames()
	check(game.world.scene_file_path=="res://scenes/maps/botafogo_departure.tscn","Departure uses its independent vessel scene")
	check(not game.world.has_node("CityGround") and not game.world.has_node("PracaDeLisboa") and not game.world.has_node("DesgasteLocal"),"Vessel has no city tiles, walls or plaza ground effects")
	check(game.world.sorted_world.find_children("*Oliveira*","",true,false).is_empty(),"No plaza planters or trees survive on deck")
	check(game.has_node("DepartureShore"),"Departure has a separate fixed quay backdrop")
	check(game.world.point_clear(game.world.player.position),"Hero starts on a clear part of the ship")
	check(not game.world.point_clear(Vector2(500,350)),"Walking cannot leave the hull")
	await shot("botafogo")
	for i in 20:
		if game.phase=="task": break
		game.advance(); await frames(1)
	check(game.task_id=="blue_rope","Approved first ship responsibility remains playable")
	check(await walk(Vector2(50,290),20),"White mooring rope can be inspected without crossing the hull")
	await key(KEY_E)
	check(game.task_step==0 and game.view.status.text.contains("branca"),"Choosing Beatriz's rope gives contextual correction instead of completing the task")
	check(await walk(game.props.marker,35),"Blue mooring rope is physically reachable on the new hull")
	var shore_position: Vector2 = game.get_node("DepartureShore").position
	await key(KEY_E)
	check(game.task_step==1 and game.world.get_node("ConvesDaBotafogo").rope_owner==game.world.player,"Picking the blue rope begins a visible handoff")
	check(await walk(game.props.marker),"Player can bring the blue rope to Duarte")
	await key(KEY_E)
	if not await idle(): await finish(); return
	check(p.flags.get("embarked",false) and game.completed,"Actual cast-off completes the chapter")
	check(game.world.position.length()>100 and game.get_node("DepartureShore").position==shore_position,"Ship leaves while Lisbon remains fixed")
	check(game.get_viewport().get_camera_2d().get_parent()==game,"Departure camera does not drift with the vessel")
	check(game.world.get_node("ConvesDaBotafogo").departure_progress==1.0,"Cast-off completes the wake presentation")
	await shot("departure")
	await finish()

func finish() -> void:
	if paused: paused = false
	if is_instance_valid(game): game.free()
	await frames()
	for path in save_hashes:
		var after := FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "absent"
		check(after==save_hashes[path],"User save preserved: "+path)
	print("CHAPTER_STAGING_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
