extends SceneTree
## Verify that scene edits drive terrain, spawn, physical geometry and navigation.
var failures: Array[String] = []
var checks := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await physics_frame
	check(game.world.player.camera.zoom == Vector2(1.25,1.25), "Approved initial camera zoom")
	for map_id in ["cais", "armazem"]:
		var world = load("res://scenes/maps/%s.tscn" % map_id).instantiate()
		var ground = world.get_node("Ground") as TileMapLayer
		check(ground.get_used_cells().size() == (183 if map_id == "cais" else 56), "Authored floor: "+map_id)
		var prop = world.get_node("ActorsAndProps/crates_06" if map_id == "cais" else "ActorsAndProps/crates_00")
		check(not prop.scene_file_path.is_empty(), "Reusable prop instance: "+map_id)
		var edited_position = ground.map_to_local(Vector2i(6,6))
		prop.position = edited_position
		world.get_node("Spawn").position = ground.map_to_local(Vector2i(7,6))
		ground.erase_cell(Vector2i(0,0))
		root.add_child(world)
		check(world.player.position == world.get_node("Spawn").position, "Edited spawn used: "+map_id)
		check(not world.cells.has(Vector2i(0,0)), "Edited ground used: "+map_id)
		var blocked = false
		for polygon in world.blockers:
			blocked = blocked or Geometry2D.is_point_in_polygon(edited_position,polygon)
		check(blocked, "Edited physical footprint used: "+map_id)
		check(not world.point_ids.has(Vector2i(6,6)), "Navigation follows edited footprint: "+map_id)
		world.free()
	var before = Image.new()
	var after = Image.new()
	check(before.load("res://tests/authorship-before-cais.png") == OK, "Baseline capture available")
	check(after.load("res://tests/cais-preview.png") == OK, "Current capture available")
	# Static house region: exclude water, animated markers and travelling actor.
	var crop = Rect2i(410,0,425,310)
	var changed_pixels = 0
	var total_error = 0.0
	var maximum_channel_error = 0.0
	for y in range(crop.position.y,crop.end.y):
		for x in range(crop.position.x,crop.end.x):
			var a = before.get_pixel(x,y)
			var b = after.get_pixel(x,y)
			if a != b:
				changed_pixels += 1
				total_error += absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)
				maximum_channel_error = maxf(maximum_channel_error,maxf(absf(a.r-b.r),maxf(absf(a.g-b.g),absf(a.b-b.b))))
	print("VISUAL_COMPARISON changed_pixels=",changed_pixels," total_error=",total_error)
	# Reparenting scaled sprites changes floating point rounding by one colour unit.
	check(maximum_channel_error <= 1.0/255.0+0.00001 and changed_pixels < crop.size.x*crop.size.y*0.002, "Approved house artwork and framing within one colour unit")
	var result = {"checks":checks,"failures":failures,"visual_changed_pixels":changed_pixels,"visual_total_pixels":crop.size.x*crop.size.y,"visual_max_channel_error":maximum_channel_error}
	var file = FileAccess.open("res://tests/authorship-report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t"))
	print("AUTHORSHIP_RESULT ",JSON.stringify(result))
	game.queue_free()
	await physics_frame
	quit(0 if failures.is_empty() else 1)
