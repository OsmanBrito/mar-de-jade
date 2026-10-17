extends SceneTree
## Native Godot capture of the first Portugal scene, using the real input path.
## --write-movie .qa-runtime/shelter-review-20261016/abrigo.avi --fixed-fps 30
var game
func _initialize() -> void: call_deferred("run")
func frames(count: int) -> void:
	for i in count: await process_frame
func press(key: Key) -> void:
	var event := InputEventKey.new(); event.keycode = key; event.physical_keycode = key; event.pressed = true
	root.push_input(event); event = event.duplicate(); event.pressed = false; root.push_input(event)
func run() -> void:
	root.get_node("ChapterProgress").auto_save = false; root.get_node("CampaignProfile").hero_name = "Inês"
	change_scene_to_file("res://scenes/chapter_01/opening.tscn")
	await frames(20); game = current_scene
	await frames(65); press(KEY_ENTER); await frames(40)
	press(KEY_LEFT); await frames(35); press(KEY_ENTER); await frames(35); press(KEY_ENTER)
	for turn in 15:
		while game.busy: await process_frame
		if game.completed: break
		await frames(roundi(clampf(game.body.text.length()/22.0,1.15,2.6)*30))
		press(KEY_ENTER)
	while game.busy: await process_frame
	await frames(65)
	press(KEY_ENTER)
	for i in 90:
		if current_scene!=null and current_scene.scene_file_path=="res://scenes/chapter_01/plaza.tscn" and not root.has_node("ChapterTransition"): break
		await process_frame
	await frames(65)
	print("SHELTER_RECORD_RESULT ",JSON.stringify({"scene":current_scene.scene_file_path,"first_plaza_line":current_scene.view.body.text}))
	current_scene.queue_free(); await frames(3)
	for voice in root.get_node("ChapterMusic").voices: voice.stop(); voice.stream = null
	await frames(5); quit()
