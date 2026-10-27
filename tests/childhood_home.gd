extends SceneTree
const Plan=preload("res://scripts/chapter/childhood_home_plan.gd")
var checks:=0
var failures:Array[String]=[]
var game
var progress

func _initialize() -> void:call_deferred("run")
func check(value:bool,message:String) -> void:
	checks+=1
	if not value:failures.append(message);push_error(message)
func frames(count:int=3) -> void:
	for i in count:await process_frame
func finish_dialogue() -> void:
	for i in 30:
		if game.phase!="dialogue":return
		game.advance()
	check(false,"Dialogue must terminate")
func visit(id:String) -> void:
	var at:Vector2=game.places()[id].at
	game.world.player.position=Vector3(at.x,0,at.y)
	game.world.stop();game.interact(id)

func run() -> void:
	progress=root.get_node("ChapterProgress");progress.auto_save=false;progress.reset()
	root.get_node("CampaignProfile").hero_name="Miguel"
	check(root.get_node("CampaignProfile").name_entry_destination==Plan.SCENE,"Fresh campaigns route to the new playable home")
	check(change_scene_to_file(Plan.SCENE)==OK,"New opening is a campaign scene")
	await frames(8);game=current_scene
	check(game.world is Node3D and game.world.knight!=null,"Blender environment and articulated knight load in the game")
	var animators:Array=game.world.knight.find_children("*","AnimationPlayer",true,false)
	check(not animators.is_empty() and animators[0].is_playing(),"Blender-authored practice animation actually plays in Godot")
	check(game.display.stretch_shrink==2,"World uses the proposed pixel presentation while UI remains native")
	check(game.world.clear(Plan.SPAWN),"Player spawns on usable ground")
	check(game.view.body.text=="Estão a chamar para comer.","Opening retains the intimate invitation")
	check(progress.flags.get("home_bowl",false) and game.world.carried_bowl.visible and not game.places().has("bowl"),"The opening child already holds his bowl instead of receiving a fetch task")
	finish_dialogue()
	check(game.phase=="explore" and game.world.enabled,"Three spoken lines hand control to the child")
	check(progress.flags.home_welcome,"Initial conversation is remembered")
	var origin:Vector2=game.world.point()
	game.interact("leonor")
	check(game.phase=="explore" and not game.completed,"Remote interaction cannot skip the opening")
	for id in game.places():
		var at:Vector2=game.places()[id].at
		check(game.world.clear(at),"Interaction has an accessible approach: "+id)
		var a:Vector2i=game.world.nearest(origin);var b:Vector2i=game.world.nearest(at)
		check(a.x>=0 and b.x>=0 and not game.world.navigation.get_id_path(a,b).is_empty(),"Connected walking route to "+id)
	check(not game.world.clear(Vector2(0,-1)),"Garden fountain blocks movement")
	check(not game.world.walk_to(Vector2(0,-1)),"Click navigation rejects the fountain")
	Engine.time_scale=4
	var child_at:Vector2=game.places().child.at
	var projected:Vector2=game.world.camera.unproject_position(Vector3(child_at.x,0,child_at.y))
	game.click(projected/Vector2(game.viewport.size)*game.display.size)
	check(game.pending=="child","Pointer coordinates select a person through the pixel viewport")
	for i in 1200:
		await physics_frame
		if game.phase!="explore":break
	check(game.phase=="dialogue" and game.world.point().distance_to(child_at)<1.3,"A click approaches the person before starting conversation")
	finish_dialogue()
	var keyboard_before:Vector2=game.world.point()
	Input.action_press("move_right")
	for i in 6:await physics_frame
	Input.action_release("move_right")
	check(game.world.point().x>keyboard_before.x+.1,"Shared movement bindings control the child")
	for id in ["table","child","stone","voyage","practice","leonor"]:
		var destination:Vector2=game.places()[id].at
		check(game.world.walk_to(destination),"Player accepts a real walking route: "+id)
		for i in 1200:
			await physics_frame
			if game.world.point().distance_to(destination)<.2 or game.world.destination_path.is_empty():break
		check(game.world.point().distance_to(destination)<.25,"Player physically reaches "+id+" without clipping or getting stuck")
	Engine.time_scale=1
	visit("leonor");check(game.phase=="dialogue" and game.after!="leave","Leonor asks the child to eat before leaving")
	finish_dialogue();visit("table");finish_dialogue()
	check(progress.flags.home_meal and progress.flags.home_tome,"Meal retains Tomé's reassurance and story of the father")
	check(not game.world.carried_bowl.visible,"Bowl stops being carried after the meal")
	for id in ["child","stone","voyage"]:visit(id);finish_dialogue()
	check(progress.flags.home_eyes and progress.flags.home_stone and progress.flags.home_voyage,"Exploration remembers discoveries and the child's discomfort about his eyes")
	var notes:Array=preload("res://scripts/chapter/campaign_journal.gd").notes(progress)
	check(notes.any(func(row):return row.id=="home:home_stone"),"Convent discoveries remain readable later in the campaign journal")
	game.save()
	var snapshot:Dictionary=progress.snapshot()
	check(progress.restore(snapshot,false)==OK,"New home progress passes full campaign save validation")
	var bad:Dictionary=snapshot.duplicate(true);bad.journey.position=[0,-1]
	check(progress.restore(bad,false)==ERR_INVALID_DATA,"Invalid saved position inside the fountain is rejected")
	bad=snapshot.duplicate(true);bad.entry_scene="res://scenes/chapter_01/plaza.tscn"
	check(progress.restore(bad,false)==ERR_INVALID_DATA,"Home journey cannot be restored in a different map")
	bad=snapshot.duplicate(true);bad.journey.position=[-8.25,3.31]
	check(progress.restore(bad)==OK and progress.journey.position==[-8.25,3.31],"Save restore keeps metre-scale subpixel position precision")
	var legacy:Dictionary=snapshot.duplicate(true);legacy.entry_scene="res://scenes/chapter_01/opening.tscn";legacy.journey={}
	check(progress.restore(legacy,false)==OK,"Existing opening saves remain loadable")
	progress.restore(snapshot)
	var before:Dictionary=progress.development.duplicate(true)
	visit("practice");finish_dialogue()
	check(game.phase=="choice","Practice is offered as an optional activity")
	game.choose_practice("watch");check(game.phase=="explore","Watching permits continuing without a fight")
	visit("practice");finish_dialogue();game.choose_practice("practice")
	check(game.phase=="battle" and game.battle_container.visible,"Optional practice uses the existing tactical combat")
	check(game.battle_host.combat.safe_training and not game.battle_host.combat.perfect_defense_enabled,"Practice is safe and does not teach Perfect Defense early")
	game.battle_host.combat.valid_hits=2
	check(game.battle_host.check_outcome(),"Two real hits complete the basic practice rules")
	game._practice_finished(true);finish_dialogue()
	check(progress.flags.home_practice and game.phase=="explore","Practice returns to exploration and records completion")
	check(progress.development==before and progress.skills.is_empty(),"Repeated introductory practice grants no adult XP or techniques")
	var menu=game.get_node("ChildhoodMenu");menu.open("journal");await frames()
	check(paused and menu.opened,"Shared journal pauses the new world")
	var frozen:Vector3=game.world.player.position;await frames(5)
	check(game.world.player.position==frozen,"Paused exploration does not move")
	menu.close();check(not paused and not game.paused,"Closing journal restores exploration")
	game.save();var at:Vector2=game.world.point()
	check(change_scene_to_file(Plan.SCENE)==OK,"New opening can be resumed")
	await frames(8);game=current_scene
	check(game.phase=="explore" and game.world.point().distance_to(at)<.04,"Resume restores location without repeating the welcome")
	check(not game.world.carried_bowl.visible,"Completed meal presentation survives resume")
	visit("leonor");finish_dialogue()
	check(game.completed and progress.journey.is_empty(),"Departure clears home exploration state")
	for i in 300:
		await process_frame
		if current_scene!=null and current_scene.scene_file_path.ends_with("plaza.tscn"):break
	check(current_scene!=null and current_scene.scene_file_path.ends_with("plaza.tscn"),"Playable opening rejoins the established Leonor, training and forest route")
	var result:Dictionary={"checks":checks,"failures":failures}
	print("CHILDHOOD_HOME_RESULT ",JSON.stringify(result));quit(0 if failures.is_empty() else 1)
