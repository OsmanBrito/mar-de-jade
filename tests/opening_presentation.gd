extends SceneTree
## Real staged motion, passive rereading, pause and the actual shelter/plaza handoff.
var checks := 0
var failures: Array[String] = []
var game
func _initialize() -> void: call_deferred("run")
func check(value: bool,message: String) -> void:
	checks += 1
	if not value: failures.append(message); push_error(message)
func frames(count: int = 3) -> void:
	for i in count: await process_frame
func press(key: Key) -> void:
	var event := InputEventKey.new(); event.keycode = key; event.physical_keycode = key; event.pressed = true
	root.push_input(event); event = event.duplicate(); event.pressed = false; root.push_input(event)
func click(control: Control) -> void:
	var point := control.get_global_rect().get_center()
	var event := InputEventMouseButton.new(); event.position = point; event.global_position = point; event.button_index = MOUSE_BUTTON_LEFT; event.pressed = true
	root.push_input(event,true); event = event.duplicate(); event.pressed = false; root.push_input(event,true)
func shot(name: String) -> void:
	await frames()
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://previews/abrigo-"+name+".png")
func saved_files() -> Dictionary:
	var result := {}
	for path in ["user://capitulo-01.json","user://campanha-perfil.json","user://navegacao.json"]:
		result[path] = FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "absent"
	return result
func inside_furniture(actor: Node2D) -> bool:
	for id in ["Table","Bed"]:
		var footprint: CollisionPolygon2D = game.room.get_node("ActorsAndProps/"+id+"/Body/Footprint")
		if Geometry2D.is_point_in_polygon(footprint.to_local(actor.global_position),footprint.polygon): return true
	return false
