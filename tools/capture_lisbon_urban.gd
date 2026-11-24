extends SceneTree
## Matched live OpenGL captures; no save files or changes to the gameplay camera.
var game
var output := "res://.qa-runtime/lisbon-urban/before"
func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument in ["before","after"]: output = "res://.qa-runtime/lisbon-urban/"+argument
	ProjectSettings.set_setting("application/config/custom_user_dir_name","Lisbon-Urban-QA")
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir())
	call_deferred("run")
func frames(count: int) -> void:
	for i in count: await process_frame
func shot(label: String) -> void:
	await frames(120)
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png(output+"/"+label+".png")
	assert(result==OK)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1440,900)
	var progress = root.get_node("ChapterProgress"); progress.auto_save = false; progress.reset()
	root.get_node("GamePreferences").persist_enabled = false
	root.get_node("CampaignProfile").hero_name = "Miguel"
	progress.flags = {"patient_helped":true,"harbor_pause":true}
	game = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate(); game.start_block = 3
	root.add_child(game); await frames(12)
	game.routes.begin("block",4)
	for row in [["civic",Vector2(-300,300)],["neighborhood",Vector2(950,350)],["market",Vector2(400,990)],["harbor",Vector2(1370,1020)],["shipyard",Vector2(-420,1010)]]:
		game.world.player.destination_path.clear()
		game.world.player.position = row[1]
		game.world.player.camera.reset_smoothing()
		await shot(row[0])
	var camera := Camera2D.new(); camera.position = Vector2(250,400); camera.zoom = Vector2(.43,.43)
	game.world.add_child(camera); camera.make_current(); game.view.root.hide()
	await shot("overview")
	game.free(); await frames(2)
	print("LISBON_URBAN_CAPTURE_COMPLETE ",output)
	quit()
