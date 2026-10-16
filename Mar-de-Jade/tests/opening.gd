extends SceneTree
var failures: Array[String] = []
var checks := 0
var game: Node2D

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
	var event = InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	game._unhandled_input(event)

func run() -> void:
	root.get_node("ChapterProgress").auto_save = false
	root.get_node("CampaignProfile").hero_name = "Inês"
	game = load("res://scenes/chapter_01/opening.tscn").instantiate()
	root.add_child(game)
	await frames(5)
	check(game.get_node("Camera").zoom == Vector2(1.25,1.25), "Opening camera uses approved initial zoom")
	check(game.speaker.text == "Tomé" and game.body.text == "Estão a chamar para comer.", "Starts with approved first line")
	check(game.room.get_node("Ground").get_used_cells().size() == 56, "Shelter floor is authored in the map scene")
	check(game.room.get_node("ActorsAndProps/Bed/Body/Footprint") is CollisionPolygon2D, "Furniture has editable collision")
	var source = FileAccess.get_file_as_string("res://docs/narrativa/C01-portugal-aprovado.md")
	var first_scene = source.get_slice("### S01 — Um lugar à mesa",1).get_slice("### S02",0)
	var approved_lines: Array[String] = []
	for line in first_scene.split("\n"):
		if line.begins_with("**"):
			approved_lines.append(line.strip_edges())
	var actual_lines: Array[String] = []
	for event in game.sequence["events"]:
		if event["type"] == "line":
			actual_lines.append("**%s:** %s" % [event["speaker"],event["text"]])
	check(actual_lines == approved_lines and actual_lines.size() == 11, "All eleven lines match approved narrative exactly")
	check(not game.completed, "First line does not prematurely complete the scene")
	var initial_position: Vector2 = game.child.position
	var movement_key = InputEventKey.new()
	movement_key.keycode = KEY_D
	movement_key.physical_keycode = KEY_D
	movement_key.pressed = true
	root.push_input(movement_key)
	await frames(6)
	movement_key.pressed = false
	root.push_input(movement_key)
	check(game.child.position == initial_position, "Opening remains staged; free movement begins later in the approved story")
	await capture("res://tests/opening-dialogue-preview.png")
	escape()
	var paused_index: int = game.event_index
	game._continue_pressed()
	check(game.event_index == paused_index, "Pause blocks dialogue continuation")
	escape()
	for i in range(6):
		game.next_button.pressed.emit()
	check(game.tome.posture == "seated" and game.body.text == "Hoje não veio.", "Tomé sits before answering about the father")
	for i in range(4):
		game.next_button.pressed.emit()
	check(game.body.text == "Amanhã também estarei aqui.", "Dialogue reaches the approved final reassurance")
	var finished_ids: Array[String] = []
	game.scene_finished.connect(func(id): finished_ids.append(id))
	game.next_button.pressed.emit()
	check(game.busy and not game.panel.visible, "Staging plays after the dialogue")
	await frames(6)
	escape()
	var frozen: Vector2 = game.child.position
	await frames(12)
	check(game.child.position == frozen, "Pause also freezes staged movement")
	escape()
	while game.busy:
		await process_frame
	check(game.completed, "Opening completes after reaching the table")
	check(game.child.position == game.room.get_node("Staging/ChildAtTable").position, "Child reaches editable arrival marker")
	check(game.tome.position == game.room.get_node("Staging/TomeAtTable").position, "Tomé reaches editable arrival marker")
	check(not game.child.carries_bowl and game.room.get_node("ActorsAndProps/Table/Bowl").visible, "Bowl moves from child's hands to the table")
	game.advance()
	check(finished_ids == ["C01-M01/S01"], "Scene completion emits the narrative ID once")
	await frames(3)
	await capture("res://tests/opening-table-preview.png")
	check(game.next_scene_path == "res://scenes/chapter_01/plaza.tscn", "Approved opening links to the plaza")
	game.view.replay_button.pressed.emit()
	check(not game.completed and game.event_index == 0 and game.body.text == "Estão a chamar para comer.", "Replay returns to the first line")
	check(game.child.position == initial_position and game.child.carries_bowl and not game.room.get_node("ActorsAndProps/Table/Bowl").visible, "Replay restores actors and bowl without keeping completion state")
	var result = {"checks":checks,"failures":failures,"rendered":DisplayServer.get_name() != "headless"}
	var file = FileAccess.open("res://tests/opening-report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t"))
	print("OPENING_RESULT ",JSON.stringify(result))
	game.queue_free()
	await frames(2)
	quit(0 if failures.is_empty() else 1)

