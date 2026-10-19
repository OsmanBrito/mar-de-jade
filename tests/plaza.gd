extends SceneTree
var failures: Array[String] = []
var checks := 0
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
		await physics_frame

func capture(path: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)

func reach_walk_stage(id: String) -> bool:
	for i in range(300):
		if game.walking_stage == id:
			return true
		if not game.busy:
			game.advance()
		await frames(1)
	return false

func escape() -> void:
	var event = InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	game._unhandled_input(event)

func run() -> void:
	root.get_node("ChapterProgress").auto_save = false
	root.get_node("CampaignProfile").hero_name = "Inês"
	game = load("res://scenes/chapter_01/plaza.tscn").instantiate()
	root.add_child(game)
	await frames(3)
	check(game.phase=="childhood_explore" and game.world.player.enabled,"Childhood begins with free exploration of the convent district")
	game.world.walk_to(Vector2(80,400))
	for i in 1000:
		await physics_frame
		if game.world.player.position.distance_to(Vector2(80,400))<40: break
	check(game.world.player.position.distance_to(Vector2(80,400))<50,"The child reaches Leonor through the same physical city")
	game.roam.interact(); await frames(3)
	check(game.view.body.text == "Sai desse lado.", "Plaza begins with the approved bank dialogue")
	check(not game.world.player.enabled, "Dialogue starts with movement locked")
	check(game.world.player.z_index == 1, "Seated hero draws in front of the bench")
	check(game.world.player.get_script() == load("res://scripts/chapter/child_player.gd"), "Child presentation reuses the approved controller")
	check(game.world.player.camera_zoom == 1.0, "The continuous district uses its human-scale exploration camera")
	check(game.world.cells.size() > 100 and game.world.has_meta("continuous_lisbon"), "The same city provides the larger navigation floor")
	var source = FileAccess.get_file_as_string("res://docs/narrativa/C01-portugal-aprovado.md")
	var text = source.get_slice("### S02 — O banco da praça",1).get_slice("### S04",0)
	var approved: Array[String] = []
	for line in text.split("\n"):
		if line.begins_with("**"):
			approved.append(line.strip_edges())
	var actual: Array[String] = []
	for segment in ["bank","instruction","blocked","arrival","repeat","finish"]:
		for event in game.data["segments"][segment]:
			if event["type"] == "line":
				actual.append("**%s:** %s" % [event["speaker"],event["text"]])
	check(actual == approved and actual.size() == 27, "All 27 bank/exercise lines match the approved chapter")
	var original_position: Vector2 = game.world.player.position
	Input.action_press("move_right")
	await frames(10)
	Input.action_release("move_right")
	check(game.world.player.position == original_position, "Keyboard does not move the child before the exercise")
	await capture("res://tests/plaza-dialogue-preview.png")
	check(await reach_walk_stage("first"), "Dialogue leads to the first movement objective")
	await frames(3)
	check(game.world.player.enabled and not game.view.panel.visible, "Exercise enables movement and hides dialogue")
	check(game.world.player.z_index == 0, "Exploration restores normal actor depth sorting")
	check(game.world.get_node("Staging/FirstTarget").active, "Authored target becomes visible")
	var segment_before: String = game.segment
	game.advance()
	check(game.segment == segment_before and game.walking_stage == "first", "Continue cannot bypass the movement objective")
	var start: Vector2 = game.world.player.position
	Input.action_press("move_right")
	for i in range(130):
		await frames(1)
		if game.segment == "blocked":
			break
	Input.action_release("move_right")
	check(game.world.player.position.x > start.x+40, "Keyboard drives the real physics actor")
	check(game.segment == "blocked" and game.view.body.text == "O banco não vai sair da frente.", "Bench collision triggers the approved optional correction")
	check(game.world.player.position.x < 64, "Physical bench prevents crossing its footprint")
	check(not game.world.player.enabled, "Correction dialogue locks movement")
	await capture("res://tests/plaza-blocked-preview.png")
	check(await reach_walk_stage("first"), "Correction resumes the same objective")
	await frames(2)
	game.world.player.position = game.world.get_node("Staging/FirstStart").position
	await frames(2)
	var first_target: Vector2 = game.world.get_node("Staging/FirstTarget").position
	check(not game.world.segment_clear(game.world.player.position,first_target), "Direct first route is obstructed")
	game.world.walk_to(first_target)
	check(not game.world.player.destination_path.is_empty(), "Click generates a route around the bank")
	var cursor: Vector2 = game.world.player.position
	var safe_path := true
	for point in game.world.player.destination_path:
		safe_path = safe_path and game.world.segment_clear(cursor,point)
		cursor = point
	check(safe_path, "Click segments preserve clearance for the approved actor radius")
	var path_before = game.world.player.destination_path.duplicate()
	game.world.walk_to(Vector2(64,352))
	check(game.world.player.destination_path == path_before, "Clicking inside the bench does not replace the safe route")
	escape()
	var frozen: Vector2 = game.world.player.position
	Input.action_press("move_down")
	await frames(12)
	Input.action_release("move_down")
	check(game.world.player.position == frozen and game.paused, "Pause freezes both keyboard and click movement")
	escape()
	for i in range(420):
		if game.phase == "arrival":
			break
		await frames(1)
	check(game.phase == "arrival", "Actual click path reaches the first target without stalling")
	check(game.world.player.position.distance_to(first_target) <= 23, "First target uses authored arrival radius")
	check(game.view.body.text == "Cheguei.", "Arrival advances to the approved response")
	check(not game.world.get_node("Staging/FirstTarget").active, "Reached target is hidden")
	check(await reach_walk_stage("second"), "Leonor repositions and starts the second exercise")
	await frames(3)
	check(game.leonor.position == game.world.get_node("Staging/LeonorSecond").position, "Leonor uses the editable second staging marker")
	check(game.world.get_node("Staging/SecondTarget").active, "Second target appears after the instruction")
	await capture("res://tests/plaza-exercise-preview.png")
	var finished_ids: Array[String] = []
	game.scene_finished.connect(func(id): finished_ids.append(id))
	var second_target: Vector2 = game.world.get_node("Staging/SecondTarget").position
	game.world.walk_to(second_target)
	check(not game.world.player.destination_path.is_empty(), "Second objective has a valid click route")
	for i in range(420):
		if game.phase == "finish":
			break
		await frames(1)
	check(game.phase == "finish" and game.view.body.text == "Agora vi.", "Second arrival triggers the approved ending")
	game.advance()
	check(game.view.body.text == "Agora.", "Leonor's final response is preserved")
	game.advance()
	game.advance()
	check(game.completed and finished_ids == ["C01-M01/S03"], "Exercise concludes once, after both traversals")
	await capture("res://tests/plaza-complete-preview.png")
	game.view.replay_button.pressed.emit()
	await frames(2)
	check(not game.completed and game.phase == "bank" and not game.blocked_hint_seen, "Replay resets phase and optional correction")
	check(not game.world.get_node("Staging/FirstTarget").active and not game.world.get_node("Staging/SecondTarget").active, "Replay clears both targets")
	game.queue_free()
	await frames(2)
	# Exercise the real link from the first scene, not a direct test-only mount.
	check(change_scene_to_file("res://scenes/chapter_01/opening.tscn") == OK, "Opening can be launched as a standalone chapter scene")
	await process_frame
	await process_frame
	var opening = current_scene
	for i in range(1200):
		if opening.completed:
			break
		if not opening.busy:
			opening.advance()
		await frames(1)
	check(opening.completed, "Opening finishes before transition")
	opening.next_button.pressed.emit()
	for i in 120:
		await physics_frame
		if current_scene.scene_file_path=="res://scenes/chapter_01/plaza.tscn": break
	check(current_scene.scene_file_path == "res://scenes/chapter_01/plaza.tscn", "Continue from the table mounts the real plaza scene")
	check(current_scene.phase == "childhood_explore", "The transition opens childhood exploration before the approved encounter")
	var result = {"checks":checks,"failures":failures,"rendered":DisplayServer.get_name() != "headless"}
	var file = FileAccess.open("res://tests/plaza-report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t"))
	print("PLAZA_RESULT ",JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)

