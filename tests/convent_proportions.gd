extends SceneTree
const Layout = preload("res://scripts/city/lisbon_layout.gd")
var game
var failures: Array[String] = []
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func frames(n: int = 3) -> void:
	for i in n: await process_frame
func walk(point: Vector2) -> bool:
	game.world.walk_to(point)
	for i in 2000:
		await physics_frame
		if game.world.player.position.distance_to(point)<12: return true
		if game.world.player.destination_path.is_empty(): break
	return false
func capture(file: String,center: Vector2,zoom: float) -> void:
	if DisplayServer.get_name()=="headless": return
	game.world.player.enabled = false
	var camera: Camera2D = game.world.player.camera
	camera.position_smoothing_enabled = false
	camera.global_position = center; camera.offset = Vector2.ZERO
	camera.zoom = Vector2.ONE*zoom
	await frames(8); await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://.qa-runtime/convent-scale")
	root.get_texture().get_image().save_png("res://.qa-runtime/convent-scale/"+file+".png")
	game.world.player.enabled = true
func run() -> void:
	root.size = Vector2i(1440,900); Engine.time_scale = 3
	root.get_node("CampaignProfile").hero_name = "Miguel"
	var progress = root.get_node("ChapterProgress"); progress.auto_save = false; progress.reset()
	game = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate()
	game.start_block = 0
	root.add_child(game); await frames()
	game._load_map("courtyard"); game.routes.begin("block",0); await frames()
	var building: Sprite2D = game.world.get_node("PracaDeLisboa/ConventoDaOrdem")
	check(is_equal_approx(building.texture.get_width()*building.scale.x,1360),"The convent has an institutional 1360px frontage")
	check(is_equal_approx(building.scale.x,building.scale.y),"Architecture retains its original proportions")
	check(not game.world.point_clear(Vector2(-900,-60)),"Expanded western masonry blocks walking")
	check(not game.world.point_clear(Vector2(-500,-120)),"The central church volume blocks walking")
	check(game.world.point_clear(Layout.ROOM_ENTRY),"Portaria is outside the new masonry")
	check(game.world.point_clear(Layout.ROOM_RETURN),"Returning from the shelter has a clear landing")
	game.world.player.position = Vector2(0,400)
	check(await walk(Layout.ROOM_ENTRY),"The actual character crosses the enlarged forecourt to the portaria")
	await capture("portaria",Vector2(-640,-150),1.0)
	check(await walk(Layout.CONVENT_ENTRY),"The eastern arcades remain connected to the western portaria")
	check(await walk(Layout.ROOM_RETURN),"The return landing connects to the square")
	await capture("conjunto",Vector2(-350,-100),0.8)
	game.queue_free(); await frames()
	print("CONVENT_PROPORTIONS_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
