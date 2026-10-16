extends Node2D
const Model = preload("res://scripts/navigation/voyage_model.gd")
const Launch = preload("res://scripts/navigation/voyage_launch.gd")
const Naval = preload("res://scripts/navigation/naval_battle.gd")
const View = preload("res://scripts/navigation/voyage_view.gd")
const BoardingLoadout = preload("res://scripts/navigation/boarding_loadout.gd")
const INK := Color("102c35")
const GOLD := Color("d7b67b")
const PAPER := Color("ece1bf")
var model = Model.new()
var view
var perspective
var naval
var current_enemy: Dictionary = {}
var overlay := ""
var clock := 0.0
var zoom := 1.0
var waypoint := Vector2.ZERO
var walker := Vector2(700,560)
var walker_goal := Vector2.ZERO
var walk_facing := 2
var walking := false
var walk_clock := 0.0
var return_phase := "sea"
var queued_fire := -1
var ui: Control
var status: Label
var resources: Label
var objective: Label
var notice_label: Label
var hint: Label
var controls: HBoxContainer
var modal_root: Control
var ocean: ColorRect
var interact_button: Button
var battle_layer: CanvasLayer
var battle_container: SubViewportContainer
var battle_host
var auto_save := true
var save_path := ""
var notice_clock := 0.0
var last_phase := ""
var shot_voice: AudioStreamPlayer
var impact_voice: AudioStreamPlayer
var heard_shot := 0
var service_feedback := ""
var ambience
var audio_settings_path := "user://navegacao-audio.cfg"
var audio_track_label: Label
var reports: Array[String] = []
var focus_id := ""
var return_course := Vector2.ZERO
var sail_level := 0
var helm_notch := 0
var course_button: Button
var sail_button: Button
var turn_sound_clock := 0.0

func _ready() -> void:
	if not InputMap.has_action("move_left"):
		var bindings = preload("res://scripts/main.gd").new(); bindings.configure_input(); bindings.free()
	save_path = Launch.save_path(Launch.mode=="campaign")
	model.hero_name = CampaignProfile.hero_name if not CampaignProfile.hero_name.is_empty() else "Aprendiz"
	model.style = ChapterProgress.style if Launch.mode=="campaign" else "ES"
	var resume := Launch.resume_requested; Launch.resume_requested = false
	var boarding_test := Launch.boarding_requested; Launch.boarding_requested = false
	if boarding_test: auto_save = false
	if resume:
		var error: Error = model.load_from(save_path)
		if error!=OK: model.last_error = "A viagem guardada não pôde ser lida. Iniciada uma nova viagem; o ficheiro anterior foi preservado."
	_prepare_boarding_profile()
	model.safe_state = model.snapshot()
	ocean = ColorRect.new(); ocean.size = get_viewport_rect().size; ocean.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new(); material.shader = load("res://assets/shaders/navigation_ocean.gdshader"); ocean.material = material; add_child(ocean)
	perspective = preload("res://scripts/navigation/voyage_perspective.gd").new(); perspective.game = self; add_child(perspective)
	view = View.new(); view.game = self; add_child(view)
	ambience = preload("res://scripts/navigation/voyage_audio.gd").new(); ambience.settings_path = audio_settings_path; add_child(ambience)
	shot_voice = AudioStreamPlayer.new(); shot_voice.stream = load("res://assets/audio/combat/powder-training.wav"); shot_voice.volume_db = -19; shot_voice.pitch_scale = 0.65; add_child(shot_voice)
	impact_voice = AudioStreamPlayer.new(); impact_voice.stream = load("res://assets/audio/combat/heavy_hit.wav"); impact_voice.volume_db = -23; impact_voice.pitch_scale = 0.75; add_child(impact_voice)
	if ambience.enabled: shot_voice.bus = ambience.buses.effects; impact_voice.bus = ambience.buses.effects
	_build_ui(); _build_boarding()
	if resume and not model.last_error.is_empty(): show_message("Viagem",model.last_error)
	elif not resume and not boarding_test:
		show_message("Ao leme da Botafogo", "Madeira é a primeira escala antes da missão em Duas Águas. Agora olhas pela proa, com o horizonte à frente.\n\nCada toque em W / cima aumenta a vela: parado → manobra → viagem → plena. S / baixo reduz. Ao soltar W, o barco mantém a vela escolhida. A/D ou esquerda/direita comandam o leme.\n\nEspaço recolhe as velas para parar. M abre a carta; marca um rumo para o piloto conduzir. A/D ou W/S devolvem-te o leme. E interage; C leva-te ao convés.\n\nProcura aves, restos e velas à frente. V retoma o rumo após um desvio. Escuta o piloto se o mar pesar.")
		if auto_save: _save(false)
	if model.phase in ["port","island"]: walker = Vector2(700,560)
	_refresh_controls()
	if boarding_test: call_deferred("_start_boarding_test")
func _start_boarding_test() -> void:
	clear_overlay(); current_enemy = model.place("patrol")
	model.position = model.point(current_enemy.pos)-Vector2(260,0); model.immunity = 30
	begin_boarding()
