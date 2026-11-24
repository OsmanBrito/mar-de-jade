extends SceneTree
var game
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func frames(n: int) -> void:
	for i in n: await process_frame
func dialogue() -> void:
	for i in 35:
		if game.phase != "dialogue": break
		game.advance()
func capture(path: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(path)
func run() -> void:
	root.get_node("ChapterProgress").auto_save = false
	root.get_node("CampaignProfile").hero_name = "Inês"
	game = load("res://scenes/chapter_01/training.tscn").instantiate()
	root.add_child(game)
	await frames(24)
	check(game.view.body.text == "Estás a apertar demais.","Approved opening")
	dialogue()
	var host = game.battle_host
	var b = host.combat
	var v = host.tactical
	var initial_cell: Vector2i = b.current().cell
	var target_cell: Vector2i = b.units[2].cell
	var destination := Vector2i(-1,-1)
	var path_cost := 99
	for cell in b.reachable(0).costs:
		var route: Array = b.path_to(0,cell)
		if b.distance(cell,target_cell)==1 and not route.is_empty() and route.size()<path_cost:
			destination = cell; path_cost = route.size()
	check(destination!=Vector2i(-1,-1),"The actual map has a reachable attack position beside the target")
	check(game.phase == "battle" and v.phase == "choose","Real reference battle opens from dialogue")
	check(b.order == [0,2] and b.heroes[1].hp == 0,"Initiative has only pupil and target")
	check(b.current().moves == 5,"Reference movement budget replaces pixel step")
	check(b.commands(0) == [0],"Only basic attack is an action")
	check(not b.available(5),"Removed defense action is also rejected by rules")
	var move_key = InputEventKey.new()
	move_key.physical_keycode = KEY_G; move_key.pressed = true
	root.push_input(move_key)
	await frames(3)
	check(v.phase == "move","Keyboard reaches scaled reference battle viewport")
	await capture("res://tests/reference-battle-preview.png")
	v.select_move()
	v.select_cell(destination)
	host.queue_redraw(); await frames(2)
	await capture("res://tests/reference-move-preview.png")
	check(b.current().cell == initial_cell,"Selecting path previews without moving")
	check(b.path_to(0,destination).size() == path_cost and path_cost<=5,"Path follows the actual map furniture within the movement budget")
	var pointer = InputEventMouseMotion.new()
	pointer.position = preload("res://scripts/combat/battle_stage.gd").ui_to_window(host,Vector2(760,496))
	pointer.global_position = pointer.position
	root.push_input(pointer,true)
	await frames(2)
	var click = InputEventMouseButton.new()
	click.position = pointer.position; click.global_position = pointer.position
	click.button_index = MOUSE_BUTTON_LEFT; click.pressed = true
	root.push_input(click,true)
	await frames(2)
	check(b.current().cell == destination and b.current().moves == 5-path_cost,"Confirmed path spends the displayed movement cost")
	v.update(1)
	v.undo_move()
	check(b.current().cell == initial_cell and b.current().moves == 5,"Reference undo restores position and budget")
	v.select_move(); v.select_cell(destination)
	await capture("res://tests/reference-move-preview.png"); v.confirm(); v.update(1)
	v.select_skill(0); v.select_cell(target_cell); v.confirm()
	check(v.phase == "timing_attack","Reference attack timing begins after confirmation")
	var escape = InputEventKey.new()
	escape.keycode = KEY_ESCAPE; escape.physical_keycode = KEY_ESCAPE; escape.pressed = true
	host._unhandled_input(escape)
	var frozen: float = v.clock
	await frames(10)
	check(host.paused and v.clock == frozen,"Pause freezes the reference timing")
	host._unhandled_input(escape)
	var hp: int = b.units[2].hp
	var qi: int = b.current().qi
	v.commit_timing(2)
	check(b.units[2].hp == hp and not b.current().acted,"Timing queues attack; damage waits for impact")
	v.update(0.44)
	check(b.units[2].hp == hp,"Windup preserves target health")
	v.update(0.02)
	check(b.units[2].hp < hp and b.current().acted,"Reference impact commits damage and action")
	check(b.current().qi >= qi,"Basic attack recovers energy")
	v.update(2)
	await frames(2)
	check(game.phase == "dialogue" and game.view.body.text == "Desta vez acertou.","First impact yields approved correction")
	dialogue()
	check(b.current().acted and v.phase == "choose","Intermediate dialogue preserves spent action")
	check(not b.available(0),"Cannot attack twice in the same turn")
	v.start_facing(); v.facing = 0; v.confirm()
	check(b.current_id == 2,"Facing confirmation ends turn and yields to opponent")
	v.update(1); v.update(2)
	check(b.current_id == 0 and not b.current().acted,"Opponent returns next turn with refreshed action")
	v.select_skill(0); v.select_cell(target_cell); v.confirm(); v.commit_timing(1)
	v.update(0.46); v.update(2)
	# Result hold and covered handoff follow the actual recovery.
	host.update_ending(1); host.update_ending(1)
	check(game.phase == "dialogue","Second attack leaves battle")
	dialogue()
	check(game.lesson == 1 and game.phase == "battle","Defense lesson opens same tactical engine")
	check(v.tutorial_timing(),"Childhood keeps reference learning timing")
	# End the turn: defense executes on the announced enemy attack.
	v.start_facing(); v.facing = 0; v.confirm()
	v.update(1)
	check(v.phase == "telegraph","Leonor announces attack before defensive execution")
	v.update(2)
	check(v.phase == "timing_defend","Reference defensive QTE opens on opponent attack")
	await capture("res://tests/reference-defense-preview.png")
	check(v.timing_windows().y == 0,"Perfect defense is not taught in childhood")
	var hero_hp: int = b.units[0].hp
	v.commit_timing(1)
	check(b.units[0].hp == hero_hp,"Defensive timing does not apply damage prematurely")
	v.update(0.46); v.update(2)
	host.update_ending(1); host.update_ending(1)
	check(b.units[0].hp > 0 and game.phase == "dialogue","Safe simple defense leads to narrative")
	dialogue()
	for i in 240:
		if game.phase=="dialogue":game.advance()
		elif game.phase!="washing":break
		await physics_frame
	check(game.completed,"Approved lessons complete")
	check(root.get_node("ChapterProgress").flags.get("child_forest_invited",false),"The completed practice leads to Leonor's spoken invitation")
	# Direct rules repeat failure without killing or granting perfect counter.
	b.start_lesson(1,"Inês"); b.end_turn(0)
	var plan: Dictionary = b.ai_plan()
	b.resolve_enemy(plan,{0:0})
	check(b.defense_failed and b.units[0].hp > 0,"Failure remains repeatable and nonlethal")
	var preview: Dictionary = b.defense_preview(2,0,plan,2)
	check(not preview.counter,"No childhood perfect counter even through direct rules")
	game.queue_free()
	await frames(3)
	print("REFERENCE_TRAINING_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)









