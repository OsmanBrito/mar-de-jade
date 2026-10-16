extends "res://tools/record_combat.gd"
## Five real basic attacks and a perfect parry, in the unmodified campaign host.
func run() -> void:
	root.get_node("ChapterProgress").auto_save = false
	root.get_node("CampaignProfile").hero_name = "Aprendiz"
	for style in ["ES","LA","MC","FO","PU"]:
		if is_instance_valid(game): game.free(); await frames(2)
		game = load("res://scenes/art/combat_study.tscn").instantiate(); game.encounter = "school"; game.style = style; root.add_child(game)
		await frames(27)
		game.hints.text = "MANEJO · "+game.host.combat.STYLES[style].name.to_upper()+"     Ataque básico"
		press(KEY_1); await frames(4); click(game.host.tactical.screen(game.host.combat.units[2].cell)); await frames(12); press(KEY_ENTER)
		if not await phase("timing_attack"): quit(1); return
		for i in 80:
			var v = game.host.tactical
			if v.grade_at(v.clock/v.duration)==2: press(KEY_SPACE); break
			await process_frame
		if not await phase("choose"): quit(1); return
		await frames(15)
	game.free(); await frames(2)
	game = load("res://scenes/art/combat_study.tscn").instantiate(); game.encounter = "perfect_defense"; root.add_child(game)
	await frames(27); game.hints.text = "TOMÉ · DEFESA PERFEITA     Reagir ao golpe"
	press(KEY_T); await frames(12); press(KEY_ENTER)
	if not await phase("timing_defend"): quit(1); return
	for i in 80:
		var v = game.host.tactical
		if v.grade_at(v.clock/v.duration)==2: press(KEY_SPACE); break
		await process_frame
	await frames(65)
	print("COMBAT_STYLES_RECORD_RESULT · five maneuvers and one perfect block")
	game.free(); await frames(2); quit()
