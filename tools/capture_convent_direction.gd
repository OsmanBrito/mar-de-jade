extends SceneTree
var game
var output := "res://.qa-runtime/claustro-direction"
func _initialize() -> void:
	ProjectSettings.set_setting("application/config/custom_user_dir_name","Mar-de-Jade-QA-Cloister")
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir())
	call_deferred("run")
func frames(n: int = 35) -> void:
	for i in n: await process_frame
func shot(label: String) -> void:
	await frames(); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+"/"+label+".png")
func run() -> void:
	root.size = Vector2i(1440,900); DirAccess.make_dir_recursive_absolute(output)
	var progress = root.get_node("ChapterProgress"); progress.auto_save = false; progress.reset(); progress.flags.delivery_pending = true
	root.get_node("GamePreferences").persist_enabled = false; root.get_node("CampaignProfile").hero_name = "Miguel"
	game = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate(); root.add_child(game); await frames(8)
	game.routes.load_area("convent",Vector2(0,805)); game.routes.resume()
	var course := [Vector2(245,760),Vector2(245,520),Vector2(245,350),Vector2(-245,350),Vector2(-245,520),Vector2(-245,760),preload("res://scripts/city/convent_plan.gd").NOTES.water.point]
	for index in course.size():
		game.world.walk_to(course[index])
		for step in 2400:
			await physics_frame
			if game.world.player.position.distance_to(course[index])<12: break
			if game.world.player.destination_path.is_empty(): break
		if game.world.player.position.distance_to(course[index])>=12:
			push_error("Could not walk through the cloister: "+str(course[index])); quit(1); return
		if index in [1,4,6]: await shot("percurso-"+str(index))
	print("CLOISTER_WALK_COMPLETE")
	for row in [["entrada",Vector2(0,805)],["galeria",Vector2(240,550)],["cisterna",preload("res://scripts/city/convent_plan.gd").NOTES.water.point],["capela",Vector2(-240,190)],["enfermaria",Vector2(570,600)],["refeitorio",Vector2(680,70)]]:
		game.world.player.position = row[1]; game.world.player.camera.reset_smoothing(); await shot(row[0])
	var camera := Camera2D.new(); camera.position = Vector2(150,40); camera.zoom = Vector2(.43,.43); game.world.add_child(camera); camera.make_current()
	game.view.root.hide(); await shot("planta")
	game.free(); await frames(2); print("CLOISTER_CAPTURE_COMPLETE"); quit()