func _prepare_boarding_profile(chapter_path: String = ChapterProgress.SAVE_PATH) -> void:
	if not model.boarding_profile.is_empty(): return
	if Launch.mode=="test": model.boarding_profile = BoardingLoadout.practice(model.style); return
	var source: Dictionary = ChapterProgress.snapshot()
	# Old voyage files had no character kit. Read the chapter checkpoint without
	# loading its scene or mutating the user's live campaign/profile singletons.
	if not source.flags.get("recovered",false) and FileAccess.file_exists(chapter_path):
		var stored: Variant = JSON.parse_string(FileAccess.get_file_as_string(chapter_path))
		if stored is Dictionary and not BoardingLoadout.capture(stored).is_empty(): source = stored
	model.boarding_profile = BoardingLoadout.capture(source)
	if not model.boarding_profile.is_empty(): model.style = model.boarding_profile.style

func _build_ui() -> void:
	var layer := CanvasLayer.new(); layer.layer = 5; add_child(layer)
	ui = Control.new(); ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); ui.mouse_filter = Control.MOUSE_FILTER_IGNORE; layer.add_child(ui)
	var top := Panel.new(); top.position = Vector2(16,16); top.size = Vector2(1408,99); top.mouse_filter = Control.MOUSE_FILTER_IGNORE; top.add_theme_stylebox_override("panel",box(INK,Color("5b756d"))); ui.add_child(top)
	status = label("MAR DE JADE  /  A PRIMEIRA DERROTA",16,GOLD); status.position = Vector2(36,29); ui.add_child(status)
	objective = label("",22,PAPER); objective.position = Vector2(36,57); ui.add_child(objective)
	resources = label("",16,PAPER); resources.position = Vector2(780,48); resources.size = Vector2(620,50); resources.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; ui.add_child(resources)
	var footer := Panel.new(); footer.position = Vector2(16,788); footer.size = Vector2(1408,96); footer.mouse_filter = Control.MOUSE_FILTER_IGNORE; footer.add_theme_stylebox_override("panel",box(INK,Color("5b756d"))); ui.add_child(footer)
	controls = HBoxContainer.new(); controls.position = Vector2(30,799); controls.add_theme_constant_override("separation",8); ui.add_child(controls)
	hint = label("",13,Color("a8beb0")); hint.position = Vector2(34,855); hint.size.x = 1370; hint.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; ui.add_child(hint)
	notice_label = label("",16,PAPER); notice_label.position = Vector2(35,736); notice_label.size = Vector2(1370,45); notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; ui.add_child(notice_label)
	modal_root = Control.new(); modal_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); modal_root.mouse_filter = Control.MOUSE_FILTER_IGNORE; ui.add_child(modal_root)
func label(value: String,size: int,color: Color) -> Label:
	var item := Label.new(); item.text = value; item.add_theme_font_size_override("font_size",size); item.add_theme_color_override("font_color",color); item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return item
func box(fill: Color,border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color = fill; style.border_color = border; style.set_border_width_all(1); style.set_corner_radius_all(5)
	style.content_margin_left = 18; style.content_margin_right = 18; style.content_margin_top = 12; style.content_margin_bottom = 12
	return style
func button(title: String,action: Callable) -> Button:
	var item := Button.new(); item.text = title; item.custom_minimum_size = Vector2(160,43); item.add_theme_font_size_override("font_size",16)
	item.add_theme_color_override("font_color",PAPER); item.add_theme_stylebox_override("normal",box(Color("183c44"),Color("52736b"))); item.add_theme_stylebox_override("hover",box(Color("2a514f"),GOLD)); item.add_theme_stylebox_override("focus",box(Color("315853"),GOLD))
	item.pressed.connect(action); return item
func notice(message: String) -> void:
	notice_label.text = message; notice_clock = 8
func queue_report(message: String) -> void:
	if message.begins_with("O piloto") or message.begins_with("Mar muito") or message.begins_with("O mar voltou"):
		notice(message); return
	if notice_clock<=0: notice(message)
	elif not reports.has(message): reports.append(message)
	if reports.size()>8: reports.pop_front()
func clear_overlay() -> void:
	audio_track_label = null
	for child in modal_root.get_children(): modal_root.remove_child(child); child.queue_free()
	overlay = ""; _refresh_controls()
func modal(kind: String,title: String,body: String,actions: Array) -> VBoxContainer:
	clear_overlay(); overlay = kind
	var shade := ColorRect.new(); shade.color = Color(0.015,0.045,0.055,0.75); shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); modal_root.add_child(shade)
	var center := CenterContainer.new(); center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); modal_root.add_child(center)
	var card := PanelContainer.new(); card.custom_minimum_size.x = 700; card.add_theme_stylebox_override("panel",box(INK,GOLD)); center.add_child(card)
	var column := VBoxContainer.new(); column.custom_minimum_size.x = 650; column.add_theme_constant_override("separation",12); card.add_child(column)
	column.add_child(label(title,26,GOLD))
	var paragraph := label(body,17,PAPER); paragraph.custom_minimum_size.x = 650; paragraph.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; column.add_child(paragraph)
	for action in actions:
		var callback: Callable = action[1]
		var choice := button(action[0],func(): clear_overlay(); callback.call())
		column.add_child(choice)
		if column.get_child_count()==3: choice.grab_focus()
	return column
func show_message(title: String,body: String,after: Callable = Callable()) -> void:
	modal("dialogue",title,body,[["Continuar",func():
		if after.is_valid(): after.call()
	]])
