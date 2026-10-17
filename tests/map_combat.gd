extends SceneTree
const Stage = preload("res://scripts/combat/battle_stage.gd")
const Maps = preload("res://scripts/combat/battle_maps.gd")
var failures: Array[String] = []
var checks := 0
var flow
func _initialize() -> void: call_deferred("run")
func frames(n: int = 6) -> void:
	for i in n:
		if is_instance_valid(flow): flow.battle_host.queue_redraw()
		await process_frame
func check(value: bool,message: String) -> void:
	checks += 1
	if not value: failures.append(message); push_error(message)
func shot(name: String) -> void:
	await frames()
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/separate-combat-"+name+".png")
func press(key: Key) -> void:
	var event := InputEventKey.new(); event.pressed = true; event.keycode = key; event.physical_keycode = key; root.push_input(event)
	event = event.duplicate(); event.pressed = false; root.push_input(event)
func click_ui(point: Vector2) -> void:
	var position := Stage.ui_to_window(flow.battle_host,point)
	var motion := InputEventMouseMotion.new(); motion.position = position; motion.global_position = position; root.push_input(motion,true)
	var event := InputEventMouseButton.new(); event.button_index = MOUSE_BUTTON_LEFT; event.pressed = true; event.position = position; event.global_position = position; root.push_input(event,true)
	event = event.duplicate(); event.pressed = false; root.push_input(event,true)
func command(id: String) -> Vector2:
	for button in flow.battle_host.buttons:
		if button.id==id: return button.rect.get_center()
	check(false,"Visible command exists: "+id); return Vector2.ZERO
