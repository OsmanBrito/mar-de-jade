extends SceneTree
## Exercise the actual departure button with autosave disabled before scene _ready.
const Launch = preload("res://scripts/navigation/voyage_launch.gd")
const Sea = preload("res://scripts/navigation/voyage_sea.gd")
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func frames(count: int = 4) -> void:
	for i in count: await process_frame
func check(value: bool,message: String) -> void:
	checks += 1
	if not value: failures.append(message); push_error(message)
func file_hashes() -> Dictionary:
	var hashes := {}
	for path in ["user://capitulo-01.json","user://campanha-perfil.json",Launch.save_path(true),Launch.save_path(false)]:
		hashes[path] = FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "absent"
	return hashes
func run() -> void:
	var before := file_hashes()
	var progress = root.get_node("ChapterProgress")
	progress.auto_save = false; progress.reset()
	root.get_node("CampaignProfile").hero_name = "Inês"
	progress.style = "LA"; progress.skills.append("LA01"); progress.flags.recovered = true
	var flow = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate()
	flow.start_block = 16; root.add_child(flow); current_scene = flow
	await frames()
	flow._finish_block(); await frames()
	check(flow.completed and progress.completed,"Departure completes the actual Portugal chapter")
	var buttons: Array = flow.options_box.get_children()
	check(buttons.size()==1 and buttons[0].text=="Navegar para a Madeira","The actual end-of-Portugal button is present")
	var chapter_before: Dictionary = progress.snapshot()
	node_added.connect(func(node):
		if node.scene_file_path==Launch.SCENE:
			node.auto_save = false
			node.audio_settings_path = "res://tests/navigation-campaign-audio.cfg")
	buttons[0].pressed.emit(); await frames(8)
	var game = current_scene
	check(game.scene_file_path==Launch.SCENE and Launch.mode=="campaign","Departure opens the shared voyage scene in campaign mode")
	game.set_process(false)
	check(not game.auto_save and game.save_path==Launch.save_path(true),"Campaign launch uses its campaign save slot with QA writes disabled")
	check(game.model.hero_name=="Inês" and game.model.style=="LA","Departure keeps the campaign character and weapon style")
	check(game.model.boarding_profile.skills.has("LA01"),"Campaign boarding carries the actual learned techniques")
	game.clear_overlay()
	var view = game.perspective
	check(view.visible and view.camera.current,"The horizon camera is active on the campaign route")
	check(view.water_material.get_shader_parameter("wave_parameters")==PackedVector4Array(Sea.WAVES),"Departure loads today's shared four-wave ocean")
	check(view.wake_material.shader.resource_path=="res://assets/shaders/navigation_wake.gdshader","Departure loads today's continuous foam shader")
	check(game.ambience.tracks.size()==6,"All six supplied music tracks remain available after departure")
	game.model.position = Vector2(11600,18800); game.model.heading = 2.52
	game.model.elapsed = 30; game.model.immunity = 10000; game.sail_level = 3
	view.update_view(0,true)
	for i in 180: game._process(1.0/60)
	check(view.wake.all(func(node): return node.visible and node.mesh.get_surface_count()>0),"Sailing after Portugal renders all three continuous wake ribbons")
	game._refresh_status(); game.view.queue_redraw(); await frames()
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/navigation-campaign-current.png")
	check(progress.snapshot()==chapter_before and file_hashes()==before,"Voyage review leaves campaign progress and all real save files unchanged")
	game.queue_free(); await frames()
	print("NAVIGATION_CAMPAIGN_ENTRY_RESULT ",JSON.stringify({"checks":checks,"failures":failures,"rendered":DisplayServer.get_name()!="headless"}))
	quit(0 if failures.is_empty() else 1)
