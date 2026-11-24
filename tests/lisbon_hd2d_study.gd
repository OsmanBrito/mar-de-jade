extends SceneTree
var checks := 0
var failures: Array[String] = []
var study
var capture := false
var tour_result: Dictionary = {}
const OUTPUT := "res://.qa-runtime/hd2d"

func _initialize() -> void:
	ProjectSettings.set_setting("application/config/custom_user_dir_name", "Mar-de-Jade-QA-HD2D")
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir())
	capture = "--capture" in OS.get_cmdline_user_args()
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message)

func frames(count: int) -> void:
	for i in count: await physics_frame

func shot(label: String) -> void:
	if not capture: return
	await frames(20)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT + "/" + label + ".png")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	root.size = Vector2i(1440, 900)
	root.get_node("ChapterProgress").auto_save = false
	root.get_node("GamePreferences").persist_enabled = false
	study = load("res://scenes/art/lisbon_hd2d_study.tscn").instantiate()
	root.add_child(study)
	await frames(10)
	check(study.ready_for_test, "Scene initialized")
	check(study.route.size() == 10, "Uses the ten existing route points")
	check(study.player is CharacterBody3D, "Character has physical 3D movement")
	check(study.actor is Sprite3D, "Character remains a sprite")
	check(study.camera.fov == 40, "Perspective experiment uses FOV 40")
	check(study.camera.projection == Camera3D.PROJECTION_PERSPECTIVE, "Starts in perspective")
	check(study.get_node_or_null("CasaDaPraca/Collision") != null, "House has collision")
	await shot("praca")
	study.toggle_projection()
	check(study.camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "Orthogonal comparison works")
	await shot("praca-ortografica")
	study.toggle_projection()
	study.toggle_pixels()
	check(float(study.pixel_material.get_shader_parameter("pixel_size")) == 1, "Native pixel presentation works")
	study.toggle_pixels()
	check(float(study.pixel_material.get_shader_parameter("pixel_size")) == 2, "Two-pixel presentation works")
	study.start_tour()
	for step in 2100:
		await physics_frame
		if not study.tour_active: break
	print("HD2D_TOUR_DIAGNOSTIC ", study.player.position, " path=", study.walking_path, " visited=", study.visited)
	check(not study.tour_active, "Tour finished without getting stuck")
	check(study.player.position.distance_to(study.route[-1]) < 0.65, "Tour reached the pier physically")
	check(study.visited.size() == 10, "Tour passed all ten checkpoints")
	check(study.player.position.y > -0.1, "Pier supports the character")
	tour_result = {"visited":study.visited.duplicate(), "reached_pier":study.player.position.distance_to(study.route[-1]) < 0.65}
	await shot("cais")
	study.player.position = study.route[5] + Vector3(0, 0.15, 0)
	study.player.velocity = Vector3.ZERO
	await frames(100)
	await shot("mercado")
	study.player.position = Vector3(5.4, 0.1, 22.6)
	study.player.velocity = Vector3.ZERO
	await frames(10)
	study.interact()
	check(study.dialog.visible, "Nearby merchant can be spoken to")
	await shot("conversa")
	study.interact()
	check(not study.dialog.visible, "Merchant conversation closes")
	study.start_tour()
	var key := InputEventKey.new()
	key.physical_keycode = KEY_D
	key.pressed = true
	Input.parse_input_event(key)
	await frames(3)
	key = InputEventKey.new()
	key.physical_keycode = KEY_D
	key.pressed = false
	Input.parse_input_event(key)
	await frames(2)
	check(not study.tour_active and study.walking_path.is_empty(), "Manual movement cancels the tour")
	study.player.position = Vector3(9.5, 0.05, 14)
	study.player.velocity = Vector3.ZERO
	study.walking_path.assign([Vector3(9.5, 0, 11)])
	await frames(130)
	check(study.player.position.z > 12.7, "House stops the character")
	study.walking_path.clear()
	study.player.position = Vector3(9.5, 0.05, 8.7)
	study.player.velocity = Vector3.ZERO
	await frames(110)
	check("CasaDaDescida" in study.faded_houses, "House fades when it blocks the protagonist")
	await shot("oclusao")
	study.player.position = study.route[0] + Vector3(0, 0.1, 0)
	study.player.velocity = Vector3.ZERO
	await frames(110)
	check(study.faded_house.is_empty(), "House opacity restores after the obstruction")
	var destination: Vector3 = study.route[0] + Vector3(1.2, 0, 0.7)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = study.camera.unproject_position(destination)
	study._unhandled_input(click)
	check(not study.walking_path.is_empty(), "Ground click creates a movement target")
	await frames(90)
	check(study.player.position.distance_to(destination) < 0.4, "Click movement reaches its target")
	study.player.position.y = -5
	await frames(2)
	check(study.player.position.y > -0.1, "Falling returns to safe ground")
	root.size = Vector2i(960, 600)
	await frames(10)
	check(study.stage_label.get_global_rect().end.x < 960, "Location fits at 960px")
	check(study.pixel_button.get_global_rect().end.x < 960, "Presentation controls fit at 960px")
	await shot("compacto-960")
	var result := {"checks":checks, "failures":failures, "tour":tour_result, "captures":capture}
	var file := FileAccess.open(OUTPUT + "/verification.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	file.close()
	print("LISBON_HD2D_STUDY ", JSON.stringify(result))
	study.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
