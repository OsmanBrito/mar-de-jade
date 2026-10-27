extends SceneTree
var checks:=0
var failures:Array[String]=[]
var game
var p
func _initialize() -> void:call_deferred("run")
func check(value:bool,message:String) -> void:
	checks+=1
	if not value:failures.append(message);push_error(message)
func frames(n:int=4) -> void:
	for i in n:await process_frame
func mount(file:String) -> void:
	change_scene_to_file("res://scenes/chapter_01/"+file+".tscn");await frames(8);game=current_scene
	for i in 22:await physics_frame
func drain() -> void:
	for i in 70:
		if game.phase!="dialogue":return
		game.advance()
func words(menu) -> String:
	var result:=""
	for node in menu.column.get_children():
		if node is Label:result+=node.text+"\n"
	return result
func walk(at:Vector2) -> void:
	game.world.walk_to(at)
	for i in 1400:
		await physics_frame
		if game.world.player.position.distance_to(at)<20:return
		if game.world.player.destination_path.is_empty():break
	check(false,"Connected journey reaches "+str(at))
func run() -> void:
	p=root.get_node("ChapterProgress");p.auto_save=false;p.reset()
	root.get_node("CampaignProfile").hero_name="Miguel"
	var resources:Dictionary={"coins":p.coins,"skills":p.skills.duplicate(),"inventory":p.inventory.duplicate(true),"vitals":p.vitals.duplicate(true)}
	await mount("plaza")
	check(game.leonor.posture=="crouched" and game.world.sorted_world.has_node("LeonorPracticeTools"),"Leonor is attending to the instruments before the encounter")
	game.roam.interact("leonor")
	check(game.phase=="childhood_explore","A remote request cannot skip approaching Leonor")
	game.world.player.position=Vector2(-25,405)
	for i in 30:await physics_frame
	var covering:=0;var revealed:=true
	for prop in game.world.sorted_world.get_children():
		if prop.get_script()==preload("res://scripts/city/lisbon_prop.gd") and prop.covers(game.leonor.global_position):
			covering+=1;revealed=revealed and prop.occlusion_alpha<.15 and float(prop.cutaway.get_shader_parameter("interest_strength"))>.9
	check(covering>0 and revealed,"Nearby Leonor remains visible through a real foreground facade during free approach")
	check(game.leonor.posture=="crouched","She keeps attending to the tools before noticing the closer approach")
	game.world.player.position=Vector2(80,400);await frames()
	check(game.leonor.posture=="standing","Leonor notices the child approaching")
	var before:Vector2=game.world.player.position
	game.roam.interact("leonor")
	check(game.world.player.position==before and game.view.body.text=="Sai desse lado.","Bank dialogue begins where the child arrived, without a teleport")
	for i in 3:game.advance()
	for i in 12:await physics_frame
	check(game.busy and game.world.player.position.distance_to(before)>2 and game.world.player.presentation.walking,"Taking a place on the bench has an actual directional gait")
	var menu=game.get_node("ChildhoodMenu");menu.open()
	var frozen:Vector2=game.world.player.position
	for i in 10:await physics_frame
	check(game.world.player.position==frozen,"Pause freezes the staged approach as well as free walking")
	menu.close()
	for i in 240:
		await physics_frame
		if not game.busy:break
	check(game.world.player.presentation.posture=="seated" and game.leonor.posture=="seated","Both actors finish seated on the authored bench")
	await mount("training")
	check(game.world.player.presentation.carries_training_tool and game.leonor.carries_training_tool,"Training starts with both instruments visible")
	drain();game._battle_finished(true);drain()
	check(p.flags.get("child_attack_practised",false) and game.lesson==1,"First lesson records a resumable checkpoint")
	check(p.restore(p.snapshot(),false)==OK,"Lesson checkpoint passes campaign save validation")
	await mount("training")
	check(game.lesson==1 and game.view.body.text=="Olha para mim.","Resume does not repeat the completed basic-attack lesson")
	drain();game._battle_finished(true);drain()
	check(game.phase=="washing" and p.flags.get("child_defense_practised",false),"Approved hand injury leads into a visible wash rather than a result card")
	menu=game.get_node("ChildhoodMenu");menu.open("journal");frozen=game.world.player.position
	check(words(menu).contains("lavas a mão"),"Notebook follows the hand-washing context instead of showing a stale training goal")
	for i in 8:await physics_frame
	check(game.world.player.position==frozen and game.phase=="washing","The wash handoff respects the shared pause")
	menu.close()
	for i in 240:
		await physics_frame
		if game.phase=="dialogue":break
	check(game.lines.any(func(row):return str(row.text).contains("corço branco")),"Leonor introduces the reason to visit the bridge herself")
	check(game.lines.any(func(row):return row.text=="Vou contigo."),"The child chooses to accompany her in the scene")
	drain()
	check(game.completed and p.flags.get("child_forest_invited",false),"Reading the invitation unlocks the accompanied departure")
	menu.open("journal");check(words(menu).contains("corço") and words(menu).contains("ponte"),"Notebook explains the purpose of the first outing");menu.close()
	check(p.restore(p.snapshot(),false)==OK,"Completed training and invitation remain saveable")
	await mount("training")
	check(game.phase=="complete" and not game.world.player.presentation.carries_training_tool,"Resume returns to the outing without repeating practice or washing")
	check(game.world.player.position==Vector2(-183,350),"Resumed outing retains its authored staging")
	game.advance()
	for i in 180:
		await physics_frame
		if current_scene!=null and current_scene.scene_file_path.ends_with("forest_hunt.tscn"):break
	game=current_scene;await frames(8)
	check(game.scene_file_path.ends_with("forest_hunt.tscn") and game.phase=="explore","The spoken invitation hands control straight to the forest")
	check(game.lines.is_empty(),"Forest arrival does not repeat the invitation in a narrator paragraph")
	var target:Vector2=game.companion_target()
	check(game.world.point_clear(target) and game.world.segment_clear(game.world.player.position,target),"Leonor's next position is on connected, safe ground")
	game.world.walk_to(game.Plan.GOALS[0])
	var phases:Dictionary={};var companion_moved:=false;var companion_start:Vector2=game.leonor.position
	for i in 80:
		await physics_frame
		if game.world.player.presentation.walking:
			var sample:Dictionary=preload("res://scripts/chapter/childhood_walk_art.gd").sample(game.world.player.facing,game.world.player.frame_time)
			phases[sample.phase]=true
		if game.leonor.position.distance_to(companion_start)>8:companion_moved=true
	check(phases.size()>=6,"Exploration uses the refined eight-phase child walk outside the convent")
	check(companion_moved and game.world.point_clear(game.leonor.position),"Leonor accompanies the physical walk instead of remaining at spawn")
	await walk(game.Plan.GOALS[0]);game.interact();check(game.lines[0][1]=="Foi aqui que o viram?","The departure conversation remembers Leonor's earlier invitation")
	drain();game.choose("departure","signs");drain()
	check(p.choices.hunt_departure=="signs","Their agreement remains a real saved choice")
	game.interact("note:shelter")
	check(game.state.notes.is_empty(),"Discoveries still require walking close enough")
	await walk(game.Plan.DISCOVERIES.shelter.at);game.interact("note:shelter")
	check(game.lines.size()==4 and game.lines.any(func(row):return row[0]=="Leonor criança"),"An optional discovery becomes a short shared conversation")
	check(game.framing.camera.enabled and not game.world.player.camera.enabled,"The shared discovery frames both speakers")
	check(game.state.notes.has("shelter") and p.restore(p.snapshot(),false)==OK,"Spoken discovery keeps the original journal and save state")
	check(resources=={"coins":p.coins,"skills":p.skills.duplicate(),"inventory":p.inventory.duplicate(true),"vitals":p.vitals.duplicate(true)},"Companionship adds no adult rewards, skills or resource changes")
	p.reset();await mount("forest_hunt")
	check(game.phase=="dialogue" and game.view.speaker.text=="Leonor criança","Legacy direct forest entry still has a spoken introduction")
	print("CHILDHOOD_JOURNEY_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
