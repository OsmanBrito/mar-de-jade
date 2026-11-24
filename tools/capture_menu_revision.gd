extends SceneTree
## Reproducible review using the real chapter and modal; does not write a user save.
var game
func _initialize() -> void:
	ProjectSettings.set_setting("application/config/custom_user_dir_name","Mar-Jade-Menu-QA")
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir())
	call_deferred("run")
func frames(n: int = 4) -> void:
	for i in n: await process_frame
func capture(name: String) -> void:
	await frames(); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.qa-runtime/menu-review/"+name+".png")
	if "--record-menu" in OS.get_cmdline_user_args(): await frames(54)
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://.qa-runtime/menu-review")
	root.size=Vector2i(1280,800)
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
	var before: Dictionary=p.snapshot()
	var passives: Array=JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_01/passives.json")).passives
	for row in passives:
		if row.owner=="hero" and not p.passives.has(row.id):
			menu.show_knowledge(row,true)
			for child in menu.details.get_children(): assert(not child is Button)
			await capture("passiva-bloqueada")
			break
	assert(before==p.snapshot())
	menu.knowledge_category="Equipadas"; menu.refresh()
	assert(menu.row_buttons.size()==p.equipped_passives.size())
	menu.switch_page("Técnicas")
	menu.switch_page("Técnicas")
	p.flags.order_audience_done=true; p.flags.order_trial_done=true; p.flags.order_manual_ES09=true
	menu.refresh()
	var rows: Array=JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_01/skill_icons.json")).skills
	for row in rows:
		if row.id=="ES09":
			menu.show_knowledge(row,false)
			await capture("manual-aprender")
			for child in menu.details.get_children():
				if child is Button and child.text=="Aprender técnica": child.pressed.emit(); break
			assert(p.skills.has("ES09"))
			assert(not preload("res://scripts/chapter/character_development.gd").equipped(p,"ES09"))
			for child in menu.details.get_children():
				if child is Button and child.text=="Preparar técnica": child.pressed.emit(); break
			assert(preload("res://scripts/chapter/character_development.gd").equipped(p,"ES09"))
			await capture("tecnica-preparada")
	menu.knowledge_category="Preparadas"; menu.refresh()
	assert(menu.row_buttons.has("ES09") and not menu.row_buttons.has("DP01"))
	root.size=Vector2i(960,600); menu.knowledge_category="Todas"; menu.refresh(); await capture("tecnicas-960")
	root.size=Vector2i(960,600); await frames(); menu.switch_page("Inventário"); menu.select_item("PT-V01"); await capture("inventario-960")
	print("MENU_LEARNING_OK")
	game._menu(); game.free(); await frames(); quit()
