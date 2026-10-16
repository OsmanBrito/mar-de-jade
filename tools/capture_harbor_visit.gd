extends SceneTree
var game
func _initialize() -> void: call_deferred("run")
func frames(n: int = 5) -> void:
	for i in n: await process_frame
func capture(name: String) -> void:
	await frames(); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/"+name+".png")
	if "--record-visit" in OS.get_cmdline_user_args(): await frames(36)
func key(code: int) -> void:
	var event := InputEventKey.new(); event.keycode = code; event.physical_keycode = code; event.pressed = true; root.push_input(event)
	await frames(2); event.pressed = false; root.push_input(event); await frames(2)
func click_world(point: Vector2) -> void:
	var event := InputEventMouseButton.new(); event.button_index = MOUSE_BUTTON_LEFT; event.pressed = true
	event.position = game.world.get_global_transform_with_canvas()*point; event.global_position = event.position
	var motion := InputEventMouseMotion.new(); motion.position = event.position; motion.global_position = event.position; root.push_input(motion,true)
	event.button_mask = MOUSE_BUTTON_MASK_LEFT; root.push_input(event,true)
	await frames(1); event.pressed = false; event.button_mask = 0; root.push_input(event,true)
func walk_to(point: Vector2) -> void:
	await click_world(point)
	for i in 360:
		if game.world.player.destination_path.is_empty(): break
		await process_frame
func run() -> void:
	var p = root.get_node("ChapterProgress"); p.auto_save = false; p.reset()
	root.get_node("CampaignProfile").hero_name = "Aprendiz"
	p.flags = {"recovered":true,"packed":true,"pack":true,"harbor_pause":true,"leonor_departed":true}
	p.inventory["PT-W01"] = 1; p.equipment.weapon = "PT-W01"; p.tested_styles.assign(["ES"])
	load("res://scripts/chapter/player_items.gd").pay_service(p)
	game = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate(); game.start_block = 15; root.add_child(game); await frames(8)
	await walk_to(game.harbor.merchant.approach)
	await capture("comerciante-lisboa")
	await key(KEY_E)
	if not game.menu_open: push_error("Merchant interaction did not open shop"); game.free(); quit(1); return
	game.player_menu.select_item("PT-V03"); await capture("comerciante-loja")
	game.player_menu.action_button.grab_focus(); await key(KEY_ENTER)
	game.player_menu.switch_page("Equipamento"); game.player_menu.select_item("PT-V03")
	game.player_menu.action_button.grab_focus(); await key(KEY_ENTER)
	await key(KEY_ESCAPE); await capture("comerciante-retorno")
	await walk_to(game.harbor.GATE+Vector2(-55,20)); await key(KEY_E)
	if game.phase != "boarding": push_error("Duarte interaction did not open boarding review"); game.free(); quit(1); return
	await capture("lisboa-embarque")
	game.options_box.get_child(1).grab_focus(); await key(KEY_ENTER)
	await capture("lisboa-capitao")
	game.free(); await frames(); quit()
