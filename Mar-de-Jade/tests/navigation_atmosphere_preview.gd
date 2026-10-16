extends SceneTree
## Run with --write-movie and --fixed-fps 30 for a real engine A/V excerpt.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game = load("res://scripts/navigation/voyage.gd").new()
	game.auto_save = false; game.audio_settings_path = "res://tests/navigation-preview-defaults.cfg"
	root.add_child(game)
	await process_frame
	game.clear_overlay(); game.model.position = Vector2(11600,18800); game.model.heading = 2.52
	game.model.elapsed = 23; game.sail_level = 3
	game.perspective.update_view(0,true)
	if game.ambience.enabled: game.ambience.music[0].seek(35)
	game.notice("Vela plena · mar, vento e ondas na proa.")
	for i in 540:
		if i==210: game._sail(0,Vector2(0.7,0))
		if i>210 and i<255: Input.action_press("move_right",0.55)
		if i==255: Input.action_release("move_right")
		await process_frame
	game.queue_free(); await process_frame; quit()
