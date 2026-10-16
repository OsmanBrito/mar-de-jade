extends Node2D
signal block_finished(scene_id: String)
const WORLD = preload("res://scripts/chapter/plaza_world.gd")
const PLAYER = preload("res://scenes/chapter_01/child_player.tscn")
const ACTOR = preload("res://scripts/chapter/actor_proxy.gd")
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

func _ready() -> void:
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
	_load_block(scene_index)

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
	get_viewport().size_changed.connect(_resize_battle)
	_resize_battle(); battle_container.hide()

func _resize_battle() -> void:
	preload("res://scripts/combat/battle_stage.gd").fit(battle_container,get_viewport_rect().size)

func _load_block(index: int) -> void:
	scene_index = index; ChapterProgress.checkpoint = index
	ChapterProgress.entry_scene = "res://scenes/chapter_01/chapter_flow.tscn"
	events = blocks[index].events.duplicate(true); event_index = -1; current_event = {}
	phase = "dialogue"; busy = false; completed = false; task_id = ""
	service_paid_now = false
	_clear_options(); view.show(); view.next_button.show(); view.next_button.disabled = false
	view.replay_button.hide(); view.next_button.text = "Continuar"
	view.caption_label.text = "Portugal · Presente\n"+blocks[index].title
	_load_map(blocks[index].map)
	scene_snapshot = ChapterProgress.snapshot()
	if ChapterProgress.auto_save: ChapterProgress.save_to()
	if index == 15 and ChapterProgress.flags.get("harbor_pause",false) and harbor.can_begin():
		harbor.begin(); return
	advance()

func _point(key: String) -> Vector2:
	var coordinates: Array = layout[map_kind].get(key,layout[map_kind].object)
	return Vector2(float(coordinates[0]),float(coordinates[1]))

func _load_map(kind: String) -> void:
	if has_node("DepartureCamera"): get_node("DepartureCamera").free()
	if world != null:
		remove_child(world); world.queue_free()
	map_kind = kind; actors.clear()
	var map_path := "res://scenes/maps/praca_infancia.tscn"
	if kind in ["cais","service"]: map_path = "res://scenes/maps/cais_vivo.tscn"
	elif kind == "room": map_path = "res://scenes/maps/abrigo_infancia.tscn"
	world = load(map_path).instantiate()
	world.set_script(WORLD)
	world.map_id = "abrigo_adulto" if kind == "room" else ("cais" if kind in ["cais","service"] else "praca_infancia")
	world.player_scene = PLAYER
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	var sorted = world.get_node("ActorsAndProps")
	for object in sorted.get_children():
		if object.name in [&"Leonor",&"Child",&"Tome",&"Acompanhante"] or object.get_script() == preload("res://scripts/interaction.gd") or kind == "deck":
			object.free()
	if not world.has_node("Spawn"):
		var spawn := Marker2D.new(); spawn.name = "Spawn"; world.add_child(spawn)
	world.get_node("Spawn").position = _point("hero")
	if kind == "deck":
		var ground = world.get_node("Ground")
		for cell in ground.get_used_cells(): ground.set_cell(cell,0,Vector2i(1,1))
	add_child(world)
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
	props.cargo_freed = ChapterProgress.flags.get("cargo_freed",false); props.packed = ChapterProgress.flags.get("packed",false)
	props.meal_ready = ChapterProgress.flags.get("meal",false)
	sorted.add_child(props)
	_configure_actors()
	if kind in ["cais","service"]:
		preload("res://scripts/chapter/portugal_quay_art.gd").apply(world)
	harbor.install(world)
	world.rebuild_navigation()

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

func _configure_actors() -> void:
	var id: String = blocks[scene_index].id
	if map_kind == "courtyard":
		actors.get("Tomé").visible = id.begins_with("C01-M04")
		actors.get("Criança").hide(); actors.get("Trabalhador").hide()
	elif map_kind == "cais":
		if actors.has("Familiar"): actors["Familiar"].visible = id=="C01-M02/S03"
		actors["Leonor"].visible = id != "C01-M02/S01" and id != "C01-M02/S02"
		actors["Tomé"].visible = id != "C01-M02/S01"
		actors["Trabalhador ferido"].posture = "seated"
		world.player.presentation.eye_glow = ChapterProgress.flags.get("green_sight",false) and id == "C01-M02/S02"
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
		actors["Leonor"].posture = "seated"; world.player.presentation.posture = "seated"
	elif map_kind == "room" and ChapterProgress.flags.get("injured",false):
		world.player.position = Vector2(-70,248); world.player.presentation.posture = "seated"
		world.player.presentation.injured = true
		props.bedside = true
		props.bedside_point = world.player.position+Vector2(30,5)
		actors["Duarte"].visible = id != "C01-M03/S07"
		actors["Tomé"].posture = "seated"
	for actor in actors.values():
		actor.get_child(1).process_mode = Node.PROCESS_MODE_PAUSABLE
		if not actor.visible: actor.get_child(1).get_child(0).set_deferred("disabled",true)

