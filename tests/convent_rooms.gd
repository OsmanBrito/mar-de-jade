extends "res://tests/order_convent.gd"
func run() -> void:
	Engine.time_scale = 3; root.size = Vector2i(1440,900)
	p = root.get_node("ChapterProgress"); p.auto_save = false; p.reset(); p.flags.delivery_pending = true
	root.get_node("CampaignProfile").hero_name = "Miguel"
	game = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate(); root.add_child(game); await frames()
	if not await go("convent"): await finish(); return
	for id in ["dormitory","refectory","kitchen"]:
		check(game.world.point_clear(Plan.NOTES[id].point),"The new discovery has human clearance: "+id)
		var reached: bool = await walk(Plan.NOTES[id].point)
		check(reached,"Actual movement connects the existing cloister to: "+id)
		if not reached: await finish(); return
		game.routes.interact(); await frames()
		check(game.phase=="order_inspection" and game.view.speaker.text==Plan.NOTES[id].title,"The new room has its own exploration interaction: "+id)
		game.options_box.get_child(0).pressed.emit(); await frames()
		check(Plan.observed(p,id),"Room knowledge persists: "+id)
		await capture(id)
	check(not game.world.point_clear(Vector2(1260,-190)),"The hearth has a real masonry footprint")
	check(await walk(Vector2(1310,5)),"The kitchen helper has a clear approach")
	game.routes.interact(); await frames()
	check(game.phase=="order_inspection" and game.view.speaker.text=="Ajudante da cozinha","The cook explains the supply and refectory route")
	game.options_box.get_child(0).pressed.emit(); await frames()
	check(await walk(Plan.NOTES.linen.point),"Service rooms reconnect to the existing infirmary")
	check(game.routes.state.kind=="delivery" and p.coins==0 and p.skills.is_empty(),"The new rooms do not advance or reward the approved campaign")
	game.free(); await frames(); p.reset()
	game = load("res://scenes/chapter_01/plaza.tscn").instantiate(); root.add_child(game); await frames()
	check(await walk(Plan.ARCADE),"The child reaches the same entrance")
	game.roam.interact(); await frames()
	check(await walk(Plan.NOTES.dormitory.point),"The child reaches the new dormitory by actual movement")
	game.roam.interact(); await frames(); game.advance(); game.roam.save()
	check(p.save_to(SAVE)==OK and p.load_from(SAVE)==OK,"A childhood save accepts the new room coordinate")
	check(p.flags.get("convent_read_dormitory",false) and p.coins==0 and p.skills.is_empty(),"Childhood room knowledge remains separate from adult rewards")
	await finish()
