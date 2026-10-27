extends SceneTree
var game
func _initialize() -> void:
	ProjectSettings.set_setting("application/config/custom_user_dir_name", "Mar-de-Jade-QA-HD2D-Baseline")
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir())
	call_deferred("run")
func frames(count: int) -> void:
	for i in count: await process_frame
func run() -> void:
	root.size = Vector2i(1440, 900)
	var progress = root.get_node("ChapterProgress")
	progress.auto_save = false
	progress.reset()
	root.get_node("GamePreferences").persist_enabled = false
	root.get_node("CampaignProfile").hero_name = "Miguel"
	progress.flags = {"patient_helped":true, "harbor_pause":true}
	game = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate()
	game.start_block = 3
	root.add_child(game)
	await frames(12)
	for row in [["praca", 0], ["mercado", 5], ["cais", 9]]:
		game.world.player.position = preload("res://scripts/city/lisbon_blocks.gd").MAIN_WALK[row[1]]
		game.world.player.camera.reset_smoothing()
		await frames(30)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.qa-runtime/hd2d/before-" + row[0] + ".png")
	game.queue_free()
	await frames(2)
	print("HD2D_BASELINE_COMPLETE")
	quit()
