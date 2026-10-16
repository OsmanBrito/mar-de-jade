extends SceneTree
## Integration checks against the actual scenes and physics, not mirrored functions.
const Session = preload("res://scripts/session.gd")
var failures: Array[String] = []
var checks: int = 0
var game
var render_mode: bool = false

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
		push_error(description)

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame

func capture(path: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)

func run() -> void:
	render_mode = DisplayServer.get_name() != "headless"
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(25)
	check(game.world.map_id == "cais","Start in cais")
	check(game.world.cells.size() == 183,"Exterior has expected connected ground and dock cells")
	check(game.world.is_walkable_point(game.world.player.position),"Spawn on traversable ground")
	check(game.world.astar.get_point_count() > 100,"Click navigation contains traversable land")
	check(InputMap.action_get_events("move_left").size() >= 4,"Keyboard, D-pad and stick mappings exist")
	check(not game.world.is_walkable_point(Vector2(9000,9000)),"River is not traversable")
	print("MAP_COORDINATES ",game.world.cell_position([0,0])," -> ",game.world.cell_position([8,8]))
	await capture("res://tests/cais-preview.png")
	var start: Vector2 = game.world.player.position
	Input.action_press("move_right")
	await frames(24)
	Input.action_release("move_right")
	await frames(2)
	check(game.world.player.position.x > start.x+25,"Keyboard moves the real physics actor")
	game.hud.show_pause()
	var stopped: Vector2 = game.world.player.position
	Input.action_press("move_left")
	await frames(12)
	Input.action_release("move_left")
	check(game.world.player.position.distance_to(stopped)<1,"Modal blocks movement")
	game.hud.close_modal()
	# Physical collision: approach the warehouse footprint from below.
	var house: Vector2 = game.world.get_node("ActorsAndProps/house_00").position - Vector2(27.921875,-10.05159375)
	game.world.player.position = house+Vector2(0,35)
	Input.action_press("move_up")
	await frames(45)
	Input.action_release("move_up")
	check(game.world.player.position.y > house.y-25,"Warehouse footprint blocks walking through the building")
	# A real click route across the open quay must complete, not stall in the river.
	game.world.player.position = game.world.cell_position([8,8])
	var target: Vector2 = game.world.cell_position([10,8])
	game.world.walk_to(target)
	await frames(115)
	check(game.world.player.position.distance_to(target)<12,"Click path reaches an open quay destination")
	game.world.player.position = game.world.interactions[0].position+Vector2(30,25)
	await frames(2)
	game.world.interact()
	check(game.hud.modal_kind == "dialogue","Proximity interaction opens dialogue")
	check(game.hud.choices.get_child_count() == 2,"First dialogue offers the authored branch")
	game.hud.choices.get_child(1).pressed.emit()
	check(game.session.phase == "arrival","Declining keeps the errand available")
	game._on_choice("accept_errand")
	check(game.session.phase == "warehouse","Accepting updates the objective")
	await game.transition_to("armazem")
	await frames(3)
	check(game.world.map_id == "armazem","Transition mounts the interior")
	check(game.session.visited_warehouse,"Interior visit persists in domain state")
	await capture("res://tests/armazem-preview.png")
	game.world.player.position = game.world.interactions[0].position+Vector2(0,25)
	await frames(2)
	game.world.interact()
	check(game.hud.modal_kind == "dialogue","Manifest is interactive in the real map")
	await capture("res://tests/dialogue-preview.png")
	game.hud.choices.get_child(0).pressed.emit()
	check(game.session.phase == "return","Manifest advances the errand")
	await game.transition_to("cais")
	await frames(3)
	check(game.world.is_walkable_point(game.world.player.position),"Door return spawn stays on land")
	game.world.player.camera.reset_smoothing()
	await frames(20)
	await capture("res://tests/authorship-door-preview.png")
	game._on_choice("finish_errand")
	game._on_choice("finish_errand")
	check(game.session.phase == "complete","Completion is stable on repeated effects")
	game.session.map_id = "cais"
	game.session.player_position = game.world.player.position
	game.session.has_position = true
	var path = "res://tests/roundtrip-save.json"
	check(game.session.save_to(path) == OK,"Save succeeds")
	check(game.session.save_to(path) == OK,"Save replacement succeeds with backup")
	check(FileAccess.file_exists(path+".bak"),"Prior save is retained")
	var restored = Session.new()
	check(restored.load_from(path) == OK,"Load succeeds")
	check(restored.snapshot() == game.session.snapshot(),"Round-trip preserves all domain state")
	var before = restored.snapshot()
	var malformed = before.duplicate(true)
	malformed["position"] = ["not a number",0]
	check(restored.restore(malformed) == ERR_INVALID_DATA,"Malformed coordinates are rejected")
	check(restored.snapshot() == before,"Rejected load leaves live state intact")
	malformed = before.duplicate(true)
	malformed["schema_version"] = 999
	check(restored.restore(malformed) == ERR_INVALID_DATA,"Future schema is rejected")
	game.hud.close_modal()
	game.world.player.position = game.world.cell_position([8,8])
	game.world.player.camera.reset_smoothing()
	await frames(20)
	await capture("res://tests/cais-complete-preview.png")
	var result = {"checks":checks,"failures":failures,"rendered":render_mode,"physical_controller_tested":false}
	var file = FileAccess.open("res://tests/playtest-report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t"))
	file.close()
	print("PLAYTEST_RESULT ",JSON.stringify(result))
	game.queue_free()
	await frames(2)
	quit(0 if failures.is_empty() else 1)