func _refresh_controls() -> void:
	if controls==null: return
	for child in controls.get_children(): controls.remove_child(child); child.queue_free()
	interact_button = null
	course_button = null; sail_button = null
	if model.phase=="boarding": return
	if overlay=="chart":
		controls.add_child(button("Fechar carta · M",clear_overlay))
		controls.add_child(button("Rumo à Madeira",func(): set_course("madeira")))
		controls.add_child(button("Rumo a Lisboa",func(): set_course("lisboa")))
		if model.discovered.has("porto_santo"): controls.add_child(button("Rumo a Porto Santo",func(): set_course("porto_santo")))
	elif model.phase in ["naval","naval_result"]:
		controls.add_child(button("Bombordo · Q",func(): fire(0)))
		controls.add_child(button("Boreste · E",func(): fire(1)))
		controls.add_child(button("Ordens · Espaço",open_orders))
		controls.add_child(button("Reparo · R",repair))
		controls.add_child(button("Retirada · F",retreat))
		controls.add_child(button("Alvo · 1 / 2 / 3",open_orders))
	else:
		controls.add_child(button("Carta · M",open_chart))
		controls.add_child(button("Convés · C" if model.phase=="sea" else "Voltar ao mar · B",enter_deck if model.phase=="sea" else leave_stage))
		interact_button = button("Interagir · E",interact); controls.add_child(interact_button)
		controls.add_child(button("Guardar · F5",func(): _save(true)))
		controls.add_child(button("Menu · Esc",open_pause))
		if model.phase=="sea":
			sail_button = button("Parar · Espaço",stop_sailing); controls.add_child(sail_button)
			course_button = button("Retomar rumo · V",resume_course); controls.add_child(course_button)

func _process(delta: float) -> void:
	clock += delta
	if view==null: return
	if is_instance_valid(audio_track_label): audio_track_label.text = "Tocando · "+ambience.track_title()
	ocean.size = get_viewport_rect().size
	ocean.material.set_shader_parameter("world_origin",-view.world_offset()/zoom)
	ocean.material.set_shader_parameter("canvas_size",get_viewport_rect().size)
	ocean.material.set_shader_parameter("world_scale",zoom)
	ocean.material.set_shader_parameter("sea_time",naval.clock if model.phase in ["naval","naval_result"] and naval!=null else model.elapsed)
	ocean.material.set_shader_parameter("roughness",clampf(maxf(model.risk_at(model.position)*0.6,model.danger/100.0),0,1))
	ambience.update_mix(delta,model.phase,overlay.is_empty(),model.velocity.length(),maxf(model.risk_at(model.position),model.danger/100.0))
	if overlay.is_empty():
		if notice_clock>0: notice_clock -= delta
		elif not reports.is_empty(): notice(reports.pop_front())
		else: notice_label.text = ""
	if overlay.is_empty():
		var direction := Input.get_vector("move_left","move_right","move_up","move_down")
		match model.phase:
			"sea": _sail(delta,direction)
			"naval":
				read_sail_input(direction)
				if queued_fire>=0: naval.fire(queued_fire); queued_fire = -1
				naval.helm(delta,direction.x,sail_level)
				if naval.shot_serial>heard_shot:
					heard_shot = naval.shot_serial
					if DisplayServer.get_name()!="headless": shot_voice.play(); impact_voice.play()
				model.hull = naval.hull
				if naval.state=="disabled": _naval_victory()
				elif naval.state=="defeat": game_over("A Botafogo afundou durante o confronto.")
				elif naval.state=="fled": finish_encounter(false,true)
			"deck","port","island": _walk(delta,direction)
	if last_phase!=model.phase: last_phase = model.phase; _refresh_controls()
	_refresh_status(); view.queue_redraw()
	perspective.update_view(delta if overlay.is_empty() else 0)
func _sail(delta: float,direction: Vector2) -> void:
	if waypoint!=Vector2.ZERO and not focus_id.is_empty():
		var target_contact: Dictionary = model.place(focus_id)
		if not target_contact.is_empty(): waypoint = model.place_position(target_contact)
	read_sail_input(direction)
	if absf(direction.x)>0.12:
		waypoint = Vector2.ZERO; focus_id = ""
	var automatic := waypoint!=Vector2.ZERO
	var throttle: float = Model.SAIL_RATIOS[sail_level]
	var course := Vector2.ZERO
	if automatic:
		if model.position.distance_to(waypoint)<95:
			waypoint = Vector2.ZERO; sail_level = 0; throttle = 0
		else:
			course = (waypoint-model.position).normalized()
			throttle = minf(throttle,clampf(model.position.distance_to(waypoint)/530.0,0.2,1.6))
	turn_sound_clock = maxf(0,turn_sound_clock-delta)
	if (absf(direction.x)>0.4 or (automatic and absf(angle_difference(model.heading,course.angle()))>0.65)) and model.velocity.length()>20 and turn_sound_clock<=0:
		ambience.cue("creak"); turn_sound_clock = 14
	var messages: Array[String] = model.update(delta,course,throttle) if automatic else model.helm(delta,direction.x,sail_level)
	for message in messages:
		queue_report(message)
		if message.begins_with("À vista:"): ambience.cue("discovery")
		elif message.contains("aves") or message.contains("bando"): ambience.cue("gull")
	if waypoint!=Vector2.ZERO and model.blocked_by_coast:
		waypoint = Vector2.ZERO; sail_level = 0; notice("Costa à frente. Escolhe outro rumo ou aproxima-te do ancoradouro.")
	if model.phase=="game_over": game_over("A Botafogo não resistiu à travessia. O mar e a falta de reservas venceram a tripulação."); return
	var enemy: Dictionary = model.encounter()
	if not enemy.is_empty(): begin_naval(enemy)
