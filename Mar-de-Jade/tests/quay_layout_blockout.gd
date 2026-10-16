extends SceneTree
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func frames(n: int) -> void:
	for i in n: await process_frame
func run() -> void:
	var game = load("res://scenes/art/quay_layout_blockout.tscn").instantiate(); root.add_child(game)
	await frames(10)
	check(game.point_clear(game.player.position),"Arrival must be free")
	for marker in game.plan.markers:
		var target: Vector2 = game.project(Vector2(marker.point[0],marker.point[1]))
		check(game.point_clear(target),"Activity must have enough clearance: "+marker.name)
		check(game.route(game.player.position,target).size()>1,"Activity must be connected: "+marker.name)
	for building in game.plan.buildings:
		check(not game.point_clear(game.project(game.rectangle(building.rect).get_center())),"Buildings must block exploration")
	check(not game.is_walkable_point(game.project(Vector2(960,450))),"River must block walking")
	var target: Vector2 = game.project(Vector2(610,190))
	game.walk_to(target)
	await create_timer(5.0).timeout
	check(game.player.position.distance_to(target)<24,"Click navigation must physically reach the service area")
	game.player.position = game.project(Vector2(game.plan.spawn[0],game.plan.spawn[1])); game.player.destination_path.clear()
	await frames(5)
	if DisplayServer.get_name()!="headless": root.get_texture().get_image().save_png("res://docs/quay-layout-blockout.png")
	game.free(); await frames(2)
	print("QUAY_LAYOUT_RESULT "+JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
