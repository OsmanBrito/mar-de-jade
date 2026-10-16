extends SceneTree
## Capture real chapter scenes without reading or writing the player's saves.
func _initialize() -> void: call_deferred("run")
func frames(n: int = 6) -> void:
	for i in n: await process_frame
func shot(label: String) -> void:
	await frames(10)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://previews/campaign-"+label+".png")
func run() -> void:
	root.get_node("ChapterProgress").auto_save = false
	root.get_node("CampaignProfile").hero_name = "Miguel"
	root.size = Vector2i(1440,900)
	for id in ["opening","plaza","training","promise","adult_opening"]:
		var scene = load("res://scenes/chapter_01/"+id+".tscn").instantiate()
		root.add_child(scene)
		await shot(id)
		if id == "opening":
			for step in 350:
				if scene.completed: break
				if not scene.busy: scene.advance()
				await physics_frame
			await shot("opening-table")
		if id == "plaza":
			for step in 120:
				if scene.leonor.posture == "seated" and not scene.busy: break
				if not scene.busy: scene.advance()
				await physics_frame
			await shot("shared-bench")
		scene.free(); await frames(2)
	var flow = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate()
	root.add_child(flow); await frames()
	for index in [0,1,4,6,12,13,14,16]:
		root.get_node("ChapterProgress").flags.injured = index in [12,13]
		flow._load_block(index)
		for step in 150:
			if not flow.busy: break
			await physics_frame
		flow.world.player.camera.reset_smoothing()
		await shot("block-%02d"%index)
		if index == 4:
			flow.interact_task()
			await shot("meal-dialogue")
	flow.free(); await frames()
	print("CAMPAIGN_MAP_CAPTURES_COMPLETE")
	quit()