func read_sail_input(direction: Vector2) -> void:
	var notch := -1 if direction.y< -0.6 else (1 if direction.y>0.6 else 0)
	if notch!=0 and notch!=helm_notch:
		waypoint = Vector2.ZERO; focus_id = ""; change_sails(-notch)
	helm_notch = notch
func sail_name() -> String: return ["parado","manobra · 1/3","viagem · 2/3","plena · 3/3"][sail_level]
func change_sails(amount: int) -> void:
	sail_level = clampi(sail_level+amount,0,3)
	ambience.sail_shift()
	notice("Velas: "+sail_name()+". A/D comandam o leme; "+("S reduz até parar." if model.phase=="naval" else "Espaço para parar."))
func stop_sailing() -> void:
	if model.phase!="sea": return
	sail_level = 0; waypoint = Vector2.ZERO; focus_id = ""
	ambience.sail_shift()
	notice("Velas recolhidas. A Botafogo perde o andamento. W volta a içar.")
func mark_contact(id: String) -> void:
	var entry: Dictionary = model.place(id)
	if entry.is_empty(): return
	if focus_id.is_empty() and return_course==Vector2.ZERO:
		return_course = waypoint if waypoint!=Vector2.ZERO else model.point(model.place("madeira" if not model.made_landfall else "lisboa").pos)
	focus_id = id; waypoint = model.place_position(entry); sail_level = maxi(sail_level,2)
	notice("Aproximar de "+entry.name+". A vela abranda ao chegar; E / A interage. V retoma o rumo anterior.")
func resume_course() -> void:
	if model.phase!="sea": return
	focus_id = ""
	if model.danger>0 or model.risk_at(model.position)>0:
		waypoint = model.safety_target()
		if waypoint.distance_to(model.position)<50: waypoint = Vector2.ZERO
		notice("Rumo para águas seguras. Mantém a manobra até o mar acalmar.")
	else:
		waypoint = return_course if return_course!=Vector2.ZERO else model.point(model.place("madeira" if not model.made_landfall else "lisboa").pos)
		notice("Rumo retomado. A descoberta ficou na carta; a viagem continua.")
	sail_level = 2; return_course = Vector2.ZERO
func _refresh_status() -> void:
	notice_label.visible = overlay!="chart"
	var title := "Madeira · primeira escala" if not model.made_landfall else "Madeira alcançada · explora e descobre novas rotas"
	if model.phase=="deck": title = "A bordo da Botafogo · conversa e prepara a viagem"
	elif model.phase in ["port","island"]: title = model.place(model.port).name+" · em terra"
	elif model.phase in ["naval","naval_result"]: title = current_enemy.get("name","")+" · encontro naval"
	objective.text = title
	var hull_value: float = naval.hull if model.phase=="naval" and naval!=null else model.hull
	resources.text = "CASCO %d%%    PROVISÕES %d%%    %d REAIS\n%s"%[ceili(hull_value),ceili(model.supplies),model.coins,"Teste de navegação" if Launch.mode=="test" else "Viagem da campanha"]
	if model.phase in ["naval","naval_result"] and naval!=null:
		hint.text = "W ↑ vela · S ↓ vela · A/D leme  |  "+sail_name()+"  |  "+naval.note
	else:
		hint.text = "W ↑ vela · S ↓ vela · A/D leme  |  Espaço parar  |  M carta · C convés · V retomar rumo · E interagir  |  "+sail_name()
		if sail_button!=null: sail_button.text = "Parar · Espaço"
		if course_button!=null: course_button.text = "Águas seguras · V" if model.danger>0 else "Retomar rumo · V"
		if interact_button!=null:
			var near: Dictionary = model.closest() if model.phase=="sea" else nearby_person()
			interact_button.disabled = near.is_empty()
			if not near.is_empty(): hint.text = "E / A · "+near.name+"    |    "+hint.text
		if model.phase in ["deck","port","island"]: hint.text = "WASD / analógico ou clique: caminhar  ·  E / A: conversar  ·  B: voltar ao mar  ·  Esc: menu"

func open_chart() -> void:
	if model.phase not in ["sea","deck","port","island"]: return
	clear_overlay(); overlay = "chart"; _refresh_controls()
	if controls.get_child_count()>0: controls.get_child(0).grab_focus()
func set_course(id: String) -> void:
	waypoint = model.point(model.place(id).pos)
	focus_id = ""; return_course = Vector2.ZERO; sail_level = maxi(sail_level,2)
	clear_overlay(); notice("Rumo marcado para "+model.place(id).name+". WASD assume o controle a qualquer momento.")
func enter_deck() -> void:
	if model.phase!="sea": return
	if not model.encounter().is_empty(): return
	return_phase = "sea"; model.phase = "deck"; model.velocity = Vector2.ZERO; sail_level = 0; waypoint = Vector2.ZERO; walker = Vector2(700,560); walker_goal = Vector2.ZERO
	notice("A tripulação mantém a posição. B ou a escada de popa retoma a viagem.")
