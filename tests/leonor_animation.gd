extends SceneTree
## Review-player behavior: real video resource, pause, replay and save isolation.
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func run() -> void:
	var before := {}
	for path in ["user://capitulo-01.json", "user://campanha-perfil.json", "user://navegacao.json"]:
		before[path] = FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "absent"
	var view = load("res://scenes/art/leonor_blender_study.tscn").instantiate()
	root.add_child(view)
	await process_frame
	check(view.player.stream is VideoStreamTheora, "Blender clip opens as a native Godot video")
	check(view.player.is_playing(), "Review starts playing")
	await create_timer(.5).timeout
	check(view.player.stream_position > .1, "Decoder advances through the actual clip")
	view.pause_movie()
	var paused_position: float = view.player.stream_position
	await create_timer(.2).timeout
	check(view.player.paused and absf(view.player.stream_position - paused_position) < .08, "Pause freezes playback")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.qa-runtime/leonor-blender/player-review.png")
	view.pause_movie()
	check(not view.player.paused and view.player.stream_position >= paused_position - .08, "Resume restores the same playback position")
	view.restart()
	await process_frame
	check(view.player.is_playing() and view.player.stream_position < .2, "Replay returns to the beginning")
	view.free()
	await process_frame
	for path in before:
		var after := FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "absent"
		check(after == before[path], "Review preserves save: " + path)
	print("LEONOR_ANIMATION_RESULT ", JSON.stringify({"checks": checks, "failures": failures}))
	quit(0 if failures.is_empty() else 1)