func run() -> void:
	var saves_before := saved_files()
	root.get_node("ChapterProgress").auto_save = false; root.get_node("CampaignProfile").hero_name = "Inês"
	check(change_scene_to_file("res://scenes/chapter_01/opening.tscn")==OK,"Shelter loads through the real scene path")
	await frames(30); game = current_scene
	while game.get_children().any(func(node): return node.get_script()==load("res://scripts/chapter/scene_transition.gd")): await process_frame
	check(game.body.text=="Estão a chamar para comer." and game.turn_counter.text=="Fala 01 / 11","First approved line is shown with its speaking turn")
	var subjects_visible := true
	for actor in [game.child,game.tome]:
		var foot: Vector2 = actor.get_global_transform_with_canvas().origin
		subjects_visible = subjects_visible and foot.y>200 and foot.y<game.panel.get_global_rect().position.y-20 and foot.x>100 and foot.x<root.get_visible_rect().size.x-100
	check(subjects_visible,"Both conversation partners remain visible above the dialogue panel")
	check(game.speaker_labels[game.tome].visible and not game.speaker_labels[game.child].visible,"The current speaker is identified in the scene")
	check(game.child.empty_bowl and game.room.get_node("ActorsAndProps/Table/Bowl").empty_bowl,"The bowl stays empty in the approved shelter scene")
	check(not game.room.has_node("ActorsAndProps/TomeStep") and game.room.get_node("ActorsAndProps/TomeSeat").furniture=="stool","The shelter uses a wooden bedside seat instead of a loose staircase")
	await shot("conversa")
	press(KEY_ENTER); await frames()
	check(game.body.text=="Já tenho esta." and game.speaker.text=="Inês","Keyboard advances to the named child's line")
	var echo := InputEventKey.new(); echo.keycode = KEY_ENTER; echo.physical_keycode = KEY_ENTER; echo.pressed = true; echo.echo = true
	root.push_input(echo); await frames()
	echo = echo.duplicate(); echo.pressed = false; echo.echo = false; root.push_input(echo)
	check(game.event_index==1 and game.history_cursor==1,"Holding Enter cannot repeat the dialogue advance")
	var position: Vector2 = game.child.position; var event_index: int = game.event_index
	click(game.previous_button); await frames()
	check(game.body.text=="Estão a chamar para comer." and game.event_index==event_index and game.child.position==position,"Rereading through the visible button changes no staging or progress")
	press(KEY_ENTER); await frames()
	check(game.body.text=="Já tenho esta." and game.event_index==event_index,"Returning to the latest read line does not consume another turn")
	for i in 4:
		if i==0:
			var pad := InputEventJoypadButton.new(); pad.button_index = JOY_BUTTON_A; pad.pressed = true; root.push_input(pad)
			pad = pad.duplicate(); pad.pressed = false; root.push_input(pad)
		else: press(KEY_ENTER)
		await frames(1)
	check(game.body.text=="O meu pai vem buscar-me?","Question about the father precedes the seated gesture")
	press(KEY_ENTER); await frames(1)
	check(game.busy and game.stage=="sitting" and not game.panel.visible,"Tomé's seated gesture has a visible separate beat")
	press(KEY_ENTER); check(game.event_index==6,"Inputs during the gesture cannot skip his reply")
	while game.busy: await process_frame
	check(game.body.text=="Hoje não veio." and game.tome.posture=="seated","His reply follows the seated gesture")
	await shot("banco")
	var seated: Vector2 = game.tome.position
	press(KEY_LEFT); await frames()
	check(game.body.text=="O meu pai vem buscar-me?" and game.tome.position==seated and game.tome.posture=="seated","Reading back across a gesture does not replay or undo it")
	press(KEY_ENTER); await frames()
	for i in 4: press(KEY_ENTER); await frames(1)
	check(game.body.text=="Amanhã também estarei aqui." and game.next_button.text=="Acompanhar Tomé","Final approved assurance has an explicit action label")
	press(KEY_ENTER)
	while game.stage!="walking": await process_frame
	await frames(12)
	check(game.tome.walking and game.tome.frame_time>0,"Walking uses directional atlas frames rather than a sliding idle sprite")
	check(not game.panel.visible and game.view.hint.text=="Esc · pausar","Staged movement clears dialogue and unusable continue hints")
	await shot("caminhada")
	press(KEY_ESCAPE); await frames(2)
	var frozen: Vector2 = game.tome.position; var frozen_frame: float = game.tome.frame_time; var frozen_steps: int = game.footstep_serial
	await frames(15)
	check(game.paused and game.tome.position==frozen and game.tome.frame_time==frozen_frame and game.footstep_serial==frozen_steps,"Pause freezes movement, gait and footstep events together")
	press(KEY_ESCAPE)
	var clear_path := true; var child_walks := false; var placed := false
	var ids: Array = []; game.scene_finished.connect(func(id): ids.append(id))
	while game.busy:
		clear_path = clear_path and not inside_furniture(game.child) and not inside_furniture(game.tome)
		child_walks = child_walks or game.child.walking
		if game.stage=="placing_bowl" and not placed: placed = true; await shot("tigela")
		await process_frame
	check(clear_path,"Both actual paths stay outside the authored bed and table footprints")
	check(child_walks and game.footstep_serial>=8,"The child follows on foot and wood footsteps follow actual travelled distance")
	check(game.completed and ids==["C01-M01/S01"],"The scene completes once after walking and placing the bowl")
	check(not game.child.carries_bowl and game.room.get_node("ActorsAndProps/Table/Bowl").visible,"The visible bowl reaches the table before continuation returns")
	check(not game.child.walking and not game.tome.walking and game.child.seat_support and game.tome.seat_support,"Both walking animations stop at their dining seats")
	await shot("mesa")
	var bounds: Rect2 = game.panel.get_global_rect()
	check(root.get_visible_rect().encloses(bounds) and game.previous_button.visible,"The final panel and reread action stay within the viewport")
	click(game.next_button); await frames(2)
	var curtain = root.get_node_or_null("ChapterTransition")
	check(curtain!=null and game.leaving,"The actual plaza button starts a covered scene transition")
	var saw_covered := false
	for i in 120:
		curtain = root.get_node_or_null("ChapterTransition")
		if curtain==null: break
		saw_covered = saw_covered or curtain.cover.color.a>0.98
		press(KEY_ENTER); await process_frame
	check(saw_covered and current_scene.scene_file_path=="res://scenes/chapter_01/plaza.tscn","The map changes under full cover and then reveals the plaza")
	check(current_scene.event_index==-1 and current_scene.phase=="childhood_explore","Carry-over Enter cannot start Leonor before the free exploration meeting")
	check(saved_files()==saves_before,"Shelter review leaves all real campaign and navigation saves unchanged")
	await shot("praca")
	current_scene.queue_free(); await frames()
	for voice in root.get_node("ChapterMusic").voices: voice.stop(); voice.stream = null
	await create_timer(0.1).timeout
	print("OPENING_PRESENTATION_RESULT ",JSON.stringify({"checks":checks,"failures":failures,"rendered":DisplayServer.get_name()!="headless"}))
	quit(0 if failures.is_empty() else 1)