func leave_stage() -> void:
	if model.phase not in ["deck","port","island"]: return
	model.phase = "sea"; model.velocity = Vector2.ZERO; sail_level = 0; model.immunity = maxf(model.immunity,8); walker_goal = Vector2.ZERO
	notice("Ao leme da Botafogo. Segue o rumo marcado ou escolhe o que investigar.")
	_refresh_controls()
func stage_people() -> Array:
	if model.phase=="island":
		return [{"id":"duarte","name":"Duarte · examinar abrigo","at":Vector2(730,465)},{"id":"beatriz","name":"Beatriz · embarcar","at":Vector2(1120,635)}]
	if model.phase=="deck":
		var crew := [{"id":"duarte","name":"Duarte","at":Vector2(420,480)},{"id":"beatriz","name":"Beatriz · piloto","at":Vector2(1010,380)},{"id":"rodrigo","name":"Rodrigo","at":Vector2(750,320)},{"id":"worker","name":"Escada · retomar viagem","at":Vector2(1100,610)}]
		if model.resolved.has("castaway"): crew.append({"id":"injured_worker","name":"Sobrevivente","at":Vector2(600,620)})
		return crew
	return [{"id":"worker","name":"Comerciante · provisões","at":Vector2(450,465)},{"id":"master","name":"Pilotos e cartas","at":Vector2(760,375)},{"id":"duarte","name":"Duarte","at":Vector2(920,540)},{"id":"attendant","name":"Cais · serviço","at":Vector2(350,610)},{"id":"beatriz","name":"Beatriz · embarcar","at":Vector2(1120,635)}]
func nearby_person() -> Dictionary:
	var best: Dictionary = {}; var distance := 92.0
	for person in stage_people():
		var d: float = walker.distance_to(person.at)
		if d<distance: best = person; distance = d
	return best
func _walk(delta: float,direction: Vector2) -> void:
	if direction.length()>0.1: walker_goal = Vector2.ZERO
	elif walker_goal!=Vector2.ZERO:
		if walker.distance_to(walker_goal)<6: walker_goal = Vector2.ZERO
		else: direction = (walker_goal-walker).normalized()
	var desired := walker+direction*165*delta
	var bounds := Rect2(300,290,800,360) if model.phase=="deck" else Rect2(235,350,950,335)
	desired = desired.clamp(bounds.position,bounds.end)
	var blocked := false
	for person in stage_people():
		if desired.distance_to(person.at)<31: blocked = true
	if model.phase=="deck" and (desired.distance_to(Vector2(520,410))<36 or desired.distance_to(Vector2(910,420))<36): blocked = true
	if not blocked: walker = desired
	else: walker_goal = Vector2.ZERO
	walking = direction.length()>0.1 and not blocked
	if walking:
		walk_clock += delta
		walk_facing = (3 if direction.x>0 else 1) if absf(direction.x)>absf(direction.y) else (2 if direction.y>0 else 0)
func interact() -> void:
	if not overlay.is_empty(): return
	if model.phase=="sea":
		var entry: Dictionary = model.closest()
		if entry.is_empty(): return
		waypoint = Vector2.ZERO; sail_level = 0; model.velocity = Vector2.ZERO; reports.clear()
		match entry.kind:
			"port","island":
				model.dock(entry.id)
				if entry.kind=="island": model.phase = "island"
				walker = Vector2(700,560); walker_goal = Vector2.ZERO; waypoint = Vector2.ZERO
				notice("Em terra · "+entry.name+". Aproxima-te das pessoas e usa E / A para interagir.")
				_save(false)
				show_message(entry.name,"Chegaste à primeira escala. Explora o porto, repõe o que precisares e procura novas informações. Duas Águas continua como destino da missão." if entry.id=="madeira" else entry.detail)
			"merchant": open_services(false)
			"fisher":
				model.reveal("porto_santo","sighted"); model.reveal("current_1","rumor")
				show_message("Batel de pescadores","O mestre aponta Porto Santo na carta. Para sul, a espuma dividida marca o começo de outra passagem. É preciso reconhecer os outros sinais antes de confiar nela.")
				_save(false)
			"hostile","boss": begin_naval(entry)
			_:
				var message: String = model.investigate(entry.id)
				ambience.cue("discovery"); focus_id = ""
				modal("discovery",entry.name,message,[["Continuar a explorar",func(): pass],["Retomar o rumo anterior",resume_course]])
				_save(false)
	elif model.phase in ["deck","port","island"]:
		var person := nearby_person()
		if person.is_empty(): return
		if model.phase=="deck":
			match person.id:
				"worker": leave_stage()
				"duarte": show_message("Duarte","Se vires algo, chama. Temos uma missão, mas prestar atenção ao caminho também faz parte dela.\n\nNa abordagem, fico contigo. Guarda espaço para te moveres e observa o golpe antes de defender.")
				"beatriz": show_message("Beatriz","A seta da bússola mostra o vento. A carta dá-nos a derrota para a Madeira. Se a água mudar e o mar pesar, escuta o aviso antes de insistir.\n\nPodes marcar um rumo na carta e assumir a manobra quando quiseres.")
				"rodrigo": show_message("Rodrigo","Madeira é a primeira escala. Depois seguimos para Duas Águas e para a busca.\n\nMantém a passagem livre e traz as dúvidas ao piloto. Explorar também exige saber voltar.")
				"injured_worker":
					model.reveal("current_1","rumor"); model.reveal("current_2","rumor")
					show_message("Sobrevivente","A espuma dividia-se junto da primeira marca. Mais adiante, as aves ficavam sobre a corrente calma. A terceira marca era o abrigo entre os recifes. Regista as três e consegues reconhecer a passagem.")
		else:
			match person.id:
				"worker": open_services(false)
				"master": open_services(true)
				"beatriz": leave_stage()
				"attendant":
					if not model.aid_used.has(model.port):
						model.aid_used[model.port] = true; model.coins += 30; model.supplies = maxf(65,model.supplies); model.hull = maxf(65,model.hull); _save(false)
						show_message("Serviço do cais","Ajudaste a conferir a carga e a preparar as amarras.\n\n+30 reais. O cais garantiu o essencial para continuar: casco e reservas repostos até pelo menos 65%. Este serviço é recebido uma vez em cada escala.")
					else: show_message("Serviço do cais","A carga desta escala já foi conferida. O comerciante e os pilotos continuam disponíveis.")
				"duarte":
					if model.phase=="island":
						if not model.resolved.has("desertas"):
							model.resolved.desertas = true; model.coins += 45; model.supplies = minf(100,model.supplies+15)
							show_message("Uma passagem antiga","Encontraste marcas de navegação talhadas junto do abrigo e restos de uma carga.\n\n+45 reais · +15 provisões. A descoberta fica registada na carta."); _save(false)
						else: show_message("Duarte","Já examinámos este abrigo. As marcas continuam aqui para quem souber procurá-las.")
					else: show_message("Duarte","O Quebra-Mar ronda o largo, longe da derrota direta. Dizem que tenta abalroar quem enfrenta. É uma ameaça para quando estivermos preparados.\n\nTambém podemos procurar Porto Santo e as marcas da Passagem das Desertas.")
