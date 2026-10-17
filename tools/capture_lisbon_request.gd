extends SceneTree
## Isolated visual QA of the playable request; no player saves are read or written.
func _initialize() -> void: call_deferred("run")
func frames(n: int = 8) -> void:
	for i in n: await process_frame
func shot(label: String) -> void:
	await frames(); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://previews/lisbon-request-"+label+".png")
func run() -> void:
	var p = root.get_node("ChapterProgress"); p.auto_save = false; p.reset()
	root.get_node("CampaignProfile").hero_name = "Joana"
	p.flags = {"patient_helped":true,"harbor_pause":true}
	var game = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate(); game.start_block = 3
	root.add_child(game); await frames()
	for id in game.harbor.city.markers:
		var point: Vector2 = game.harbor.city.approach(id)
		print("CITY_APPROACH ",id," ",point," clear=",game.world.point_clear(point))
	game.world.player.position = game.harbor.city.approach("cart")
	game.world.player.camera.reset_smoothing()
	p.local_requests["C01-LIS-01"] = "inspect"
	game.harbor.city.conversation = "cart"; game.harbor.city._cart()
	while game.harbor.city.cursor<game.harbor.city.lines.size(): game.advance()
	await shot("choices")
	game.harbor.city.close(); game._menu("Pedidos")
	for size in [Vector2i(1024,768),Vector2i(1280,800)]:
		root.size = size; await shot("layout-"+str(size.x))
	game._menu()
	game.free(); await frames(); print("LISBON_REQUEST_CAPTURE_COMPLETE"); quit()
