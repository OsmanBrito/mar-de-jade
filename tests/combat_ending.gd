extends "res://tests/combat_presentation.gd"
const Stage = preload("res://scripts/combat/battle_stage.gd")
func pad(button: JoyButton) -> void:
	var event := InputEventJoypadButton.new(); event.button_index = button; event.pressed = true; root.push_input(event)
	event = event.duplicate(); event.pressed = false; root.push_input(event)
func refresh() -> void:
	game.battle_host.queue_redraw(); await frames(2)
func run() -> void:
	var progress = root.get_node("ChapterProgress")
	progress.reset(); progress.auto_save = false
	root.get_node("CampaignProfile").hero_name = "Aprendiz"
	game = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate(); game.start_block = 8; root.add_child(game)
	await frames(4)
	var host = game.battle_host; host.set_process(false)
	var v = host.tactical; var model = host.combat
	var completions: Array = []; var blocks: Array = []
	host.lesson_completed.connect(func(ok): completions.append({"success":ok,"cover":Stage.curtain_for(host).modulate.a}))
	game.block_finished.connect(func(id): blocks.append(id))
	check(game.phase=="battle" and model.mode=="duel" and model.units[0].hp==90,"Canonical duel starts at real full health")
	for i in 5:
		if model.units[0].hp<=0: break
		press(KEY_T); press(KEY_ENTER); v.update(1); v.update(2)
		check(v.phase=="timing_defend","Leonor's actual attack offers defensive timing")
		press(KEY_SPACE); v.update(0.451)
		if model.units[0].hp>0: v.update(2)
	check(model.units[0].hp<=0 and model.lesson_result().finished,"Defeat is produced by resolved HP damage")
	check(not host.completed and completions.is_empty() and game.phase=="battle","Lethal contact does not cut off the final reaction")
	v.update(0.34); await refresh()
	check(not host.completed and v.phase=="animate_enemy","Recovery and the fallen pose stay visible before the result")
	v.update(0.70); await refresh()
	check(host.completed and not host.active and host.ending.phase=="hold" and completions.is_empty(),"Result holds after recovery, before narrative handoff")
	check(host.ending.title=="LEONOR VENCEU" and not host.ending.detail.contains("game over"),"Defeat is framed as a story continuation")
	var hp: int = model.units[0].hp
	var turns: int = model.enemy_turns
	press(KEY_1); press(KEY_ENTER); press(KEY_SPACE)
	check(model.units[0].hp==hp and model.enemy_turns==turns and v.phase=="animate_enemy","Result input cannot schedule another attack or turn")
	pad(JOY_BUTTON_START)
	var held: float = host.ending.clock
	host.update_ending(1)
	check(host.paused and is_equal_approx(host.ending.clock,held),"Pause freezes the result hold")
	pad(JOY_BUTTON_START); host.update_ending(0.75)
	var curtain := Stage.curtain_for(host)
	check(host.ending.phase=="out" and curtain.visible and curtain.modulate.a>0 and curtain.modulate.a<1 and completions.is_empty(),"Arena fades out before the outcome signal")
	check(curtain.size.is_equal_approx(game.get_viewport_rect().size),"Curtain covers the entire outer viewport, including letterbox bands")
	host.update_ending(0.2); await refresh()
	check(completions.size()==1 and completions[0].success and completions[0].cover==1,"Outcome is emitted once while fully covered")
	check(progress.flags.get("duel_lost",false) and progress.flags.get("injured",false),"Existing narrative flags are applied at the handoff")
	check(game.scene_index==9 and game.phase=="dialogue" and game.view.body.text=="Agora vais mandar-me repetir?","Defeat flows directly into the first approved line")
	check(game.world.player.presentation.posture=="fallen" and blocks==["C01-M03/S03"],"Dedicated fallen silhouette is ready and the duel block completes once")
	var line: int = game.event_index
	press(KEY_ENTER); pad(JOY_BUTTON_A); await frames(2)
	check(game.event_index==line,"Keys and controller presses during the cover cannot skip the first dialogue")
	host.update_ending(0.11); press(KEY_ENTER); await frames(2)
	check(game.event_index==line and curtain.modulate.a>0 and curtain.modulate.a<1,"Incoming dialogue stays protected throughout the reveal")
	host.update_ending(0.2); press(KEY_ENTER); await frames(2)
	check(not curtain.visible and host.ending.phase=="idle" and game.view.body.text=="Hoje não.","Fresh input advances one approved line after the reveal")
	host.check_outcome(); host.update_ending(4)
	check(completions.size()==1 and model.enemy_turns==turns and model.units[0].hp==hp,"Completed duel never emits twice or attacks the fallen hero")
	game.free(); await frames(2)
	await mount("child_defense"); host = game.host; host.set_process(false); v = host.tactical
	var failures_seen: Array = []
	host.lesson_completed.connect(func(ok): failures_seen.append(ok))
	v.start_facing(); v.facing = 0; v.confirm(); v.update(1); v.update(2); press(KEY_SPACE); v.update(0.451); v.update(1)
	check(host.ending.phase=="hold" and failures_seen.is_empty() and host.combat.units[0].hp>0,"Failed child lesson also waits safely for recovery")
	host.update_ending(1); host.update_ending(1)
	check(failures_seen==[false] and host.ending.title=="VOLTAR A PRATICAR","Failed lesson keeps its retry outcome instead of showing success")
	game.restart()
	check(not host.completed and not host.ending.has_result and not Stage.curtain_for(host).visible and host.active,"Replay clears the result and curtain")
	v.start_facing(); v.facing = 0; v.confirm(); v.update(1); v.update(2); press(KEY_SPACE); v.update(0.451); v.update(1)
	game.restart(); host.update_ending(4)
	check(failures_seen.size()==1 and host.active and not host.completed,"Restart during the hold cancels the old pending handoff")
	game.free(); await frames(2)
	progress.reset(); progress.auto_save = false; progress.flags.injured = true
	game = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate(); game.start_block = 13; root.add_child(game); await frames(3)
	for i in 1200:
		if game.phase=="battle": break
		if not game.busy:
			if game.phase=="dialogue": game.advance()
			elif game.phase=="task": game.world.player.position = game.props.marker; game.interact_task()
			elif game.phase=="styles": game.choose_style("ES")
			elif game.phase=="roaming": check(await load("res://tests/lisbon_walk_driver.gd").new().reach(game),"Recovery returns physically to the courtyard before the maneuver trial")
		if game.busy: await physics_frame
		else: await process_frame
	host = game.battle_host; host.set_process(false); v = host.tactical
	check(host.combat.mode=="style_test","Canonical maneuver trial opens before school")
	if host.combat.units.size()<3:
		game.free(); print("COMBAT_ENDING_RESULT ",JSON.stringify({"checks":checks,"failures":failures})); quit(1); return
	v.select_skill(0); v.select_cell(host.combat.units[2].cell); v.confirm(); v.commit_timing(2); v.update(0.451); v.update(1); host.update_ending(1)
	check(host.combat.mode=="school" and host.active and not host.completed and host.ending.phase=="in" and Stage.curtain_for(host).modulate.a==1,"Chained school encounter is initialized under the same curtain")
	press(KEY_1)
	check(v.phase=="choose","Carry-over input cannot select an action in the new encounter")
	host.update_ending(1); press(KEY_1)
	check(v.phase=="aim" and not Stage.curtain_for(host).visible,"New encounter accepts fresh input after its reveal")
	game.free(); await frames(2)
	print("COMBAT_ENDING_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