func open_services(specialists: bool) -> void:
	var ids := ["chart","pilot","cartographer","hull"] if specialists else ["supplies","repair","chart"]
	var names := {"supplies":"Provisões +40 · 12 reais","repair":"Reparar casco +45 · 15 reais","chart":"Carta das Desertas · 35 reais","pilot":"Contratar piloto · 65 reais","cartographer":"Contratar cartógrafo · 55 reais","hull":"Reforçar o casco · 90 reais"}
	var actions: Array = []
	for id in ids:
		var item_id: String = id
		actions.append([names[id]+(" · adquirido" if model.upgrades.has(id) else ""),func():
			var message: String = model.buy(item_id); service_feedback = message; _save(false); notice(message); open_services(specialists)
		])
	actions.append(["Voltar",func(): pass])
	modal("services","Pilotos e cartas" if specialists else "Provisões e reparos","%d reais · casco %d%% · provisões %d%%\n%s"%[model.coins,ceili(model.hull),ceili(model.supplies),"O piloto melhora a manobra; o cartógrafo melhora os avistamentos. A carta oferece pistas, e o casco amplia a margem em mar pesado." if specialists else "Prepara a próxima viagem. O serviço do cais ajuda com o essencial uma vez por escala."]+("\n\n"+service_feedback if not service_feedback.is_empty() else ""),actions)

func begin_naval(entry: Dictionary) -> void:
	current_enemy = entry; naval = Naval.new(); naval.begin(entry.kind=="boss",model.hull,model.upgrades.get("hull",false))
	heard_shot = 0
	model.phase = "naval"; model.velocity = Vector2.ZERO; waypoint = Vector2.ZERO; queued_fire = -1; sail_level = 2
	reports.clear()
	notice("Contato hostil · "+entry.name+". Observa os sinais na água e apresenta um flanco para disparar.")
	_refresh_controls()
	show_message(entry.name,"O contato abre uma vista tática do encontro naval.\n\nW aumenta a vela; S reduz até parar. A/D comandam o leme em relação à proa, como na viagem. Apresenta um flanco e usa Q / E para ordenar a bordada. A tripulação aponta os canhões.\n\nEspaço pausa para escolher ordens. Sai das marcas de impacto. R repara com provisões. F marca a zona de retirada."+("\n\nO Quebra-Mar anuncia a carga antes de avançar. Desvia-te e aproveita os flancos expostos." if entry.kind=="boss" else ""))
func fire(side: int) -> void:
	if model.phase=="naval" and overlay.is_empty(): naval.fire(side)
func repair() -> void:
	if model.phase=="naval" and overlay.is_empty(): model.supplies -= naval.repair(model.supplies)
func retreat() -> void:
	if model.phase!="naval": return
	naval.retreat = true; naval.note = "Conduz até à zona verde, no canto inferior esquerdo, para romper o contato."
func open_orders() -> void:
	if model.phase!="naval": return
	modal("orders","Ordens · encontro em pausa","O tempo está parado. Alvo atual: %s.\nCasco neutraliza pela resistência; velas reduzem a mobilidade; bateria reduz o dano recebido.\nBombordo %.1fs · Boreste %.1fs"%[{"hull":"casco","sails":"velas","guns":"bateria"}[naval.target_part],naval.reloads[0],naval.reloads[1]],[
		["Retomar a manobra",func(): pass],
		["Visar casco",func(): naval.target_part = "hull"],
		["Visar velas",func(): naval.target_part = "sails"],
		["Visar bateria",func(): naval.target_part = "guns"],
		["Bombordo ao retomar",func(): queued_fire = 0],
		["Boreste ao retomar",func(): queued_fire = 1],
		["Preparar retirada",retreat],
		["Som e música",open_audio]
	])
