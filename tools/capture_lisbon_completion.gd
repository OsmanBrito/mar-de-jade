extends SceneTree
## Native staging review. Combat and navigation are verified by their own suites.
const OUT := "res://.qa-runtime/lisbon-completion"
var game
func _initialize() -> void:
	ProjectSettings.set_setting("application/config/custom_user_dir_name","Mar-de-Jade-QA-Lisbon-Completion")
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir())
	call_deferred("run")
func frames(n: int = 10) -> void:
	for i in n: await physics_frame
func shot(name: String) -> void:
	for i in 180:
		if not root.has_node("ChapterTransition"): break
		await physics_frame
	await frames(10)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"/"+name+".png")
func until_line(text: String) -> void:
	for i in 1500:
		if not game.busy:
			if game.view.body.text == text: return
			game.advance()
		await physics_frame
	push_error("Missing promise beat: "+text)
	quit(1)
func run() -> void:
	root.size = Vector2i(1440,900); Engine.max_fps = 60; Engine.time_scale = 2
	DirAccess.make_dir_recursive_absolute(OUT)
	var p = root.get_node("ChapterProgress"); p.auto_save = false; p.reset()
	root.get_node("GamePreferences").persist_enabled = false
	root.get_node("CampaignProfile").hero_name = "Miguel"
	p.flags.hunt_completed = true
	change_scene_to_file("res://scenes/chapter_01/promise.tscn")
	await frames(); game = current_scene
	await shot("01-regresso-da-floresta")
	await until_line("Gostava de ficar contigo.")
	await shot("02-no-banco")
	await until_line("Então trabalho.")
	game.advance()
	for i in 600:
		await physics_frame
		if game.leonor.carries_training_tool: break
	await shot("03-reservar-as-varas")
	while game.busy: await physics_frame
	await shot("04-para-amanha")
	await until_line("Não me faças esperar.")
	game.advance()
	while game.busy: await physics_frame
	await shot("05-a-promessa")
	game._continue_pressed()
	for i in 180:
		await physics_frame
		if current_scene != null and current_scene.scene_file_path.ends_with("adult_opening.tscn"): break
	game = current_scene
	await shot("06-primeiro-servico")
	for i in 600:
		if game.phase == "choice": break
		if not game.busy: game.advance()
		await physics_frame
	game.choose("assumir")
	for i in 600:
		if game.completed: break
		if not game.busy: game.advance()
		await physics_frame
	await shot("07-sair-para-lisboa")
	game._continue_pressed()
	for i in 180:
		await physics_frame
		if current_scene != null and current_scene.scene_file_path.ends_with("chapter_flow.tscn"): break
	game = current_scene
	await shot("08-a-entrega")
	print("LISBON_COMPLETION_CAPTURE_COMPLETE")
	quit()
