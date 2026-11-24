extends SceneTree
var checks := 0
var failures: Array[String] = []
var game

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func frames(count: int) -> void:
	for i in range(count):
		await process_frame

func capture(path: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)

func escape() -> void:
	var key = InputEventKey.new()
	key.keycode = KEY_ESCAPE
	key.pressed = true
	game._unhandled_input(key)

func run() -> void:
	root.get_node("ChapterProgress").auto_save = false
	root.get_node("CampaignProfile").hero_name = "Inês"
	game = load("res://scenes/chapter_01/promise.tscn").instantiate()
	root.add_child(game)
	await frames(3)
	check(game.view.speaker.text == "Inês" and game.view.body.text == "Gostava de ficar contigo.", "Promise starts with approved line and selected name")
	check(game.world.player.camera.zoom == Vector2(1.25,1.25), "Approved camera zoom is preserved")
	check(not game.world.player.enabled and not game.world.player.is_physics_processing(), "Staged scene does not enable free movement")
	check(not game.child.carries_cup and game.leonor.carries_cup, "Child gives Leonor water before drinking")
	var source = FileAccess.get_file_as_string("res://docs/narrativa/C01-portugal-aprovado.md")
	var approved: Array[String] = []
	for line in source.get_slice("### S06 — A primeira promessa",1).get_slice("### S07",0).split("\n"):
		if line.begins_with("**"):
			approved.append(line.strip_edges())
	var actual: Array[String] = []
	for event in game.sequence["events"]:
		if event["type"] == "line":
			actual.append("**%s:** %s" % [event["speaker"],event["text"]])
	check(actual == approved and actual.size() == 14, "All fourteen promise lines match the approved chapter")
	var contracts = JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_01/training_contracts.json"))
	check(contracts["lessons"].size() == 2, "Both implemented training lessons have data definitions")
	for lesson in contracts["lessons"]:
		check(lesson["status"] == "implemented_mar_de_ferro_training" and not lesson["requires_perfect_defense"] and not lesson["lethal"], "Training is implemented, nonlethal and without Perfect Defense: "+lesson["scene_id"])
		var scene_header = "### %s — %s" % [lesson["scene_id"].get_slice("/",1),lesson["title"]]
		var expected: Array[String] = []
		for line in source.get_slice(scene_header,1).get_slice("### ",0).split("\n"):
			if line.begins_with("**"):
				expected.append(line.strip_edges())
		var lines: Array[String] = []
		for line in lesson["lines"]:
			lines.append("**%s:** %s" % [line["speaker"],line["text"]])
		check(lines == expected and not lines.is_empty(), "Training dialogue matches approved text: "+lesson["scene_id"])
	await capture("res://tests/promise-dialogue-preview.png")
	escape()
	var index: int = game.event_index
	game.advance()
	check(game.event_index == index, "Pause blocks dialogue continuation")
	escape()
	for i in range(3):
		game.advance()
		while game.busy: await physics_frame
	check(game.view.body.text == "Viver contigo. Para sempre." and not game.leonor.carries_cup and game.world.get_node("ActorsAndProps/Bench/Cups").visible, "Leonor puts her cup down at the approved beat")
	for i in range(6):
		game.advance()
	check(game.view.body.text == "Então trabalho.", "Promise reaches the child's commitment")
	game.advance()
	check(game.busy, "Reserving the instruments starts staged movement")
	check(not game.view.panel.visible, "Tool staging leaves the action visible")
	await frames(2)
	escape()
	var frozen: Vector2 = game.leonor.position
	await frames(8)
	check(game.leonor.position == frozen, "Pause freezes Leonor's staging tween")
	escape()
	while game.busy:
		await process_frame
	check(game.view.body.text == "Esse fica?" and game.world.get_node("ActorsAndProps/ReservedTools").visible, "Both reserved instruments appear before the child's question")
	check(game.world.get_node("ActorsAndProps/ReturnTools").visible and game.world.get_node("ActorsAndProps/ReturnTools").count == 1, "Returned equipment remains visually separate from the reserved pair")
	check(not game.leonor.walking and not game.leonor.carries_training_tool and game.leonor.posture == "standing", "Leonor puts the instrument down and stops before replying")
	var ids: Array[String] = []
	game.scene_finished.connect(func(id): ids.append(id))
	for i in range(3):
		game.advance()
	check(game.view.body.text == "Não me faças esperar.", "Leonor's final line remains unchanged")
	game.advance()
	while game.busy:
		await process_frame
	game.advance()
	check(game.completed and ids == ["C01-M01/S06"], "Promise completes once with its own scene ID")
	check(game.leonor.position == game.world.get_node("Staging/LeonorExit").position, "Leonor leaves by the authored exit marker")
	check(not game.framing.subjects.has(game.leonor) and game.framing.subjects.has(game.world.player), "Farewell camera stays with the child instead of following Leonor away")
	check(game.world.get_meta("intimate_scene_people").has(game.world.get_node("ActorsAndProps/ReservedTools")), "Farewell cutaway keeps tomorrow's instruments visible after Leonor leaves")
	await capture("res://tests/promise-end-preview.png")
	game.view.replay_button.pressed.emit()
	check(not game.completed and game.leonor.posture == "seated" and not game.world.get_node("ActorsAndProps/ReservedTools").visible, "Replay resets actors and equipment")
	check(game.framing.subjects.has(game.leonor) and not game.leonor.walking, "Replay restores the shared camera and stationary pose")
	game.queue_free()
	await frames(2)
	# Verify direct F6 review with the same name entry, without skipping the main flow.
	root.get_node("CampaignProfile").hero_name = ""
	check(change_scene_to_file("res://scenes/chapter_01/promise.tscn") == OK, "Promise preview launches directly")
	await frames(5)
	check(current_scene.scene_file_path == "res://scenes/chapter_01/name_entry.tscn", "Direct review requests the protagonist name")
	current_scene.profile_path = "res://tests/name-profile-promise.json"
	current_scene.name_field.text = "Dinis"
	current_scene.confirm()
	await frames(3)
	check(current_scene.scene_file_path == "res://scenes/chapter_01/promise.tscn" and current_scene.view.speaker.text == "Dinis", "Name confirmation returns to the requested promise preview")
	check(root.get_node("CampaignProfile").name_entry_destination == "res://scenes/chapter_01/childhood_home.tscn", "Review destination resets to the playable convent for the next new game")
	var result = {"checks":checks,"failures":failures,"rendered":DisplayServer.get_name() != "headless"}
	var file = FileAccess.open("res://tests/promise-report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t"))
	print("PROMISE_RESULT ",JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)


