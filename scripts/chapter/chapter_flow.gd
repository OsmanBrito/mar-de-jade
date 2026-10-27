extends Node2D
signal block_finished(scene_id: String)
const WORLD = preload("res://scripts/chapter/plaza_world.gd")
const PLAYER = preload("res://scenes/chapter_01/child_player.tscn")
const ACTOR = preload("res://scripts/chapter/actor_proxy.gd")
const OrderService = preload("res://scripts/chapter/first_order_service.gd")
const RULES = preload("res://scripts/combat/campaign_rules.gd")
@export_range(0,16) var start_block := 0
var blocks: Array
var layout: Dictionary
var scene_index := 0
var events: Array = []
var event_index := -1
var current_event: Dictionary = {}
var phase := "dialogue"
var busy := false
var paused := false
var world
var actors: Dictionary = {}
var props
var view
var options_box: VBoxContainer
var task_id := ""
var task_step := 0
var task_start := Vector2.ZERO
var choice_event: Dictionary = {}
var lesson_choice
var style_options: Array = []
var pending_style := ""
var pending_style_lines: Array = []
var battle_host
var battle_container: SubViewportContainer
var battle_layer: CanvasLayer
var map_kind := ""
var completed := false
var menu_open := false
var status_before_pause := ""
var menu_snapshot: Dictionary = {}
var equipment_return_phase := "styles_result"
var scene_snapshot: Dictionary = {}
var continue_after_duel := false
const Items = preload("res://scripts/chapter/player_items.gd")
var player_menu
var menu_focus: Control
var service_paid_now := false
var harbor
var routes
var staging
var block_generation := 0
var practice_resume_index := -1
var practice_events: Array = []
var order_practice_return := false
var order_trial_return := false

func _ready() -> void:
	ChapterProgress.development_awarded.connect(_show_development_notice)
	if CampaignProfile.hero_name.is_empty():
		CampaignProfile.name_entry_destination = "res://scenes/chapter_01/chapter_flow.tscn"
		get_tree().change_scene_to_file.call_deferred("res://scenes/chapter_01/name_entry.tscn")
		return
	if not InputMap.has_action("move_left"):
		var bindings = preload("res://scripts/main.gd").new(); bindings.configure_input(); bindings.free()
	blocks = JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_01/chapter_flow.json")).scenes
	layout = JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_01/staging.json"))
	ChapterProgress.choices.origin_response = CampaignProfile.origin_response
	scene_index = ChapterProgress.checkpoint if ChapterProgress.resume_requested else start_block
	ChapterProgress.resume_requested = false
	view = preload("res://scripts/chapter/dialogue_view.gd").new()
	add_child(view)
	view.continuation_requested.connect(advance)
	view.replay_requested.connect(restart_block)
	view.menu_requested.connect(_menu)
	player_menu = preload("res://scripts/chapter/player_menu.gd").new()
	player_menu.director = self; add_child(player_menu)
	player_menu.close_requested.connect(_menu)
	player_menu.save_requested.connect(func(): player_menu.notice.text = "Capítulo guardado." if ChapterProgress.save_to() == OK else ChapterProgress.last_error)
	player_menu.load_requested.connect(load_checkpoint)
	player_menu.restart_requested.connect(restart_block)
	options_box = VBoxContainer.new()
	options_box.add_theme_constant_override("separation",6)
	view.body.get_parent().add_child(options_box)
	_create_battle()
	harbor = preload("res://scripts/chapter/harbor_visit.gd").new(self)
	routes = preload("res://scripts/chapter/lisbon_routes.gd").new(self)
	_load_block(scene_index,false,true)

func _create_battle() -> void:
	battle_layer = CanvasLayer.new(); battle_layer.layer = 10; add_child(battle_layer)
	battle_container = SubViewportContainer.new(); battle_container.size = Vector2(960,540); battle_container.stretch = true
	battle_layer.add_child(battle_container)
	preload("res://scripts/combat/battle_stage.gd").install(battle_layer,battle_container)
	var viewport := SubViewport.new(); viewport.size = Vector2i(960,540); viewport.world_2d = World2D.new()
	battle_container.add_child(viewport)
	battle_host = preload("res://scripts/combat/battle_host.gd").new()
	battle_host.combat = RULES.new()
	viewport.add_child(battle_host)
	battle_host.lesson_completed.connect(_battle_finished)
	battle_host.practice_aborted.connect(_practice_aborted)
	get_viewport().size_changed.connect(_resize_battle)
	_resize_battle(); battle_container.hide()

func _resize_battle() -> void:
	preload("res://scripts/combat/battle_stage.gd").fit(battle_container,get_viewport_rect().size)

func _load_block(index: int,preserve_position: bool = false,restore_journey: bool = false) -> void:
	block_generation += 1
	var saved_journey: Dictionary = ChapterProgress.journey.duplicate(true) if restore_journey else {}
	if routes!=null and routes.active: routes.stop(true)
	var previous_kind := map_kind
	var feet: Vector2 = world.player.position if is_instance_valid(world) else Vector2.ZERO
	scene_index = index; ChapterProgress.checkpoint = index
	ChapterProgress.entry_scene = "res://scenes/chapter_01/chapter_flow.tscn"
	if saved_journey.get("kind","")=="port_visit" and ChapterProgress.completed:
		completed = true; events = []; event_index = -1; current_event = {}; busy = false
		_load_map("cais"); routes.restore(saved_journey)
		scene_snapshot = ChapterProgress.snapshot(); return
	events = blocks[index].events.duplicate(true); event_index = -1; current_event = {}

	# Additive introduction: old in-progress saves without this flag keep their event indices.
	if index==0 and (ChapterProgress.flags.get("order_intro_started",false) or (saved_journey.is_empty() and ChapterProgress.flags.is_empty())):
		ChapterProgress.flags.order_intro_started = true
		var styles: Dictionary = blocks[13].events.filter(func(e): return e.type=="styles")[0]
		events = OrderService.intro(styles)+events
	if index==3 and ChapterProgress.flags.get("order_intro_started",false): events.append({"type":"order_help"})
	if index==4 and ChapterProgress.flags.get("meal",false): events = events.filter(func(event): return event.get("id","")!="meal")
	if index==0 and ChapterProgress.flags.get("order_intro_started",false) and (ChapterProgress.flags.get("delivery_pending",false) or saved_journey.get("stage","")=="delivery_return"):
		ChapterProgress.flags.order_delivery_prefix = true
	if index==0 and (ChapterProgress.flags.get("order_delivery_prefix",false) or (ChapterProgress.flags.get("delivery_pending",false) and not ChapterProgress.flags.get("delivery_finished",false)) or saved_journey.get("stage","")=="delivery_return"):
		events = [{"type":"task","id":"delivery","caption":"Leva os sacos de farinha à vizinha da cozinha; mantém-nos separados do peixe.","map":"cais"},{"type":"line","speaker":"Vizinha","text":"Chegaram secos e separados. Obrigada pela entrega. O Duarte espera-te no pátio para descerem juntos ao cais."},{"type":"stage","action":"delivery_return"}]+events
	phase = "dialogue"; busy = false; completed = false; task_id = ""
	service_paid_now = false
	view.status.text = ""; view.speaker.text = ""; view.body.text = ""
	_clear_options(); view.show(); view.next_button.show(); view.next_button.disabled = false
	view.replay_button.hide(); view.next_button.text = "Continuar"
	view.caption_label.text = "Portugal · "+preload("res://scripts/chapter/adult_arc.gd").context(index)+"\n"+blocks[index].title
	view.hint.text = "Enter / espaço / A · continuar     Esc / Start · menu"
	var first_delivery: bool = index==0 and ChapterProgress.flags.get("delivery_pending",false) and not ChapterProgress.flags.get("delivery_finished",false)
	_load_map("room" if first_delivery else blocks[index].map)
	if world.has_meta("continuous_lisbon") and not preserve_position and saved_journey.is_empty() and index not in [6,7]: world.player.position = _point("hero")
	if first_delivery and saved_journey.is_empty(): world.player.position = Vector2(-40,345)
	if preserve_position and routes.zone(previous_kind)==routes.zone(map_kind):
		world.player.position = feet
		if index==7:
			world.player.presentation.posture = "standing"
			events.insert(0,{"type":"stage","action":"sit_bench"})
	if not saved_journey.is_empty():
		event_index = int(saved_journey.event)
		if event_index>=0 and event_index<events.size(): current_event = events[event_index]
		routes.restore(saved_journey); scene_snapshot = ChapterProgress.snapshot(); return
	scene_snapshot = ChapterProgress.snapshot()
	if ChapterProgress.auto_save: ChapterProgress.save_to()
	if index in [3,5,15] and ChapterProgress.flags.get("harbor_pause",false) and harbor.can_begin():
		ChapterProgress.flags.erase("harbor_pause")
		routes.begin("rest" if index==5 else "block",6 if index==5 else index+1); return
	advance()

