extends Node2D
const Plan = preload("res://scripts/city/forest_plan.gd")
const State = preload("res://scripts/chapter/forest_hunt_state.gd")
const Animal = preload("res://scripts/city/forest_animal.gd")
const Actor = preload("res://scripts/chapter/actor_proxy.gd")
var world
var leonor
var wolf
var bear
var deer
var view
var phase := "explore"
var paused := false
var completed := false
var state: Dictionary
var data: Dictionary
var lines: Array = []
var cursor := -1
var after := "resume"
var choices: VBoxContainer
var marker
var intent = preload("res://scripts/chapter/interaction_intent.gd").new()
var follow_path := PackedVector2Array()
var follow_clock := 0.0
var battle_host
var battle_container: SubViewportContainer
var battle_kind := ""
const Bond=preload("res://scripts/chapter/childhood_bond.gd")
var return_marker:Node2D
var progress:
	get: return get_node("/root/ChapterProgress")
func _ready() -> void:
	preload("res://scripts/chapter/childhood_pacing.gd").install(self)
	if get_node("/root/CampaignProfile").hero_name.is_empty():
		get_node("/root/CampaignProfile").name_entry_destination = State.SCENE
		get_tree().change_scene_to_file.call_deferred("res://scenes/chapter_01/name_entry.tscn"); return
	state = progress.childhood_hunt.duplicate(true) if not progress.childhood_hunt.is_empty() else State.initial()
	progress.childhood_hunt = state; progress.journey.clear(); progress.enter_scene(State.SCENE)
	data = JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_01/forest_hunt.json"))
	world = load("res://scenes/maps/forest_hunt.tscn").instantiate(); world.process_mode = Node.PROCESS_MODE_PAUSABLE; add_child(world)
	var saved := Vector2(state.position[0],state.position[1])
	if world.point_clear(saved): world.player.position = saved
	world.player.camera.reset_smoothing(); world.player.camera.force_update_scroll()
	leonor = Actor.new(); leonor.identity = "leonor"; leonor.position = companion_point(); world.sorted_world.add_child(leonor)
	wolf = creature("wolf",Vector2(2360,1100),70)
	bear = creature("bear",Vector2(2470,1030),130)
	deer = creature("deer",Vector2(2390,315),80)
	view = preload("res://scripts/chapter/dialogue_view.gd").new(); add_child(view)
	view.caption_label.text = "Infância · À procura do corço branco"
	view.continuation_requested.connect(advance)
	view.replay_button.hide()
	choices = VBoxContainer.new(); view.body.get_parent().add_child(choices)
	marker = preload("res://scripts/chapter/local_request_marker.gd").new(); marker.symbol = "!"; world.sorted_world.add_child(marker)
	var trail:=Node2D.new();trail.set_script(preload("res://scripts/city/forest_trail.gd"));world.add_child(trail)
	return_marker=preload("res://scripts/chapter/local_request_marker.gd").new();return_marker.caption="Leonor · regressar juntos";return_marker.symbol="↩";leonor.add_child(return_marker);return_marker.position=Vector2(0,26)
	_create_battle()
	preload("res://scripts/chapter/childhood_menu.gd").install(self)
	_sync()
	if int(state.stage)==6: dialogue(data.dialogs.wolf_after,"battle:bear")
	elif int(state.stage)==9: complete()
	elif int(state.stage)>0: dialogue([["Narrador","Retomas o caminho onde o deixaste. "+Bond.hint(int(state.stage))]],"resume")
	else: dialogue([["Narrador","Depois do treino, Leonor propõe uma saída pelos arredores de Lisboa. Dizem que um corço branco atravessa o vale da ponte. Há tempo para procurar os sinais do animal e conhecer o caminho juntos."]],"resume")
func companion_point() -> Vector2:
	for offset in [Vector2(45,-10),Vector2(-45,10),Vector2(0,45),Vector2(0,-45)]:
		var at:Vector2=world.player.position+offset
		if world.point_clear(at) and world.segment_clear(world.player.position,at):return at
	return world.player.position
func creature(id: String,at: Vector2,height: float) -> Node2D:
	var animal := Animal.new(); animal.animal = id; animal.position = at; animal.size = height; world.sorted_world.add_child(animal); return animal
