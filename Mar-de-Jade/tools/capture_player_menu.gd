extends SceneTree
## Reproducible review using the real chapter and modal; does not write a user save.
var game
func _initialize() -> void: call_deferred("run")
func frames(n: int = 4) -> void:
	for i in n: await process_frame
func capture(name: String) -> void:
	await frames(); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/"+name+".png")
	if "--record-menu" in OS.get_cmdline_user_args(): await frames(54)
func run() -> void:
	var p = root.get_node("ChapterProgress"); p.auto_save = false; p.reset()
	root.get_node("CampaignProfile").hero_name = "Aprendiz"
	p.flags = {"recovered":true,"clear_passage":true}; p.checkpoint = 14
	p.tested_styles.assign(["ES","LA","PU"]); p.skills.assign(["ES07","LA07","DP01","DU01"])
	p.passives.assign(["GE21","GE22","ES-P11","LA-P11","DU-P09"]); p.equipped_passives.assign(["GE21","ES-P11"])
	p.duarte_equipped_passives.assign(["DU-P09"])
	p.inventory = {"PT-Q01":1,"PT-W01":1,"PT-V02":1,"PT-A02":1,"PT-C01":2,"PT-C02":1,"PT-C03":1}
	p.equipment = {"weapon":"PT-W01","outfit":"PT-V02","accessory":"PT-A02"}; p.coins = 40
	p.vitals = {"hp":83,"qi":8,"posture":92}
	game = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate(); game.start_block = 14; root.add_child(game); await frames()
	game._finish_block(); game._menu(); await capture("menu-personagem")
	var menu = game.player_menu
	menu.switch_page("Loja de Lisboa"); menu.select_item("PT-V01"); await capture("loja-lisboa")
	menu.action_button.emit_signal("pressed"); await frames()
	menu.switch_page("Inventário"); menu.select_item("PT-V01"); await capture("inventario-portugal")
	menu.action_button.emit_signal("pressed"); await frames()
	menu.select_item("PT-C01"); menu.action_button.emit_signal("pressed"); await frames()
	menu.switch_page("Equipamento"); menu.select_item("PT-V01"); await capture("equipamento-portugal")
	menu.switch_page("Passivas"); menu.show_knowledge(JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_01/passives.json")).passives[0],true)
	await capture("passivas-menu")
	game._menu(); game.free(); await frames(); quit()