func _point(key: String) -> Vector2:
	var coordinates: Array = layout[map_kind].get(key,layout[map_kind].object)
	return Vector2(float(coordinates[0]),float(coordinates[1]))

func _load_map(kind: String) -> void:
	if kind=="service":
		_load_refectory(); return
	if kind=="convent":
		if is_instance_valid(world): remove_child(world); world.queue_free()
		map_kind = kind; actors.clear()
		world = load("res://scenes/maps/convento_ordem.tscn").instantiate(); add_child(world)
		props = preload("res://scripts/chapter/stage_props.gd").new(); props.hero = world.player; props.map_kind = "room"
		world.sorted_world.add_child(props); props.hide(); staging = null
		return
	if kind in ["plaza","courtyard","cais"]:
		_load_city(kind); return
	if has_node("DepartureCamera"): get_node("DepartureCamera").free()
	if has_node("DepartureShore"): get_node("DepartureShore").free()
	if world != null:
		remove_child(world); world.queue_free()
	map_kind = kind; actors.clear()
	var map_path := "res://scenes/maps/praca_infancia.tscn"
	if kind in ["cais","service"]: map_path = "res://scenes/maps/cais_vivo.tscn"
	elif kind == "room": map_path = "res://scenes/maps/abrigo_infancia.tscn"
	elif kind == "deck": map_path = "res://scenes/maps/botafogo_departure.tscn"
	world = load(map_path).instantiate()
	world.set_script(WORLD)
	world.map_id = "abrigo_adulto" if kind == "room" else ("cais" if kind in ["cais","service"] else ("botafogo_departure" if kind=="deck" else "praca_infancia"))
	world.player_scene = PLAYER
	if kind in ["plaza","courtyard"]: world.set_meta("open_lisbon",true)
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	var sorted = world.get_node("ActorsAndProps")
	for object in sorted.get_children():
		if object.name in [&"Leonor",&"Child",&"Tome",&"Acompanhante"] or object.get_script() == preload("res://scripts/interaction.gd") or kind == "deck":
			object.free()
	if not world.has_node("Spawn"):
		var spawn := Marker2D.new(); spawn.name = "Spawn"; world.add_child(spawn)
	world.get_node("Spawn").position = _point("hero")
	if kind=="deck":
		for x in 10:
			for y in 10: world.get_node("Ground").set_cell(Vector2i(x,y),0,Vector2i(1,0))
	add_child(world)
	if kind in ["plaza","courtyard"]: preload("res://scripts/chapter/lisbon_routes.gd").open_paths(world)
	if kind == "deck":
		for node_name in ["CityGround","PracaDeLisboa"]:
			var decoration: Node = world.get_node_or_null(node_name)
			if decoration != null: decoration.free()
		preload("res://scripts/chapter/departure_deck.gd").install(world)
		var shore := Node2D.new(); shore.set_script(preload("res://scripts/chapter/departure_shore.gd")); shore.name = "DepartureShore"; add_child(shore)
	world.player.presentation.identity = "hero"
	world.player.presentation.posture = "standing"
	world.player.enabled = false; world.player.set_physics_process(false)
	world.player.camera.reset_smoothing()
	if kind in ["cais","service","deck"]: world.player.camera.offset = Vector2(120,65)
	for name in layout[kind]:
		if name in ["hero","object","destination"]: continue
		_add_actor(name,_point(name))
	props = preload("res://scripts/chapter/stage_props.gd").new()
	props.map_kind = kind; props.object_position = _point("object"); props.hero = world.player
	if kind == "courtyard": props.object_position = _point("Criança")+Vector2(-30,30)
	props.cargo_freed = ChapterProgress.flags.get("cargo_freed",false); props.packed = ChapterProgress.flags.get("packed",false)
	props.meal_ready = ChapterProgress.flags.get("meal",false)
	sorted.add_child(props)
	if kind == "service":
		var table := preload("res://scenes/chapter_01/table.tscn").instantiate()
		table.position = _point("object")+Vector2(0,28)
		sorted.add_child(table)
		props.z_index = 1 # Crockery belongs on the tabletop, not behind the table sprite.
		_add_actor("Ajudante da cozinha",Vector2(470,830))
		actors["Ajudante da cozinha"].npc_id = "attendant"; actors["Ajudante da cozinha"].carries_bowl = not ChapterProgress.flags.get("meal",false)
	_configure_actors()
	staging = preload("res://scripts/chapter/chapter_staging.gd").new()
	staging.name = "ChapterStaging"; staging.director = self; world.add_child(staging)
	staging.configure(kind,blocks[scene_index].id)
	if kind in ["cais","service"]:
		preload("res://scripts/chapter/portugal_quay_art.gd").apply(world)
	harbor.install(world)
	world.rebuild_navigation()

func _load_city(kind: String) -> void:
	var reuse: bool = is_instance_valid(world) and world.has_meta("continuous_lisbon")
	var feet := Vector2.ZERO
	if reuse:
		feet = world.player.position
		world.clear_story()
	else:
		if is_instance_valid(world): remove_child(world); world.queue_free()
		world = load("res://scenes/maps/praca_infancia.tscn").instantiate()
		world.set_script(preload("res://scripts/city/lisbon_world.gd")); world.childhood = false
		world.player_scene = PLAYER
		for object in world.get_node("ActorsAndProps").get_children():
			if object.name in [&"Leonor",&"Child",&"Tome",&"Acompanhante"] or object.get_script()==preload("res://scripts/interaction.gd"): object.free()
		world.get_node("Spawn").position = Vector2(-130,350)
		add_child(world); world.remember_static()
	map_kind = kind; actors.clear()
	world.player.presentation.identity = "hero"; world.player.presentation.posture = "standing"
	world.player.enabled = false; world.player.set_physics_process(false)
	world.player.camera.enabled = true; world.player.camera.make_current()
	for name in layout[kind]:
		if name not in ["hero","object","destination"]: _add_actor(name,_point(name))
	props = preload("res://scripts/chapter/stage_props.gd").new()
	props.map_kind = kind; props.object_position = _point("object"); props.hero = world.player
	if kind=="courtyard": props.object_position = _point("Criança")+Vector2(-30,30)
	props.cargo_freed = ChapterProgress.flags.get("cargo_freed",false); props.packed = ChapterProgress.flags.get("packed",false)
	props.meal_ready = ChapterProgress.flags.get("meal",false); world.sorted_world.add_child(props)
	if kind=="service":
		var table := preload("res://scenes/chapter_01/table.tscn").instantiate(); table.position = _point("object")+Vector2(0,28)
		world.sorted_world.add_child(table); props.z_index = 1
		_add_actor("Ajudante da cozinha",Vector2(470,830)); actors["Ajudante da cozinha"].npc_id = "attendant"
		actors["Ajudante da cozinha"].carries_bowl = not ChapterProgress.flags.get("meal",false)
	_configure_actors()
	world.player.position = feet if reuse else _point("hero")
	staging = preload("res://scripts/chapter/chapter_staging.gd").new(); staging.name = "ChapterStaging"; staging.director = self; world.add_child(staging)
	staging.configure(kind,blocks[scene_index].id)
	harbor.install(world); world.rebuild_navigation(); world.player.camera.reset_smoothing()

