extends SceneTree
## Capture the shelter (childhood, adult room, overview) without touching saves.
## Usage: Godot --path . --script res://tools/capture_shelter.gd -- <output_dir>
func _initialize() -> void: call_deferred("run")
func frames(n: int = 6) -> void:
	for i in n: await process_frame
func shot(dir: String, label: String) -> void:
	await frames(10)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(dir.path_join("shelter-"+label+".png"))
func run() -> void:
	var args := OS.get_cmdline_user_args()
	var dir: String = args[0] if args.size() > 0 else "res://previews"
	root.get_node("ChapterProgress").auto_save = false
	root.get_node("CampaignProfile").hero_name = "Miguel"
	root.size = Vector2i(1440,900)
	var opening = load("res://scenes/chapter_01/opening.tscn").instantiate()
	root.add_child(opening)
	await shot(dir,"child")
	var ground: TileMapLayer = opening.room.get_node("Ground")
	print("FLOOR ",opening.room.get_node("ShelterFloor").polygon," cells ",ground.get_used_rect())
	var overview := Camera2D.new()
	opening.room.add_child(overview)
	overview.position = Vector2(0,200)
	overview.zoom = Vector2.ONE*0.75
	overview.make_current()
	await shot(dir,"overview")
	opening.free(); await frames(2)
	var flow = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate()
	root.add_child(flow); await frames()
	for index in [12,4]:
		root.get_node("ChapterProgress").flags.injured = index == 12
		flow._load_block(index)
		for step in 1800:
			if not flow.busy: break
			await physics_frame
		flow.world.player.camera.reset_smoothing()
		await shot(dir,"block-%02d"%index)
	flow.free(); await frames()
	print("SHELTER_CAPTURES_COMPLETE")
	quit()
