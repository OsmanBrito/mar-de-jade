extends "res://tools/record_combat.gd"
## Real full-health duel and approved narrative handoff, through normal input.
func click(point: Vector2) -> void:
	var at: Vector2 = preload("res://scripts/combat/battle_stage.gd").ui_to_window(game.battle_host,point)
	var motion := InputEventMouseMotion.new(); motion.position = at; motion.global_position = at; root.push_input(motion,true)
	var event := InputEventMouseButton.new(); event.position = at; event.global_position = at; event.button_index = MOUSE_BUTTON_LEFT; event.pressed = true; root.push_input(event,true)
	event = event.duplicate(); event.pressed = false; root.push_input(event,true)
func click_cell(cell: Vector2i) -> void:
	click(game.battle_host.tactical.screen(cell))
func phase(wanted: String,limit := 180) -> bool:
	for i in limit:
		if game.battle_host.tactical.phase==wanted: return true
		await process_frame
	push_error("Recording did not reach "+wanted); return false
func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/combate-"+name+"-v4.png")
func run() -> void:
	var progress = root.get_node("ChapterProgress"); progress.reset(); progress.auto_save = false
	root.get_node("CampaignProfile").hero_name = "Aprendiz"
	game = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate(); game.start_block = 8; root.add_child(game)
	await frames(25)
	var host = game.battle_host; var v = host.tactical
	press(KEY_1); await frames(4); click_cell(host.combat.units[2].cell); await frames(15); press(KEY_ENTER)
	if not await phase("timing_attack"): quit(1); return
	for i in 80:
		if v.grade_at(v.clock/v.duration)==2: press(KEY_SPACE); break
		await process_frame
	if not await phase("choose"): quit(1); return
	for turn in 5:
		if host.completed: break
		await frames(12); press(KEY_T); await frames(15); press(KEY_ENTER)
		if not await phase("timing_defend"): quit(1); return
		# An early reaction is resolved by the real defensive timing and HP rules.
		press(KEY_SPACE)
		for i in 160:
			if host.completed or v.phase=="choose": break
			await process_frame
	if not host.completed or host.combat.units[0].hp>0: push_error("Duel did not resolve a real defeat"); quit(1); return
	await frames(6); await capture("encerramento")
	for i in 120:
		if not host.ending.running(): break
		await process_frame
	var first_line: String = game.view.body.text
	if game.scene_index!=9 or first_line!="Agora vais mandar-me repetir?": push_error("Unexpected narrative return"); quit(1); return
	await frames(40); await capture("retorno")
	press(KEY_ENTER); await frames(30)
	print("COMBAT_ENDING_RECORD_RESULT ",JSON.stringify({"hero_hp":host.combat.units[0].hp,"leonor_hp":host.combat.units[2].hp,"first_line":first_line,"next_line":game.view.body.text}))
	game.free(); await frames(2); quit()