func _add_actor(name: String, point: Vector2) -> void:
	var actor := Node2D.new(); actor.set_script(ACTOR)
	actor.identity = "tome" if name == "Tomé" else ("duarte" if name == "Duarte" else ("leonor_adult" if name == "Leonor" else ("child" if name == "Criança" else "hero")))
	actor.npc_id = {"Tomé":"tome_adult","Duarte":"duarte","Leonor":"leonor_adult","Criança":"shelter_child","Trabalhador":"worker","Trabalhador ferido":"injured_worker","Mulher do cais":"dock_woman","Observador":"observer","Mestre":"master","Combatente":"combatant","Rodrigo":"rodrigo","Beatriz":"beatriz","Familiar":"family"}.get(name,"")
	actor.position = point
	var label := Label.new(); label.name = "NameLabel"; label.text = name; label.position = Vector2(-65,-92); label.size.x = 130
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.add_theme_font_size_override("font_size",12)
	label.add_theme_color_override("font_color",Color("eee5cc")); actor.add_child(label)
	label.add_theme_color_override("font_outline_color",Color("142c2b")); label.add_theme_constant_override("outline_size",4)
	var body := StaticBody2D.new(); body.collision_mask = 0; actor.add_child(body)
	var footprint := CollisionPolygon2D.new(); var polygon := PackedVector2Array()
	for i in 12: polygon.append(Vector2.from_angle(i*TAU/12)*12)
	footprint.polygon = polygon; body.add_child(footprint)
	world.get_node("ActorsAndProps").add_child(actor); actors[name] = actor

func _load_refectory() -> void:
	var reuse: bool = is_instance_valid(world) and world.has_meta("order_convent")
	var feet: Vector2 = world.player.position if reuse else Vector2(1310,20)
	if reuse: world.clear_story()
	else:
		if is_instance_valid(world): remove_child(world); world.queue_free()
		world = load("res://scenes/maps/convento_ordem.tscn").instantiate(); add_child(world)
	map_kind = "service"; actors.clear()
	world.player.presentation.identity = "hero"; world.player.presentation.posture = "standing"
	world.player.presentation.seat_support = false
	world.player.enabled = false; world.player.set_physics_process(false)
	_add_actor("Leonor",Vector2(594,35)); actors.Leonor.posture = "seated"; actors.Leonor.facing = 1
	actors["Ajudante da cozinha"] = world.sorted_world.get_node("AjudanteDaCozinha")
	actors["Ajudante da cozinha"].carries_bowl = not ChapterProgress.flags.get("meal",false)
	props = preload("res://scripts/chapter/stage_props.gd").new(); props.map_kind = "service"; props.hero = world.player
	props.object_position = Vector2(560,-80); props.meal_surface_offset = Vector2(0,-45); props.meal_ready = ChapterProgress.flags.get("meal",false); world.sorted_world.add_child(props)
	world.player.position = feet
	if ChapterProgress.flags.get("meal",false): _seat_at_meal()
	staging = preload("res://scripts/chapter/chapter_staging.gd").new(); staging.name = "ChapterStaging"; staging.director = self; world.add_child(staging)
	staging.configure("service",blocks[scene_index].id)
	world.rebuild_navigation(); world.player.camera.reset_smoothing()

func _configure_actors() -> void:
	var id: String = blocks[scene_index].id
	if map_kind == "courtyard":
		actors.get("Tomé").visible = id.begins_with("C01-M04")
		actors.get("Criança").hide(); actors.get("Trabalhador").hide()
	elif map_kind == "cais":
		if actors.has("Familiar"): actors["Familiar"].visible = id=="C01-M02/S03"
		actors["Leonor"].visible = id != "C01-M02/S01" and id != "C01-M02/S02"
		actors["Tomé"].visible = id != "C01-M02/S01"
		actors["Trabalhador ferido"].posture = "fallen" if id=="C01-M02/S01" else "seated"
		world.player.presentation.eye_glow = ChapterProgress.flags.get("green_sight",false) and id == "C01-M02/S02"
		if scene_index==0:
			for actor in actors.values(): actor.hide()
			var receiver = world.sorted_world.get_node_or_null("Vizinha")
			if receiver!=null:
				receiver.set_physics_process(false); receiver.position = Vector2(315,955); receiver.presentation.walking = false
	elif map_kind == "plaza":
		var public_scene: bool = id == "C01-M03/S01"
		actors["Mestre"].visible = public_scene; actors["Combatente"].visible = public_scene
		actors["Duarte"].visible = public_scene or id == "C01-M03/S06"
		for name in ["Mestre","Combatente","Leonor"]: actors[name].carries_training_tool = public_scene
		actors["Leonor"].visible = id not in ["C01-M03/S06"]
		if id in ["C01-M03/S02","C01-M03/S03","C01-M03/S04","C01-M03/S05","C01-M03/S06"]:
			world.get_node("ActorsAndProps/Bench/Cups").show()
		if ChapterProgress.flags.get("injured",false):
			world.player.presentation.posture = "fallen"; world.player.position = Vector2(23,352)
	elif map_kind == "service":
		_seat_at_meal()
		if not ChapterProgress.flags.get("meal",false):
			world.player.position = _point("hero"); world.player.presentation.posture = "standing"
	elif map_kind == "room" and ChapterProgress.flags.get("injured",false):
		world.player.position = Vector2(-70,205); world.player.presentation.posture = "seated"
		world.player.presentation.injured = true
		var bedside := Node2D.new(); bedside.name = "BedsideSupport"
		bedside.set_script(preload("res://scripts/chapter/bedside_setting.gd"))
		bedside.position = world.player.position+Vector2(52,20)
		world.get_node("ActorsAndProps").add_child(bedside)
		var body := StaticBody2D.new(); body.collision_mask = 0; bedside.add_child(body)
		var footprint := CollisionPolygon2D.new()
		footprint.polygon = PackedVector2Array([Vector2(-17,-3),Vector2(0,-11),Vector2(17,-3),Vector2(0,6)])
		body.add_child(footprint)
		actors["Duarte"].visible = id != "C01-M03/S07"
		actors["Tomé"].posture = "seated"
		actors["Tomé"].seat_support = true
	for actor in actors.values():
		actor.get_child(1).process_mode = Node.PROCESS_MODE_PAUSABLE
		if not actor.visible: actor.get_child(1).get_child(0).set_deferred("disabled",true)

func _seat_at_meal() -> void:
	if world.has_meta("order_convent"):
		world.player.position = Vector2(526,35); actors.Leonor.position = Vector2(594,35)
		actors.Leonor.posture = "seated"; world.player.presentation.posture = "seated"
		actors.Leonor.facing = 1; world.player.presentation.facing = 3
		actors.Leonor.seat_support = false; world.player.presentation.seat_support = false
		return
	world.player.position = _point("object")+Vector2(-74,27)
	actors["Leonor"].position = _point("object")+Vector2(75,28)
	actors["Leonor"].posture = "seated"; world.player.presentation.posture = "seated"
	actors["Leonor"].facing = 1; world.player.presentation.facing = 3
	actors["Leonor"].seat_support = true; world.player.presentation.seat_support = true
	actors["Leonor"].queue_redraw(); world.player.presentation.queue_redraw()