func _sync() -> void:
	var step := int(state.stage)
	wolf.visible = step in [5,6]; wolf.fallen = step>=6; wolf.queue_redraw()
	bear.visible = step in [6,7]; bear.fallen = step>=7; bear.queue_redraw()
	deer.visible = step==7
	leonor.visible = step!=5
	if step==6: leonor.position = companion_point()
	return_marker.visible=step==8
	marker.visible = step<9
	if step<9: marker.position = Plan.GOALS[step]+Vector2(0,28); marker.caption = Plan.LABELS[step]
func resume() -> void:
	intent.cancel(); phase = "explore"; world.player.enabled = true; world.player.set_physics_process(true)
	view.show(); view.panel.hide(); choices.hide(); view.next_button.hide()
	view.caption_label.text = "Infância · "+Plan.title(world.player.position)
	view.hint.text = "WASD / setas · mover     Clique · aproximar e interagir     E / A · examinar     J / Y · caderno     F5 / menu · guardar     Esc / Start · pausa"
	var focus = get_viewport().gui_get_focus_owner()
	if focus!=null: focus.release_focus()
	_sync()
func dialogue(rows: Array,then: String) -> void:
	intent.cancel(); phase = "dialogue"; after = then; lines = rows; cursor = -1
	leonor.walking = false
	view.status.text = ""
	world.player.enabled = false; world.player.destination_path.clear(); world.player.velocity = Vector2.ZERO
	view.show(); view.panel.show(); choices.hide(); view.next_button.show(); view.next_button.text = "Continuar"; view.next_button.grab_focus()
	view.hint.text = "Enter / espaço / A · continuar     Esc / Start · pausa"
	advance()
func advance() -> void:
	if paused: return
	if phase=="complete": get_tree().change_scene_to_file("res://scenes/chapter_01/promise.tscn"); return
	if phase!="dialogue": return
	cursor += 1
	if cursor<lines.size():
		var speaker: String = lines[cursor][0]
		view.speaker.text = get_node("/root/CampaignProfile").speaker_name(speaker); view.body.text = lines[cursor][1]; view.remember(view.speaker.text,view.body.text); return
	if after=="next": next_stage()
	elif after.begins_with("choice:"): show_choice(after.trim_prefix("choice:"))
	elif after.begins_with("battle:"): begin_battle(after.trim_prefix("battle:"))
	elif after=="finish": complete()
	else: resume()
func next_stage() -> void:
	var leaving:bool=int(state.stage)==4
	state.stage = mini(9,int(state.stage)+1);save()
	if leaving:
		phase="separating";world.player.enabled=false;follow_path.clear();leonor.visible=true
		view.panel.hide();view.next_button.hide()
		var start:Vector2i=world._nearest_id(leonor.position);var end:Vector2i=world._nearest_id(Plan.GOALS[7])
		var path:PackedVector2Array=world.navigation.get_point_path(start,end) if start.x>=0 and end.x>=0 else PackedVector2Array()
		var points:Array[Vector2]=[];var before:Vector2=leonor.position;var distance:=0.0
		for at in path:
			if distance+before.distance_to(at)>180:points.append(before.move_toward(at,180-distance));break
			points.append(at);distance+=before.distance_to(at);before=at
		if not points.is_empty(): await preload("res://scripts/chapter/staged_walk.gd").along(leonor,points,self,150).finished
		leonor.walking=false;leonor.hide()
	resume()
func show_choice(kind: String) -> void:
	phase = "choice"; view.next_button.hide(); choices.show()
	for child in choices.get_children(): child.free()
	var options := [["Prometer que seguem juntos","together"],["Combinar que deixam sinais no caminho","signs"]] if kind=="departure" else [["Testar a ponte primeiro","lead"],["Confiar no trajeto de Leonor","trust"]] if kind=="bridge" else [["Observar o corço sem o assustar","observe"],["Tentar aproximarem-se juntos","approach"]]
	for row in options:
		var button := Button.new(); button.text = row[0]; choices.add_child(button); button.pressed.connect(choose.bind(kind,row[1]))
	if kind=="return":
		for child in choices.get_children():child.free()
		for row in [["Regressar juntos pelo caminho conhecido","home"],["Continuar a explorar o caminho","explore"]]:
			var button:=Button.new();button.text=row[0];choices.add_child(button);button.pressed.connect(choose.bind(kind,row[1]))
	choices.get_child(0).grab_focus()
