extends SceneTree
const SCENE="res://scenes/chapter_01/childhood_home.tscn"
var checks:=0
var failures:Array[String]=[]
var game
var progress
func _initialize() -> void:call_deferred("run")
func check(value:bool,message:String) -> void:
	checks+=1
	if not value:failures.append(message);push_error(message)
func frames(count:int=4) -> void:
	for i in count:await process_frame
func finish_dialogue() -> void:
	for i in 30:
		if game.phase!="dialogue":return
		game.advance()
	check(false,"Opening conversations terminate")
func table() -> void:
	var at:Vector2=game.places().table.at
	game.world.player.position=Vector3(at.x,0,at.y);game.world.stop();game.interact("table")
func run() -> void:
	progress=root.get_node("ChapterProgress");progress.auto_save=false;progress.reset()
	root.get_node("CampaignProfile").hero_name="Miguel"
	change_scene_to_file(SCENE);await frames(8);game=current_scene
	check(game.objective().contains("Leonor") and game.objective().contains("mesa"),"First goal connects the meal to meeting Leonor")
	check(progress.flags.get("home_bowl",false) and game.world.carried_bowl.visible,"Child begins holding the bowl from the story")
	finish_dialogue();await frames()
	check(game.phase=="explore" and game.view.objective_label.visible,"Exploration has a persistent goal without running the city guide")
	check(game.view.interaction_label.visible and game.view.objective_label.text==game.objective(),"Nearby interaction does not replace the main goal")
	check(game.world.segment_clear(Vector2(0,-4.5),Vector2(0,-7)),"Raised central arch opens a direct axis to the porter's gate")
	var building:Node3D=game.world.get_child(0)
	var banners:Array[MeshInstance3D]=[]
	for node in building.find_children("*","MeshInstance3D",true,false):
		if node.get_blend_shape_count()>0:banners.append(node)
	check(banners.size()==2,"Both authored cloth banners survive glTF import as morph meshes")
	check(not game.world.environment_animators.is_empty(),"Blender cloth animation is present in the runtime")
	if not game.world.environment_animators.is_empty():
		var animator:AnimationPlayer=game.world.environment_animators[0]
		check(animator.is_playing(),"Wind animation starts in normal exploration")
		animator.pause();animator.seek(0,true)
		var previous:Array[float]=[]
		for banner in banners:previous.append(banner.get_blend_shape_value(0))
		animator.seek(1,true)
		for i in banners.size():
			var banner:MeshInstance3D=banners[i]
			check(absf(banner.get_blend_shape_value(0)-previous[i])>.4,"Authored animation actually changes the cloth morph: "+str(i))
			check(banner.mesh.get_surface_count()==2 and banner.material_override==null,"Woven cross keeps its separate red surface: "+str(i))
			var uv:PackedVector2Array=banner.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV]
			check(not uv.is_empty(),"Animated cloth has exportable UVs and valid tangent input: "+str(i))
		animator.play()
	check(is_instance_valid(game.world.water) and game.world.water.material_override is ShaderMaterial,"Fountain uses its own animated water material")
	var knight_players:Array=game.world.knight.find_children("*","AnimationPlayer",true,false)
	var knight_player:AnimationPlayer=knight_players[0]
	check(knight_player.get_animation(knight_player.current_animation).get_track_count()>=5,"Knight exports torso, both shoulders and both elbows as one coordinated clip")
	var elbows:Array=game.world.knight.find_children("Cotovelo*","Node3D",true,false)
	check(elbows.size()==2,"Training knight has two articulated elbows")
	knight_player.pause();knight_player.seek(0,true)
	var rotations:Array[Vector3]=[]
	for elbow in elbows:rotations.append(elbow.rotation)
	knight_player.seek(1,true)
	for i in elbows.size():check(elbows[i].rotation.distance_to(rotations[i])>.1,"Authored elbow actually bends in Godot: "+str(i))
	knight_player.play()
	table();check(game.phase=="dialogue","Fresh game can go directly to the meal")
	finish_dialogue()
	check(progress.flags.get("home_meal",false) and not game.world.carried_bowl.visible,"Meal ends the carrying action")
	check(game.objective().contains("portaria") and game.objective().contains("praça"),"Next goal explains where Leonor is and why to find her")
	game.world.player.position=Vector3(-5.8,0,3.25);game.world.stop();await frames()
	check(progress.flags.get("home_cloister",false) and game.ambient_seconds>0,"First courtyard arrival notices the active training bay")
	check(game.phase=="explore" and game.world.enabled,"Courtyard moment never takes movement control away")
	game.save();var snapshot:Dictionary=progress.snapshot()
	check(progress.restore(snapshot,false)==OK,"New arrival beat passes campaign save validation")
	change_scene_to_file(SCENE);await frames(8);game=current_scene
	check(game.phase=="explore" and game.ambient_seconds==0,"Resuming never repeats the arrival beat")
	# A previously saved welcome, before the old bowl fetch, is still playable.
	progress.reset();progress.flags.home_welcome=true
	change_scene_to_file(SCENE);await frames(8);game=current_scene
	check(not progress.flags.get("home_bowl",false),"Legacy unfinished bowl state is preserved on resume")
	table()
	check(game.phase=="dialogue" and game.view.body.text.contains("tigela para ti"),"Old saves can sit down without a fetch detour")
	finish_dialogue()
	check(progress.flags.get("home_bowl",false) and progress.flags.get("home_meal",false) and not game.world.waiting_bowl.visible,"Meal reconciles old bowl flags and visible objects")
	print("CHILDHOOD_HOME_PRESENTATION_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
