extends SceneTree
## Visual fixtures; the leadership test separately walks and verifies this route.
var game
func _initialize() -> void:
	ProjectSettings.set_setting("application/config/custom_user_dir_name","Mar-de-Jade-QA-Order-Delivery-"+str(OS.get_process_id()))
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir());call_deferred("run")
func frames(count: int = 12) -> void:
	for i in count:await process_frame
func capture(id: String) -> void:
	await frames();await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.qa-runtime/order-completion/"+id+".png")
func run() -> void:
	root.size=Vector2i(1440,900)
	DirAccess.make_dir_recursive_absolute("res://.qa-runtime/order-completion")
	var p=root.get_node("ChapterProgress");p.auto_save=false;p.reset()
	root.get_node("GamePreferences").persist_enabled=false;root.get_node("CampaignProfile").hero_name="Miguel"
	p.flags={"delivery_pending":true,"house_adult_done":true,"order_audience_done":true,"order_cargo_asked":true,"order_cargo_ledger":true}
	game=load("res://scenes/chapter_01/chapter_flow.tscn").instantiate();root.add_child(game);await frames()
	var order=load("res://scripts/chapter/order_campaign.gd")
	game.routes.load_area("cais",Vector2(1500,1050));game.routes.resume();await frames()
	game.routes.inspect(order.talk(game.world,p,"order_manifest"));order.act(game,"order_manifest","order:manifest")
	await capture("manifesto-no-pontao")
	p.flags.order_cargo_recipient=true
	game.routes.load_area("convent",Vector2(175,-520));game.routes.resume();await frames()
	game.routes.inspect(order.talk(game.world,p,"commander"));order.act(game,"commander","order:cargo_report")
	await capture("entrega-urgente-confirmada")
	print("ORDER_DELIVERY_CAPTURE_OK");game.free();quit()
