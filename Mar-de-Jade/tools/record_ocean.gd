extends SceneTree
## Real renderer and audio: anchor, three sail notches, rudder turn and wake decay.
## Use --write-movie docs/navigation-ocean.avi --fixed-fps 30.
var game
func _initialize() -> void: call_deferred("run")
func frames(count: int) -> void:
	for i in count: await process_frame
func press(code: Key) -> void:
	var event := InputEventKey.new(); event.keycode = code; event.physical_keycode = code; event.pressed = true
	root.push_input(event); event = event.duplicate(); event.pressed = false; root.push_input(event)
func run() -> void:
	game = load("res://scripts/navigation/voyage.gd").new()
	game.auto_save = false; game.audio_settings_path = "res://tests/navigation-ocean-preview-defaults.cfg"
	root.add_child(game); await frames(2); game.clear_overlay()
	game.model.position = Vector2(11600,18800); game.model.heading = 2.52
	game.model.elapsed = 31; game.model.immunity = 10000
	game.perspective.update_view(0,true)
	if game.ambience.enabled: game.ambience.music[0].seek(35)
	game.notice("Parado · ondulação e reflexo do céu."); await frames(105)
	for i in 3:
		Input.action_press("move_up"); await frames(2); Input.action_release("move_up"); await frames(2)
	game.notice("Vela plena · espuma na proa e rastro contínuo."); await frames(210)
	game.notice("Curva ao leme · a espuma acompanha o percurso.")
	Input.action_press("move_right",0.55); await frames(45); Input.action_release("move_right"); await frames(105)
	press(KEY_SPACE); game.notice("Velas recolhidas · o rastro dispersa enquanto o mar continua."); await frames(255)
	print("OCEAN_RECORD_RESULT ",JSON.stringify({"sail_level":game.sail_level,"wake_dissolved":game.perspective.wake.all(func(node): return not node.visible),"speed":game.model.velocity.length(),"elapsed":game.model.elapsed}))
	game.queue_free(); await frames(2); quit()
