extends SceneTree
const OUT="res://.qa-runtime/childhood-journey"
var game
func _initialize() -> void:
	ProjectSettings.set_setting("application/config/custom_user_dir_name","Mar-de-Jade-QA-Childhood-Journey")
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir());call_deferred("run")
func frames(n:int=8) -> void:
	for i in n:await process_frame
func shot(name:String) -> void:
	await frames(12);await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"/"+name+".png")
func dialogue() -> void:
	for i in 60:
		if game.phase!="dialogue":return
		game.advance()
func walk(at:Vector2) -> void:
	game.world.walk_to(at)
	for i in 2400:
		await physics_frame
		if game.world.player.position.distance_to(at)<20:return
		if game.world.player.destination_path.is_empty():return
func plaza_stage(id:String) -> void:
	for i in 1600:
		if game.walking_stage==id:return
		if not game.busy:game.advance()
		await physics_frame
	push_error("Plaza staging did not reach "+id);quit(1)
func wait_scene(file:String) -> void:
	for i in 180:
		await process_frame
		if current_scene!=null and current_scene.scene_file_path.ends_with(file):
			game=current_scene;await frames(12);return
	push_error("Missing journey handoff: "+file);quit(1)
func run() -> void:
	root.size=Vector2i(1440,900);Engine.max_fps=60;Engine.time_scale=2
	DirAccess.make_dir_recursive_absolute(OUT)
	var p=root.get_node("ChapterProgress");p.auto_save=false;p.reset()
	root.get_node("CampaignProfile").hero_name="Miguel";root.get_node("GamePreferences").persist_enabled=false
	change_scene_to_file("res://scenes/chapter_01/plaza.tscn");await frames(45);game=current_scene
	await walk(Vector2(-25,405));await shot("01-leonor-a-espera")
	await walk(Vector2(80,400));game.roam.interact()
	for i in 3:game.advance()
	for i in 180:
		await physics_frame
		if not game.busy:break
	await shot("02-agua-no-banco")
	await plaza_stage("first");await shot("03-primeiro-percurso")
	await walk(game.world.get_node("Staging/FirstTarget").position)
	await plaza_stage("second");await shot("04-olhar-para-leonor")
	await walk(game.world.get_node("Staging/SecondTarget").position)
	for i in 180:
		if game.completed:break
		if not game.busy:game.advance()
		await physics_frame
	game.view.next_button.pressed.emit();await wait_scene("training.tscn")
	dialogue();await shot("05-treino-com-leonor")
	# Battle rules are exercised by training.gd; this captures the authored
	# handoffs without pretending the automated fixture is a human playthrough.
	game._battle_finished(true);dialogue();game._battle_finished(true);dialogue()
	for i in 180:
		await physics_frame
		if game.world.player.presentation.posture=="crouched":break
	await shot("06-lavar-a-mao")
	for i in 180:
		await physics_frame
		if game.phase=="dialogue":break
	await shot("07-convite-para-a-ponte")
	dialogue();game.advance();await wait_scene("forest_hunt.tscn")
	await walk(Vector2(265,810));await shot("08-juntos-nos-arredores")
	await walk(game.Plan.GOALS[0]);game.interact();dialogue();game.choose("departure","together");dialogue()
	await walk(game.Plan.DISCOVERIES.shelter.at);game.interact("note:shelter");await shot("09-descoberta-partilhada")
	print("CHILDHOOD_JOURNEY_CAPTURE_COMPLETE");quit()
