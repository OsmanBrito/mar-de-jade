extends SceneTree
## Render the live exterior and its HUD using an isolated, unsaved campaign.
var game
var output := "res://.qa-runtime/lisbon-direction"
func _initialize() -> void:
	ProjectSettings.set_setting("application/config/custom_user_dir_name","Mar-de-Jade-QA-Lisbon-Direction")
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir())
	call_deferred("run")
func frames(count: int = 12) -> void:
	for i in count: await process_frame
func shot(label: String) -> void:
	await frames(30)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+"/"+label+".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1440,900)
	var p = root.get_node("ChapterProgress"); p.auto_save = false; p.reset()
	root.get_node("GamePreferences").persist_enabled = false
	root.get_node("CampaignProfile").hero_name = "Miguel"
	p.flags = {"patient_helped":true,"harbor_pause":true}
	game = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate(); game.start_block = 3
	root.add_child(game); await frames()
	print("LISBON_DIRECTION_ACTORS ",game.actors.keys())
	game.world.player.position = preload("res://scripts/city/lisbon_blocks.gd").MAIN_WALK[0]
	for index in preload("res://scripts/city/lisbon_blocks.gd").MAIN_WALK.size():
		var destination: Vector2 = preload("res://scripts/city/lisbon_blocks.gd").MAIN_WALK[index]
		game.world.walk_to(destination)
		for step in 2400:
			await physics_frame
			if game.world.player.position.distance_to(destination)<12: break
			if game.world.player.destination_path.is_empty(): break
		if game.world.player.position.distance_to(destination)>=12:
			push_error("Composition capture could not walk to "+str(destination)); quit(1); return
		if index in [0,3,5,9]: await shot("percurso-"+str(index))
	print("LISBON_COMPOSITION_WALK_COMPLETE")
	for row in [["praca",Vector2(-300,300)],["portaria",Vector2(-740,160)],["ribeira",Vector2(400,990)],["estaleiro",Vector2(-420,1010)],["oficina",Vector2(1370,1020)],["rua-poente",Vector2(-900,570)],["oclusao",Vector2(125,430)]]:
		game.world.player.position = row[1]; game.world.player.camera.reset_smoothing()
		await shot(row[0])
	game.world.player.position = game.harbor.merchant.approach; game.world.player.camera.reset_smoothing()
	await shot("interacao")
	root.size = Vector2i(960,600)
	root.get_node("GamePreferences").set_text_scale(1.2)
	await shot("interacao-960")
	root.size = Vector2i(1440,900); root.get_node("GamePreferences").set_text_scale(1.0)
	var camera := Camera2D.new(); camera.position = Vector2(250,400); camera.zoom = Vector2(.43,.43)
	game.world.add_child(camera); camera.make_current()
	game.view.root.hide()
	await shot("overview")
	game.free(); await frames(2)
	print("LISBON_DIRECTION_CAPTURE_COMPLETE")
	quit()
