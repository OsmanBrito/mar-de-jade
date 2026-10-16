extends SceneTree
## Reproducible captures from the live renderer, without campaign save writes.
var game
func _initialize() -> void: call_deferred("run")
func frames(n: int) -> void:
	for i in n: await process_frame
func capture(name: String) -> void:
	game.host.queue_redraw()
	await frames(2)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/combate-"+name+".png")
func mount(mode: String,style: String = "ES") -> void:
	if is_instance_valid(game): game.free(); await frames(2)
	game = load("res://scenes/art/combat_study.tscn").instantiate(); game.encounter = mode; game.style = style; root.add_child(game)
	game.host.set_process(false)
	await frames(4)
func defense() -> void:
	var v = game.host.tactical
	v.start_facing(); v.facing = 0; v.confirm(); v.update(1); v.update(2)
	v.clock = v.duration*0.55
	await frames(2)
func run() -> void:
	root.get_node("ChapterProgress").auto_save = false
	root.get_node("CampaignProfile").hero_name = "Inês"
	await mount("child_attack"); await capture("infancia")
	await mount("duel"); await capture("leonor")
	var v = game.host.tactical
	v.select_skill(0); v.select_cell(game.host.combat.units[2].cell); v.confirm(); v.commit_timing(2); v.update(0.45)
	await capture("golpe")
	await mount("perfect_defense"); await defense(); await capture("defesa-perfeita")
	v = game.host.tactical; v.commit_timing(2); v.update(0.46); await capture("aparo")
	await mount("school","LA"); await capture("manejo")
	await mount("duarte_support"); await capture("duarte")
	game.free(); await frames(2); quit()
