extends "res://tools/record_combat.gd"
## Contextual route and line-of-sight review, entirely through actual game inputs.
func run() -> void:
	root.get_node("ChapterProgress").auto_save = false
	root.get_node("CampaignProfile").hero_name = "Aprendiz"
	game = load("res://scenes/art/combat_study.tscn").instantiate(); game.encounter = "child_attack"; root.add_child(game)
	await frames(20); game.hints.text = "MOVIMENTO · Obstáculo, orçamento e percurso"
	press(KEY_G); await frames(10)
	click(game.host.tactical.screen(Vector2i(3,4))); await frames(32)
	click(game.host.tactical.screen(Vector2i(7,4))); await frames(38)
	click(game.host.tactical.screen(Vector2i(4,3))); await frames(45)
	press(KEY_ENTER)
	if not await phase("choose"): quit(1); return
	await frames(25); press(KEY_Z); await frames(28)
	game.free(); await frames(2)
	game = load("res://scenes/art/combat_study.tscn").instantiate(); game.encounter = "school"; game.style = "FO"; root.add_child(game)
	await frames(20); game.hints.text = "ALCANCE · O banco bloqueia a linha; mudar de posição abre o tiro"
	press(KEY_G); await frames(4); click(game.host.tactical.screen(Vector2i(2,4))); await frames(20); press(KEY_ENTER)
	if not await phase("choose"): quit(1); return
	press(KEY_1); await frames(4); click(game.host.tactical.screen(game.host.combat.units[2].cell)); await frames(50)
	press(KEY_Z); await frames(15); press(KEY_1); await frames(4); click(game.host.tactical.screen(game.host.combat.units[2].cell)); await frames(50)
	print("COMBAT_FIELD_RECORD_RESULT · routes, budget, obstruction, undo and valid aim through real input")
	game.free(); await frames(2); quit()