func choose(kind: String,value: String) -> void:
	if paused or phase!="choice":return
	var expected:String={0:"departure",3:"bridge",7:"deer",8:"return"}.get(int(state.stage),"")
	var allowed:Dictionary={"departure":["together","signs"],"bridge":["lead","trust"],"deer":["observe","approach"],"return":["home","explore"]}
	if kind!=expected or not allowed.has(kind) or not allowed[kind].has(value):return
	if kind=="return":
		if value=="explore":resume();return
		progress.flags.hunt_return_assisted=true
		world.player.position=Plan.SPAWN;leonor.position=companion_point();world.player.camera.reset_smoothing();world.player.camera.force_update_scroll()
		dialogue([["Narrador","Seguem juntos pelo caminho já conhecido. Repassam a ponte e reconhecem "+("a pedra e o ramo que deixaram nas curvas." if progress.choices.get("hunt_departure","")=="signs" else "a lama dos cascos e o ramo partido junto da curva.")]]+data.dialogs["8"],"finish");save();return
	progress.choices["hunt_"+kind] = value
	if kind=="deer":
		if value=="approach": create_tween().tween_property(deer,"position",Vector2(2650,220),2.2)
		dialogue(data.dialogs[value],"next")
	else:
		var response := "Então ninguém desaparece atrás das árvores sem avisar." if kind=="departure" and value=="together" else "Uma pedra virada e um ramo no chão. Assim também encontramos o caminho de volta." if kind=="departure" else "Espera. Eu seguro a outra ponta enquanto passas." if value=="lead" else "Põe o pé onde eu pus. Depois dizes-me se a tua passagem foi mais elegante."
		dialogue([["Leonor criança",response]],"next")
	save()
func focus() -> String:
	if int(state.stage)<9 and near(Plan.GOALS[int(state.stage)]): return "goal"
	for id in Plan.DISCOVERIES:
		if near(Plan.DISCOVERIES[id].at): return "note:"+id
	if int(state.stage)==8 and leonor.visible and near(leonor.position):return "return"
	return ""
func near(at: Vector2) -> bool:
	return world.player.position.distance_to(at)<60 and world.segment_clear(world.player.position,at)
func interact(id: String = "") -> void:
	if phase!="explore" or paused: return
	if id.is_empty(): id = focus()
	if id=="return":
		if int(state.stage)!=8 or not leonor.visible or not near(leonor.position):return
		dialogue([["Leonor criança","Conhecemos o caminho de volta. Queres regressar comigo ou ainda vamos espreitar os recantos que deixámos para trás?"]],"choice:return");return
	if id=="goal":
		if not near(Plan.GOALS[int(state.stage)]): return
		var step := int(state.stage)
		if step==5: dialogue(data.dialogs.wolf_intro,"battle:wolf")
		else:
			var rows:Array=data.dialogs[str(step)].duplicate(true)
			if step==4:rows.insert(3,Bond.parting(progress)[0]);rows.insert(4,Bond.parting(progress)[1])
			dialogue(rows,"choice:departure" if step==0 else "choice:bridge" if step==3 else "choice:deer" if step==7 else "finish" if step==8 else "next")
	elif id.begins_with("note:"):
		var key := id.trim_prefix("note:")
		if not Plan.DISCOVERIES.has(key) or not near(Plan.DISCOVERIES[key].at): return
		if not state.notes.has(key): state.notes.append(key)
		dialogue([[Plan.DISCOVERIES[key].title,Plan.DISCOVERIES[key].text]],"resume"); save()
func save() -> void:
	if not is_instance_valid(world): return
	state.position = [roundi(world.player.position.x),roundi(world.player.position.y)]
	progress.childhood_hunt = state.duplicate(true)
	if progress.auto_save: progress.save_to()
func complete() -> void:
	state.stage = 9; progress.flags.hunt_completed = true; save(); completed = true; phase = "complete"
	world.player.enabled = false; view.panel.show(); view.next_button.show(); view.next_button.text = "Continuar com Leonor"
	view.speaker.text = "Uma manhã com Leonor"; view.body.text = "Encontraram o corço branco e regressam juntos. O lobo foi vencido pelo herói; a força de Leonor mudou aquilo que ele julgava conhecer. Ainda têm uma tarde para partilhar em Lisboa."
	marker.hide()
