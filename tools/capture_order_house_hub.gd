extends SceneTree
var game
func _initialize():
	ProjectSettings.set_setting("application/config/custom_user_dir_name","Mar-de-Jade-QA-hub-capture-"+str(Time.get_ticks_usec()))
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir())
	call_deferred("run")
func frames(n := 12):
	for i in n:await process_frame
func capture(label: String,at: Vector2,zoom: float):
	game.world.player.position=at
	game.view.caption_label.text=load("res://scripts/city/convent_plan.gd").title(at)
	game.world.player.enabled=false
	game.world.player.camera.offset=Vector2.ZERO
	game.world.player.camera_zoom=zoom
	game.world.player.camera.zoom=Vector2.ONE*zoom
	game.world.player.camera.reset_smoothing()
	await frames();await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/ordem-interior-"+label+".png")
func run():
	root.size=Vector2i(1440,900)
	var p=root.get_node("ChapterProgress");p.auto_save=false;p.reset();p.flags.delivery_pending=true
	root.get_node("CampaignProfile").hero_name="Miguel"
	root.get_node("GamePreferences").persist_enabled=false
	game=load("res://scenes/chapter_01/chapter_flow.tscn").instantiate();root.add_child(game);await frames()
	game.routes.load_area("convent",Vector2(0,825));game.routes.resume();await frames()
	await capture("planta",Vector2(200,300),.51)
	await capture("secretaria",Vector2(230,75),1.12)
	await capture("armaria",Vector2(-750,915),1.12)
	game.world.player.position=Vector2(1360,95)
	var hub=load("res://scripts/city/order_house_hub.gd")
	game.routes.inspect(hub.talk(game.world,p,"kitchen"))
	await capture("cozinha",Vector2(1190,115),1.12)
	game.free();await frames();print("ORDER_HUB_CAPTURE_OK");quit()
