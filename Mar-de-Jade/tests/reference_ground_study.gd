extends SceneTree
var failures: Array[String] = []
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func frames(n: int) -> void:
	for i in n: await process_frame
func run() -> void:
	var game = load("res://scenes/art/reference_ground_study.tscn").instantiate(); root.add_child(game)
	await frames(20)
	check(game.reference_manifest.source_unchanged,"Original bundle hash must remain unchanged")
	check(game.reference_manifest.sprites.size()==37,"Sample must contain 37 sprites")
	check(game.reference_manifest.errors.is_empty(),"No extraction errors")
	check(game.world.point_clear(game.world.player.position),"Spawn must remain free")
	var cells = game.world.terrain.get_used_cells()
	for i in 4:
		game.apply_ground(i); await frames(4)
		check(game.world.terrain.get_used_cells().size()==cells.size(),"Switching floor must preserve map geometry")
		check(game.world.terrain.tile_set.get_source_count()==6,"All reference floor variants must exist")
		if DisplayServer.get_name()!="headless": root.get_texture().get_image().save_png("res://reference-study/heros-adventure/godot-floor-%d.png"%(i+1))
	var event := InputEventKey.new(); event.pressed = true; event.keycode = KEY_5
	game._unhandled_input(event); check(game.world.terrain.tile_set!=game.reference_tiles,"5 must show previous artwork")
	event.keycode = KEY_2; game._unhandled_input(event)
	check(game.world.terrain.tile_set==game.reference_tiles and game.selected_ground==1,"Reference floor must restore after comparison")
	var before: Vector2 = game.world.player.position
	Input.action_press("move_down"); await create_timer(0.2).timeout; Input.action_release("move_down")
	check(game.world.player.position.distance_to(before)>15,"Movement must remain functional")
	game.free(); await frames(2)
	print("REFERENCE_ART_RESULT "+JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