func _process(delta: float) -> void:
	if paused or not is_instance_valid(world) or not is_instance_valid(view): return
	if phase!="explore": return
	var selected := focus(); marker.highlighted = selected=="goal"
	view.caption_label.text = "Infância · "+Plan.title(world.player.position)
	view.status.text = "E / A · "+("Falar com Leonor · regressar juntos" if selected=="return" else Plan.LABELS[int(state.stage)] if selected=="goal" else Plan.DISCOVERIES[selected.trim_prefix("note:")].title) if not selected.is_empty() else Plan.LABELS[int(state.stage)]
	view.guide.track(world,Vector2(1460,730) if int(state.stage)==8 and world.player.position.x>1520 else Plan.GOALS[int(state.stage)])
	var arrived := intent.poll(world)
	if not arrived.is_empty(): interact(arrived); return
	if leonor.visible:
		follow_clock -= delta
		var target: Vector2 = world.player.position+Vector2(-55,20)
		if follow_clock<=0 and leonor.position.distance_to(target)>65:
			follow_clock = .4
			var start: Vector2i = world._nearest_id(leonor.position); var end: Vector2i = world._nearest_id(target)
			if start.x>=0 and end.x>=0: follow_path = world.navigation.get_point_path(start,end)
		var before: Vector2 = leonor.position
		if not follow_path.is_empty():
			var next: Vector2 = leonor.position.move_toward(follow_path[0],185*delta)
			if world.point_clear(next) and world.segment_clear(leonor.position,next): leonor.position = next
			if leonor.position.distance_to(follow_path[0])<8: follow_path.remove_at(0)
		leonor.walking = before.distance_to(leonor.position)>.1; leonor.facing = 1 if leonor.position.x<before.x else 3; leonor.frame_time += delta*7
func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(view) or phase=="battle": return
	if event.is_action_pressed("ui_cancel"):
		paused = not paused; get_tree().paused = paused; view.status.text = "Pausa · Esc para continuar" if paused else ""; save(); get_viewport().set_input_as_handled(); return
	if paused: return
	if phase in ["dialogue","complete"] and event.is_action_pressed("ui_accept"): advance(); get_viewport().set_input_as_handled(); return
	if phase!="explore": return
	if event.is_action_pressed("interact"): interact(); get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		var targets: Array = [{"id":"goal","at":Plan.GOALS[int(state.stage)],"point":Plan.GOALS[int(state.stage)]}]
		if int(state.stage)==8:targets.append({"id":"return","at":leonor.position,"point":leonor.position})
		for id in Plan.DISCOVERIES: targets.append({"id":"note:"+id,"at":Plan.DISCOVERIES[id].at,"point":Plan.DISCOVERIES[id].at})
		intent.begin(world,world.get_global_transform_with_canvas().affine_inverse()*event.position,targets); get_viewport().set_input_as_handled()
func _create_battle() -> void:
	var layer := CanvasLayer.new(); layer.layer = 10; add_child(layer)
	battle_container = SubViewportContainer.new(); battle_container.stretch = true; battle_container.size = Vector2(960,540); layer.add_child(battle_container)
	preload("res://scripts/combat/battle_stage.gd").install(layer,battle_container)
	var viewport := SubViewport.new(); viewport.world_2d = World2D.new(); viewport.size = Vector2i(960,540); battle_container.add_child(viewport)
	battle_host = preload("res://scripts/combat/forest_battle_host.gd").new(); viewport.add_child(battle_host)
	battle_host.lesson_completed.connect(_battle_finished)
	get_viewport().size_changed.connect(_resize_battle); _resize_battle(); battle_container.hide()
func _resize_battle() -> void:
	preload("res://scripts/combat/battle_stage.gd").fit(battle_container,get_viewport_rect().size)
func begin_battle(kind: String) -> void:
	phase = "battle"; battle_kind = kind; save(); view.hide(); battle_container.show()
	var focus = get_viewport().gui_get_focus_owner()
	if focus!=null: focus.release_focus()
	battle_host.begin_hunt(kind,get_node("/root/CampaignProfile").hero_name)
func _battle_finished(success: bool) -> void:
	battle_container.hide(); view.show()
	if not success:
		dialogue([["Narrador","O encontro recomeça no instante anterior ao ataque. O Golpe firme ataca; Respirar recupera. No fim do turno, volta a guarda para o lobo. Falhar o timing não impede um golpe normal."]],"battle:"+battle_kind); return
	if battle_kind=="wolf":
		state.stage = 6; progress.flags.hunt_wolf = true; _sync(); save(); dialogue(data.dialogs.wolf_after,"battle:bear")
	else:
		state.stage = 7; progress.flags.hunt_bear = true; _sync(); save(); dialogue(data.dialogs.bear_after+Bond.apology(progress),"resume")