func _lock_player(lock: bool) -> void:
	world.player.enabled = not lock; world.player.set_physics_process(not lock)
	if not lock:
		world.player.presentation.posture = "standing"; world.player.presentation.seat_support = false; world.player.presentation.seat_lift = 0
	world.player.velocity = Vector2.ZERO; world.player.destination_path.clear(); world.player.presentation.walking = false
	var local_camera: bool = routes!=null and routes.active and phase in ["roaming","local_dialogue","order_inspection","boarding","shore_return","rest_confirm"]
	if not local_camera:
		world.player.camera.offset = Vector2(120,65) if lock and map_kind in ["cais","service","deck"] else Vector2(0,-100)
		if lock and map_kind == "room": world.player.camera.offset = Vector2(64,250)-world.player.position
	if is_instance_valid(staging) and staging.get_parent()==world and not has_node("DepartureCamera"): staging.set_control_locked(lock and not local_camera)
	if local_camera:
		world.player.camera.enabled=true;world.player.camera.make_current();world.player.camera.reset_smoothing()

func _clear_options() -> void:
	if is_instance_valid(lesson_choice): lesson_choice.close()
	for child in options_box.get_children():
		options_box.remove_child(child)
		child.queue_free()
	options_box.hide()

func _option(label: String, callback: Callable) -> void:
	var button := Button.new(); button.text = label; button.custom_minimum_size.y = 42
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.pressed.connect(callback); options_box.add_child(button)

func advance() -> void:
	if phase == "local_dialogue" and not busy and not paused:
		harbor.city.advance(); return
	if busy or paused or phase not in ["dialogue","block_end"]: return
	if phase == "block_end":
		if scene_index+1 < blocks.size(): _load_block(scene_index+1)
		return
	event_index += 1
	if event_index >= events.size(): _finish_block(); return
	current_event = events[event_index]
	match current_event.type:
		"line":
			_lock_player(true); _clear_options(); view.panel.show(); view.next_button.show()
			view.speaker.text = CampaignProfile.speaker_name(current_event.speaker)
			view.body.text = current_event.text; view.status.text = ""
			view.remember(view.speaker.text,view.body.text)
			if is_instance_valid(staging):staging.attend(current_event.speaker)
			view.hint.text = "Enter / espaço / A · continuar     Esc · menu     F5 / menu · guardar"
			view.next_button.grab_focus()
		"choice": _show_choice(current_event)
		"stage":
			busy = true; view.next_button.disabled = true
			view.hint.text = "Esc / Start · pausar"
			var generation := block_generation
			await _stage(current_event.action)
			if generation!=block_generation: return
			busy = false; view.next_button.disabled = false; advance()
		"task": _begin_task(current_event)
		"battle": _begin_battle(current_event.mode)
		"styles": _show_styles(current_event.options)
		"order_supply": OrderService.supply(self)
		"order_check":
			if ChapterProgress.flags.get("order_check_done",false): advance()
			else: routes.begin("order_check",scene_index)
		"order_report":
			if ChapterProgress.flags.get("order_reported",false): advance()
			else: routes.begin("order_report",scene_index)
		"order_help": OrderService.help_offer(self)


func _finish_block() -> void:
	if RULES.Development.STORY.has(blocks[scene_index].id):
		ChapterProgress.award_development("story:"+blocks[scene_index].id,RULES.Development.STORY[blocks[scene_index].id])
	ChapterProgress.sync_development()
	# Keep the approved defeat and its first dialogue together, under the curtain.
	if continue_after_duel and scene_index+1<blocks.size():
		continue_after_duel = false
		block_finished.emit(blocks[scene_index].id)
		_load_block(scene_index+1,true)
		return
	phase = "block_end"; _lock_player(true); _clear_options(); view.show(); view.panel.show()
	block_finished.emit(blocks[scene_index].id)
	if scene_index in [0,3,5,6,14,15]:
		routes.begin("rest" if scene_index==5 else "block",scene_index+1); return
	if scene_index == blocks.size()-1:
		completed = true; ChapterProgress.completed = true
		preload("res://scripts/chapter/party_progress.gd").recruit_duarte(ChapterProgress)
		view.speaker.text = "Capítulo 1 · A promessa impossível"
		view.body.text = "A Botafogo parte. Vais como aprendiz sob Rodrigo. Madeira é a primeira escala para mantimentos, antes de Duas Águas e da busca pela caravela desaparecida."
		view.status.text = "Rumo à Madeira"; view.next_button.hide(); view.replay_button.hide()
		view.hint.text = "Enter / A · navegar para a Madeira     Esc · menu"
		options_box.show()
		_option("Navegar para a Madeira",func(): preload("res://scripts/navigation/voyage_launch.gd").start(get_tree(),true))
		options_box.get_child(0).grab_focus()
		if ChapterProgress.auto_save: ChapterProgress.save_to()
		return
	# The final line leads straight into the next scene. Safe preparation and
	# shore leave keep their own menus instead of a filler "Continuar." card.
	var paid := service_paid_now
	_load_block(scene_index+1,true)
	if paid: view.status.text = "Serviço no cais · +40 de ouro"

func _show_choice(event: Dictionary) -> void:
	phase = "choice"; choice_event = event; _lock_player(true); _clear_options()
	view.speaker.text = CampaignProfile.hero_name; view.body.text = "Escolhe a tua resposta."
	view.next_button.hide(); options_box.show()
	for option in event.options:
		var label: String = option.label
		for response in option.events:
			if response.type=="line" and response.speaker in ["Herói","Herói adulto"]:
				label = "“"+response.text+"”"; break
		_option(label,choose.bind(option.id))
	options_box.get_child(0).grab_focus()

func choose(id: String) -> void:
	if paused or phase != "choice": return
	for option in choice_event.options:
		if option.id == id:
			ChapterProgress.choices[choice_event.get("flag",blocks[scene_index].id)] = id
			_insert(option.events); phase = "dialogue"; _clear_options(); advance(); return

func _insert(extra: Array) -> void:
	for i in range(extra.size()-1,-1,-1): events.insert(event_index+1,extra[i].duplicate(true))

func _begin_task(event: Dictionary) -> void:
	if event.id=="delivery" and ChapterProgress.flags.get("delivery_finished",false): advance(); return
	if event.id=="fetch_tome":
		routes.begin("fetch",scene_index); return
	if event.id=="delivery" and routes.area()!="cais":
		routes.begin("delivery",scene_index); return
	if event.has("map") and event.map!=map_kind: _load_map(event.map)
	task_id = event.id; task_step = 0; phase = "task"
	view.panel.hide(); _clear_options(); _lock_player(false)
	world.player.presentation.posture = "standing"; world.player.presentation.position = Vector2.ZERO
	if task_id == "recovery_walk":
		props.marker = Vector2(110,365)
		actors["Tomé"].position = Vector2(10,295); actors["Tomé"].posture = "standing"
	else: props.marker = _point("object")
	if task_id == "recovery_water":
		props.marker = world.player.position+Vector2(28,16)
		world.player.presentation.posture = "seated"; _lock_player(true)
	# The first adult task is performed beside the child, not at the generic
	# prop position.  Keeping the marker on the actor makes the instruction
	# match what the player sees and lets E/A work when approaching the child.
	if task_id == "knot" and actors.has("Criança"):
		props.marker = actors["Criança"].position + Vector2(0, 18)
		props.object_position = props.marker
	props.marker_active = true; props.marker_label = "E · "+{"lever":"usar a alavanca","fetch_tome":"falar com Tomé","clear_passage":"pegar o caixote","meal":"levar a refeição","pack":"guardar a tigela","blue_rope":"apanhar a amarra","knot":"apertar a correia","recovery_walk":"caminhar"}.get(task_id,"interagir")
	if task_id=="recovery_water": props.marker_label = "E / A · beber água"
	if task_id == "fetch_tome": props.marker = actors["Tomé"].position+Vector2(-35,25)
	if task_id=="delivery":
		props.delivery_active = true; props.carrying = true; props.marker = Vector2(315,997)
		props.marker_label = "E / A · conferir a entrega da cozinha"
	if task_id=="lever":
		props.marker_label = "E / A · assentar o apoio"
		view.status.text = "A madeira prende o braço. Assenta a alavanca num apoio antes de combinar a elevação com Duarte."
	if task_id == "clear_passage": props.crate_task = true
	if task_id == "meal":
		props.carrying = false; props.meal_ready = false; actors["Ajudante da cozinha"].carries_bowl = true
		props.marker = actors["Ajudante da cozinha"].position+Vector2(0,30)
		props.marker_label = "E / A · receber duas porções e água"
	if task_id == "pack":
		actors["Tomé"].carries_bowl = false
		world.player.presentation.carries_bowl = true
	task_start = world.player.position
	var instruction:=preload("res://scripts/chapter/adult_arc.gd").task(task_id,task_step)
	view.status.text = "OBJETIVO  ·  "+(event.caption if instruction.is_empty() else instruction); view.hint.text = "WASD / setas / clique · mover     E / A · executar objetivo     Esc · menu"
	if task_id=="recovery_water": view.hint.text = "E / A · beber a água     Esc / Start · menu"
	var focus = get_viewport().gui_get_focus_owner()
	if focus != null: focus.release_focus()
	world.rebuild_navigation()

