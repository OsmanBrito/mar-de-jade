extends SceneTree
const Sea = preload("res://scripts/navigation/voyage_sea.gd")
const Wake = preload("res://scripts/navigation/voyage_wake.gd")
var checks := 0
var failures: Array[String] = []
var game
var gpu_ms: Array[float] = []
var cpu_ms: Array[float] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func frames(count: int = 3) -> void:
	for i in count: await process_frame
func advance(count: int,render: bool = false) -> void:
	for i in count:
		game._process(1.0/60)
		if render:
			await process_frame
			gpu_ms.append(RenderingServer.viewport_get_measured_render_time_gpu(game.perspective.viewport.get_viewport_rid()))
			cpu_ms.append(RenderingServer.viewport_get_measured_render_time_cpu(game.perspective.viewport.get_viewport_rid()))
func capture(name: String) -> void:
	if DisplayServer.get_name()=="headless": return
	game._refresh_status(); game.view.queue_redraw(); await frames(); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/navigation-ocean-"+name+".png")
func run() -> void:
	var progress = root.get_node("ChapterProgress"); var campaign_before: Dictionary = progress.snapshot()
	var gradients_match := true
	for i in 20:
		var p := Vector2(11600+i*137.7,18800-i*63.7); var t := i*0.73
		var expected := Vector2((Sea.height(p+Vector2(0.1,0),t)-Sea.height(p-Vector2(0.1,0),t))/0.2,(Sea.height(p+Vector2(0,0.1),t)-Sea.height(p-Vector2(0,0.1),t))/0.2)
		if Sea.gradient(p,t).distance_to(expected)>0.001: gradients_match = false
	check(gradients_match,"Analytical wave normals match finite differences of the actual flotation surface")
	game = load("res://scripts/navigation/voyage.gd").new(); game.auto_save = false
	game.audio_settings_path = "res://tests/navigation-ocean-audio-fixture.cfg"
	root.add_child(game); await frames(); game.clear_overlay(); game.set_process(false)
	var m = game.model; var view = game.perspective
	m.position = Vector2(11600,18800); m.heading = 2.52; m.elapsed = 30; m.immunity = 10000; m.velocity = Vector2.ZERO; game.sail_level = 0
	view.update_view(0,true)
	RenderingServer.viewport_set_measure_render_time(view.viewport.get_viewport_rid(),true)
	check(view.water_material.get_shader_parameter("wave_parameters")==PackedVector4Array(Sea.WAVES) and view.near_material.get_shader_parameter("wave_parameters")==PackedVector4Array(Sea.WAVES),"Far water, near mesh and flotation share the same four-wave spectrum")
	await advance(90)
	check(view.wake.all(func(node): return not node.visible),"An anchored ship does not leave a travel wake")
	game.notice("Mar parado · ondulação longa e reflexo do céu."); await capture("calm")
	var level_camera: float = view.camera.position.y
	game.sail_level = 3
	await advance(390)
	check(view.wake.size()==3 and view.wake.all(func(node): return node.visible and node.mesh is ArrayMesh),"Full sail produces three continuous foam ribbons instead of separate circles")
	check(view.trail.size()<=Wake.MAX_POINTS and m.elapsed-float(view.trail[0].time)<=Wake.LIFETIME+0.06,"Wake history is bounded by both capacity and lifetime")
	check(view.camera.position.y==level_camera and absf(view.camera.global_basis.x.y)<0.0001,"Large swells preserve the approved level horizon")
	game.notice("Vela plena · proa, espuma e rastro contínuo."); await capture("travel")
	var historical: Dictionary = view.trail[-1].duplicate(true)
	Input.action_press("move_right",0.55); await advance(120); Input.action_release("move_right")
	check(absf(angle_difference(m.heading,float(historical.heading)))>0.5,"Rudder input still turns the ship normally with the new water")
	check(view.trail.any(func(sample): return sample.at==historical.at and sample.heading==historical.heading),"Old foam samples retain their original heading after the ship turns")
	var vertices: PackedVector3Array = view.wake[1].mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var historical_stern: Vector2 = historical.at-Vector2.from_angle(historical.heading)*48
	var follows_history := false
	for i in range(0,vertices.size(),6):
		var middle: Vector3 = (vertices[i]+vertices[i+1])*0.5
		if Vector2(middle.x,middle.z).distance_to(historical_stern)<20: follows_history = true
	check(follows_history,"Rendered foam geometry stays on the old path instead of rotating with the new heading")
	game.notice("Curva ao leme · o rastro conserva o caminho percorrido."); await capture("turn")
	await advance(100,DisplayServer.get_name()!="headless")
	game.stop_sailing(); await advance(480)
	check(view.wake.all(func(node): return not node.visible),"Stopping lets the entire moving wake dissolve instead of leaving permanent foam")
	var before_water: float = view.near_material.get_shader_parameter("sea_time")
	var before_ship: Transform3D = view.player.transform
	game.open_pause(); game._process(4)
	check(view.near_material.get_shader_parameter("sea_time")==before_water and view.player.transform==before_ship,"Pause freezes the water phase and flotation together")
	game.clear_overlay(); m.position += Vector2(2500,0); view.update_view(0)
	check(view.trail.is_empty() and view.wake.all(func(node): return not node.visible),"Teleporting resets all wake geometry without drawing a stripe across the sea")
	m.elapsed = 2; view.update_view(0)
	check(view.last_impact_time<m.elapsed and float(view.near_material.get_shader_parameter("hull_impact"))==0,"Restoring an earlier checkpoint resets impact foam as well as audio cooldown")
	m.position = Vector2(1600,16000); m.heading = 2.52; m.danger = 55; m.elapsed = 54; m.immunity = 10000
	game.sail_level = 3; view.update_view(0,true); await advance(150)
	var risk := clampf(maxf(m.risk_at(m.position)*0.6,m.danger/100),0,1)
	check(risk>0.5 and is_equal_approx(view.player.position.y,Sea.height(m.position,m.elapsed,risk)*0.8),"Rough sea keeps the hull on the same amplified wave field")
	check(absf(view.camera.global_basis.x.y)<0.0001 and view.camera.position.y==level_camera,"The horizon also stays level in rough water")
	game.notice("Mar agitado · cristas, espuma e movimento do casco."); await capture("rough")
	check(progress.snapshot()==campaign_before,"Ocean review leaves the campaign's inventory, progression and vitals unchanged")
	var mean_gpu := 0.0; var mean_cpu := 0.0
	for value in gpu_ms: mean_gpu += value/maxi(1,gpu_ms.size())
	for value in cpu_ms: mean_cpu += value/maxi(1,cpu_ms.size())
	var result := {"checks":checks,"failures":failures,"rendered":DisplayServer.get_name()!="headless","water_gpu_ms":mean_gpu,"water_cpu_ms":mean_cpu,"samples":gpu_ms.size()}
	FileAccess.open("res://tests/navigation-ocean-report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print("OCEAN_RESULT ",JSON.stringify(result))
	game.queue_free(); await frames(); quit(0 if failures.is_empty() else 1)
