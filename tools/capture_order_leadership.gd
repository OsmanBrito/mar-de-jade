extends SceneTree
var game
var p
var Order
func _initialize():
	ProjectSettings.set_setting("application/config/custom_user_dir_name","Mar-de-Jade-QA-leadership-capture-"+str(Time.get_ticks_usec()))
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir());call_deferred("run")
func frames(n:=12):
	for i in n:await process_frame
func capture(label: String,at: Vector2,zoom:=1.0):
	game.world.player.position=at;game.world.player.enabled=false;game.world.player.camera.offset=Vector2.ZERO;game.world.player.camera_zoom=zoom;game.world.player.camera.zoom=Vector2.ONE*zoom;game.world.player.camera.reset_smoothing()
	game.view.caption_label.text=load("res://scripts/city/convent_plan.gd").title(at)
	if game.phase=="order_inspection":game.view.status.text="Audiência e serviços da Ordem"
	await frames();await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://docs/"+label+".png")
func run():
	root.size=Vector2i(1440,900);p=root.get_node("ChapterProgress");p.auto_save=false;p.reset();p.flags.delivery_pending=true;p.flags.house_adult_done=true
	root.get_node("GamePreferences").persist_enabled=false;root.get_node("CampaignProfile").hero_name="Miguel"
	Order=load("res://scripts/chapter/order_campaign.gd")
	game=load("res://scenes/chapter_01/chapter_flow.tscn").instantiate();root.add_child(game);await frames();game.routes.load_area("convent",Vector2(0,825));game.routes.resume();await frames()
	await capture("ordem-capitulo-planta",Vector2(200,50),.43)
	game.routes.inspect(Order.talk(game.world,p,"grandmaster"));await capture("ordem-audiencia",Vector2(390,-545),1.02)
	p.flags.order_audience_done=true;p.coins=60;p.learn("ES07")
	game.world.player.position=Vector2(230,75);Order.catalog(game,"registry");await capture("ordem-manuais",Vector2(230,75),1.12)
	Order.act(game,"registry","order:view:ES09");await capture("ordem-estudo-detalhes",Vector2(230,75),1.12)
	game.routes.resume();game.world.player.position=Vector2(-850,920);game.routes.inspect(load("res://scripts/city/order_house_hub.gd").talk(game.world,p,"armory"));game.begin_order_trial();await frames()
	await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://docs/ordem-avaliacao.png")
	game._practice_aborted()
	p.style="FO"
	for id in ["FO07","FO01","FO08","FO09","FO10"]:p.learn(id)
	game.world.player.position=Vector2(-850,920);game.routes.inspect(load("res://scripts/city/order_house_hub.gd").talk(game.world,p,"armory"));game.begin_order_practice();await frames()
	await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://docs/ordem-estudo-fogo-combate.png")
	game._practice_aborted();game.free();await frames();print("ORDER_LEADERSHIP_CAPTURE_OK");quit()
