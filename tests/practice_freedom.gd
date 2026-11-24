extends SceneTree
var failures: Array[String] = []
var checks := 0
var game
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func frames(n: int = 3) -> void:
	for i in n: await process_frame
func run() -> void:
	var p = root.get_node("ChapterProgress"); p.auto_save = false; p.reset(); p.flags.recovered = true
	root.get_node("GamePreferences").persist_enabled = false
	root.get_node("CampaignProfile").hero_name = "Miguel"
	game = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate(); game.start_block = 14; root.add_child(game); await frames()
	var styles: Array = []
	for event in game.blocks[13].events:
		if event.type=="styles": styles = event.options
	game._show_styles(styles)
	var original: Dictionary = p.snapshot()
	for style in ["ES","LA","MC","FO","PU"]:
		p.style = style; game.practice_resume_index = game.event_index; game.practice_events = game.events.duplicate(true)
		game._begin_battle("practice"); await frames()
		var b = game.battle_host.combat
		check(b.commands(0)==([0,1,2,3,8] if style=="FO" else [0,1,2,3]),style+" exposes its practice techniques")
		check(not b.lesson_result().finished,style+" free practice has no automatic reward")
		check((b.skill_def(0,2).content_id=="FO01" and b.skill_def(0,3).content_id=="FO09") if style=="FO" else (b.skill_def(0,2).content_id.begins_with("C01-DEMO-") and b.skill_def(0,3).name.begins_with("Exercício")),style+" practice uses the correct catalogue or exercise identities")
		for skill in [1,2,3]:
			var pad := InputEventJoypadButton.new(); pad.button_index = JOY_BUTTON_Y; pad.pressed = true
			game.battle_host._unhandled_input(pad)
			check(game.battle_host.tactical.selected_skill==skill,"Controller Y reaches borrowed action "+str(skill)+" for "+style)
		for skill in [1,2,3]:
			b.current_id = 0; b.units[0].acted = false; b.units[0].qi = 40
			b.units[0].cell = Vector2i(4,3); b.units[0].turn_origin = b.units[0].cell; b.obstacles.clear()
			b.units[2].cell = Vector2i(5,3) if not (style=="LA" and skill==1) else Vector2i(6,3)
			b.units[3].cell = Vector2i(7,3) if style=="LA" and skill==1 else Vector2i(6,3)
			var aim: Vector2i = b.units[0].cell if b.skill_def(0,skill).shape=="self" else b.units[2].cell
			var preview: Dictionary = b.predict(0,2,skill,1,aim) if b.skill_def(0,skill).shape!="self" else {}
			var hp: int = b.units[2].hp
			var result: Dictionary = b.perform(skill,aim,1)
			check(not result.has("error"),style+" executes borrowed technique "+str(skill)+" "+str(result.get("error","")))
			if not preview.is_empty(): check(hp-b.units[2].hp==preview.damage,style+" preview agrees with contact "+str(skill))
		for phase in ["choose","walk","timing_attack","timing_defend","animate_player","animate_enemy"]:
			game.battle_host.active = true; game.battle_host.tactical.phase = phase
			var event := InputEventKey.new(); event.physical_keycode = KEY_R; event.pressed = true
			game.battle_host._unhandled_input(event); await frames(1)
			check(game.phase=="styles" and not game.battle_container.visible,style+" exits during "+phase)
			check(p.skills==original.skills and p.passives==original.passives and p.inventory==original.inventory and p.coins==original.coins,"Exit grants no skill, passive, item or gold")
			game._begin_battle("practice")
		game.battle_host.abort_practice()
		game.confirm_style()
		check(not p.flags.get("initial_weapon_received",false),"Free demonstration cannot grant an unlearned initial weapon")
	game.choose_style("LA"); await frames()
	var driver = load("res://tests/chapter_driver.gd").new()
	for i in 300:
		if game.phase=="battle": break
		game.advance(); await frames(1)
	game.battle_host.abort_practice(); await frames()
	game.choose_style("PU"); await frames()
	for i in 900:
		if game.phase=="styles_result": break
		if game.phase=="battle": driver.drive(game.battle_host)
		elif not game.busy: game.advance()
		await process_frame
	check(p.skills.has("PU07") and not p.skills.has("LA07"),"Switch after abandoned lesson teaches only the completed weapon")
	check(game.phase=="styles_result","A new lesson completes after interrupting a different weapon")
	game._begin_battle("duel"); game.battle_host.abort_practice()
	check(game.phase=="battle" and game.battle_host.active,"Narrative duel cannot use practice exit")
	game.free(); await frames()
	print("PRACTICE_FREEDOM_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
