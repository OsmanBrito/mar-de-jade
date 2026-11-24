extends SceneTree
const OUT="res://.qa-runtime/childhood-home/vertical-walk/native"
var game
func _initialize() -> void:
	ProjectSettings.set_setting("application/config/custom_user_dir_name","Mar-de-Jade-QA-Vertical-Walk")
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir());call_deferred("run")
func run() -> void:
	root.size=Vector2i(1440,900);Engine.max_fps=60
	DirAccess.make_dir_recursive_absolute(OUT)
	var p=root.get_node("ChapterProgress");p.auto_save=false;p.reset();p.flags.home_welcome=true
	root.get_node("CampaignProfile").hero_name="Miguel";root.get_node("GamePreferences").persist_enabled=false
	change_scene_to_file("res://scenes/chapter_01/childhood_home.tscn")
	for i in 45:await process_frame
	game=current_scene;game.world.player.position=Vector3(-7.2,0,9);game.world.stop();game.world.follow_camera(1,true)
	var frame:=0
	for target in [Vector2(-7.2,6.5),Vector2(-7.2,9)]:
		if not game.world.walk_to(target):push_error("Unable to capture vertical walk");quit(1);return
		for i in 200:
			await physics_frame
			await RenderingServer.frame_post_draw
			if frame%2==0:
				root.get_texture().get_image().save_png(OUT+"/screen-%04d.png"%frame)
				var point:Vector2=game.world.camera.unproject_position(game.world.visual_position+Vector3(0,.6,0))
				var crop:=Rect2i(Vector2i(point)-Vector2i(30,40),Vector2i(60,80))
				game.viewport.get_texture().get_image().get_region(crop).save_png(OUT+"/child-%04d.png"%frame)
			frame+=1
			if game.world.destination_path.is_empty():break
	print("CHILDHOOD_VERTICAL_WALK_CAPTURE_COMPLETE ",frame," frames")
	quit()
