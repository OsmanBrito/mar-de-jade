extends SceneTree
var failures: Array[String] = []
var checks := 0
var game
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func frames(n: int) -> void:
	for i in n: await process_frame
func mount(mode: String,style: String = "ES") -> void:
	if is_instance_valid(game): game.free(); await frames(2)
	game = load("res://scenes/art/combat_study.tscn").instantiate(); game.encounter = mode; game.style = style; root.add_child(game)
	await frames(5)
func press(key: Key) -> void:
	var event := InputEventKey.new(); event.keycode = key; event.physical_keycode = key; event.pressed = true; root.push_input(event)
	event = event.duplicate(); event.pressed = false; root.push_input(event)
func click(point: Vector2) -> void:
	var screen_point: Vector2 = preload("res://scripts/combat/battle_stage.gd").ui_to_window(game.host,point)
	var motion := InputEventMouseMotion.new(); motion.position = screen_point; motion.global_position = screen_point; root.push_input(motion,true)
	var event := InputEventMouseButton.new(); event.position = screen_point; event.global_position = screen_point; event.button_index = MOUSE_BUTTON_LEFT; event.pressed = true; root.push_input(event,true)
	event = event.duplicate(); event.pressed = false; root.push_input(event,true)
func run() -> void:
	root.get_node("ChapterProgress").auto_save = false; root.get_node("CampaignProfile").hero_name = "Inês"
	await mount("school")
	var v = game.host.tactical; var model = game.host.combat
	check(is_equal_approx(game.container.scale.x,game.container.scale.y),"Reference viewport keeps undistorted character proportions")
	check(v.icon_texture(0,0)!=null and v.icon_texture(0,1)!=null,"Actual basic and technique buttons have their existing icons")
	check(not game.host.buttons.any(func(b): return b.id=="t_skill_5"),"Presentation does not reintroduce Defender")
	var command = game.host.buttons.filter(func(b): return b.id=="t_skill_0")[0]
	click(command.rect.get_center()); await frames(2)
	check(v.phase=="aim","Mouse selects the actual illustrated action button")
	click(game.host.tactical.screen(model.units[2].cell)); await frames(2)
	check(v.confirmation,"Mouse selects a target using the new board projection")
	press(KEY_ENTER); await frames(2)
	check(v.phase=="timing_attack","Keyboard confirms the real mouse-selected attack")
	# Execute through the controller event at the visible sweet spot, not commit_timing().
	game.host.paused = true; v.clock = v.duration*v.timing_center
	var hp: int = model.units[2].hp
	game.host.paused = false
	var pad := InputEventJoypadButton.new(); pad.button_index = JOY_BUTTON_A; pad.pressed = true; root.push_input(pad)
	await frames(1)
	check(v.phase=="animate_player" and model.units[2].hp==hp,"Controller confirms timing; damage still waits for the visible impact")
	game.host.paused = true; v.update(0.46)
	check(model.units[2].hp<hp,"Pose and effects meet the inherited simulation impact")
	await mount("child_defense"); v = game.host.tactical
	v.start_facing(); v.facing = 0; v.confirm(); v.update(1); v.update(2)
	check(not v.defense_instruction().contains("Perfeita") and v.timing_windows().y==0,"Childhood instructs only simple defense")
	await mount("perfect_defense"); v = game.host.tactical
	v.start_facing(); v.facing = 0; v.confirm(); v.update(1); v.update(2)
	check(v.phase=="timing_defend" and v.defense_instruction().contains("Perfeita") and v.timing_windows().y>0,"Tomé teaches the golden perfect window with the correct instruction")
	var audio = game.host.combat_audio
	for event in ["swing","guard","parry","gesture_cover_impact","powder-training"]:
		var stream: AudioStreamWAV = audio.stream(event)
		check(stream!=null and stream.data.size()>2000 and stream.get_length()>0.05,"Complete audible recording: "+event)
	check(audio.impact_events("ES",false,{"hits":[{"id":0,"damage":0}],"skill":-1},{0:2}).has("parry"),"Perfect block selects the parry recording at impact")
	check(audio.release_event("FO")=="powder-training" and not audio.impact_events("FO",false,{"hits":[{"id":2,"damage":4}],"skill":0},{}).has("powder-training"),"Firearm report belongs to the muzzle release, not the later target impact")
	check(audio.impact_events("MC",false,{"hits":[{"id":2,"damage":8,"breaks":true}],"skill":0},{}).has("posture_break"),"Posture-break cue uses the actual simulation result")
	var art = preload("res://scripts/combat/portugal_actor_art.gd")
	var complete := art.data().size()==6
	for entry in art.data().values(): complete = complete and entry.frames.size()==9 and entry.grips.size()==9 and entry.pivots.size()==9
	check(complete,"All six chapter combat identities have complete illustrated pose sources and anchors")
	game.free(); await frames(2)
	print("COMBAT_PRESENTATION_RESULT "+JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
