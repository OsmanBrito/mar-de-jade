extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.get_node("CampaignProfile").hero_name = "Inês"
	root.get_node("ChapterProgress").auto_save = false
	var flow = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate()
	root.add_child(flow)
	await process_frame
	print("FLOW_READY ",flow.phase)
	flow.queue_free()
	await process_frame
	quit()