func _naval_victory() -> void:
	model.phase = "naval_result"; model.hull = naval.hull
	modal("result","Embarcação incapacitada","Podes abordar para enfrentar a tripulação e recuperar mais recursos, ou recolher apenas o salvado e continuar a viagem.",[
		["Abordar · combate por turnos",begin_boarding],
		["Recolher salvado e continuar",func(): finish_encounter(false)]
	])
func finish_encounter(boarded: bool,fled: bool = false) -> void:
	model.phase = "sea"; model.velocity = Vector2.ZERO; model.immunity = 18; queued_fire = -1; sail_level = 0; waypoint = Vector2.ZERO
	if not fled:
		model.resolved[current_enemy.id] = true; model.discovered[current_enemy.id] = "explored"
		var reward := (140 if current_enemy.kind=="boss" else 40)+(30 if boarded else 0)
		model.coins += reward; model.supplies = minf(100,model.supplies+(20 if boarded else 8))
		notice(("Boss vencido! " if current_enemy.kind=="boss" else "Encontro concluído. ")+"+%d reais · recursos recuperados."%reward)
		_save(false)
	else:
		var at: Vector2 = model.place_position(current_enemy)
		model.traffic[current_enemy.id] = model.point(current_enemy.pos)
		var escape: Vector2 = model.position+(model.position-at).normalized()*450
		if model.water(escape): model.position = escape
		notice("Contato rompido. A ameaça continua no mar; o dano da Botafogo permanece.")
	_refresh_controls()
func _build_boarding() -> void:
	battle_layer = CanvasLayer.new(); battle_layer.layer = 10; add_child(battle_layer)
	battle_container = SubViewportContainer.new(); battle_container.size = Vector2(960,540); battle_container.stretch = true; battle_layer.add_child(battle_container)
	preload("res://scripts/combat/battle_stage.gd").install(battle_layer,battle_container)
	var viewport := SubViewport.new(); viewport.size = Vector2i(960,540); viewport.world_2d = World2D.new(); battle_container.add_child(viewport)
	battle_host = preload("res://scripts/combat/battle_host.gd").new()
	battle_host.combat = preload("res://scripts/navigation/boarding_rules.gd").new()
	battle_host.tactical = preload("res://scripts/navigation/boarding_view.gd").new()
	battle_host.ending = preload("res://scripts/navigation/boarding_ending.gd").new()
	viewport.add_child(battle_host); battle_host.lesson_completed.connect(_boarding_completed)
	if ambience.enabled:
		for player in battle_host.effect_players: player.bus = ambience.buses.effects
	get_viewport().size_changed.connect(func(): preload("res://scripts/combat/battle_stage.gd").fit(battle_container,get_viewport_rect().size))
	preload("res://scripts/combat/battle_stage.gd").fit(battle_container,get_viewport_rect().size)
	battle_container.hide()
func begin_boarding() -> void:
	# Campaign carries its learned kit; quick tests use an isolated prepared kit.
	_prepare_boarding_profile()
	battle_host.combat.progress_override = model.boarding_profile.duplicate(true)
	model.phase = "boarding"; battle_container.show()
	battle_host.begin_encounter("boarding",model.hero_name,model.style)
	if current_enemy.kind=="boss":
		for unit in battle_host.combat.enemies: unit.hp += 25; unit.max_hp += 25
	_refresh_controls()
func _boarding_completed(success: bool) -> void:
	battle_container.hide()
	if success: finish_encounter(true)
	else: game_over("O grupo foi vencido na abordagem. A viagem regressa ao último ponto seguro.")
func game_over(reason: String) -> void:
	model.phase = "game_over"; model.velocity = Vector2.ZERO
	modal("game_over","A viagem terminou",reason+"\nO último salvamento seguro foi preservado.",[["Retomar do ponto seguro",restore_safe],["Menu inicial",return_menu]])
func restore_safe() -> void:
	if model.load_from(save_path)!=OK: model.restore(model.safe_state)
	_prepare_boarding_profile()
	naval = null; waypoint = Vector2.ZERO; walker = Vector2(700,560); walker_goal = Vector2.ZERO
	focus_id = ""; return_course = Vector2.ZERO; reports.clear(); sail_level = 0; helm_notch = 0
	notice("Viagem retomada do último ponto seguro."); _refresh_controls()
func _save(feedback: bool) -> Error:
	if not auto_save: return OK
	var original: String = model.phase
	if model.phase=="deck": model.phase = return_phase
	var result: Error = model.save_to(save_path)
	model.phase = original
	if feedback: notice("Viagem guardada em segurança." if result==OK else model.last_error)
	return result
func open_pause() -> void:
	if model.phase=="boarding": return
	if model.phase=="naval": open_orders(); return
	if model.phase=="game_over": return
	modal("pause","Viagem em pausa","O mar espera. Consulta a carta ou retoma a última viagem guardada.",[
		["Continuar",func(): pass],
		["Som e música",open_audio],
		["Guardar viagem",func(): _save(true)],
		["Carregar ponto seguro",restore_safe],
		["Menu inicial",return_menu]
	])
