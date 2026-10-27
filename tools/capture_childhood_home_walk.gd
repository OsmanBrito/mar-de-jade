extends SceneTree
const OUT="res://.qa-runtime/childhood-home/walk-review"
var game
func _initialize() -> void:
	ProjectSettings.set_setting("application/config/custom_user_dir_name","Mar-de-Jade-QA-Childhood-Walk")
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir());call_deferred("run")
func run() -> void:
	root.size=Vector2i(1440,900);Engine.max_fps=60
	DirAccess.make_dir_recursive_absolute(OUT)
	var p=root.get_node("ChapterProgress");p.auto_save=false;p.reset();p.flags.home_welcome=true
	root.get_node("CampaignProfile").hero_name="Miguel";root.get_node("GamePreferences").persist_enabled=false
	change_scene_to_file("res://scenes/chapter_01/childhood_home.tscn")
	for i in 45:await process_frame
	game=current_scene
	var frame:=0
	for target in [Vector2(-7.2,6.5),Vector2(-8.4,3.3),Vector2(-9,-7.9)]:
		if not game.world.walk_to(target):push_error("Unable to review walking route: "+str(target));quit(1);return
		for i in 800:
			await physics_frame
			await RenderingServer.frame_post_draw
			if frame%4==0:root.get_texture().get_image().save_png(OUT+"/walk-%04d.png"%frame)
			frame+=1
			if game.world.destination_path.is_empty():break
	print("CHILDHOOD_WALK_CAPTURE_COMPLETE ",frame," frames")
	quit()
