extends SceneTree
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)
func accept() -> InputEventKey:
	var event = InputEventKey.new()
	event.keycode = KEY_ENTER
	event.pressed = true
	return event
func run() -> void:
	root.get_node("ChapterProgress").auto_save = false
	root.get_node("CampaignProfile").hero_name = "Inês"
	change_scene_to_file("res://scenes/chapter_01/opening.tscn")
	await process_frame
	await process_frame
	var opening = current_scene
	opening.completed = true
	# Exact reported path: keyboard handler continues and removes its own scene.
	opening._unhandled_input(accept())
	await process_frame
	await process_frame
	check(current_scene.scene_file_path == "res://scenes/chapter_01/plaza.tscn","Enter transitions opening to plaza")
	change_scene_to_file("res://scenes/chapter_01/training.tscn")
	await process_frame
	await process_frame
	var training = current_scene
	training.phase = "complete"
	training.completed = true
	training._unhandled_input(accept())
	await process_frame
	await process_frame
	check(current_scene.scene_file_path == "res://scenes/chapter_01/promise.tscn","Enter transitions training to promise")
	print("INPUT_TRANSITIONS_RESULT ",JSON.stringify({"checks":2,"failures":failures}))
	quit(0 if failures.is_empty() else 1)

