extends SceneTree
var game
func _initialize(): call_deferred("run")
func frames(n := 4):
	for i in n: await process_frame
func mount():
	if is_instance_valid(game): game.free(); await frames()
	game = load("res://scenes/art/firearm_study.tscn").instantiate(); root.add_child(game)
	game.host.set_process(false); await frames()
func capture(name: String):
	game.host.queue_redraw(); await frames()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/arma-de-fogo-"+name+".png")
func run():
	root.size = Vector2i(1280,800)
	root.get_node("ChapterProgress").auto_save = false
	root.get_node("GamePreferences").persist_enabled = false
	root.get_node("CampaignProfile").hero_name = "Miguel"
	await mount(); await capture("pratica")
	for action in [1,2,3,8]:
		await mount()
		var v = game.host.tactical
		v.select_skill(action); v.select_cell(game.host.combat.units[0].cell if action==8 else game.host.combat.units[2].cell)
		await capture("previsao-"+str(action))
		v.confirm(); v.commit_timing(2); v.update(0.32 if action!=8 else 0.451)
		await capture("acao-"+str(action))
		if action==3:
			v.update(0.75); await capture("passo-lateral")
	game.free(); await frames(); print("FIREARM_CAPTURE_RESULT: ten native captures"); quit()