func _lock_player(lock: bool) -> void:
	world.player.enabled = not lock; world.player.set_physics_process(not lock)
	world.player.velocity = Vector2.ZERO; world.player.destination_path.clear(); world.player.presentation.walking = false
	world.player.camera.offset = Vector2(120,65) if lock and map_kind in ["cais","service","deck"] else Vector2(0,-100)

func _clear_options() -> void:
	for child in options_box.get_children():
		options_box.remove_child(child)
		child.queue_free()
	options_box.hide()
	view.panel.offset_top = -295; view.panel.offset_bottom = -55

func _option(label: String, callback: Callable) -> void:
	var button := Button.new(); button.text = label; button.custom_minimum_size.y = 36
	button.pressed.connect(callback); options_box.add_child(button)

func advance() -> void:
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
			view.hint.text = "Enter / espaço / A · continuar     Esc · menu     F5 · guardar"
			view.next_button.grab_focus()
		"choice": _show_choice(current_event)
		"stage":
			busy = true; view.next_button.disabled = true
			await _stage(current_event.action)
			busy = false; view.next_button.disabled = false; advance()
		"task": _begin_task(current_event)
		"battle": _begin_battle(current_event.mode)
		"styles": _show_styles(current_event.options)

func _finish_block() -> void:
	# Keep the approved defeat and its first dialogue together, under the curtain.
	if continue_after_duel and scene_index+1<blocks.size():
		continue_after_duel = false
		block_finished.emit(blocks[scene_index].id)
		_load_block(scene_index+1)
		return
	phase = "block_end"; _lock_player(true); _clear_options(); view.show(); view.panel.show()
	view.speaker.text = blocks[scene_index].title; view.status.text = "Etapa concluída"
	if service_paid_now: view.status.text += " · Serviço no cais: +40 reais"
	view.body.text = "Continuar."; view.next_button.show(); view.next_button.text = "Continuar"
	view.next_button.grab_focus()
	block_finished.emit(blocks[scene_index].id)
	if scene_index == 15 and harbor.can_begin():
		harbor.begin(); return
	if scene_index == blocks.size()-1:
		completed = true; ChapterProgress.completed = true
		view.speaker.text = "Capítulo 1 · A promessa impossível"
		view.body.text = "A Botafogo parte. Portugal fica para trás. A viagem começa como aprendiz."
		view.status.text = "Capítulo 1 concluído"; view.next_button.hide(); view.replay_button.show()
		options_box.show()
		_option("Navegar para a Madeira",func(): preload("res://scripts/navigation/voyage_launch.gd").start(get_tree(),true))
		view.replay_button.grab_focus()
		if ChapterProgress.auto_save: ChapterProgress.save_to()

func _show_choice(event: Dictionary) -> void:
	phase = "choice"; choice_event = event; _lock_player(true); _clear_options()
	view.speaker.text = CampaignProfile.hero_name; view.body.text = "Escolhe a tua resposta."
	view.next_button.hide(); options_box.show()
	for option in event.options: _option(option.label,choose.bind(option.id))
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
	if event.has("map"): _load_map(event.map)
	task_id = event.id; task_step = 0; phase = "task"
	view.panel.hide(); _clear_options(); _lock_player(false)
	world.player.presentation.posture = "standing"; world.player.presentation.position = Vector2.ZERO
	if task_id == "recovery_walk":
		world.player.position = Vector2(110,365); props.marker = _point("destination")
	else: props.marker = _point("object")
	props.marker_active = true; props.marker_label = "E · "+{"lever":"alavanca","fetch_tome":"Tomé","clear_passage":"caixote","meal":"refeição","pack":"sacola","blue_rope":"amarra azul","knot":"último nó","recovery_walk":"caminhar"}.get(task_id,"interagir")
	if task_id == "fetch_tome": props.marker = actors["Tomé"].position+Vector2(-35,25)
	if task_id == "clear_passage": props.crate_task = true
	if task_id == "meal": props.carrying = true
	if task_id == "pack":
		actors["Tomé"].carries_bowl = false
		world.player.presentation.carries_bowl = true
	task_start = world.player.position
	view.status.text = event.caption; view.hint.text = "WASD / setas / clique · mover     E / A · interagir     Esc · menu"
	var focus = get_viewport().gui_get_focus_owner()
	if focus != null: focus.release_focus()
	world.rebuild_navigation()