func interact_task() -> void:
	if paused or busy or phase != "task": return
	if task_id=="blue_rope" and task_step==0:
		var white := Vector2(50,290)
		if world.player.position.distance_to(white)<70 and world.player.position.distance_to(white)<world.player.position.distance_to(props.marker):
			view.status.text = "Beatriz · A branca fica comigo. Leva a ponta da azul ao Duarte."
			return
	if world.player.position.distance_to(props.marker) > (68 if task_id=="meal" else 92): return
	if task_id=="delivery":
		phase = "delivery_choice"; _lock_player(true); _clear_options(); view.panel.show(); view.next_button.hide(); options_box.show()
		view.speaker.text = "Vizinha da cozinha"; view.body.text = "São os sacos do abrigo? Confere onde os pousas antes de me passares a entrega."
		_option("Farinha seca, separada do peixe · entregar à cozinha",_deliver.bind(true))
		_option("Pousar tudo na banca do peixe",_deliver.bind(false))
		options_box.get_child(0).grab_focus(); return
	if task_id=="meal" and task_step==0:
		task_step = 1; props.carrying = true; actors["Ajudante da cozinha"].carries_bowl = false
		props.marker = _point("object")+Vector2(-50,20); props.marker_label = "E / A · servir a refeição"
		view.status.text = "Leonor espera no refeitório, a poente da cozinha. Leva as porções pelo corredor e aproxima-te da mesa."
		return
	if task_id=="lever":
		busy = true
		if task_step==0:
			task_step = 1; await staging.support_cargo(); busy = false
			props.marker = actors.Duarte.position+Vector2(-40,25)
			props.marker_label = "E / A · levantar com Duarte"
			view.status.text = "Apoio firme. Duarte segura a madeira; aproxima-te dele e confirma a elevação conjunta."
			return
		await staging.lift_cargo(); busy = false
	if task_id == "recovery_walk" and world.player.position.distance_to(task_start) < 35: return
	if task_id == "clear_passage" and task_step == 0:
		task_step = 1; props.carrying = true; props.marker = _point("destination")
		props.marker_label = "E · pousar no lado seco"; view.status.text = "Leva o caixote para o lado seco."; return
	if task_id=="recovery_walk" and task_step==0:
		task_step = 1; props.marker = Vector2(-30,330)
		props.marker_label = "E / A · regressar ao apoio"
		view.status.text = "Chegaste à mesa. Volta devagar até Tomé; o treino pode esperar."
		return
	if task_id=="blue_rope" and task_step==0:
		task_step = 1; props.marker = actors.Duarte.position+Vector2(35,-20)
		props.marker_label = "E / A · entregar a ponta azul"
		view.status.text = "Leva a ponta azul ao Duarte. Beatriz trata da branca."
		world.get_node("ConvesDaBotafogo").rope_owner = world.player
		staging.sound("creak",-26,1.1,true)
		return
	if task_id=="blue_rope":
		world.get_node("ConvesDaBotafogo").rope_owner = null
		world.get_node("ConvesDaBotafogo").rope_secured = true
	var already_done: bool = ChapterProgress.flags.get(task_id,false)
	ChapterProgress.flags[task_id] = true
	if task_id == "meal":
		props.carrying = false; props.meal_ready = true
		busy = true; _lock_player(true); await staging.sit_refectory(); busy = false
		_seat_at_meal()
	if task_id == "lever": ChapterProgress.flags.cargo_freed = true; props.cargo_freed = true
	if task_id == "clear_passage": props.object_position = _point("destination"); props.carrying = false
	if task_id == "clear_passage":
		service_paid_now = not ChapterProgress.payments.has("cais_service")
		Items.pay_service(ChapterProgress)
		if ChapterProgress.auto_save: ChapterProgress.save_to()
	if task_id == "pack":
		world.player.presentation.carries_bowl = false
		if not already_done:
			for item in ["PT-Q02","PT-C02","PT-C03"]: ChapterProgress.inventory[item] = int(ChapterProgress.inventory.get(item,0))+1
	if task_id == "fetch_tome": _load_map(blocks[scene_index].map)
	props.marker_active = false; _lock_player(true); phase = "dialogue"; view.panel.show(); advance()

func _deliver(clean: bool) -> void:
	if paused or phase!="delivery_choice" or world.player.position.distance_to(props.marker)>92: return
	if not clean:
		view.body.text = "O pano da banca está molhado. Tomé pediu farinha separada do peixe; entrega os sacos secos diretamente à cozinha."
		return
	ChapterProgress.flags.delivery_finished = true; ChapterProgress.flags.delivery_pending = false
	props.delivery_active = false; props.carrying = false; props.marker_active = false
	_clear_options(); phase = "dialogue"; advance()

func _begin_battle(mode: String) -> void:
	phase = "battle"; _lock_player(true); view.hide(); _clear_options(); battle_container.show()
	battle_host.select_battle_map("courtyard" if order_practice_return else map_kind)
	battle_host.allow_practice_exit = mode!="duel"
	battle_host.begin_encounter(mode,CampaignProfile.hero_name,ChapterProgress.style)
	if mode=="duel":battle_host.note="Avaliação reservada · Controlas "+CampaignProfile.hero_name+". Leonor quer ver o que sabes agora."

func _practice_aborted() -> void:
	if order_trial_return:return_from_order_trial(false);return
	if order_practice_return: return_from_order_practice(); return
	battle_container.hide(); view.show(); phase = "dialogue"
	if battle_host.combat.mode in ["style_test","school","practice"]:
		if practice_resume_index>=0:
			event_index = practice_resume_index; events = practice_events.duplicate(true)
		_show_styles(style_options)
		view.status.text = "Treino interrompido. Escolhe outro manejo; uma aula incompleta não concede aprendizado."
	else:
		_clear_options(); options_box.show(); view.panel.show(); view.next_button.hide()
		phase = "practice_retry"
		view.speaker.text = "Treino em pausa"; view.body.text = "Podes rever o equipamento e tentar novamente quando estiveres pronto."
		_option("Repetir exercício",func(): _begin_battle(current_event.mode))
		_option("Consultar equipamento e passivas",func(): _menu("Equipamento"))
		options_box.get_child(0).grab_focus()

