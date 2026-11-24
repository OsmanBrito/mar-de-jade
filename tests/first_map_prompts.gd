extends SceneTree
## The shown task key must perform the real interaction, including its next step.
var checks := 0
var failures: Array[String] = []
var game
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func frames(n: int = 4) -> void:
	for i in n: await process_frame
func key(code: int) -> void:
	var event := InputEventKey.new(); event.keycode = code; event.physical_keycode = code; event.pressed = true
	root.push_input(event); await frames(); event.pressed = false; root.push_input(event); await frames()
func pad(code: int) -> void:
	var event := InputEventJoypadButton.new(); event.button_index = code; event.pressed = true
	root.push_input(event); await frames(); event.pressed = false; root.push_input(event); await frames()
func walk(target: Vector2) -> bool:
	for offset in [Vector2.ZERO,Vector2(-40,25),Vector2(40,25)]:
		if not game.world.point_clear(target+offset): continue
		game.world.walk_to(target+offset)
		for i in 1200:
			await physics_frame
			if game.world.player.position.distance_to(target)<68: return true
			if game.world.player.destination_path.is_empty(): break
	return false
func run() -> void:
	var p = root.get_node("ChapterProgress"); p.auto_save = false; p.reset()
	var prefs = root.get_node("GamePreferences"); prefs.persist_enabled = false
	root.get_node("CampaignProfile").hero_name = "Inês"
	game = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate(); game.start_block = 3; root.add_child(game)
	await frames()
	for i in 600:
		if game.phase=="task": break
		if not game.busy: game.advance()
		await physics_frame
	check(game.phase=="task" and game.task_id=="clear_passage","Actual shore service reaches the crate interaction")
	check(prefs.bind_key("interact",KEY_U)=="Comando atualizado.","Player can remap the interaction key")
	check(prefs.hint_text(game.props.marker_label).begins_with("U ·"),"Crate pickup marker shows the rebound interaction key")
	check(await walk(game.props.marker),"Player can approach the crate on foot")
	await key(KEY_E)
	check(game.task_step==0 and not game.props.carrying,"Former interaction key does not pick up the crate")
	await key(KEY_U)
	check(game.task_step==1 and game.props.carrying,"Shown rebound key picks up the crate")
	check(prefs.hint_text(game.props.marker_label).begins_with("U ·") and game.props.marker_label.contains("lado seco"),"Drop-off marker preserves the rebound key after task state changes")
	# Switching device changes the same task prompt before the next interaction.
	await pad(JOY_BUTTON_DPAD_LEFT)
	check(prefs.hint_text(game.props.marker_label).begins_with("A ·"),"Task marker changes to the controller button")
	check(await walk(game.props.marker),"Player can carry the crate to its destination")
	await pad(JOY_BUTTON_A)
	check(p.flags.get("clear_passage",false) and not game.props.carrying,"Shown controller button completes the service at its destination")
	game.free(); await frames()
	prefs.bindings = prefs.DEFAULT_BINDINGS.duplicate(); prefs.apply_bindings()
	print("FIRST_MAP_PROMPTS_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
