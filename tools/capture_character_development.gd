extends SceneTree
var game
func _initialize():
	ProjectSettings.set_setting("application/config/custom_user_dir_name","Mar-de-Jade-QA-01a15602-capture-"+str(Time.get_ticks_usec()))
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir())
	call_deferred("run")
func frames(n := 5):
	for i in n: await process_frame
func capture(path: String):
	await frames(); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/"+path+".png")
func run():
	root.size = Vector2i(1280,800)
	var p = root.get_node("ChapterProgress"); p.auto_save = false; p.reset()
	root.get_node("GamePreferences").persist_enabled = false
	root.get_node("CampaignProfile").hero_name = "Miguel"
	p.flags = {"recovered":true,"perfect_defense":true}
	p.style = "FO"; p.tested_styles.assign(["FO"])
	p.inventory["PT-W04"] = 1; p.inventory["PT-V01"] = 1; p.equipment = {"weapon":"PT-W04","outfit":"PT-V01"}
	for id in ["FO07","FO01","FO08","FO09","DP01"]: p.learn(id)
	p.award_development("capture:journey",400)
	p.learn("DU01"); p.learn("GE21","passive"); p.learn("GE22","passive")
	p.equipped_passives.assign(["GE21","GE22"])
	var dev = load("res://scripts/chapter/character_development.gd")
	dev.allocate(p,"hero",{"FOR":5,"AGI":7,"VIG":7,"ESP":7,"PER":6})
	dev.training(p,"FO"); dev.member(p).practice.FO07 = 8
	dev.allocate(p,"duarte",{"FOR":5,"AGI":8,"VIG":6,"ESP":5,"PER":7})
	p.companion_vitals = {"duarte":{"hp":93,"qi":8,"posture":80}}
	game = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate(); game.start_block = 14; root.add_child(game); await frames()
	game.phase = "exploration"; game.busy = false; game._menu("Evolução"); await frames()
	await capture("desenvolvimento-personagem")
	var editor = game.player_menu.listing.get_child(0)
	editor.change_attribute("PER",1)
	await capture("desenvolvimento-previa")
	game.player_menu.listing.get_parent().scroll_vertical = 540
	await capture("desenvolvimento-repertorio")
	root.size = Vector2i(960,600); root.get_node("GamePreferences").text_scale = 1.2
	game.player_menu.refresh(); await frames(); game.player_menu.listing.get_parent().scroll_vertical = 0; await capture("desenvolvimento-960")
	game.free(); paused = false; await frames()
	root.size = Vector2i(1280,800); root.get_node("GamePreferences").text_scale = 1.0
	p.completed = true; p.checkpoint = 16; p.entry_scene = "res://scenes/chapter_01/chapter_flow.tscn"; p.flags.embarked = true; p.flags.packed = true
	var launch = load("res://scripts/navigation/voyage_launch.gd"); launch.mode = "campaign"; launch.resume_requested = false
	game = load("res://scenes/navigation/voyage.tscn").instantiate(); game.auto_save = false; root.add_child(game); await frames()
	game.set_process(false); game.clear_overlay(); game.model.dock("lisboa"); game.open_personal("development"); await frames()
	await capture("desenvolvimento-bordo")
	game.free(); paused = false; await frames(); print("DEVELOPMENT_CAPTURE_RESULT: five native views including 960x600 at 120% text and the ship"); quit()