func _battle_finished(success: bool) -> void:
	if order_trial_return:return_from_order_trial(success);return
	battle_container.hide(); view.show(); phase = "dialogue"
	var mode: String = battle_host.combat.mode
	if order_practice_return and mode=="practice": return_from_order_practice(); return
	if mode == "duel":
		ChapterProgress.flags.injured = true; ChapterProgress.flags.duel_lost = true
		for key in ["hp","qi","posture"]: ChapterProgress.vitals[key] = int(battle_host.combat.units[0][key])
		continue_after_duel = true
	elif mode == "perfect_defense" and success:
		ChapterProgress.flags.perfect_defense = true; ChapterProgress.learn("DP01")
	elif mode == "school" and success:
		ChapterProgress.learn(battle_host.combat.FIRST[ChapterProgress.style])
		RULES.Development.training(ChapterProgress,ChapterProgress.style)
		if ChapterProgress.style=="FO":
			for id in RULES.Firearm.LEARNED: ChapterProgress.learn(id)
		ChapterProgress.learn("GE21","passive"); ChapterProgress.learn("GE22","passive")
		ChapterProgress.learn(ChapterProgress.style+"-P11","passive")
	elif mode == "duarte_support" and success:
		ChapterProgress.learn("DU01"); ChapterProgress.learn("DU02"); ChapterProgress.learn("DU-P09","passive")
	if mode == "style_test":
		if not ChapterProgress.tested_styles.has(ChapterProgress.style): ChapterProgress.tested_styles.append(ChapterProgress.style)
		current_event = {"type":"battle","mode":"school"}; _begin_battle("school"); return
	if mode == "school": _style_result(); return
	if not success and current_event.has("on_failure"):
		var retry := current_event.duplicate(true)
		var extra: Array = current_event.on_failure.duplicate(true); extra.append(retry)
		_insert(extra)
	advance()

func _show_styles(options: Array) -> void:
	if scene_index>0 and ChapterProgress.flags.get("order_prepared",false):
		phase = "styles_result"; _clear_options(); options_box.show(); view.panel.show(); view.next_button.hide()
		view.speaker.text = "Tomé · Retomar o manejo"; view.body.text = "A arma e o fundamento escolhidos no primeiro serviço continuam teus. Revê o repertório e retoma a prática depois da recuperação."
		_option("Continuar com "+Items.STYLES[ChapterProgress.style],func(): phase="dialogue"; advance())
		_option("Rever técnicas e equipamento",func(): _menu("Evolução"))
		options_box.get_child(0).grab_focus(); return
	phase = "styles"; style_options = options; _clear_options(); options_box.show(); _lock_player(true)
	view.panel.show(); view.next_button.hide(); view.speaker.text = "Tomé"
	view.body.text = "Escolhe a arma que queres aprender a usar. Depois da aula, confirma a escolha para equipar a tua arma e continuar. A primeira é oferecida por Tomé. Podes experimentar outras antes de decidir. Os treinos usam armas emprestadas e não gastam os teus suprimentos. R / Select volta à escolha."
	for option in options: _option("Treinar "+option.label+ (" · já experimentado" if ChapterProgress.tested_styles.has(option.style) else ""),choose_style.bind(option.style))
	_option("Comparar armas em prática livre",_free_practice_menu)
	if ChapterProgress.tested_styles.has(ChapterProgress.style) and ChapterProgress.skills.has(RULES.FIRST[ChapterProgress.style]): _option("Continuar com "+RULES.STYLES[ChapterProgress.style].name,confirm_style)
	# Returning from a completed lesson should offer onward progress first.
	options_box.get_child(options_box.get_child_count()-1 if ChapterProgress.tested_styles.has(ChapterProgress.style) and ChapterProgress.skills.has(RULES.FIRST[ChapterProgress.style]) else 0).grab_focus()
	if not is_instance_valid(lesson_choice):
		lesson_choice=preload("res://scripts/chapter/weapon_lesson_choice.gd").new();add_child(lesson_choice)
		lesson_choice.chosen.connect(_choose_lesson_weapon)
		lesson_choice.practice_requested.connect(_free_practice_menu)
	view.panel.hide();lesson_choice.open(options)


func _choose_lesson_weapon(style: String) -> void:
	if paused or phase!="styles":return
	if not style_options.any(func(option):return option.style==style):return
	var item:String=preload("res://scripts/chapter/weapon_lesson_choice.gd").FIRST[style]
	if ChapterProgress.flags.get("initial_weapon_received",false) and style!="PU" and int(ChapterProgress.inventory.get(item,0))<1:
		lesson_choice.preview.text="A primeira arma já foi recebida. Compra esta em Lisboa ou escolhe uma que já tens."
		return
	ChapterProgress.style=style
	# Tomé gives the selected foundation directly; comparison fights are optional.
	if not ChapterProgress.tested_styles.has(style):ChapterProgress.tested_styles.append(style)
	ChapterProgress.learn(RULES.FIRST[style])
	RULES.Development.training(ChapterProgress,style)
	if style=="FO":
		for id in RULES.Firearm.LEARNED: ChapterProgress.learn(id)
	for id in ["GE21","GE22",style+"-P11"]:ChapterProgress.learn(id,"passive")
	confirm_style()

func choose_style(style: String) -> void:
	if paused or phase != "styles": return
	for option in style_options:
		if option.style == style:
			practice_resume_index = event_index; practice_events = events.duplicate(true)
			ChapterProgress.style = style; pending_style = style
			_insert(option.events+[{"type":"battle","mode":"style_test"}]); _clear_options(); phase = "dialogue"; advance(); return

func _style_result() -> void:
	phase = "styles_result"; _clear_options(); options_box.show(); view.panel.show(); view.next_button.hide()
	view.speaker.text = "Fundamento · "+RULES.STYLES[ChapterProgress.style].name
	view.body.text = "Aprendeste a usar "+Items.STYLES[ChapterProgress.style]+". Confirma abaixo para ficar com esta escolha e continuar. Também podes experimentar outra arma. As passivas são uma preparação opcional."
	view.status.text = "Ativas: %d/4 tuas · %d/4 de Duarte"%[ChapterProgress.equipped_passives.size(),ChapterProgress.duarte_equipped_passives.size()]
	_option("Ficar com "+Items.STYLES[ChapterProgress.style]+(" · receber arma e continuar" if not ChapterProgress.flags.get("initial_weapon_received",false) else " · equipar e continuar"),confirm_style)
	_option("Preparar passivas · escolher as ativas",func(): _menu("Passivas"))
	_option("Experimentar outro manejo",func():
		if not paused: _show_styles(style_options))
	_option("Prática livre · fundamento e dois exercícios",_free_practice_menu)
	options_box.get_child(0).grab_focus()

func _free_practice_menu() -> void:
	if paused: return
	if is_instance_valid(lesson_choice):lesson_choice.close()
	view.panel.show()
	_clear_options(); options_box.show(); phase = "styles"
	view.body.text = "Prática livre com armas emprestadas: ataque básico, um fundamento e dois exercícios temporários. Não concede aprendizado, itens ou aprovação. R / Select regressa à escolha de armas."
	for style in RULES.STYLES:
		_option(RULES.STYLES[style].name+" · "+RULES.PRACTICE_TIPS[style],func():
			ChapterProgress.style = style
			practice_resume_index = event_index; practice_events = events.duplicate(true)
			_begin_battle("practice"))
	_option("Voltar às aulas de Tomé",func(): _show_styles(style_options))
	options_box.get_child(0).grab_focus()

func confirm_style() -> void:
	if paused or phase not in ["styles","styles_result"]: return
	if not ChapterProgress.skills.has(RULES.FIRST[ChapterProgress.style]) and not (ChapterProgress.style=="PU" and ChapterProgress.flags.get("initial_weapon_received",false)):
		view.status.text = "Conclui a aula deste manejo para aprender o fundamento antes da escolha inicial. A prática livre não concede aprendizado."
		return
	var item: String = {"ES":"PT-W01","LA":"PT-W02","MC":"PT-W03","FO":"PT-W04","PU":"PT-W05"}[ChapterProgress.style]
	if not ChapterProgress.flags.get("initial_weapon_received",false):
		ChapterProgress.inventory[item] = int(ChapterProgress.inventory.get(item,0))+1
		ChapterProgress.flags.initial_weapon_received = true
	elif int(ChapterProgress.inventory.get(item,0)) < 1 and ChapterProgress.style != "PU":
		view.status.text = "Este manejo precisa da tua própria arma. Compra-a em Lisboa ou escolhe desarmado."; return
	if int(ChapterProgress.inventory.get(item,0)) > 0: ChapterProgress.equipment.weapon = item
	else: ChapterProgress.equipment.erase("weapon")
	Items.clamp_vitals(ChapterProgress)
	phase = "dialogue"; _clear_options()
	advance()