func run() -> void:
	root.get_node("ChapterProgress").auto_save = false
	root.get_node("CampaignProfile").hero_name = "Inês"
	flow = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate(); root.add_child(flow); await frames()
	var host = flow.battle_host; host.set_process(false)
	var world = flow.world
	var terrain = world.terrain
	var start: Vector2 = world.player.position
	var camera_zoom: Vector2 = world.player.camera.zoom
	var camera_offset: Vector2 = world.player.camera.offset
	var cast_positions: Dictionary = {}
	for id in flow.actors: cast_positions[id] = flow.actors[id].position
	flow._begin_battle("school"); await frames()
	var model = host.combat; var view = host.tactical
	check(host.battle_map_id==flow.map_kind,"Campaign selects the battle map of the current exploration location")
	check(not host.get_viewport().transparent_bg,"Battle is opaque and independent of exploration")
	check(host.get_viewport().world_2d!=world.get_viewport().world_2d,"Battle uses its own World2D")
	check(view.arena.c==host,"The dedicated battlefield draws inside the combat viewport")
	check(world.player.presentation.visible,"Exploration hero is not hidden or replaced")
	check(world.player.position==start and world.player.camera.zoom==camera_zoom and world.player.camera.offset==camera_offset,"Entering combat leaves exploration staging and camera unchanged")
	for y in model.SIZE.y:
		for x in model.SIZE.x:
			var cell := Vector2i(x,y)
			check(view.cell_at(view.screen(cell))==cell,"Projection and selection agree: "+str(cell))
	await shot("courtyard")
	var origin: Vector2i = model.current().cell
	var destination := Vector2i(-1,-1)
	for cell in model.reachable(0).costs:
		if model.distance(origin,cell)==1 and model.passable(cell,0): destination = cell; break
	press(KEY_G); await frames(); click_ui(view.screen(destination)); await frames()
	check(view.selected_cell==destination and view.field_state.valid,"Mouse selects a reachable battlefield cell")
	await shot("move")
	click_ui(command("t_confirm")); await frames()
	check(model.units[0].cell==destination and model.units[0].moves==4,"Visible confirmation moves the combat hero")
	view.update(1); press(KEY_Z); await frames()
	check(model.units[0].cell==origin and model.units[0].moves==5,"Undo restores the combat cell and budget")
	click_ui(command("t_skill_0")); await frames()
	click_ui(view.screen(model.units[2].cell)); await frames(); press(KEY_ENTER); await frames()
	check(view.phase=="timing_attack","Mouse target and keyboard confirmation begin offensive timing")
	var hp: int = model.units[2].hp
	view.clock = view.duration*view.timing_center; click_ui(command("t_timing")); await frames()
	check(view.phase=="animate_player" and model.units[2].hp==hp,"Timing does not apply damage before contact")
	view.update(0.451); await frames(); await shot("impact")
	check(model.units[2].hp<hp,"Damage arrives at the rendered impact")
	for id in Maps.data():
		host.combat = load("res://scripts/combat/portugal_rules.gd").new() if id=="plaza_child" else load("res://scripts/combat/campaign_rules.gd").new()
		model = host.combat; view.setup(host,model)
		host.select_battle_map(id)
		if id=="plaza_child": host.begin(0,"Inês")
		else: host.begin_encounter("duel" if id=="plaza" else "school","Inês","ES")
		await frames()
		check(view.arena.map_id==id,"Dedicated battlefield selected: "+id)
		check(not model.obstacles.is_empty(),"Authored battlefield obstacles: "+id)
		check(model.units.all(func(unit): return unit.get("withdrawn",false) or not model.obstacles.has(unit.cell)),"No unit spawns inside an obstacle: "+id)
		await shot(id)
	for style in ["ES","LA","MC","FO","PU"]:
		host.select_battle_map("courtyard"); host.begin_encounter("school","Inês",style)
		check(not model.obstacles.has(model.units[0].cell),"Teaching spawn remains free for "+style)
	if DisplayServer.get_name()!="headless":
		var original_size := root.size
		for size in [Vector2i(1280,800),Vector2i(1600,900),Vector2i(1024,768),Vector2i(1920,1080),Vector2i(2560,1440)]:
			root.size = size; await frames(12)
			var transform: Transform2D = host.get_viewport().canvas_transform
			var presentation: Transform2D = root.get_final_transform()*flow.battle_container.get_global_transform()
			var displayed: Transform2D = presentation*transform
			var outer := root.get_final_transform()
			var expected_pixels := Vector2i((flow.get_viewport_rect().size*Vector2(outer.x.length(),outer.y.length())).round())
			check(is_equal_approx(displayed.x.length(),displayed.y.length()),"No anisotropic scaling at "+str(size))
			check(host.get_viewport().size==expected_pixels,"Render target matches physical pixels, not logical campaign size: "+str(size))
			check(is_equal_approx(presentation.x.length(),1.0) and is_equal_approx(presentation.y.length(),1.0),"One combat texel per displayed pixel: "+str(size))
			check(is_equal_approx(host.get_viewport().oversampling_override,maxf(1.0,transform.x.length())),"Fonts rasterize at their displayed size: "+str(size))
			var ui_point: Vector2 = view.screen(origin)
			var ui_transform: Transform2D = flow.battle_container.get_global_transform()*transform
			check((ui_transform.affine_inverse()*Stage.ui_to_window(host,ui_point)).is_equal_approx(ui_point),"Input matches render after resize: "+str(size))
			view.cancel(); click_ui(command("t_move")); await frames()
			var reachable: Vector2i = model.current().cell+Vector2i.RIGHT
			for cell in model.reachable(model.current_id).costs:
				if cell!=model.current().cell: reachable = cell; break
			click_ui(view.screen(reachable)); await frames()
			check(view.phase=="move" and view.selected_cell==reachable and view.field_state.valid,"Real mouse input selects a reachable cell after resize: "+str(size))
			view.cancel(); await frames()
			await shot("%dx%d"%[size.x,size.y])
		root.size = original_size; await frames()
	var fit: Vector2 = view.arena.fitted_size(Vector2(240,500),Vector2(63,42))
	check(is_equal_approx(fit.x/240,fit.y/500),"Scenery aspect ratio is preserved")
	flow.battle_container.hide(); await frames()
	check(world.player.position==start,"Combat does not move the exploration hero")
	check(world.player.camera.zoom==camera_zoom and world.player.camera.offset==camera_offset,"Combat does not alter the exploration camera")
	for id in cast_positions: check(flow.actors[id].position==cast_positions[id],"Combat does not move exploration NPC: "+id)
	check(flow.world==world and world.terrain==terrain,"Original exploration scene survives combat")
	flow.free(); await frames()
	print("MAP_COMBAT_RESULT "+JSON.stringify({"checks":checks,"failures":failures,"rendered":DisplayServer.get_name()!="headless"}))
	quit(0 if failures.is_empty() else 1)