func open_audio() -> void:
	var column := modal("audio","Som e música","",[
		["Próxima música",func(): open_audio(); ambience.next_track()],
		["Voltar à pausa",close_audio]
	])
	audio_track_label = column.get_child(1) as Label
	audio_track_label.text = "Tocando · "+ambience.track_title()
	var i := 0
	for key in ["music","ambience","effects"]:
		var row := HBoxContainer.new(); row.add_theme_constant_override("separation",12)
		var title := label({"music":"Música","ambience":"Mar e ambiente","effects":"Efeitos"}[key],17,PAPER)
		title.custom_minimum_size.x = 175; row.add_child(title)
		var slider := HSlider.new(); slider.name = key; slider.custom_minimum_size = Vector2(320,40)
		slider.min_value = 0; slider.max_value = 100; slider.step = 5; slider.value = float(ambience.levels[key])*100
		row.add_child(slider)
		var percentage := label("%d%%"%roundi(slider.value),16,GOLD); percentage.custom_minimum_size.x = 65; row.add_child(percentage)
		slider.value_changed.connect(func(value): ambience.set_level(key,value/100.0); percentage.text = "%d%%"%roundi(value))
		column.add_child(row); column.move_child(row,2+i); i += 1
		if i==1: slider.grab_focus()
func close_audio() -> void:
	ambience.save_settings()
	if model.phase=="naval": open_orders()
	else: open_pause()
func return_menu() -> void: get_tree().change_scene_to_file("res://scenes/chapter_01/name_entry.tscn")

func _input(event: InputEvent) -> void:
	# E and pad A are contextual actions outside dialogs, even after a HUD click.
	if model.phase=="boarding" or not overlay.is_empty(): return
	# Polling still reads these actions, but arrows/d-pad cannot also move HUD focus.
	if model.phase in ["sea","naval"]:
		for action in ["move_left","move_right","move_up","move_down"]:
			if event.is_action(action): get_viewport().set_input_as_handled(); return
	if (event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_E,KEY_SPACE]) or (event is InputEventJoypadButton and event.pressed and event.button_index==JOY_BUTTON_A):
		_unhandled_input(event); get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if model.phase=="boarding": return
	if event.is_action_pressed("ui_cancel") or (event is InputEventJoypadButton and event.pressed and event.button_index==JOY_BUTTON_START):
		if overlay in ["game_over","result"]: return
		if not overlay.is_empty(): clear_overlay()
		else: open_pause()
		get_viewport().set_input_as_handled(); return
	if overlay=="chart":
		if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and view.chart_rect.has_point(event.position):
			var at: Vector2 = view.chart_world(event.position)
			if model.water(at): waypoint = at; sail_level = maxi(sail_level,2); clear_overlay(); notice("Rumo marcado na carta. A/D ou W/S devolvem-te o leme.")
			else: notice("Marca o rumo em água livre, junto do ancoradouro.")
		elif event is InputEventKey and event.pressed and event.physical_keycode in [KEY_M,KEY_B]: clear_overlay()
		return
	if not overlay.is_empty(): return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_ESCAPE: open_pause()
			KEY_M,KEY_TAB: open_chart()
			KEY_C:
				if model.phase=="sea": enter_deck()
				elif model.phase=="deck": leave_stage()
			KEY_B:
				if model.phase in ["deck","port","island"]: leave_stage()
			KEY_E:
				if model.phase=="naval": fire(1)
				else: interact()
			KEY_Q: fire(0)
			KEY_SPACE:
				if model.phase=="naval": open_orders()
				elif model.phase=="sea": stop_sailing()
			KEY_V: resume_course()
			KEY_R: repair()
			KEY_F: retreat()
			KEY_1,KEY_2,KEY_3:
				if model.phase=="naval": naval.target_part = {KEY_1:"hull",KEY_2:"sails",KEY_3:"guns"}[event.physical_keycode]
				elif model.phase=="sea": waypoint = Vector2.ZERO; sail_level = {KEY_1:1,KEY_2:2,KEY_3:3}[event.physical_keycode]
			KEY_F5: _save(true)
			KEY_F9: restore_safe()
	elif event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JOY_BUTTON_A: interact()
			JOY_BUTTON_B: leave_stage()
			JOY_BUTTON_X:
				if model.phase=="naval": repair()
				else: enter_deck()
			JOY_BUTTON_Y:
				if model.phase=="naval": open_orders()
				else: open_chart()
			JOY_BUTTON_LEFT_SHOULDER:
				if model.phase=="sea": resume_course()
				else: fire(0)
			JOY_BUTTON_RIGHT_SHOULDER:
				if model.phase=="sea": stop_sailing()
				else: fire(1)
	elif event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and event.position.y>125 and event.position.y<730:
		if model.phase=="sea":
			var tracked: Dictionary = view.tracked_contact()
			if model.danger<=0 and view.contact_rect.has_point(event.position) and not tracked.is_empty():
				mark_contact(tracked.id); return
			var at: Vector2 = view.to_world(event.position)
			var picked := false
			for entry in model.chart.places:
				if model.resolved.has(entry.id) and entry.kind not in ["port","island","landmark"]: continue
				if at.distance_to(model.place_position(entry))<105: mark_contact(entry.id); picked = true; break
			if not picked and model.water(at): waypoint = at; focus_id = ""; sail_level = maxi(sail_level,2)
		elif model.phase in ["deck","port","island"]: walker_goal = event.position