func restart_block() -> void:
	if busy or phase == "battle": return
	get_tree().paused = false; paused = false; menu_open = false
	if player_menu != null: player_menu.close()
	if scene_index==0: ChapterProgress.flags.order_intro_started = true
	_load_block(scene_index)

func _stage(action: String) -> void:
	match action:
		"rescue_arrival": await staging.rescue_arrival()
		"leave_refectory": await staging.stand_refectory()
		"delivery_return":
			routes.waiting_stage = true; routes.begin("stage",scene_index,"delivery_return")
			await routes.stage_arrived; routes.waiting_stage = false
		"child_arrives": actors["Criança"].show()
		"green_sight":
			ChapterProgress.flags.green_sight = true
			await staging.perceive_injury()
		"treatment":
			props.green_sight = false; actors["Trabalhador ferido"].injured = true
			await staging.ordinary_treatment(); ChapterProgress.flags.patient_stable = true
		"leonor_arrives": actors["Leonor"].show(); world.player.presentation.eye_glow = false
		"patient_departure":
			await staging.leave_with_family(); ChapterProgress.flags.patient_helped = true
		"clean_cloth":
			ChapterProgress.flags.clean_cloth = true
			await staging.clean_cloth()
		"morning": view.caption_label.text = "Portugal · Manhã seguinte · Demonstração pública\n"+blocks[scene_index].title
		"afternoon": view.caption_label.text = "Portugal · Fim da tarde · Avaliação reservada\n"+blocks[scene_index].title
		"sit_bench":
			_lock_player(true); view.panel.hide()
			var origin: Vector2 = world.player.position
			world.player.presentation.walking = true; world.player.presentation.facing = 2
			var sitting := create_tween()
			sitting.tween_method(func(weight: float):
				world.player.position = origin.lerp(Vector2(23,367),weight)
				world.player.presentation.frame_time = weight*5,0.0,1.0,maxf(0.3,origin.distance_to(Vector2(23,367))/70))
			await sitting.finished; world.player.presentation.walking = false
			world.player.presentation.posture = "seated"; world.player.presentation.facing = 3
		"two_cups","cup_in_reach": await staging.cups_on_bench(action=="cup_in_reach")
		"master_demonstration":
			await staging.master_demonstration()
		"leonor_demonstration":
			await staging.leonor_demonstration()
			ChapterProgress.flags.city_leonor_demonstrated = true
		"fallen","cannot_stand": world.player.presentation.posture = "fallen"
		"leonor_leaves":
			await _move_actor("Leonor",Vector2(330,270),1.2); actors["Leonor"].hide(); ChapterProgress.flags.leonor_departed = true
		"silence": view.panel.hide(); await get_tree().create_timer(1.0,false).timeout; view.panel.show()
		"duarte_arrives":
			actors["Duarte"].show()
			await _move_actor("Duarte",world.player.position+Vector2(-35,5),0.6)
			actors["Duarte"].posture = "crouched"
		"tome_assistance":
			_add_actor("Tomé",Vector2(-230,390))
			await _move_actor("Tomé",world.player.position+Vector2(-25,25),0.8)
			await staging.assisted_return()
			ChapterProgress.flags.assisted_return = true
		"treated_in_bed": ChapterProgress.flags.treated = true
		"water_drunk": await staging.water_drunk()
		"time_passes": await staging.recovery_time()
		"recovered":
			ChapterProgress.flags.injured = false; ChapterProgress.flags.recovered = true
			var limits: Dictionary = preload("res://scripts/chapter/player_items.gd").stats(ChapterProgress)
			ChapterProgress.vitals = {"hp":limits.hp,"qi":mini(8,int(limits.qi)),"posture":limits.posture}
		"return_courtyard":
			routes.waiting_stage = true; routes.begin("stage",scene_index,"return_courtyard")
			await routes.stage_arrived; routes.waiting_stage = false
		"give_bowl": actors["Tomé"].carries_bowl = true
		"packed": ChapterProgress.flags.packed = true; props.packed = true
		"ship_departs":
			ChapterProgress.flags.embarked = true; view.panel.hide(); view.status.text = "A Botafogo parte."
			view.hint.text = "Esc / Start · pausar"
			var camera := Camera2D.new(); camera.name = "DepartureCamera"
			var previous: Camera2D = get_viewport().get_camera_2d()
			camera.position = previous.global_position; camera.zoom = previous.zoom; camera.offset = previous.offset
			staging.camera.enabled = false; world.player.camera.enabled = false
			add_child(camera); camera.make_current()
			staging.mark("departure_cast_off"); staging.sound("creak",-22,1.0,true)
			var tween = world.create_tween().set_parallel(true)
			tween.tween_property(world,"position",Vector2(145,85),3.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			tween.tween_property(world.get_node("ConvesDaBotafogo"),"departure_progress",1.0,3.5)
			staging.sound("sail_flap",-25,0.9,true)
			await tween.finished; staging.mark("departure_underway"); view.panel.show()

func _move_actor(name: String, destination: Vector2, seconds: float) -> void:
	actors[name].facing = 3 if destination.x > actors[name].position.x else 1
	var tween = world.create_tween(); tween.tween_property(actors[name],"position",destination,seconds); await tween.finished

func _process(_delta: float) -> void:
	if routes!=null and routes.active: routes.update(_delta)
	elif harbor != null: harbor.update()
	if is_instance_valid(world):
		for name in actors:
			var label: Label = actors[name].get_node_or_null("NameLabel")
			if label==null: continue
			label.visible = phase == "dialogue" and not busy and current_event.get("speaker","") == name
	if phase == "task" and not paused and props != null:
		props.queue_redraw()

func _menu(initial: String = "Personagem") -> void:
	if phase == "battle": return
	if menu_open:
		player_menu.close(); menu_open = false; paused = false; get_tree().paused = false
		view.show()
		if phase == "styles": _show_styles(style_options)
		elif phase == "styles_result": _style_result()
		elif phase=="roaming": routes.resume()
		if is_instance_valid(menu_focus) and menu_focus.is_visible_in_tree(): menu_focus.grab_focus()
		return
	menu_focus = get_viewport().gui_get_focus_owner()
	if routes.active: routes.save()
	view.hide()
	menu_open = true; paused = true; get_tree().paused = true
	player_menu.open(initial)
func load_checkpoint() -> void:
	if busy: return
	var error := ChapterProgress.load_from()
	if error != OK:
		player_menu.notice.text = "Não foi possível carregar este capítulo."; return
	get_tree().paused = false; paused = false; menu_open = false
	player_menu.close()
	_load_block(ChapterProgress.checkpoint,false,true)

func _input(event: InputEvent) -> void:
	# Task input belongs to the world, before the completed combat viewport can
	# consume ui_accept (E/A is also registered as dialogue confirmation).
	if paused or phase not in ["task","exploration","roaming"]: return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		if battle_host.ending.running(): return
		if phase == "task": interact_task()
		elif phase=="roaming": routes.interact()
		else: harbor.interact()

func _unhandled_input(event: InputEvent) -> void:
	if view == null or phase == "battle": return
	if phase == "local_dialogue" and not paused and not busy and (event.is_action_pressed("ui_cancel") or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B)):
		get_viewport().set_input_as_handled(); harbor.city.close(); return
	if phase == "boarding" and not paused and (event.is_action_pressed("ui_cancel") or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B)):
		get_viewport().set_input_as_handled(); harbor.resume(); return
	if phase in ["rest_confirm","shore_return"] and not paused and (event.is_action_pressed("ui_cancel") or (event is InputEventJoypadButton and event.pressed and event.button_index==JOY_BUTTON_B)):
		get_viewport().set_input_as_handled(); routes.resume(); return
	if event.is_action_pressed("ui_cancel") or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START): get_viewport().set_input_as_handled(); _menu(); return
	if paused: return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_I,KEY_C,KEY_K,KEY_P]:
		get_viewport().set_input_as_handled()
		_menu({KEY_I:"Inventário",KEY_C:"Personagem",KEY_K:"Técnicas",KEY_P:"Passivas"}[event.physical_keycode]); return
	if event.is_action_pressed("journal"):
		get_viewport().set_input_as_handled(); _menu("Pedidos"); return
	if event.is_action_pressed("quick_save"):
		if routes.active: routes.save()
		view.status.text = "Capítulo guardado." if ChapterProgress.save_to() == OK else ChapterProgress.last_error
		get_viewport().set_input_as_handled(); return
	if phase=="roaming":
		if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
			get_viewport().set_input_as_handled()
			routes.click(world.get_global_transform_with_canvas().affine_inverse()*event.position)
	elif phase == "exploration":
		if event.is_action_pressed("interact"):
			get_viewport().set_input_as_handled(); harbor.interact()
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			get_viewport().set_input_as_handled()
			world.walk_to(world.get_global_transform_with_canvas().affine_inverse()*event.position)
	elif phase == "task":
		if event.is_action_pressed("interact"): interact_task(); get_viewport().set_input_as_handled()
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			get_viewport().set_input_as_handled()
			world.walk_to(world.get_global_transform_with_canvas().affine_inverse()*event.position)
	elif event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled(); advance()


