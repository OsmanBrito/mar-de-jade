extends SceneTree
## Render the quay's real campaign staging without touching the user's checkpoint.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.get_node("CampaignProfile").hero_name = "Inês"
	root.get_node("ChapterProgress").auto_save = false
	var flow = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate()
	flow.start_block = 1; root.add_child(flow)
	for i in 15: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/cais-vivo-capitulo.png")
	flow.free(); quit()
