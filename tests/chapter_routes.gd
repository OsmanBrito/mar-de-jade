extends SceneTree
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func frames(n: int) -> void:
	for i in n: await process_frame
func run() -> void:
	var profile = root.get_node("CampaignProfile")
	var progress = root.get_node("ChapterProgress")
	progress.auto_save = false; progress.reset(); profile.hero_name = "Inês"; profile.origin_response = "desculpar"
	change_scene_to_file("res://scenes/chapter_01/adult_opening.tscn")
	await frames(3)
	current_scene.completed = true; current_scene.phase = "complete"
	var accept = InputEventKey.new(); accept.keycode = KEY_ENTER; accept.pressed = true
	current_scene._unhandled_input(accept)
	await frames(3)
	check(current_scene.scene_file_path == "res://scenes/chapter_01/chapter_flow.tscn","Adult opening connects to remaining chapter")
	check(progress.choices.origin_response == "desculpar" and current_scene.view.speaker.text == "Duarte","Name and original response survive real bridge")
	var flow = current_scene
	flow._menu()
	var stopped: int = flow.event_index
	flow.advance()
	check(flow.event_index == stopped and paused,"Pause blocks narrative progression")
	flow._menu()
	check(not paused and flow.view.body.text == "O apoio saiu antes do golpe.","Menu restores previous dialogue")
	for index in [5,10]:
		flow._load_block(index)
		for i in 100:
			if flow.phase == "choice": break
			if not flow.busy: flow.advance()
			await frames(1)
		check(flow.phase == "choice","Narrative branch opens")
		var option: Dictionary = flow.choice_event.options[-1]
		flow.choose(option.id)
		check(flow.view.body.text == option.events[0].text,"Alternate choice uses approved branch")
	flow._load_block(14)
	# All five styles remain available; equipment is independent of learning.
	progress.passives.assign(["GE21","GE22","ES-P11","LA-P11","MC-P11","FO-P11","PU-P11","DU-P09"])
	flow.phase = "styles_result"; flow._show_equipment()
	for id in ["GE21","GE22","ES-P11","LA-P11","MC-P11"]: flow.toggle_passive(id)
	check(progress.equipped_passives.size() == 4 and not progress.equipped_passives.has("MC-P11"),"Four hero passive slots enforced")
	flow.toggle_passive("DU-P09")
	check(progress.duarte_equipped_passives == ["DU-P09"] and not progress.equipped_passives.has("DU-P09"),"Duarte passive has separate owner")
	var state_before: Dictionary = progress.snapshot()
	flow.phase = "battle"; flow.toggle_passive("GE21")
	check(progress.snapshot() == state_before,"Cannot equip during battle")
	progress.checkpoint = 9; progress.entry_scene = "res://scenes/chapter_01/chapter_flow.tscn"
	check(progress.save_to("res://tests/resume-fixture.json") == OK,"Checkpoint writes")
	progress.reset(); check(progress.load_from("res://tests/resume-fixture.json") == OK,"Checkpoint loads")
	change_scene_to_file(progress.entry_scene); await frames(3)
	check(current_scene.scene_index == 9 and profile.hero_name == "Inês","Resume restores chapter block and identity")
	var valid: Dictionary = progress.snapshot()
	var bad = valid.duplicate(true); bad.entry_scene = "res://scenes/main.tscn"
	FileAccess.open("res://tests/resume-invalid.json",FileAccess.WRITE).store_string(JSON.stringify(bad))
	check(progress.load_from("res://tests/resume-invalid.json") == ERR_INVALID_DATA and progress.snapshot() == valid,"Unrelated save scene rejected without destroying state")
	for i in 180:
		if not current_scene.busy: break
		await physics_frame
	current_scene.queue_free()
	await frames(3)
	print("CHAPTER_ROUTES_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)