func interact_task() -> void:
	if paused or phase != "task" or world.player.position.distance_to(props.marker) > 72: return
	if task_id == "recovery_walk" and world.player.position.distance_to(task_start) < 35: return
	if task_id == "clear_passage" and task_step == 0:
		task_step = 1; props.carrying = true; props.marker = _point("destination")
		props.marker_label = "E · pousar no lado seco"; view.status.text = "Leva o caixote para o lado seco."; return
	var already_done: bool = ChapterProgress.flags.get(task_id,false)
	ChapterProgress.flags[task_id] = true
	if task_id == "meal": props.carrying = false; props.meal_ready = true
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

func _begin_battle(mode: String) -> void:
	phase = "battle"; _lock_player(true); view.hide(); _clear_options(); battle_container.show()
	battle_host.begin_encounter(mode,CampaignProfile.hero_name,ChapterProgress.style)

func _battle_finished(success: bool) -> void:
	if ChapterProgress.flags.get("recovered",false) and battle_host.combat.mode in ["school","perfect_defense","duarte_support"]:
		for key in ["hp","qi","posture"]: ChapterProgress.vitals[key] = int(battle_host.combat.units[0][key])
	battle_container.hide(); view.show(); phase = "dialogue"
	var mode: String = battle_host.combat.mode
	if mode == "duel":
		ChapterProgress.flags.injured = true; ChapterProgress.flags.duel_lost = true
		for key in ["hp","qi","posture"]: ChapterProgress.vitals[key] = int(battle_host.combat.units[0][key])
		continue_after_duel = true
	elif mode == "perfect_defense" and success:
		ChapterProgress.flags.perfect_defense = true; ChapterProgress.learn("DP01")
	elif mode == "school" and success:
		ChapterProgress.learn(battle_host.combat.FIRST[ChapterProgress.style])
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
	phase = "styles"; style_options = options; _clear_options(); options_box.show(); _lock_player(true)
	view.panel.show(); view.next_button.hide(); view.speaker.text = "Tomé"
	view.body.text = "Experimenta um manejo. Podes testar os cinco antes de escolher."
	view.panel.offset_top = -490
	for option in options: _option(option.label+ (" · testado" if ChapterProgress.tested_styles.has(option.style) else ""),choose_style.bind(option.style))
	if not ChapterProgress.tested_styles.is_empty(): _option("Continuar com "+RULES.STYLES[ChapterProgress.style].name,confirm_style)
	options_box.get_child(0).grab_focus()

func choose_style(style: String) -> void:
	if paused or phase != "styles": return
	for option in style_options:
		if option.style == style:
			ChapterProgress.style = style; pending_style = style
			_insert(option.events+[{"type":"battle","mode":"style_test"}]); _clear_options(); phase = "dialogue"; advance(); return

func _style_result() -> void:
	phase = "styles_result"; _clear_options(); options_box.show(); view.panel.show(); view.next_button.hide()
	view.speaker.text = "Fundamento · "+RULES.STYLES[ChapterProgress.style].name
	view.body.text = "Prática concluída. Técnica e passivas aprendidas; as passivas ficam por equipar."
	_option("Experimentar outro manejo",func():
		if not paused: _show_styles(style_options))
	_option("Escolher este manejo e continuar",confirm_style)
	_option("Preparar passivas",func(): _menu("Passivas"))
	view.panel.offset_top = -350
	options_box.get_child(0).grab_focus()

func confirm_style() -> void:
	if paused or phase not in ["styles","styles_result"]: return
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
	_insert([{ "type":"battle","mode":"duarte_support"}]); advance()

func restart_block() -> void:
	if busy or phase == "battle": return
	get_tree().paused = false; paused = false; menu_open = false
	if player_menu != null: player_menu.close()
	_load_block(scene_index)

