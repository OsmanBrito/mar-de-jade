extends SceneTree
var failures: Array[String] = []
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func frames(count: int) -> void:
	for i in count: await process_frame
func run() -> void:
	var game = load("res://scenes/art/cais_study.tscn").instantiate(); root.add_child(game)
	await frames(20)
	check(game.world.point_clear(game.world.player.position),"Spawn must be navigable")
	check(not game.world.point_clear(game.duarte.position),"Duarte must block navigation")
	for name in ["Amarra","Carro","Redes","Carga"]:
		var prop = game.world.sorted_world.get_node(name)
		check(not game.world.point_clear(prop.position),"Prop footprint must block: "+name)
	var data = game.ART.metadata()
	for actor in ["hero","duarte"]:
		check(data[actor].frames.size()==16,"Every actor needs sixteen frames")
		for rect in data[actor].frames:
			check(rect[2]<200 and rect[3]>250 and rect[3]<320,"Frame must contain exactly one complete actor")
	Input.action_press("move_right"); var before: Vector2 = game.world.player.position
	await create_timer(0.25).timeout; Input.action_release("move_right"); await frames(3)
	check(game.world.player.position.distance_to(before)>15,"Keyboard must move the actor")
	check(game.hero.facing==3,"Artwork must follow movement direction")
	game.world.player.position = Vector2(50,480); game.world.player.facing = 0; game.world.player.camera.reset_smoothing()
	await frames(15)
	if DisplayServer.get_name()!="headless":
		root.get_texture().get_image().save_png("res://docs/cais-art-study.png")
	var event := InputEventAction.new(); event.action = "interact"; event.pressed = true
	game._unhandled_input(event); check(game.dialogue.visible and not game.world.player.enabled,"Dialogue must stop movement")
	await frames(3)
	if DisplayServer.get_name()!="headless": root.get_texture().get_image().save_png("res://docs/cais-art-study-dialogue.png")
	game._unhandled_input(event); check(not game.dialogue.visible and game.world.player.enabled,"Closing dialogue must restore movement")
	var route = game.world.navigation.get_point_path(game.world._nearest_id(Vector2(50,480)),game.world._nearest_id(Vector2(210,500)))
	check(route.size()>1,"Click path must route around Duarte")
	game.free(); await frames(2)
	print("ART_STUDY_RESULT "+JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
