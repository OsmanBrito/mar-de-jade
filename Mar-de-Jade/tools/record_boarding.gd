extends SceneTree
## Complete live boarding battle through actual keyboard/mouse events, with audio.
## Godot --write-movie docs/boarding-mar-de-ferro.avi --fixed-fps 30 --script tools/record_boarding.gd
var game
var recorded_frames := 0
var attacks := 0
var defenses := 0
func _initialize() -> void: call_deferred("run")
func frames(count: int) -> void:
	for i in count: recorded_frames += 1; await process_frame
func press(code: Key) -> void:
	var event := InputEventKey.new(); event.keycode = code; event.physical_keycode = code; event.pressed = true
	root.push_input(event); event = event.duplicate(); event.pressed = false; root.push_input(event)
func click(point: Vector2) -> void:
	var at: Vector2 = game.battle_container.position+point*game.battle_container.scale
	var motion := InputEventMouseMotion.new(); motion.position = at; motion.global_position = at; root.push_input(motion,true)
	var event := InputEventMouseButton.new(); event.position = at; event.global_position = at; event.button_index = MOUSE_BUTTON_LEFT; event.pressed = true
	root.push_input(event,true); event = event.duplicate(); event.pressed = false; root.push_input(event,true)
func run() -> void:
	root.get_node("ChapterProgress").auto_save = false
	change_scene_to_file("res://scenes/chapter_01/name_entry.tscn"); await frames(3)
	current_scene.get_node("Center/Card/Margin/Content/BoardingQuickStart").pressed.emit(); await frames(12)
	game = current_scene
	if game.model.phase!="boarding" or game.auto_save: push_error("Boarding recording must use the isolated menu shortcut"); quit(1); return
	await frames(30)
	while game.model.phase=="boarding" and recorded_frames<4200:
		var host = game.battle_host; var b = host.combat; var v = host.tactical
		if host.ending.running(): await frames(1); continue
		if v.phase=="choose" and v.is_player():
			if b.current().acted:
				press(KEY_T); await frames(6); press(KEY_ENTER); await frames(1); continue
			var aim := Vector2i(-1,-1); var nearest := 999
			for enemy in b.enemies:
				if enemy.hp>0 and b.distance(b.current().cell,enemy.cell)<nearest:
					aim = enemy.cell; nearest = b.distance(b.current().cell,enemy.cell)
			if b.valid_attack(0,aim):
				press(KEY_1); await frames(4); click(v.screen(aim)); await frames(9); press(KEY_ENTER); attacks += 1
			else:
				var best := Vector2i(-1,-1); var distance := 999
				for cell in b.reachable(b.current_id).costs:
					if b.distance(cell,aim)<distance: best = cell; distance = b.distance(cell,aim)
				if best!=Vector2i(-1,-1) and best!=b.current().cell:
					press(KEY_G); await frames(4); click(v.screen(best)); await frames(9); press(KEY_ENTER)
				else: press(KEY_T); await frames(6); press(KEY_ENTER)
		elif v.phase.begins_with("timing") and v.grade_at(v.clock/v.duration)==2:
			if v.phase=="timing_defend": defenses += 1
			press(KEY_SPACE)
		await frames(1)
	await frames(25)
	var passed: bool = game.model.phase=="sea" and game.model.resolved.has("patrol") and attacks>0 and defenses>0
	print("BOARDING_RECORD_RESULT ",JSON.stringify({"frames":recorded_frames,"attacks":attacks,"defenses":defenses,"returned_to_sea":game.model.phase=="sea","passed":passed}))
	game.queue_free(); await frames(2); quit(0 if passed else 1)
