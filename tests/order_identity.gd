extends SceneTree
const House = preload("res://scripts/chapter/order_house.gd")
const Livery = preload("res://scripts/chapter/order_livery.gd")
var failures: Array[String] = []
var checks := 0
var game
func _initialize() -> void: call_deferred("run")
func check(value: bool,message: String) -> void:
	checks += 1
	if not value: failures.append(message); push_error(message)
func frames(count: int = 3) -> void:
	for i in count: await process_frame
func capture(name: String) -> void:
	if DisplayServer.get_name()=="headless" or not "--capture" in OS.get_cmdline_user_args(): return
	await frames(6); await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://.qa-runtime/order-preview")
	root.get_texture().get_image().save_png("res://.qa-runtime/order-preview/"+name+".png")
func walk(point: Vector2) -> bool:
	game.world.walk_to(point)
	for i in 1000:
		await physics_frame
		if game.world.player.position.distance_to(point)<12: return true
		if game.world.player.destination_path.is_empty(): break
	return game.world.player.position.distance_to(point)<16
class CostumeSheet extends Node2D:
	func _draw() -> void:
		var npc = preload("res://scripts/npcs/lisbon_npc_library.gd")
		var battle = preload("res://scripts/combat/portugal_actor_art.gd")
		for i in 4:
			npc.draw_actor(self,"duarte",i,true,1,"standing",2.1,Vector2(200+i*300,280))
			draw_string(ThemeDB.fallback_font,Vector2(140+i*300,320),["Frente","Perfil oeste","Costas","Perfil leste"][i],HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("eddfbb"))
		for i in 5:
			battle.draw_actor(self,"duarte",Vector2(160+i*270,650),false,["idle","walk","attack","guard","hurt"][i],0.45,"ES",true,0,false,Vector2.RIGHT,2.3)
			draw_string(ThemeDB.fallback_font,Vector2(100+i*270,700),["Espera","Passo","Ataque","Guarda","Reação"][i],HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("eddfbb"))
	func _process(_delta: float) -> void: queue_redraw()
func run() -> void:
	root.size = Vector2i(1440,900)
	root.get_node("CampaignProfile").hero_name = "Joana"
	var p = root.get_node("ChapterProgress"); p.auto_save = false; p.reset()
	var source_path := "res://assets/art/npcs/lisbon/duarte-v1.png"
	var before_hash := FileAccess.get_sha256(source_path)
	game = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate()
	game.start_block = 0; root.add_child(game); await frames()
	game._load_map("courtyard"); game.routes.begin("block",0); await frames()
	check(game.world.has_node("PracaDeLisboa/ConventoDaOrdem"),"The convent replaces the generic shelter facade in the actual square")
	check(game.world.has_node("ActorsAndProps/ConventFootprint"),"Architecture has a physical footprint used by navigation")
	check(game.world.point_clear(preload("res://scripts/city/lisbon_layout.gd").ROOM_ENTRY),"Expanded convent entrance remains physically accessible")
	check(game.world.point_clear(game.routes.order_point),"Order memorial has a reachable approach")
	check(await walk(game.routes.order_point),"Real walking reaches the optional institutional memorial")
	var before: Dictionary = p.snapshot(); var feet: Vector2 = game.world.player.position
	game.routes.interact()
	check(game.phase=="order_inspection" and game.view.body.text.contains("Tomar") and game.view.body.text.contains("Templários"),"Reading identifies the Order, its heritage and the connection to Tomar")
	check(p.snapshot()==before,"Institutional reading grants no rewards or narrative unlocks")
	game.options_box.get_child(0).pressed.emit()
	check(game.phase=="roaming" and game.world.player.position==feet,"Closing returns to the same exploration position")
	game.view.panel.hide(); game.world.player.camera.position_smoothing_enabled = false
	game.world.player.camera.global_position = Vector2(-90,80); game.world.player.camera.offset = Vector2.ZERO; game.world.player.camera.zoom = Vector2.ONE
	await capture("convento")
	game.routes.load_area("room",Vector2(-20,355)); game.routes.resume(); await frames()
	check(game.world.has_node("OrderIdentity"),"Shelter interior has the same institutional heraldry")
	check(await walk(game.routes.order_point),"The shelter ledger is reachable by actual walking")
	before = p.snapshot(); game.routes.interact()
	check(game.phase=="order_inspection" and game.view.body.text.contains("Tomé") and p.snapshot()==before,"Ledger connects institutional life and Tomé without changing approved progress")
	game.options_box.get_child(0).pressed.emit()
	game.world.player.camera.position_smoothing_enabled = false; game.world.player.camera.zoom = Vector2.ONE*1.45
	game.world.player.camera.global_position = Vector2(0,155); game.world.player.camera.offset = Vector2.ZERO
	await capture("acolhimento")
	game.queue_free(); await frames()
	var sample := CostumeSheet.new(); root.add_child(sample); await frames(20)
	if DisplayServer.get_name()!="headless":
		check(Livery.ready_textures.has("walk") and Livery.ready_textures.has("battle"),"GPU costume is available in exploration and combat")
		if Livery.ready_textures.has("walk"):
			var source: Image = load(source_path).get_image()
			var result: Image = Livery.ready_textures.walk.diffuse_texture.get_image()
			var alpha_preserved := source.get_size()==result.get_size()
			for y in range(0,source.get_height(),11):
				for x in range(0,source.get_width(),11):
					if absf(source.get_pixel(x,y).a-result.get_pixel(x,y).a)>.02: alpha_preserved = false
			check(alpha_preserved,"Livery preserves original atlas dimensions and sampled silhouettes")
	await capture("duarte")
	check(FileAccess.get_sha256(source_path)==before_hash,"Original Duarte animation atlas remains unchanged")
	check(Livery.WALK_CHESTS.size()==20 and Livery.BATTLE_CHESTS.size()==9,"Livery accounts for all walk, story and combat poses")
	sample.queue_free(); await frames()
	print("ORDER_IDENTITY_RESULT ",JSON.stringify({"checks":checks,"failures":failures,"rendered":DisplayServer.get_name()!="headless"}))
	quit(0 if failures.is_empty() else 1)