func _stage(action: String) -> void:
	match action:
		"child_arrives": actors["Criança"].show()
		"green_sight": world.player.presentation.eye_glow = true; props.green_sight = true; ChapterProgress.flags.green_sight = true; await get_tree().create_timer(0.7,false).timeout
		"treatment": props.green_sight = false; ChapterProgress.flags.patient_stable = true; actors["Trabalhador ferido"].injured = true
		"leonor_arrives": actors["Leonor"].show(); world.player.presentation.eye_glow = false
		"patient_departure": actors["Trabalhador ferido"].hide(); ChapterProgress.flags.patient_helped = true
		"clean_cloth": ChapterProgress.flags.clean_cloth = true
		"morning": view.caption_label.text = "Portugal · Manhã\n"+blocks[scene_index].title
		"afternoon": view.caption_label.text = "Portugal · Fim da tarde\n"+blocks[scene_index].title
		"two_cups","cup_in_reach":
			if world.has_node("ActorsAndProps/Bench/Cups"): world.get_node("ActorsAndProps/Bench/Cups").show()
		"master_demonstration":
			await _move_actor("Mestre",actors["Combatente"].position+Vector2(-20,0),0.5)
			actors["Combatente"].posture = "seated"
			actors["Combatente"].carries_training_tool = false
		"leonor_demonstration":
			await _move_actor("Leonor",actors["Mestre"].position+Vector2(25,0),0.35)
			actors["Mestre"].posture = "seated"; actors["Leonor"].posture = "standing"
			actors["Mestre"].carries_training_tool = false
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
			ChapterProgress.flags.assisted_return = true
		"treated_in_bed": ChapterProgress.flags.treated = true
		"time_passes": view.body.text = "O tempo passa. Primeiro caminhar, depois pequenas tarefas."; view.panel.show(); await get_tree().create_timer(1.0,false).timeout
		"recovered":
			ChapterProgress.flags.injured = false; ChapterProgress.flags.recovered = true
			ChapterProgress.vitals = {"hp":100,"qi":8,"posture":100}
		"return_courtyard": _load_map("courtyard")
		"give_bowl": actors["Tomé"].carries_bowl = true
		"packed": ChapterProgress.flags.packed = true; props.packed = true
		"ship_departs":
			ChapterProgress.flags.embarked = true; view.panel.hide(); view.status.text = "A Botafogo parte."
			var camera := Camera2D.new(); camera.name = "DepartureCamera"
			camera.position = world.player.camera.global_position; camera.zoom = world.player.camera.zoom; camera.offset = world.player.camera.offset
			world.player.camera.enabled = false; add_child(camera); camera.make_current()
			var tween = world.create_tween(); tween.tween_property(world,"position",Vector2(80,-35),2.0); await tween.finished; view.panel.show()

func _move_actor(name: String, destination: Vector2, seconds: float) -> void:
	actors[name].facing = 3 if destination.x > actors[name].position.x else 1
	var tween = world.create_tween(); tween.tween_property(actors[name],"position",destination,seconds); await tween.finished

func _process(_delta: float) -> void:
	if harbor != null: harbor.update()
	if is_instance_valid(world) and world.has_meta("living_quay"):
		for name in actors:
			var label: Label = actors[name].get_node("NameLabel")
			label.visible = phase == "dialogue" and current_event.get("speaker","") == name
	if phase == "task" and not paused and props != null:
		props.queue_redraw()

func _menu(initial: String = "Personagem") -> void:
	if phase == "battle" or busy: return
	if menu_open:
		player_menu.close(); menu_open = false; paused = false; get_tree().paused = false
		view.show()
		if phase == "styles": _show_styles(style_options)
		elif phase == "styles_result": _style_result()
		if is_instance_valid(menu_focus) and menu_focus.is_visible_in_tree(): menu_focus.grab_focus()
		return
	menu_focus = get_viewport().gui_get_focus_owner()
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
	_load_block(ChapterProgress.checkpoint)

func _unhandled_input(event: InputEvent) -> void:
	if view == null or phase == "battle": return
	if phase == "boarding" and not paused and (event.is_action_pressed("ui_cancel") or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B)):
		get_viewport().set_input_as_handled(); harbor.resume(); return
	if event.is_action_pressed("ui_cancel") or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START): get_viewport().set_input_as_handled(); _menu(); return
	if paused: return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_I,KEY_C,KEY_K,KEY_P]:
		get_viewport().set_input_as_handled()
		_menu({KEY_I:"Inventário",KEY_C:"Personagem",KEY_K:"Técnicas",KEY_P:"Passivas"}[event.physical_keycode]); return
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_F5:
		view.status.text = "Capítulo guardado." if ChapterProgress.save_to() == OK else ChapterProgress.last_error
		get_viewport().set_input_as_handled(); return
	if phase == "exploration":
		if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled(); harbor.interact()
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			get_viewport().set_input_as_handled()
			world.walk_to(world.get_global_transform_with_canvas().affine_inverse()*event.position)
	elif phase == "task":
		if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"): interact_task(); get_viewport().set_input_as_handled()
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT: world.walk_to(world.get_global_mouse_position())
	elif event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled(); advance()


func _show_equipment() -> void:
	if paused or phase == "battle": return
	_lock_player(true)
	phase = "equipment"; _clear_options(); options_box.show(); view.panel.show(); view.next_button.hide()
	view.speaker.text = "Passivas · %s %d/4 · Duarte %d/4" % [CampaignProfile.hero_name,ChapterProgress.equipped_passives.size(),ChapterProgress.duarte_equipped_passives.size()]
	view.body.text = "Escolhe até quatro passivas aprendidas. Equipar não recupera vida nem energia."
	view.panel.offset_top = -610
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




