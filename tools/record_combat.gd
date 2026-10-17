extends SceneTree
## Live-rendered review using real mouse/key events; use --write-movie with --fixed-fps 30.
var game
func _initialize() -> void: call_deferred("run")
func frames(n: int) -> void:
	for i in n: await process_frame
func press(key: Key) -> void:
	var event := InputEventKey.new(); event.keycode = key; event.physical_keycode = key; event.pressed = true; root.push_input(event)
	event = event.duplicate(); event.pressed = false; root.push_input(event)
func click(point: Vector2) -> void:
	var at: Vector2 = preload("res://scripts/combat/battle_stage.gd").ui_to_window(game.host,point)
	var motion := InputEventMouseMotion.new(); motion.position = at; motion.global_position = at; root.push_input(motion,true)
	var event := InputEventMouseButton.new(); event.position = at; event.global_position = at; event.button_index = MOUSE_BUTTON_LEFT; event.pressed = true; root.push_input(event,true)
	event = event.duplicate(); event.pressed = false; root.push_input(event,true)
func click_cell(cell: Vector2i) -> void:
	click(game.host.tactical.screen(cell))
func phase(wanted: String,limit := 180) -> bool:
	for i in limit:
		if game.host.tactical.phase==wanted: return true
		await process_frame
	push_error("Recording did not reach "+wanted); return false
func run() -> void:
	root.get_node("ChapterProgress").auto_save = false
	root.get_node("CampaignProfile").hero_name = "Aprendiz"
	game = load("res://scenes/art/combat_study.tscn").instantiate(); game.encounter = "duel"; root.add_child(game)
	await frames(35)
	press(KEY_G); await frames(4); click_cell(Vector2i(5,2)); await frames(10); press(KEY_ENTER)
	if not await phase("choose"): quit(1); return
	await frames(20); press(KEY_1); await frames(4); click_cell(game.host.combat.units[2].cell); await frames(15); press(KEY_ENTER)
	if not await phase("timing_attack"): quit(1); return
	for i in 80:
		var v = game.host.tactical
		if v.grade_at(v.clock/v.duration)==2: press(KEY_SPACE); break
		await process_frame
	if not await phase("choose"): quit(1); return
	await frames(15); press(KEY_T); await frames(18); press(KEY_ENTER)
	if not await phase("timing_defend"): quit(1); return
	for i in 80:
		var v = game.host.tactical
		if v.grade_at(v.clock/v.duration)>=1: press(KEY_SPACE); break
		await process_frame
	await frames(65)
	print("COMBAT_RECORD_RESULT ",JSON.stringify({"hero_hp":game.host.combat.units[0].hp,"leonor_hp":game.host.combat.units[2].hp,"phase":game.host.tactical.phase}))
	game.free(); await frames(2); quit()
