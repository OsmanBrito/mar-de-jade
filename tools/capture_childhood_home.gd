extends SceneTree
var game
const OUT="res://.qa-runtime/childhood-home/presentation"
func _initialize() -> void:
	ProjectSettings.set_setting("application/config/custom_user_dir_name","Mar-de-Jade-QA-Childhood-Home-Capture")
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir());call_deferred("run")
func frames(n:int=40) -> void:
	for i in n:await process_frame
func shot(label:String) -> void:
	await frames();await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"/"+label+".png")
func run() -> void:
	root.size=Vector2i(1440,900);DirAccess.make_dir_recursive_absolute(OUT)
	var p=root.get_node("ChapterProgress");p.auto_save=false;p.reset()
	root.get_node("CampaignProfile").hero_name="Miguel";root.get_node("GamePreferences").persist_enabled=false
	change_scene_to_file("res://scenes/chapter_01/childhood_home.tscn");await frames(80);game=current_scene
	await shot("01-acolhimento")
	for i in 3:game.advance()
	for row in [["02-dormitorio",Vector2(-7.2,8.8)],["03-claustro",Vector2(-5.8,3.25)],["04-galeria",Vector2(-1.6,-7.3)],["07-portaria",Vector2(-1.2,-8.7)],["05-patio",Vector2(7.7,.5)]]:
		if row[0]=="03-claustro":
			p.flags.home_meal=true;game.world.carried_bowl.hide();game.world.waiting_bowl.hide()
		game.world.player.position=Vector3(row[1].x,0,row[1].y);game.world.follow_camera(1,true);await shot(row[0])
		if row[0]=="05-patio":await capture_motion()
	game.world.player.position=Vector3(7.7,0,.5);game.interact("practice")
	for i in 3:game.advance()
	game.choose_practice("practice");await shot("06-treino")
	print("CHILDHOOD_HOME_CAPTURE_COMPLETE");quit()

func capture_motion() -> void:
	var motion_out:=OUT+"/motion";DirAccess.make_dir_recursive_absolute(motion_out)
	var animators:Array=game.world.environment_animators.duplicate()
	animators.append_array(game.world.knight.find_children("*","AnimationPlayer",true,false))
	var clips:Array[String]=[]
	for animator in animators:clips.append(animator.current_animation);animator.pause()
	for i in 32:
		for j in animators.size():
			var animator:AnimationPlayer=animators[j]
			animator.seek(fmod(i*.125,animator.get_animation(clips[j]).length),true)
		await RenderingServer.frame_post_draw
		var point:Vector2=game.world.camera.unproject_position(Vector3(9,1.8,-2.4))
		var crop:=Rect2i(Vector2i(point)-Vector2i(100,110),Vector2i(200,220))
		game.viewport.get_texture().get_image().get_region(crop).save_png(motion_out+"/frame-%02d.png"%i)
	for animator in animators:animator.play()