func _show_equipment() -> void:
	if paused or phase == "battle": return
	_lock_player(true)
	phase = "equipment"; _clear_options(); options_box.show(); view.panel.show(); view.next_button.hide()
	view.speaker.text = "Passivas · %s %d/4 · Duarte %d/4" % [CampaignProfile.hero_name,ChapterProgress.equipped_passives.size(),ChapterProgress.duarte_equipped_passives.size()]
	view.body.text = "Escolhe até quatro passivas aprendidas. Equipar não recupera vida nem energia."
	var catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_01/passives.json"))
	for row in catalog.passives:
		if ChapterProgress.passives.has(row.id):
			var equipped = ChapterProgress.equipped_passives if row.owner == "hero" else ChapterProgress.duarte_equipped_passives
			_option(("✓ " if equipped.has(row.id) else "○ ")+row.name+(" · Duarte" if row.owner == "duarte" else ""),toggle_passive.bind(row.id))
	_option("Voltar",_leave_equipment)
	options_box.get_child(0).grab_focus()

func toggle_passive(id: String) -> void:
	if paused or phase != "equipment" or not ChapterProgress.passives.has(id): return
	var equipped = ChapterProgress.duarte_equipped_passives if id.begins_with("DU") else ChapterProgress.equipped_passives
	if equipped.has(id): equipped.erase(id)
	elif equipped.size() < 4: equipped.append(id)
	_show_equipment()




func _equipment_from_menu() -> void:
	if busy: return
	equipment_return_phase = phase
	_menu()
	_show_equipment()

func _leave_equipment() -> void:
	if paused: return
	if equipment_return_phase == "styles_result": _style_result(); return
	phase = equipment_return_phase; _clear_options()
	view.speaker.text = menu_snapshot.get("speaker",view.speaker.text)
	view.body.text = menu_snapshot.get("body",view.body.text)
	view.next_button.visible = phase in ["dialogue","block_end"]
	if phase == "task": view.panel.hide(); _lock_player(false)





func _show_development_notice(message: String) -> void:
	var old := get_node_or_null("DevelopmentNotice")
	if old!=null: remove_child(old); old.queue_free()
	var layer := CanvasLayer.new(); layer.name = "DevelopmentNotice"; layer.layer = 24; add_child(layer)
	var anchor := Control.new(); anchor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE; layer.add_child(anchor)
	var panel := PanelContainer.new(); panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	panel.offset_left = -220; panel.offset_right = 220; panel.offset_top = 74; panel.offset_bottom = 128; panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel",preload("res://scripts/ui/presentation.gd").panel(Color("173630"),Color("b39b65"))); anchor.add_child(panel)
	var label := Label.new(); label.text = message; label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color",Color("e6cb8d")); label.add_theme_font_size_override("font_size",GamePreferences.font_size(18)); panel.add_child(label)
	await get_tree().create_timer(3.5,false).timeout
	if is_instance_valid(layer): layer.queue_free()

func begin_order_practice() -> void:
	if paused or phase!="order_inspection" or not routes.active or routes.area()!="convent":return
	if not routes.near(Vector2(-850,920)):return
	if ChapterProgress.flags.get("injured",false) or not ChapterProgress.skills.has(RULES.FIRST[ChapterProgress.style]):
		view.status.text="A prática espera pelo tratamento e pelo fundamento de Tomé.";return
	if ChapterProgress.choices.get("tracked_request","")=="ORDER-PRACTICE":ChapterProgress.choices.erase("tracked_request")
	order_practice_return=true
	_begin_battle("practice")
func return_from_order_practice() -> void:
	order_practice_return=false
	battle_host.active=false;battle_host.ending.reset(battle_host);battle_container.hide()
	view.show();routes.resume()
	view.status.text="Prática concluída ou interrompida. O serviço e os recursos pessoais foram preservados."

func begin_order_trial() -> void:
	if paused or phase!="order_inspection" or not routes.active or routes.area()!="convent" or not routes.near(Vector2(-850,920)):return
	if ChapterProgress.flags.get("injured",false) or not ChapterProgress.flags.get("order_audience_done",false) or not ChapterProgress.skills.has(RULES.FIRST[ChapterProgress.style]):
		view.status.text="A avaliação exige recuperação, fundamento de Tomé e autorização da liderança.";return
	order_practice_return=true;_begin_battle("practice");order_practice_return=false;order_trial_return=true
	var c=battle_host.combat;c.mode="order_trial";c.lesson=1;c.caption="A medida do serviço"
	for cell in [Vector2i(4,3),Vector2i(4,4),Vector2i(4,5),Vector2i(4,6)]:c.obstacles.erase(cell)
	c.units[0].cell=Vector2i(4,3);c.units[0].turn_origin=c.units[0].cell;c.units[0].qi=40;c.units[0].max_qi=40;c.units[0].speed=50
	c.units[2].cell=Vector2i(4,6);c.units[2].kind="tome";c.units[2].name="Instrutor da Ordem";c.units[2].speed=10
	for i in range(3,c.units.size()):c.units[i].hp=0;c.units[i].withdrawn=true
	c.order_index=-1;c.rebuild_order();c.next_turn();battle_host.tactical.begin()
	battle_host.note="Alcança a casa dourada (4,4), acerta um golpe e responde de frente com Bom ou Perfeito. R / Select sai sem perder recursos."
func return_from_order_trial(success: bool) -> void:
	var outcome: Dictionary=battle_host.combat.lesson_result()
	var complete: bool=success and outcome.get("finished",false) and outcome.get("success",false)
	order_trial_return=false
	if complete:preload("res://scripts/chapter/order_campaign.gd").finish_trial(ChapterProgress)
	return_from_order_practice();routes.save()
	view.status.text="Avaliação confirmada: um vale de estudo e 25 XP na primeira conclusão. Leva os manuais ao instrutor para aprender." if complete else "Avaliação interrompida. Podes voltar à armaria e tentar sem taxa ou perda de recursos pessoais."
