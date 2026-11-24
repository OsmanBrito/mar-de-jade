extends SceneTree
## Capture the Botafogo departure deck without touching saves.
## Usage: Godot --path . --script res://tools/capture_deck.gd -- <output_dir> [debug]
func _initialize() -> void: call_deferred("run")
func frames(n: int = 6) -> void:
	for i in n: await process_frame
func shot(dir: String, label: String) -> void:
	await frames(10)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(dir.path_join("deck-"+label+".png"))
func run() -> void:
	var args := OS.get_cmdline_user_args()
	var dir: String = args[0] if args.size() > 0 else "res://previews"
	root.get_node("ChapterProgress").auto_save = false
	root.get_node("CampaignProfile").hero_name = "Miguel"
	root.size = Vector2i(1440,900)
	var flow = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate()
	root.add_child(flow); await frames()
	flow._load_block(16)
	if "debug" in args: flow.world.get_node("ConvesDaBotafogo").set_meta("debug",true)
	for step in 1800:
		if not flow.busy: break
		await physics_frame
	flow.world.player.camera.reset_smoothing()
	await shot(dir,"block-16")
	var overview := Camera2D.new()
	flow.add_child(overview)
	overview.position = Vector2(0,300) if "debug" in args else Vector2(0,150)
	overview.zoom = Vector2.ONE*(1.1 if "debug" in args else 0.5)
	overview.make_current()
	await shot(dir,"overview")
	flow.free(); await frames()
	print("DECK_CAPTURES_COMPLETE")
	quit()
