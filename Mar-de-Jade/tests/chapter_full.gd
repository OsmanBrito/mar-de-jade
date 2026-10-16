extends SceneTree
var game
var checks := 0
var failures: Array[String] = []
var battle_modes: Array[String] = []
var scene_ids: Array[String] = []
var captured: Dictionary = {}
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func frames(n: int) -> void:
	for i in n: await process_frame
func drive_battle() -> void:
	var host = game.battle_host
	var b = host.combat
	var v = host.tactical
	if not battle_modes.has(b.mode): battle_modes.append(b.mode)
	if v.phase in ["choose","move","aim"] and v.is_player():
		if v.phase != "choose": v.cancel()
		if b.current().acted:
			v.start_facing(); v.facing = b.suggested_facing(b.current_id); v.confirm(); return
		if b.mode == "adult_basic" and not b.moved_in_battle:
			v.select_move(); v.select_cell(Vector2i(4,3)); v.confirm(); return
		if b.mode in ["adult_defense","perfect_defense"] or (b.mode == "duarte_support" and b.current_id == 0):
			v.start_facing(); v.facing = b.suggested_facing(b.current_id); v.confirm(); return
		var skill := 0
		if b.mode == "duarte_support" and b.current_id == 1: skill = 4
		elif b.mode == "school" and b.previous_action == 0 and b.previous_action_turn == b.current().turns-1: skill = 1
		var aim: Vector2i = b.units[2].cell
		if skill == 4: aim = b.units[0].cell
		if skill == 1 and b.style == "MC": aim = b.current().cell
		if not b.valid_attack(skill,aim):
			var best := Vector2i(-1,-1)
			for cell in b.reachable(b.current_id).costs:
				if b.distance(cell,aim) <= int(b.skill_def(b.current_id,skill).range) and b.distance(cell,aim) > 0:
					best = cell; break
			if best != Vector2i(-1,-1): v.select_move(); v.select_cell(best); v.confirm()
			else: v.start_facing(); v.confirm()
			return
		v.select_skill(skill); v.select_cell(aim); v.confirm()
	elif v.phase.begins_with("timing"):
		v.commit_timing(2 if b.mode == "perfect_defense" or v.phase == "timing_attack" else 1)
	else:
		v.update(2.1)
func capture_scene() -> void:
	if DisplayServer.get_name() == "headless": return
	var id: String = game.blocks[game.scene_index].id
	if captured.has(id): return
	if game.phase == "dialogue" and not game.busy:
		captured[id] = true
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tests/chapter-"+id.replace("/","-")+".png")
func run() -> void:
	root.get_node("CampaignProfile").hero_name = "Inês"
	root.get_node("ChapterProgress").reset()
	root.get_node("ChapterProgress").auto_save = false
	game = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate()
	root.add_child(game)
	await frames(3)
	game.block_finished.connect(func(id): scene_ids.append(id))
	for i in 9000:
		if game.completed: break
		await capture_scene()
		if not game.busy:
			match game.phase:
				"dialogue","block_end": game.advance()
				"choice": game.choose(game.choice_event.options[0].id)
				"task":
					var event_before: int = game.event_index
					game.advance()
					check(game.event_index == event_before,"Dialogue cannot skip task "+game.task_id)
					var found_route := false
					for offset in [Vector2.ZERO,Vector2.LEFT*40,Vector2.RIGHT*40,Vector2.UP*40,Vector2.DOWN*40]:
						var destination: Vector2 = game.props.marker+offset
						if not game.world.point_clear(destination): continue
						game.world.walk_to(destination)
						if not game.world.player.destination_path.is_empty() or game.world.player.position.distance_to(destination) < 72: found_route = true; break
					check(found_route,"Safe click route reaches interaction "+game.task_id)
					game.world.player.position = game.props.marker
					game.interact_task()
				"battle": drive_battle()
				"styles": game.choose_style("ES")
				"styles_result": game.confirm_style()
				"exploration":
					game.world.player.position = game.harbor.GATE+Vector2(-55,20)
					game.harbor.request_boarding()
				"boarding": game.harbor.confirm_boarding()
		await frames(1)
	check(game.completed,"Full chapter reaches departure")
	check(scene_ids.size() == 17,"Every remaining scene block completed")
	check(root.get_node("ChapterProgress").flags.get("duel_lost",false),"Adult duel produces real defeat")
	check(root.get_node("ChapterProgress").flags.get("recovered",false),"Recovery precedes final training")
	check(root.get_node("ChapterProgress").flags.get("perfect_defense",false),"Perfect defense learned only with Tomé")
	check(root.get_node("ChapterProgress").flags.get("embarked",false),"Botafogo departs")
	check(root.get_node("ChapterProgress").inventory.has("PT-Q02"),"Bowl packed")
	check(root.get_node("ChapterProgress").skills.has("DP01"),"Defensive lesson recorded")
	check(root.get_node("ChapterProgress").choices.has("departure_response") and root.get_node("ChapterProgress").choices.has("promise_response"),"Adult narrative choices recorded")
	check(battle_modes.size() == 7,"Every encounter kind exercised")
	var progress = root.get_node("ChapterProgress")
	check(progress.save_to("res://tests/chapter-fixture.json") == OK,"Chapter save writes checkpoint")
	var expected: Dictionary = progress.snapshot()
	progress.reset()
	var load_error: int = progress.load_from("res://tests/chapter-fixture.json")
	check(load_error == OK and progress.snapshot() == expected,"Chapter state round-trips")
	var invalid = expected.duplicate(true); invalid.checkpoint = 90
	FileAccess.open("res://tests/chapter-invalid.json",FileAccess.WRITE).store_string(JSON.stringify(invalid))
	check(progress.load_from("res://tests/chapter-invalid.json") == ERR_INVALID_DATA and progress.snapshot() == expected,"Invalid save preserves current state")
	print("CHAPTER_RESULT ",JSON.stringify({"checks":checks,"failures":failures,"scenes":scene_ids,"battle_modes":battle_modes}))
	game.queue_free(); await frames(3)
	quit(0 if failures.is_empty() else 1)




