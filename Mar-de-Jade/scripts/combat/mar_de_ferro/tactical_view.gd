extends RefCounted
## Tactical input, animation and drawing. Host owns the outer game state.
const PassiveFeedback=preload("res://scripts/combat/mar_de_ferro/passive_feedback.gd")
const Rules = preload("res://scripts/combat/mar_de_ferro/tactics.gd")
const ActorMotion = preload("res://scripts/combat/mar_de_ferro/actor_motion.gd")
const SkillMotion = preload("res://scripts/combat/mar_de_ferro/skill_motion.gd")
const Onboarding = preload("res://scripts/combat/mar_de_ferro/combat_onboarding.gd")
const ORIGIN := Vector2(590,108)
const TILE := Vector2(37,18)
const GOLD := Color("e2b66c")
const JADE := Color("78c5af")
const RED := Color("df8370")
const PAPER := Color("eddfbb")
const MUTED := Color("9db3af")
const BG := Color("102c37")
const EDGE := Color("42616a")

var host: Node2D
var model: RefCounted
var phase := "choose"
var selected_skill := 0
var selected_cell := Vector2i(-1,-1)
var hover_cell := Vector2i(-1,-1)
var cursor_cell := Vector2i(-1,-1)
var facing := 0
var clock := 0.0
var duration := 1.5
var result: Dictionary = {}
var plan: Dictionary = {}
var defense_grades: Dictionary = {}
var defense_index := 0
var defense_beat := 0
var first_defense_grade := 0
var walk_path: Array[Vector2i] = []
var walk_actor := -1
var walking_enemy := false
var log_lines: Array[String] = []
var floats: Array = []
var passive_feedback=PassiveFeedback.new()
var quality_label := ""
var motion_clock := 0.0
var confirmation := false
var keys_cursor := false
var cached_reachable: Dictionary = {}
var pending: Dictionary = {}
var exploration_notice_time:=0.0
var hit_pause := 0.0
var lesson:=false
var learned: Dictionary={}
var seen_boss_phase:=1
var phase_notice:=""
var phase_notice_time:=0.0
var timing_center:=0.72
var timing_direction:=1
var timing_curve:="linear"
var timing_label:=""
var perfect_streak: Array=[0,0]
var skill_icons: Dictionary={}
var presentation=preload("res://scripts/combat/mar_de_ferro/skill_presentation.gd").new()
var battlefield=preload("res://scripts/combat/mar_de_ferro/battlefield_art.gd").new()
var detail_skill:=-1
var hovered_detail_skill:=-1
var move_history: Array[Dictionary]=[]
var onboarding=Onboarding.new()
var cutin=preload("res://scripts/combat/mar_de_ferro/technique_cutin.gd").new()
var cutin_resume:=""
var sequence_active:=false
var stream_grades: Array[int]=[]
var stream_resolved:=0
var stream_events: Array[Dictionary]=[]
var post_action_walk:=false

func setup(owner_node: Node2D, rules: RefCounted) -> void:
	host=owner_node; model=rules

func begin() -> void:
	cutin.clear(); cutin_resume=""; sequence_active=false; plan.clear()
	stream_grades.clear(); stream_events.clear(); stream_resolved=0; post_action_walk=false
	detail_skill=-1; hovered_detail_skill=-1
	passive_feedback.clear()
	selected_cell=Vector2i(-1,-1); floats.clear(); log_lines.clear(); result.clear()
	quality_label=""; clock=0; motion_clock=0; defense_beat=0; first_defense_grade=0
	timing_center=0.72; timing_direction=1; timing_curve="linear"; timing_label=""; perfect_streak=[0,0]
	pending.clear(); hit_pause=0; exploration_notice_time=7.0 if not model.exploration_notes.is_empty() else 0.0
	seen_boss_phase=1; phase_notice=""; phase_notice_time=0
	lesson=not host.practice_mode and ((model.encounter=="training" and not host.flags.training) or model.encounter=="prologue_raid")
	learned={"move":false,"attack":false,"facing":false,"defend":false,"posture":false,"combo":false,"cover":false}
	onboarding.reset(not host.practice_mode and model.encounter=="prologue_raid" and not host.flags.prologue,model.current_id)
	log_message("Clica em Mover, escolhe uma casa e confirma o caminho." if model.current().team==0 else "O adversário age primeiro. Observa a sua intenção.")
	arrive({"skip":false})
	onboarding.present("welcome")

func log_message(message: String) -> void:
	log_lines.append(message)
	if log_lines.size()>4: log_lines.pop_front()

func screen(cell: Vector2i) -> Vector2:
	return ORIGIN+Vector2((cell.x-cell.y)*TILE.x,(cell.x+cell.y)*TILE.y)

func cell_at(point: Vector2) -> Vector2i:
	var p:=point-ORIGIN
	return Vector2i(roundi((p.x/TILE.x+p.y/TILE.y)/2),roundi((p.y/TILE.y-p.x/TILE.x)/2))

func tile_points(cell: Vector2i, inset := 0.0) -> PackedVector2Array:
	var p:=screen(cell)
	return PackedVector2Array([p+Vector2(0,-TILE.y+inset),p+Vector2(TILE.x-inset,0),p+Vector2(0,TILE.y-inset),p+Vector2(-TILE.x+inset,0)])

func is_player() -> bool:
	return model.current_id>=0 and model.current().team==0

func refresh_paths() -> void:
	cached_reachable=model.reachable(model.current_id)

func arrive(info: Dictionary) -> void:
	collect_passive_feedback()
	move_history.clear()
	selected_cell=Vector2i(-1,-1); confirmation=false; keys_cursor=false
	observe_boss_phase()
	for event in model.turn_events:
		floats.append({"id":event.id,"text":event.text,"color":RED if int(event.get("damage",0))>0 else JADE,"life":1.6})
	if host.check_outcome(): return
	facing=model.current().face
	if info.get("skip",false):
		phase="skip"; clock=1.3; log_message(info.text)
	elif is_player():
		phase="choose"; refresh_paths(); cursor_cell=model.current().cell
		log_message("%s: %d casas, uma acção e uma técnica rápida."%[model.current().name,model.current().moves])
		if onboarding.seen.has("welcome") and model.current_id!=onboarding.first_actor: onboarding.present("duo")
	else:
		phase="enemy_wait"; clock=0.65

func next_turn() -> void:
	arrive(model.next_turn())

func cancel() -> bool:
	if detail_skill>=0: detail_skill=-1; return true
	if not onboarding.active.is_empty(): return false
	if phase in ["move","aim","facing","items"]:
		phase="choose"; selected_cell=Vector2i(-1,-1); confirmation=false; return true
	return false

func can_undo_move() -> bool:
	return is_player() and phase in ["choose","move","aim","facing","items"] and not move_history.is_empty() and int(move_history[-1].actor)==model.current_id

func undo_move() -> void:
	if not can_undo_move(): return
	var previous: Dictionary=move_history[-1]
	if not model.passable(previous.cell,model.current_id): return
	move_history.pop_back()
	var actor: Dictionary=model.current()
	actor.cell=previous.cell; actor.moves=previous.moves; actor.face=previous.face
	facing=actor.face; cursor_cell=actor.cell; hover_cell=actor.cell
	selected_cell=Vector2i(-1,-1); confirmation=false; keys_cursor=true
	walk_path.clear(); walk_actor=-1; phase="choose"; refresh_paths()
	log_message("Movimento desfeito. Escolhe um novo caminho.")

func input_event(event: InputEvent) -> void:
	if phase=="cutin":
		if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_ENTER: finish_cutin()
		return
	if detail_skill>=0:
		if event is InputEventKey and event.pressed and event.physical_keycode in [KEY_F,KEY_ESCAPE,KEY_ENTER]: detail_skill=-1
		elif event is InputEventMouseButton and event.pressed:
			if event.button_index==MOUSE_BUTTON_RIGHT: detail_skill=-1
			elif event.button_index==MOUSE_BUTTON_LEFT:
				for button in host.buttons:
					if button.id=="t_detail_close" and button.rect.has_point(host.get_global_mouse_position()): detail_skill=-1; return
		return
	if not onboarding.active.is_empty():
		if event is InputEventKey and event.pressed and not event.echo:
			if event.physical_keycode==KEY_ENTER: onboarding.dismiss()
		elif event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
			for button in host.buttons:
				if button.id in ["t_lesson_continue","t_lesson_skip"] and button.rect.has_point(host.get_global_mouse_position()):
					activate(button.id); return
		return
	if event is InputEventMouseMotion: keys_cursor=false
	if event is InputEventKey and event.pressed and not event.echo:
		var key: int=event.physical_keycode
		if phase.begins_with("timing"):
			if key==KEY_SPACE: commit_timing()
			return
		if key==KEY_F and is_player() and phase in ["choose","move","aim"]: open_details(); return
		if key==KEY_Z: undo_move(); return
		if phase=="items":
			if key in [KEY_1,KEY_2]: phase="choose"; select_skill(6 if key==KEY_1 else 7)
			return
		if not phase in ["choose","move","aim","facing"]: return
		if key>=KEY_1 and key<=KEY_9:
			if key==KEY_9 and not model.profile.is_empty(): open_items()
			else:
				var commands: Array=model.commands(model.current_id)
				var slot: int=key-KEY_1
				if slot<commands.size(): select_skill(commands[slot])
			return
		if key==KEY_TAB and phase=="aim": cycle_target(); return
		if key==KEY_R and phase=="choose": activate("t_optional"); return
		if key==KEY_B and phase=="choose": activate("t_loot"); return
		if key==KEY_G: select_move(); return
		if key==KEY_T: start_facing(); return
		if key==KEY_Q and phase=="facing": facing=(facing+3)%4; return
		if key==KEY_E and phase=="facing": facing=(facing+1)%4; return
		if key==KEY_ENTER: confirm(); return
		if key in [KEY_UP,KEY_DOWN,KEY_LEFT,KEY_RIGHT]:
			keys_cursor=true
			if phase=="aim" and model.skill_def(model.current_id,selected_skill).shape=="self":
				selected_cell=model.current().cell; cursor_cell=selected_cell; confirmation=true; return
			var delta:=Vector2i.ZERO
			match key:
				KEY_UP: delta=Vector2i(0,-1)
				KEY_DOWN: delta=Vector2i(0,1)
				KEY_LEFT: delta=Vector2i(-1,0)
				KEY_RIGHT: delta=Vector2i(1,0)
			cursor_cell=(cursor_cell+delta).clamp(Vector2i.ZERO,Rules.SIZE-Vector2i.ONE)
			selected_cell=cursor_cell; confirmation=true
	if event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_RIGHT: cancel(); return
		if event.button_index!=MOUSE_BUTTON_LEFT: return
		for b in host.buttons:
			if b.rect.has_point(host.get_global_mouse_position()) and b.has("inspect_skill") and not b.enabled:
				detail_skill=b.inspect_skill; return
			if b.rect.has_point(host.get_global_mouse_position()) and b.enabled:
				activate(b.id); return
		if not phase in ["choose","move","aim","facing"]: return
		var cell:=cell_at(host.get_global_mouse_position())
		if not model.inside(cell) or host.get_global_mouse_position().y>399: return
		if phase=="facing":
			if cell!=model.current().cell: facing=model.direction_index(cell-Vector2i(model.current().cell))
			return
		select_cell(cell,event.double_click)

func select_cell(cell: Vector2i, double_click := false) -> void:
	if not phase in ["choose","move","aim"] or not model.inside(cell): return
	if phase=="aim" and model.skill_def(model.current_id,selected_skill).shape=="self": cell=model.current().cell
	var execute: bool=double_click and confirmation and selected_cell==cell
	if phase=="choose": select_move()
	selected_cell=cell; cursor_cell=cell; confirmation=true
	if execute: confirm()

func activate(id: String) -> void:
	if phase=="cutin": return
	if id=="t_loot":
		if phase!="choose" or not is_player(): return
		var loot: Dictionary=model.collect_boss_loot()
		if loot.has("error"): host.notify_player(loot.error)
		else: log_message(loot.text)
		return
	if id=="t_detail_close": detail_skill=-1; return
	if id=="t_details": open_details(); return
	if id=="t_lesson_continue": onboarding.dismiss(); return
	if id=="t_lesson_skip": onboarding.skip(); return
	if id=="t_undo": undo_move(); return
	if id=="t_items": open_items(); return
	if id=="t_optional":
		if not is_player() or phase!="choose": return
		var extra: Dictionary=model.complete_optional()
		if extra.has("error"): host.notify_player(extra.error)
		else:
			move_history.clear(); log_message(extra.text); host.notify_player(extra.text)
		return
	if id.begins_with("t_item_"): phase="choose"; select_skill(int(id.trim_prefix("t_item_"))); return
	if id.begins_with("t_skill_"): select_skill(int(id.trim_prefix("t_skill_")))
	elif id=="t_move": select_move()
	elif id=="t_end": start_facing()
	elif id=="t_confirm": confirm()
	elif id=="t_cancel": cancel()
	elif id=="t_left": facing=(facing+3)%4
	elif id=="t_right": facing=(facing+1)%4

func open_items() -> void:
	if not is_player() or not phase in ["choose","aim","move"]: return
	if model.current().acted: host.notify_player("Já usaste a acção deste turno. Ainda podes mover e usar uma técnica rápida."); return
	phase="items"

func select_move() -> void:
	if not is_player() or not phase in ["choose","move","aim"]: return
	phase="move"; selected_cell=Vector2i(-1,-1); confirmation=false; refresh_paths()
	log_message("Escolhe uma casa verde. Confirma para percorrer o caminho.")

func select_skill(index: int) -> void:
	if not is_player() or not phase in ["choose","move","aim"]: return
	var reason: String=model.availability_reason(index)
	if not reason.is_empty():
		if index>=0 and not model.skill_def(model.current_id,index).is_empty(): detail_skill=index
		host.notify_player(reason); return
	selected_skill=index; phase="aim"; confirmation=false; quality_label=""
	var definition: Dictionary=model.skill_def(model.current_id,index)
	selected_cell=Vector2i(-1,-1)
	if definition.shape=="self": selected_cell=model.current().cell
	elif definition.shape in ["ally","friend"]:
		# Prefer the ally with the greatest useful recovery, never a full resource.
		var most_useful:=-1
		for unit in model.heroes:
			if not model.valid_attack(index,unit.cell): continue
			var preview: Dictionary=model.support_preview(model.current_id,index,unit.cell)
			var useful: int=preview.get("amount",0)
			if useful>most_useful: most_useful=useful; selected_cell=unit.cell
	confirmation=model.inside(selected_cell)
	if confirmation: cursor_cell=selected_cell
	log_message(definition.description)
	onboarding.present("actions")

func cycle_target() -> void:
	var candidates: Array[Vector2i]=[]
	if model.skill_def(model.current_id,selected_skill).get("shape","")=="leap":
		for y in Rules.SIZE.y:
			for x in Rules.SIZE.x:
				var cell:=Vector2i(x,y)
				if valid_target_cell(cell): candidates.append(cell)
	else:
		for unit in model.units:
			if unit.hp>0 and valid_target_cell(unit.cell): candidates.append(unit.cell)
	if candidates.is_empty(): host.notify_player("Sem alvo válido nesta posição. Move-te para abrir o alcance."); return
	var index:=candidates.find(selected_cell)
	selected_cell=candidates[(index+1)%candidates.size()]
	cursor_cell=selected_cell; keys_cursor=true; confirmation=true

func skill_key(actor: int, skill: int) -> String:
	var index: int=model.commands(actor).find(skill)
	return str(index+1) if index>=0 else ""

func action_kind(definition: Dictionary) -> String:
	return "rápida" if definition.get("quick",false) else "acção"

func valid_target_cell(cell: Vector2i) -> bool:
	if model.skill_def(model.current_id,selected_skill).shape=="self" and cell!=model.current().cell: return false
	return model.valid_attack(selected_skill,cell)

func start_facing() -> void:
	if not is_player() or not phase in ["choose","move","aim"]: return
	phase="facing"; facing=model.suggested_facing(model.current_id)
	log_message("Escolhe para onde ficas virado. Q / E roda; Enter termina.")
	onboarding.present("facing")

func confirm() -> void:
	if phase=="facing":
		learned.facing=true
		arrive(model.end_turn(facing)); return
	if phase=="move" and model.inside(selected_cell):
		var origin: Vector2i=model.current().cell
		var previous: Dictionary={"actor":model.current_id,"cell":origin,"moves":model.current().moves,"face":model.current().face}
		var path: Array[Vector2i]=model.move_to(selected_cell)
		if path.is_empty(): host.notify_player("Essa casa não está acessível com o movimento restante."); return
		move_history.append(previous)
		learned.move=true
		walk_path.assign([origin]); walk_path.append_array(path)
		walk_actor=model.current_id; walking_enemy=false; phase="walk"; clock=0
		host.tone(290,0.06)
	elif phase=="aim" and model.valid_attack(selected_skill,selected_cell):
		move_history.clear()
		if model.skill_def(model.current_id,selected_skill).get("ultimate",false):
			show_cutin(model.current(),model.skill_def(model.current_id,selected_skill).name,"player"); return
		if model.skill_def(model.current_id,selected_skill).shape in ["self","ally","friend"]:
			queue_player(1)
		else:
			phase="timing_attack"; clock=0; duration=attack_timing_duration(); prepare_timing(false); quality_label=""
			onboarding.present("attack")
			host.tone(410,0.07)
	elif phase=="aim": host.notify_player(model.attack_reason(selected_skill,selected_cell))

func grade_at(fraction: float) -> int:
	var position: float=timing_progress(fraction) if phase.begins_with("timing") else fraction
	var error:=absf(position-timing_center)
	var windows:=timing_windows()
	return 2 if windows.y>0.0 and error<=windows.y else (1 if error<=windows.x else 0)

func timing_windows() -> Vector2:
	if tutorial_timing(): return Vector2(0.23,0.09)
	var windows:=Vector2(0.23,0.09) if host.progress.data.options.wide_timing else (Vector2(0.13,0.04) if host.progress.data.options.get("difficulty","normal")=="challenging" else Vector2(0.16,0.052))
	if phase=="timing_attack" and is_player():
		var streak: int=perfect_streak[model.current_id]
		if model.has_passive(model.current_id,"steady_rhythm"):
			windows*=1.0+mini(streak,3)*0.08
	if phase=="timing_defend" and defense_index<plan.targets.size() and not plan.get("universal_parry",false):
		var side: String=model.flank(model.current_id,plan.targets[defense_index],plan.get("projectile_origin",Vector2i(-1,-1)))
		if side=="Flanco": windows*=0.82
		elif side=="Costas": windows=Vector2(windows.x*0.72,0.0)
	return windows

func tutorial_timing() -> bool:
	return model.encounter in ["prologue_raid","training"] and not host.practice_mode

func timing_progress(fraction: float) -> float:
	var progress:=clampf(fraction,0.0,1.0)
	if timing_curve=="accelerate": progress=progress*progress
	elif timing_curve=="brake": progress=sqrt(progress)
	return progress if timing_direction>0 else 1.0-progress

func prepare_timing(defending: bool) -> void:
	if not defending:
		timing_center=0.72; timing_direction=1; timing_curve="linear"; timing_label="Ritmo firme"
		return
	if tutorial_timing():
		timing_center=0.72; timing_direction=1; timing_curve="linear"; timing_label="Ritmo de aprendizagem"
		return
	var seed: int=model.current_id*11+model.current().turns*3+defense_index+model.round_no+defense_beat*7
	var kind: String=model.current().kind
	timing_curve=plan.get("timing_curve","accelerate" if kind in ["archer","rogue"] else ("brake" if kind in ["duelist","boss"] else "linear"))
	timing_label=("Tempo %d/%d"%[defense_beat+1,defense_beat_count()]) if double_defense_timing() else {"archer":"Tiro rápido","rogue":"Investida","duelist":"Finta","boss":"Golpe do mestre"}.get(kind,"Golpe anunciado")
	timing_center=[0.46,0.54,0.63,0.72,0.79][posmod(seed,5)]
	timing_direction=-1 if posmod(int(seed/5),2)==1 else 1

func begin_defense_timing() -> void:
	if plan.get("kind","")=="volley": begin_volley(); return
	phase="timing_defend"; clock=0; defense_beat=0; first_defense_grade=0; prepare_timing(true); duration=defense_timing_duration()
	onboarding.present("defense")

func defense_beat_count() -> int:
	if tutorial_timing(): return 1
	if plan.has("defense_beats"): return clampi(int(plan.defense_beats),1,5)
	if model.is_avelar(model.current_id): return 5 if plan.get("kind","")=="heavy" else 3
	if model.current().kind=="boss": return 5 if plan.get("kind","")=="heavy" else 3
	return 2 if model.current().kind in ["archer","duelist"] else 1

func double_defense_timing() -> bool:
	return defense_beat_count()>1

func attack_timing_duration() -> float:
	return 1.65 if tutorial_timing() else 1.50

func defense_timing_duration() -> float:
	if tutorial_timing(): return 1.75
	var attacker: Dictionary=model.current()
	var value: float=1.65 if plan.get("kind","")=="heavy" else (1.30 if plan.get("kind","")=="ranged" else 1.48)
	if int(attacker.get("speed",0))>=18: value-=0.10
	if host.progress.data.options.get("difficulty","normal")=="challenging": value-=0.08
	# Multiple targets are successive pressure rather than identical repeated bars.
	value-=float(defense_index)*0.05
	if double_defense_timing() and defense_beat>0: value-=0.12
	return clampf(value,0.90,1.70)

func commit_timing(forced := -1) -> void:
	if phase=="timing_volley": commit_volley(forced); return
	if not phase.begins_with("timing"): return
	var grade:=grade_at(clock/duration) if forced<0 else forced
	if host.has_method("record_playtest_timing"): host.record_playtest_timing(phase!="timing_attack",grade)
	quality_label=["FORA DE TEMPO","BOM TEMPO","PERFEITO"][grade]
	if phase=="timing_attack": host.tone([160,610,890][grade],0.1)
	if phase=="timing_attack":
		var actor: int=model.current_id
		if not tutorial_timing() and model.has_passive(actor,"steady_rhythm"):
			model.record_passive(actor,"steady_rhythm",{"timing_percent":mini(int(perfect_streak[actor]),3)*8})
		perfect_streak[actor]=int(perfect_streak[actor])+1 if grade==2 else 0
		learned.attack=true
		queue_player(grade)
	else:
		learned.defend=true
		if defense_beat==0: first_defense_grade=grade
		elif defense_beat_count()>2: first_defense_grade=mini(first_defense_grade,grade)
		else: first_defense_grade=2 if first_defense_grade==2 and grade==2 else (1 if first_defense_grade>0 or grade>0 else 0)
		if defense_beat+1<defense_beat_count():
			defense_beat+=1
			clock=0; prepare_timing(true); duration=defense_timing_duration()
			return
		grade=first_defense_grade
		defense_grades[plan.targets[defense_index]]=grade
		defense_index+=1
		defense_beat=0; first_defense_grade=0
		if defense_index<plan.targets.size(): clock=0; prepare_timing(true); duration=defense_timing_duration()
		else: queue_enemy(defense_grades)

func queue_player(grade: int) -> void:
	move_history.clear()
	pending={"enemy":false,"skill":selected_skill,"aim":selected_cell,"grade":grade}
	var definition: Dictionary=model.skill_def(model.current_id,selected_skill)
	var landing: Vector2i=model.current().cell
	if definition.shape=="leap": landing=selected_cell
	elif definition.get("flank_attack",false):
		var victim: int=model.unit_at(selected_cell)
		if victim>=0 and model.flank(model.current_id,victim)=="Frente":
			var destination: Vector2i=model.dash_destination(model.current_id,selected_cell,int(definition.range))
			if destination!=Vector2i(-1,-1): landing=destination
	start_animation({"actor":model.current_id,"skill":selected_skill,"cells":model.area(model.current_id,selected_skill,selected_cell),"hits":[],"text":definition.name,"movement_origin":model.current().cell,"movement_destination":landing},false)

func queue_enemy(grades: Dictionary) -> void:
	pending={"enemy":true,"plan":plan.duplicate(true),"grades":grades.duplicate()}
	start_animation({"actor":model.current_id,"skill":-5 if plan.kind=="heal" else (-2 if plan.kind=="heavy" else (-3 if plan.kind=="ranged" else (-4 if plan.kind in ["brace","charge","signal","recover","reclaim"] else -1))),"cells":plan.get("cells",[]),"hits":[],"text":model.current().name+" · "+plan.get("name","")},true)

func apply_impact() -> void:
	if not pending.is_empty():
		var source_cells: Dictionary=result.get("source_cells",{})
		if pending.enemy:
			result=model.resolve_sequence_step(pending.grades) if sequence_active else model.resolve_enemy(pending.plan,pending.grades)
		else: result=model.perform(pending.skill,pending.aim,pending.grade)
		result.source_cells=source_cells
		result.defense_grades=pending.get("grades",{}).duplicate()
		if not pending.enemy and not result.has("error") and host.has_method("record_playtest_action"):
			host.record_playtest_action(model.current_id,pending.skill)
		if result.get("cover",false): learned.cover=true
		pending.clear()
		log_message(result.get("text",""))
	collect_passive_feedback()
	observe_boss_phase()
	result.impacted=true
	for hit in result.get("hits",[]):
		if hit.get("breaks",false): learned.posture=true
		if hit.get("combo",false): learned.combo=true
	hit_pause=0.0 if sequence_active and plan.get("no_counter",false) else (0.065 if not result.get("hits",[]).is_empty() else 0.0)

func start_animation(data: Dictionary, enemy: bool) -> void:
	if enemy:
		for field in ["rope","bounce_cell","projectile_origin","lance_throw","lance_return","lance_end","unarmed"]:
			if plan.has(field): data[field]=plan[field]
	if data.has("error"): phase="choose"; host.notify_player(data.error); return
	data.source_cells={}
	for unit in model.units: data.source_cells[unit.id]=unit.cell
	result=data; phase="animate_enemy" if enemy else "animate_player"; clock=0
	host.combat_action_sound(result.skill,result.actor,"windup",plan if enemy else {})
	log_message(result.text)
	# Popups appear on impact, not before the wind-up.
	result.impacted=false

func presentation_speed() -> float:
	return 1.75 if host.progress.data.options.get("fast_combat",false) and not tutorial_timing() else 1.0

func update(delta: float) -> void:
	if phase=="cutin":
		if cutin.update(delta): finish_cutin()
		return
	if detail_skill>=0: return
	if not onboarding.active.is_empty(): return
	phase_notice_time=maxf(0,phase_notice_time-delta)
	if phase=="choose": exploration_notice_time=maxf(0,exploration_notice_time-delta)
	if hit_pause>0:
		var frozen:=minf(delta,hit_pause)
		hit_pause-=frozen; delta-=frozen
	passive_feedback.update(delta,passive_feedback_readable())
	motion_clock+=delta
	for f in floats: f.life-=delta
	floats=floats.filter(func(f): return f.life>0)
	if not keys_cursor: hover_cell=cell_at(host.get_global_mouse_position())
	else: hover_cell=cursor_cell
	if phase=="timing_volley":
		update_volley(delta)
	elif phase.begins_with("timing"):
		clock+=delta
		if clock>=duration: commit_timing(0)
	elif phase=="telegraph":
		clock-=delta
		if clock<=0: begin_defense_timing()
	elif phase=="walk":
		clock+=delta*presentation_speed()
		if clock>=0.14*(walk_path.size()-1):
			if post_action_walk:
				post_action_walk=false; next_turn()
			elif walking_enemy: enemy_action()
			else:
				phase="choose"; refresh_paths(); selected_cell=Vector2i(-1,-1)
				onboarding.present("undo")
	elif phase=="enemy_wait":
		clock-=delta*presentation_speed()
		if clock<=0:
			plan=model.ai_plan()
			if not plan.get("path",[]).is_empty():
				var origin: Vector2i=model.current().cell
				var path: Array[Vector2i]=model.move_to(plan.destination)
				walk_path.assign([origin]); walk_path.append_array(path)
				walk_actor=model.current_id; walking_enemy=true; phase="walk"; clock=0
			else: enemy_action()
	elif phase.begins_with("animate"):
		clock+=delta*(presentation_speed() if result.get("impacted",false) else 1.0)
		if clock>=ActorMotion.IMPACT and not result.impacted:
			apply_impact()
			for hit in result.get("hits",[]):
				var label: String="+%d"%-hit.damage if hit.damage<0 else ("APARADO" if hit.damage==0 else "−%d"%hit.damage)
				if hit.damage==0 and hit.get("pushed",false): label="SEM DANO"
				if hit.damage<0: label+={"hp":" VIDA","qi":" ALENTO","posture":" POSTURA"}.get(hit.get("resource","hp"),"")
				if hit.get("breaks",false): label+=" · QUEBRA"
				elif hit.get("stun",false): label+=" · ATORDOADO"
				elif hit.get("bleed",false): label+=" · SANGRAMENTO"
				if hit.get("pushed",false): label+=" · EMPURRÃO"
				var stacked: int=floats.filter(func(f): return f.id==hit.id and f.life>1.4).size()
				var healing_colour: Color={"qi":Color("74b5d0"),"posture":GOLD}.get(hit.get("resource","hp"),JADE)
				floats.append({"id":hit.id,"text":label,"color":healing_colour if hit.damage<0 else (GOLD if hit.side=="Contra-ataque" else PAPER),"life":1.5,"offset":stacked*17})
			host.combat_impact_sound(result,plan if phase=="animate_enemy" else {},result.get("defense_grades",{}))
		if clock>=1.35:
			if host.check_outcome(): return
			if phase=="animate_enemy":
				if sequence_active: advance_sequence()
				elif result.has("reposition_path"):
					walk_path.assign(result.reposition_path); walk_actor=result.actor; walking_enemy=true; post_action_walk=true; phase="walk"; clock=0
				else: next_turn()
			else:
				phase="choose"; selected_cell=Vector2i(-1,-1); refresh_paths()
				onboarding.present("resources")
	elif phase=="skip":
		clock-=delta*presentation_speed()
		if clock<=0:
			if sequence_active: advance_sequence()
			else: next_turn()

func enemy_action() -> void:
	if plan.get("kind","")=="sequence":
		show_cutin(model.current(),plan.name,"sequence"); return
	if plan.get("cinematic",false) and not plan.get("intro_shown",false):
		show_cutin(model.current(),plan.name,"enemy"); return
	if plan.kind in ["flee","burn","heal"]:
		queue_enemy({})
	elif plan.kind in ["approach","wait","reposition"]:
		if sequence_active: model.resolve_sequence_step({})
		log_message(model.current().name+" recua sem disparar: a pressão impediu o tiro." if plan.get("name","")=="Recuar sob pressão" else model.current().name+" procura uma abertura.")
		phase="skip"; clock=0.55
	elif plan.kind in ["charge","brace","signal","recover","reclaim"]: queue_enemy({})
	elif plan.get("targets",[]).is_empty():
		queue_enemy({})
		log_message("O golpe não encontrou um alvo.")
	else:
		phase="telegraph"; clock=0.58
		defense_grades.clear(); defense_index=0; quality_label=""
		log_message(model.current().name+" anuncia "+plan.name+". Lê o golpe antes do ritmo.")

func preview_cell() -> Vector2i:
	return selected_cell if confirmation and model.inside(selected_cell) else hover_cell

func draw() -> void:
	if battlefield.c==null: battlefield.setup(host)
	battlefield.draw_ground(model.encounter,motion_clock,host.progress.data.options.reduced_fx)
	draw_board()
	draw_header()
	draw_sidebar()
	if phase=="aim" and is_player(): draw_aim_hero_hud()
	draw_controls()
	if phase=="walk" and walking_enemy and plan.get("rope_swing",false) and not walk_path.is_empty():
		host.draw_line(screen(walk_path[0])+Vector2(0,-85),unit_position(walk_actor)+Vector2(0,-28),Color(GOLD,0.75),2,true)
	if phase.begins_with("animate") and result.get("rope",false):
		for cell in result.get("cells",[]): host.draw_line(screen(model.units[result.actor].cell)+Vector2(0,-30),screen(cell)+Vector2(0,-18),Color(GOLD,0.65),2,true)
	if phase.begins_with("animate") and result.has("bounce_cell"):
		var bank: Vector2=screen(result.bounce_cell)+Vector2(0,-18)
		host.draw_circle(bank,5,GOLD)
		for cell in result.get("cells",[]): host.draw_line(bank,screen(cell)+Vector2(0,-18),GOLD,2,true)
	for bag in model.boss_loot:
		var bag_position: Vector2=screen(bag.cell)
		host.draw_circle(bag_position,8,GOLD)
		host.text_at("B",bag_position+Vector2(-4,4),11,BG)
	if phase_notice_time>0:
		var alpha:=minf(1,phase_notice_time/0.35)
		host.draw_rect(Rect2(353,78,480,25),Color(BG,alpha*0.95))
		var boss_name: String="CATARINA" if model.encounter=="stronghold" else ("GUARDIÃO DA ROSA" if model.encounter=="vigia_guard" else "MESTRE DE FERRO")
		if model.encounter=="lisbon_avelar": boss_name="RUI DE AVELAR"
		if model.encounter=="ceuta_depot": boss_name="MESTRE DO PAGAMENTO"
		if model.encounter=="coast_yusuf": boss_name="CAPITÃO DA REPRESÁLIA"
		if model.encounter=="storm_mate": boss_name="IMEDIATO DE ESTEBAN"
		if model.encounter=="final_esteban": boss_name="ESTEBAN DE ALARCÓN"
		if model.encounter=="refuge_trial": boss_name="ECO DA PRIMEIRA MARÉ"
		host.centered(boss_name+" · "+phase_notice,95,12,Color(GOLD,alpha),593)
	if not onboarding.active.is_empty(): draw_onboarding()
	if detail_skill>=0: draw_details()
	if phase=="timing_volley": draw_volley_effects()
	for enemy in model.enemies:
		if enemy.hp>0 and enemy.get("lance_cell",Vector2i(-1,-1))!=Vector2i(-1,-1):
			var shaft: Vector2=screen(enemy.lance_cell)
			host.draw_line(shaft,shaft+Vector2(6,-40),GOLD,3,true)
			host.draw_colored_polygon(PackedVector2Array([shaft+Vector2(6,-47),shaft+Vector2(2,-37),shaft+Vector2(10,-39)]),PAPER)
			host.centered("LANÇA · RETORNO",shaft.y+15,9,GOLD,shaft.x)
	if phase=="cutin":
		host.buttons.clear()
		cutin.draw(host)

func draw_onboarding() -> void:
	var card: Dictionary=Onboarding.CARDS[onboarding.active]
	host.draw_rect(Rect2(0,0,960,540),Color(0.01,0.04,0.06,0.82))
	host.panel(Rect2(163,94,634,354),BG,GOLD)
	host.text_at("APRENDER EM COMBATE · %d / %d"%[onboarding.seen.size(),Onboarding.CARDS.size()],Vector2(189,121),11,JADE)
	host.text_at(card.title,Vector2(189,153),23,GOLD)
	host.text_at(card.cue,Vector2(189,181),14,PAPER)
	var y:=209.0
	for paragraph in card.lines:
		var text: String=String(paragraph).replace("%HERÓI%",model.current().name)
		for line in wrap_hint(text,582,14,4):
			host.text_at(line,Vector2(189,y),14,PAPER); y+=19
		y+=7
	host.text_at("A batalha está em pausa enquanto lês.",Vector2(189,389),11,MUTED)
	host.button("t_lesson_continue","Enter · Continuar",Rect2(189,405,245,30))
	host.button("t_lesson_skip","Saltar tutorial",Rect2(573,405,198,30))

func observe_boss_phase() -> void:
	for enemy in model.enemies:
		if Rules.Identity.is_boss(enemy) and enemy.boss_phase>seen_boss_phase:
			seen_boss_phase=enemy.boss_phase; phase_notice=model.boss_phase_name(enemy.id); phase_notice_time=2.8
			log_message(enemy.name+" mudou de fase: "+phase_notice+".")

func draw_header() -> void:
	host.panel(Rect2(16,12,222,61),BG,EDGE)
	var mission: Dictionary=model.objective_status()
	var header: String=mission.get("title","A PROVA DO CABO")
	if model.encounter=="prologue_raid": header="A NOITE SEM ESTRELAS"
	elif model.encounter=="lisbon_avelar": header="LISBOA · RUI DE AVELAR"
	elif model.encounter=="douro_blockade": header="BLOQUEIO DO DOURO"
	elif model.encounter=="saint_roman": header="SÃO ROMÃO · CAPELA"
	elif model.encounter=="stronghold": header="SÃO ROMÃO · CATARINA"
	elif model.encounter=="vigia_sentinel": header="ILHA DA VIGIA · GALERIA"
	elif model.encounter=="vigia_guard": header="ILHA DA VIGIA · GUARDIÃO DA ROSA"
	elif model.encounter=="ceuta_patrol": header="CEUTA · PORTA DA COSTA"
	elif model.encounter=="ceuta_hostages": header="CEUTA · PÁTIO DAS CORDAS"
	elif model.encounter=="ceuta_depot": header="CEUTA · ENTREPOSTO"
	elif model.encounter=="coast_convoy": header="COSTA · RETIRADA CIVIL"
	elif model.encounter=="coast_yusuf": header="COSTA · PASSAGEM DO SINAL"
	elif model.encounter=="storm_escort": header="MAR ABERTO · ESCOLTA"
	elif model.encounter=="storm_mate": header="MAR ABERTO · O IMEDIATO"
	elif model.encounter=="final_boarding": header="NAU DE ESTEBAN · ABORDAGEM"
	elif model.encounter=="final_esteban": header="MARÉ PARTILHADA · ESTEBAN"
	if model.encounter.begins_with("refuge_"): header="REFÚGIO · PROVA DA ROSA" if model.encounter=="refuge_trial" else "ORDEM · DEFESA DO ARQUIVO"
	if model.encounter.begins_with("cargo_"): header="CARGA · "+{"cargo_boarding":"ABORDAGEM","cargo_signals":"ANCORADOURO","cargo_return":"REGRESSO"}.get(model.encounter,"")
	if model.encounter.begins_with("cove_trial"):
		header="LASTRO · PROVA %d/4"%(4 if model.encounter=="cove_trial" else int(model.encounter.right(1)))
	host.text_at(header,Vector2(30,33),10,GOLD)
	if mission.is_empty(): host.text_at("RONDA %02d"%model.round_no,Vector2(30,58),19,PAPER)
	elif model.objective.kind=="protect": host.text_at("INTEGRIDADE %d/%d · R%02d"%[mission.value,mission.maximum,model.round_no],Vector2(30,57),14,PAPER)
	elif model.objective.kind=="escort": host.text_at("BARCA %d%% · %d CASAS · R%02d"%[int(float(mission.value)/float(mission.maximum)*100.0),mission.distance,model.round_no],Vector2(30,57),13,PAPER)
	elif model.objective.kind in ["changing_deck","duel_rescue"]: host.text_at("DUELO · R%02d"%model.round_no,Vector2(30,57),14,PAPER)
	else: host.text_at("SAÍDA: %d casa%s · R%02d"%[mission.value,"" if mission.value==1 else "s",model.round_no],Vector2(30,57),14,PAPER)
	if mission.is_empty(): host.text_at("ESC  Pausa",Vector2(155,56),10,MUTED)
	host.panel(Rect2(250,12,694,61),BG,EDGE)
	host.text_at("ORDEM POR INICIATIVA",Vector2(263,30),9,MUTED)
	var living_count: int=model.order.filter(func(id): return model.units[id].hp>0).size()
	var card_width:=initiative_card_width(living_count)
	var shown:=0
	for offset in model.order.size():
		var idx: int=(model.order_index+offset)%model.order.size()
		var id: int=model.order[idx]
		var u: Dictionary=model.units[id]
		if u.hp<=0: continue
		var x:=263+shown*card_width
		host.draw_rect(Rect2(x,37,card_width-8,26),Color("36575a") if shown==0 else Color("183c46"))
		host.draw_line(Vector2(x,63),Vector2(x+card_width-8,63),GOLD if shown==0 else (JADE if u.team==0 else RED),2)
		var label: String=host.fit_text(initiative_name(u,living_count>=8),card_width-35,11)
		host.text_at(label,Vector2(x+6,54),11,PAPER)
		host.text_at(str(u.speed),Vector2(x+card_width-27,54),10,GOLD)
		shown+=1

func initiative_card_width(living_count: int) -> float:
	return minf(112.0,floor(672.0/maxi(1,living_count)))

func initiative_name(u: Dictionary, compact: bool=false) -> String:
	if model.is_avelar(u.id): return "Avelar"
	if u.name=="Yusuf ibn Rami": return "Yusuf"
	if u.kind=="boss": return {"Mestre de Ferro":"Mestre","Grão-mestre do Lastro":"Lastro","Catarina":"Catarina","Guardião da Rosa":"Guardião","Mestre do pagamento":"Cobrador","Capitão de Esteban":"Capitão","Imediato de Esteban":"Imediato","Esteban de Alarcón":"Esteban"}.get(u.name,"Chefe")
	if u.get("disrupts_qi",false): return "Interr." if compact else "Interruptor"
	if u.team==0: return u.name
	if compact:
		if u.kind=="archer":
			var archers: Array=model.enemies.filter(func(enemy): return enemy.kind=="archer")
			return "Arco%d"%[archers.find(u)+1]
		return {"defender":"Def.","duelist":"Duel.","rogue":"Bat.","guard":"Gd.","boss":"Mestre","pikeman":"Pique","bombard":"Pólvora","medic":"Socorro"}.get(u.kind,u.name)
	if u.kind=="boss" and model.encounter=="cove_trial": return "Grão-mestre"
	if model.objective.get("kind","") in ["capture","protect"] and u.id==int(model.objective.get("actor_id",-1)):
		return "Mensageiro" if model.objective.kind=="capture" else "Incendiário"
	var names: Dictionary={"defender":"Defensor","archer":"Arqueira","duelist":"Duelista","rogue":"Batedor","guard":"Guarda","boss":"Mestre","pikeman":"Piqueiro","bombard":"Bombardeiro","medic":"Socorrista"}
	if u.kind=="archer": return "Interruptor" if u.get("disrupts_qi",false) else ("Arqueira" if u.name.begins_with("Arqueira") or u.name.begins_with("Atiradora") else "Arqueiro")
	return names.get(u.kind,u.name)

func draw_board() -> void:
	var preview:=preview_cell()
	var highlighted: Array=[]
	if phase=="aim": highlighted=model.area(model.current_id,selected_skill,preview)
	var aim_valid: bool=phase=="aim" and model.valid_attack(selected_skill,preview)
	var threats: Array=[]
	var following: Array=[]
	for u in model.units:
		if u.get("withdrawn",false): continue
		if u.hp>0 and u.charging: threats.append_array(u.warning)
		if u.hp>0: following.append_array(u.followup)
	var range_cells: Array[Vector2i]=[]
	if phase=="aim":
		var definition: Dictionary=model.skill_def(model.current_id,selected_skill)
		for y in Rules.SIZE.y:
			for x in Rules.SIZE.x:
				var cell:=Vector2i(x,y)
				var origin: Vector2i=model.current().cell
				if model.distance(origin,cell)>model.aim_range(model.current_id,selected_skill): continue
				if definition.shape=="line" and cell.x!=origin.x and cell.y!=origin.y: continue
				range_cells.append(cell)
	for y in Rules.SIZE.y:
		for x in Rules.SIZE.x:
			var cell:=Vector2i(x,y)
			var p:=screen(cell)
			var valid_cell: bool=phase=="aim" and valid_target_cell(cell)
			var reachable: bool=phase in ["choose","move"] and is_player() and cached_reachable.get("costs",{}).has(cell)
			var in_range: bool=range_cells.has(cell)
			var tile:=tile_points(cell,0)
			if phase=="aim" and not in_range: host.draw_colored_polygon(tile,Color(0.025,0.065,0.075,0.34))
			if reachable: host.draw_colored_polygon(tile_points(cell,2),Color(JADE,0.15 if phase=="move" else 0.07))
			if model.objective.get("kind","")=="capture" and cell==model.objective.exit: host.draw_colored_polygon(tile,Color(RED,0.20))
			if model.objective.get("kind","") in ["protect","escort"] and cell==model.objective.asset_cell: host.draw_colored_polygon(tile,Color(GOLD,0.20))
			var outline:=tile.duplicate(); outline.append(outline[0])
			var grid_alpha:=0.075
			if phase=="move" and reachable: grid_alpha=0.38
			elif phase=="aim" and in_range: grid_alpha=0.28
			host.draw_polyline(outline,Color(PAPER,grid_alpha),0.8,true)
			if phase=="aim" and in_range:
				var neighbours: Array[Vector2i]=[Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]
				for edge in 4:
					if not range_cells.has(cell+neighbours[edge]): host.draw_dashed_line(tile[edge],tile[(edge+1)%4],Color("b3d9df"),1.4,4,true,true)
			if model.obstacles.has(cell):
				host.draw_colored_polygon(tile_points(cell,3),Color(0.08,0.07,0.05,0.24))
				var base:=tile_points(cell,4); base.append(base[0]); host.draw_polyline(base,Color(GOLD,0.42),1,true)
				host.draw_line(p+Vector2(-4,10),p+Vector2(4,15),Color(PAPER,0.8),1.4,true)
				host.draw_line(p+Vector2(-4,15),p+Vector2(4,10),Color(PAPER,0.8),1.4,true)
			if highlighted.has(cell):
				host.draw_colored_polygon(tile_points(cell,2),Color(GOLD if aim_valid else MUTED,0.21))
				var ring:=tile_points(cell,3); ring.append(ring[0]); host.draw_polyline(ring,GOLD if aim_valid else MUTED,2,true)
			# Danger uses hatching and a cross, so gold targeting never erases it.
			if threats.has(cell):
				host.draw_colored_polygon(tile_points(cell,3),Color(RED,0.15))
				var hatch:=tile_points(cell,5)
				for i in range(1,4): host.draw_line(hatch[0].lerp(hatch[3],i/4.0),hatch[1].lerp(hatch[2],i/4.0),Color(RED,0.8),1.4,true)
				host.draw_circle(p+Vector2(0,8),6,Color(BG,0.92))
				host.draw_line(p+Vector2(-3,5),p+Vector2(3,11),RED,1.5,true)
				host.draw_line(p+Vector2(-3,11),p+Vector2(3,5),RED,1.5,true)
			if following.has(cell):
				host.draw_circle(p+Vector2(-17,0),6,Color(BG,0.95))
				host.text_at("2",p+Vector2(-20,3),9,GOLD)
			if reachable and phase=="move": host.draw_circle(p+Vector2(0,9),1.8,JADE)
			if valid_cell: host.draw_circle(p+Vector2(0,-8),2.5,JADE)
	if model.inside(preview) and phase in ["move","aim"]:
		var ring:=tile_points(preview,1); ring.append(ring[0]); host.draw_polyline(ring,RED if phase=="aim" and not aim_valid else PAPER,2)
	if phase=="move" and model.inside(preview):
		var path: Array[Vector2i]=model.path_to(model.current_id,preview)
		var last: Vector2=screen(model.current().cell)
		for i in path.size():
			var p:=screen(path[i])
			host.draw_line(last,p,JADE,2); host.draw_circle(p,3,PAPER)
			host.text_at(str(i+1),p+Vector2(5,-3),9,PAPER); last=p
	for hero in model.heroes:
		if hero.hp>0 and model.cover_info(hero.id,4).id>=0:
			var protector: int=model.cover_info(hero.id,4).id
			host.draw_line(screen(model.units[protector].cell),screen(hero.cell),Color(JADE,0.55),2)
	# Sort obstacles and characters by their projected feet, not array order.
	var objects: Array=[]
	for cell in model.obstacles: objects.append({"cell":cell,"obstacle":true,"id":-1})
	for u in model.units:
		if u.get("withdrawn",false): continue
		if u.hp>0 or (phase.begins_with("animate") and result.get("hits",[]).any(func(h): return h.id==u.id)):
			objects.append({"cell":u.cell,"obstacle":false,"id":u.id})
	objects.sort_custom(func(a,b): return a.cell.x+a.cell.y<b.cell.x+b.cell.y)
	for object in objects:
		var p:=screen(object.cell)
		if object.obstacle:
			if model.objective.get("kind","")=="escort" and object.cell==model.objective.asset_cell: draw_escort_boat(p)
			elif model.objective.get("kind","")=="protect" and object.cell==model.objective.asset_cell:
				if model.objective.get("asset_kind","")=="civilians":
					host.art.actor(p+Vector2(-12,0),"civilian",host.time)
					host.art.actor(p+Vector2(12,4),"civilian",host.time)
				else: draw_evidence(p)
			else: battlefield.draw_obstacle(model.encounter,object.cell,model.objective.get("deck_cells",[]).has(object.cell))
		else: draw_unit(object.id)
	draw_optional_marker()
	draw_objective_cue()
	if phase=="aim":
		draw_target_consequence()
		draw_aim_feedback()
	draw_map_legend(not threats.is_empty(),not following.is_empty())
	if phase.begins_with("animate"): draw_skill_effect()
	for actor in passive_feedback.pulses: draw_passive_badge(actor)
	for f in floats:
		var p:=unit_position(f.id)+Vector2(0,-53-(1.5-f.life)*23-f.get("offset",0))
		host.centered(f.text,p.y,12,f.color,p.x)

func draw_aim_feedback() -> void:
	var feedback: Dictionary=model.aim_feedback(model.current_id,selected_skill,preview_cell())
	if feedback.is_empty(): return
	var cell: Vector2i=feedback.cell
	var origin:=screen(model.current().cell)
	var point:=screen(cell)
	var ring:=tile_points(cell,2); ring.append(ring[0])
	host.draw_polyline(ring,RED,2.2,true)
	if feedback.kind=="range":
		var distance: int=model.distance(model.current().cell,cell)
		var end:=origin.lerp(point,minf(1.0,(float(feedback.range)+0.5)/maxi(1,distance)))
		host.draw_line(origin,end,Color("b3d9df"),1.5,true)
		host.draw_dashed_line(end,point,RED,1.8,5,true,true)
		var cross: Vector2=(point-origin).normalized().orthogonal()*7
		host.draw_line(end-cross,end+cross,RED,2,true)
	else:
		host.draw_dashed_line(origin,point,Color(RED,0.85),1.5,5,true,true)
		host.draw_line(point+Vector2(-6,-5),point+Vector2(6,5),RED,2,true)
		host.draw_line(point+Vector2(-6,5),point+Vector2(6,-5),RED,2,true)
	# A short anchored label remains within the map, outside the left HUD.
	var label: String=host.localization.text(feedback.label)
	var width: float=minf(270,host.font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,11).x+20)
	var at:=feedback_label_position(point,width)
	host.draw_line(point+Vector2(0,-12),at+Vector2(width*0.5,23),Color(RED,0.7),1,true)
	host.panel(Rect2(at,Vector2(width,24)),BG,RED)
	host.text_at(host.fit_text(label,width-16,11),at+Vector2(8,16),11,PAPER)

func feedback_label_position(point: Vector2, width: float) -> Vector2:
	var candidates: Array[Vector2]=[point+Vector2(-width*0.5,-108),point+Vector2(42,-26),point+Vector2(-width-42,-26),point+Vector2(-width*0.5,28)]
	var best:=Vector2.ZERO; var best_score:=INF
	for candidate in candidates:
		var at:=Vector2(clampf(candidate.x,427,938-width),clampf(candidate.y,83,365))
		var box:=Rect2(at,Vector2(width,24)).grow(4)
		var score:=box.get_center().distance_to(point)*0.01
		for unit in model.units:
			if unit.hp<=0 or unit.get("withdrawn",false): continue
			var silhouette:=Rect2(screen(unit.cell)-Vector2(44,90),Vector2(88,99))
			score+=box.intersection(silhouette).get_area()
		if score<best_score: best=at; best_score=score
	return best

func draw_map_legend(danger: bool, following: bool) -> void:
	if not is_player() or phase not in ["choose","move","aim"]: return
	var entries: Array=[]
	if phase=="aim": entries.append(["Limite de alcance",Color("b3d9df"),"range"]); entries.append(["Área atingida",GOLD,"area"])
	else: entries.append(["Movimento disponível",JADE,"move"])
	if danger: entries.append(["Golpe anunciado",RED,"danger"])
	if following: entries.append(["Segundo golpe",GOLD,"following"])
	if not danger and not following: entries.append(["Casa bloqueada",MUTED,"blocked"])
	host.draw_rect(Rect2(252,392,687,15),Color(BG,0.83))
	var x:=264.0
	for entry in entries:
		var p:=Vector2(x,400); var color: Color=entry[1]
		match entry[2]:
			"range": host.draw_dashed_line(p-Vector2(6,0),p+Vector2(6,0),color,1,3)
			"area": host.draw_polyline(PackedVector2Array([p+Vector2(0,-4),p+Vector2(6,0),p+Vector2(0,4),p+Vector2(-6,0),p+Vector2(0,-4)]),color,1,true)
			"move": host.draw_circle(p,2,color)
			"following": host.text_at("2",p+Vector2(-3,3),9,color)
			_:
				host.draw_line(p+Vector2(-3,-3),p+Vector2(3,3),color,1.4,true)
				host.draw_line(p+Vector2(-3,3),p+Vector2(3,-3),color,1.4,true)
		host.text_at(entry[0],p+Vector2(12,3),9,PAPER)
		x+=660.0/entries.size()

func draw_evidence(p: Vector2) -> void:
	var ratio: float=float(model.objective.hp)/maxf(1.0,float(model.objective.max_hp))
	host.draw_colored_polygon(PackedVector2Array([p+Vector2(-25,0),p+Vector2(0,12),p+Vector2(25,0),p+Vector2(0,-12)]),Color("8d6a45"))
	for i in 3:
		var at:=p+Vector2(-14+i*10,-12-i*2)
		host.draw_rect(Rect2(at,Vector2(16,11)),Color("e5d4a7"))
		host.draw_line(at+Vector2(3,4),at+Vector2(13,4),Color("705442"),1)
	host.bar(p+Vector2(-25,-31),Vector2(50,4),int(model.objective.hp),int(model.objective.max_hp),GOLD if ratio>0.34 else RED)
	host.centered("PROVAS",p.y+24,9,GOLD,p.x)

func draw_escort_boat(p: Vector2) -> void:
	var ratio:=float(model.objective.hp)/maxf(1.0,float(model.objective.max_hp))
	# Reuse the illustrated world boat on the same objective cell and depth layer.
	battlefield.sprite("boat",p+Vector2(0,15),Vector2(66,51))
	host.bar(p+Vector2(-26,-43),Vector2(52,4),int(model.objective.hp),int(model.objective.max_hp),JADE if ratio>0.45 else RED)
	host.centered("CIVIS",p.y+27,9,GOLD,p.x)

func objective_cue() -> Dictionary:
	var kind: String=model.objective.get("kind","")
	if kind=="escort":
		var actor_id: int=-1
		for enemy in model.enemies:
			if enemy.hp>0 and enemy.get("siege_actor",false): actor_id=enemy.id; break
		if actor_id<0: return {}
		var actor: Dictionary=model.units[actor_id]
		var intent: Dictionary=model.enemy_intent(actor_id)
		var active: bool=intent.get("plan_kind","")=="asset_attack"
		var label: String="BARCA: %d → %d DE DANO NO PRÓXIMO GOLPE"%[model.objective.hp,maxi(0,int(model.objective.hp)-int(model.objective.siege_damage))] if active else "BARCA CIVIL · AVANÇA QUANDO A ROTA ESTÁ LIVRE"
		return {"actor":actor_id,"target":model.objective.asset_cell,"route":[],"text":label,"active":active}
	if kind not in ["capture","protect"]: return {}
	var actor_id: int=int(model.objective.get("actor_id",-1))
	if actor_id<0 or actor_id>=model.units.size() or model.units[actor_id].hp<=0: return {}
	var actor: Dictionary=model.units[actor_id]
	var intent: Dictionary=model.enemy_intent(actor_id)
	if kind=="capture":
		var route: Array[Vector2i]=model.path_to(actor_id,model.objective.exit,Rules.SIZE.x*Rules.SIZE.y)
		var turns: int=int(ceil(float(route.size())/maxf(1.0,float(actor.movement))))
		var label: String="ROTA DE FUGA BLOQUEADA" if route.is_empty() and actor.cell!=model.objective.exit else "FUGA EM %d TURNO%s"%[turns+1,"" if turns==0 else "S"]
		return {"actor":actor_id,"target":model.objective.exit,"route":route,"text":label,"active":intent.plan_kind=="flee"}
	var damage: int=int(model.objective.get("damage",34))
	var asset: String="RETIRADA" if model.objective.get("asset_kind","")=="civilians" else "REGISTOS"
	var label: String="%s: %d → %d NO PRÓXIMO GOLPE"%[asset,model.objective.hp,maxi(0,int(model.objective.hp)-damage)] if model.distance(actor.cell,model.objective.asset_cell)==1 else "%s: −%d POR GOLPE"%[asset,damage]
	return {"actor":actor_id,"target":model.objective.asset_cell,"route":[],"text":label,"active":intent.plan_kind=="burn"}

func draw_optional_marker() -> void:
	if model.optional_objective.is_empty(): return
	var extra: Dictionary=model.optional_objective
	var position:=screen(extra.cell)
	var colour:=JADE if extra.completed else (GOLD if model.optional_status()=="Disponível" else MUTED)
	var ring:=tile_points(extra.cell,5); ring.append(ring[0]); host.draw_polyline(ring,colour,2,true)
	host.draw_circle(position+Vector2(0,-14),9,BG)
	host.centered("R" if not extra.completed else "✓",position.y-10,11,colour,position.x)

func draw_exploration_notice() -> void:
	host.panel(Rect2(16,287,222,109),BG,JADE)
	host.text_at("EXPLORAÇÃO · VANTAGEM",Vector2(29,307),10,JADE)
	var lines:=wrap_hint(" ".join(model.exploration_notes),197,11,4)
	for i in lines.size(): host.text_at(lines[i],Vector2(29,329+i*17),11,PAPER)

func draw_optional_sidebar() -> void:
	var extra: Dictionary=model.optional_objective
	host.panel(Rect2(16,287,222,109),BG,GOLD)
	host.text_at(host.fit_text("OPCIONAL · "+extra.title,197,10),Vector2(29,305),10,GOLD)
	var status: String=model.optional_status()
	var text: String=extra.detail if status=="Disponível" else status
	var lines:=wrap_hint(text,197,10,2)
	for i in lines.size(): host.text_at(lines[i],Vector2(29,323+i*14),10,PAPER)
	host.text_at("Até à ronda %d · usa a acção rápida"%extra.deadline if status=="Disponível" else "Sem penalizar o objectivo principal.",Vector2(29,364),9,MUTED)
	host.text_at("+%d ouro · %s"%[extra.gold,Rules.Catalog.ITEMS[extra.item].name],Vector2(29,383),10,JADE)

func draw_objective_cue() -> void:
	var cue: Dictionary=objective_cue()
	if cue.is_empty() or not cue.active: return
	var actor_pos: Vector2=screen(model.units[cue.actor].cell)
	var target_pos: Vector2=screen(cue.target)
	var route: Array=cue.route
	if not route.is_empty():
		var last: Vector2=actor_pos
		for cell in route:
			var next: Vector2=screen(cell)
			host.draw_line(last,next,Color(RED,0.72),2)
			last=next
	else: host.draw_line(actor_pos,target_pos,Color(RED,0.65),2)
	host.draw_arc(actor_pos+Vector2(0,-19),30,0,TAU,28,RED,2)
	host.draw_rect(Rect2(418,82,348,24),Color(BG,0.94))
	host.centered(cue.text,99,12,RED,592)

func target_badge(target: int) -> String:
	if phase!="aim" or target<0 or target>=model.units.size(): return ""
	if model.units[target].team==model.current().team: return ""
	var low: Dictionary=model.predict(model.current_id,target,selected_skill,0,preview_cell())
	var high: Dictionary=model.predict(model.current_id,target,selected_skill,2,preview_cell())
	if int(low.get("redirect",-1))>=0: return "INTERCEPTA"
	if low.get("last_stand",false): return "VENDAVAL"
	if target==int(model.objective.get("actor_id",-1)) and (low.lethal or low.breaks or low.stun): return "INTERROMPE"
	if low.lethal: return "DERROTA"
	if low.breaks: return "QUEBRA"
	if high.breaks: return "QUEBRA?"
	if high.stun: return "ATORDOA"
	if high.bleed: return "SANGRA"
	return "ATINGE"

func draw_target_consequence() -> void:
	var hits: Array=model.targets(model.current_id,model.area(model.current_id,selected_skill,preview_cell()))
	for i in mini(3,hits.size()):
		var target: int=hits[i]
		var label: String=target_badge(target)
		if label.is_empty(): continue
		var p: Vector2=screen(model.units[target].cell)
		var size: Vector2=Vector2(88,20)
		var at:=Vector2(clampf(p.x-size.x/2,250,858),maxf(111,p.y-83))
		host.draw_rect(Rect2(at,size),Color(BG,0.96))
		host.draw_rect(Rect2(at,size),JADE if label in ["INTERROMPE","DERROTA","QUEBRA"] else GOLD,false,1)
		host.centered(label,at.y+14,10,JADE if label in ["INTERROMPE","DERROTA","QUEBRA"] else GOLD,at.x+size.x/2)

func unit_position(id: int) -> Vector2:
	var p:=screen(model.units[id].cell)
	if phase=="walk" and walk_actor==id and walk_path.size()>1:
		var t:=clock/0.14
		var index:=clampi(int(t),0,walk_path.size()-2)
		p=screen(walk_path[index]).lerp(screen(walk_path[index+1]),clampf(t-index,0,1))
		if plan.get("rope_swing",false) and walking_enemy:
			p.y-=sin(clampf(clock/(0.14*(walk_path.size()-1)),0,1)*PI)*(12 if host.progress.data.options.reduced_fx else 34)
	if not phase.begins_with("animate"): return p
	if result.get("actor",-1)==id and result.has("reposition_path"): p=screen(result.reposition_path[0])
	if result.get("impacted",false) and result.get("hits",[]).any(func(hit): return hit.id==id and hit.get("pulled",false)):
		var source: Vector2i=result.get("source_cells",{}).get(id,model.units[id].cell)
		p=screen(source).lerp(p,smoothstep(ActorMotion.IMPACT,0.72,clock))
	if result.get("actor",-1)==id:
		var aim: Vector2=screen(selected_cell) if result.skill>=0 else (screen(plan.cells[0]) if not plan.get("cells",[]).is_empty() else p)
		var kind:=effect_kind(id,result.skill)
		var restrained: bool=host.progress.data.options.reduced_fx
		var origin: Vector2i=result.get("movement_origin",model.units[id].cell)
		var destination: Vector2i=result.get("movement_destination",origin)
		if kind=="leap":
			var flight:=clampf(clock/ActorMotion.IMPACT,0,1)
			p=screen(origin).lerp(screen(destination),flight)
			p.y-=sin(flight*PI)*(18 if restrained else 48)
		elif origin!=destination:
			p=screen(origin).lerp(screen(destination),SkillMotion.dash(clock))
		elif kind in ["cut","sweep","line","stun","bleed","breaker","hook"]:
			p+=(aim-p).normalized()*SkillMotion.recoil(kind,clock)*(0.45 if restrained else 1.0)
		elif kind=="heavy": p.y-=sin(clampf(clock/ActorMotion.IMPACT,0,1)*PI)*(5 if restrained else 10)
	return p

func visual_direction(id: int, fallback: Vector2) -> Vector2:
	if phase=="walk" and walk_actor==id and walk_path.size()>1:
		var index:=clampi(int(clock/0.14),0,walk_path.size()-2)
		return (screen(walk_path[index+1])-screen(walk_path[index])).normalized()
	if phase.begins_with("animate") and result.get("actor",-1)==id:
		var target: Vector2i=selected_cell
		if result.skill<0:
			target=plan.cells[0] if not plan.get("cells",[]).is_empty() else model.units[id].cell
		var origin: Vector2i=result.get("movement_origin",model.units[id].cell)
		if model.inside(target) and target!=origin:
			var destination: Vector2i=result.get("movement_destination",origin)
			if destination!=origin and effect_kind(id,result.skill)!="leap":
				var to_target:=screen(target)-unit_position(id)
				if to_target.length()>1: return to_target.normalized()
			return (screen(target)-screen(origin)).normalized()
	return fallback

func damage_reaction(id: int) -> float:
	if not phase.begins_with("animate") or not result.get("impacted",false): return 0.0
	if not result.get("hits",[]).any(func(h): return h.id==id and h.damage>0): return 0.0
	return ActorMotion.hurt_weight(clock-ActorMotion.IMPACT)

func draw_unit(id: int) -> void:
	var u: Dictionary=model.units[id]
	var p:=unit_position(id)
	draw_passive_pulse(id,p)
	var active: bool=id==model.current_id
	var unit_facing: int=facing if phase=="facing" and active else u.face
	var fv: Vector2i=Rules.DIRECTIONS[unit_facing]
	var v:=visual_direction(id,Vector2((fv.x-fv.y)*37,(fv.x+fv.y)*18).normalized())
	var col:=JADE if u.team==0 else RED
	var sprite_kind: String="esteban" if model.encounter=="final_esteban" and u.id==2 else u.kind
	if model.encounter=="refuge_trial" and u.id==2: sprite_kind="guardiao"
	sprite_kind={"signaller":"medic","boarder":"pikeman"}.get(sprite_kind,sprite_kind)
	sprite_kind=host.art.ActorCatalog.NAMED_COMBAT.get(u.name,sprite_kind)
	if u.kind=="archer" and u.name.begins_with("Arqueira"): sprite_kind="archer_woman"
	if model.encounter=="training" and u.kind=="guard": sprite_kind="bruma_guard"
	var detailed: bool=host.art.hero_frames.has(sprite_kind)
	if active:
		var ring:=tile_points(u.cell,3); ring.append(ring[0]); host.draw_polyline(ring,GOLD,2)
		host.centered("▼ "+u.name,p.y-(78 if detailed else 66),10,GOLD,p.x)
	var arrow:=p+v*24
	host.draw_colored_polygon(PackedVector2Array([arrow+v*5,arrow-v*4+v.orthogonal()*4,arrow-v*4-v.orthogonal()*4]),GOLD if active else col)
	var pose:=""
	var anim_time:=0.0
	if phase=="walk" and walk_actor==id: pose="walk"; anim_time=clock
	if phase.begins_with("animate") and result.get("actor",-1)==id:
		pose={"signal":"breathe","cut":"attack","sweep":"sweep","line":"thrust","stun":"crush","bleed":"draw_cut","cover":"guard","breaker":"crush","hook":"draw_cut","root":"guard","step":"step","breath":"breathe","heal":"cast","qi":"cast","brace":"guard","ranged":"shoot","heavy":"crush","leap":"crush","charge":"cast"}.get(effect_kind(id,result.skill),"attack")
		anim_time=clock
	if phase=="timing_volley" and id==model.current_id and not stream_events.is_empty():
		pose="attack" if plan.get("fencing",false) or plan.has("mirror_hero") else "shoot"; anim_time=maxf(0,clock-float(stream_events[-1].born))
	var reaction:=damage_reaction(id)
	if reaction>0:
		pose="hurt"; anim_time=maxf(0,clock-ActorMotion.IMPACT)
		if not host.progress.data.options.reduced_fx: p.x+=sin(anim_time*55)*3*reaction
	var manifestation: bool=model.encounter=="refuge_trial" and u.team==1
	if manifestation and u.hp>0: host.art.OrderAppearance.ring(host,p,1.5)
	var weapons_hidden: bool=host.art.map_npc_weaponless
	if model.encounter=="vigia_guard" and u.kind=="boss" and (u.lance_cell!=Vector2i(-1,-1) or plan.get("unarmed",false)): host.art.map_npc_weaponless=true
	host.art.actor(p,sprite_kind,motion_clock,active,v.x<0,1.9 if u.kind=="boss" else 1.65,u.hp<=0,pose,anim_time,Color(0.66,0.93,0.88,0.80) if manifestation else Color.WHITE)
	host.art.map_npc_weaponless=weapons_hidden
	var bw:=35.0
	var bar_y: int=-52 if detailed else (-41 if u.kind!="boss" else -48)
	host.bar(p+Vector2(-bw/2,bar_y),Vector2(bw,3),u.hp,u.max_hp,col)
	host.bar(p+Vector2(-bw/2,bar_y+5),Vector2(bw,2),u.posture,u.max_posture,GOLD)
	var status_y: float=p.y-(63 if detailed else 51)
	if u.stun>0: host.centered("ATORD.",status_y,9,GOLD,p.x)
	elif u.broken: host.centered("QUEBRA",status_y,9,GOLD,p.x)
	elif u.bleed>0: host.centered("SANGRA %d"%u.bleed,status_y,9,RED,p.x)
	elif u.get("exposed",false): host.centered("EXPOSTO",status_y,9,GOLD,p.x)
	elif model.cover_info(id,4).id>=0: host.centered("PROTEGIDA",status_y,9,JADE,p.x)
	elif u.get("fortitude_hits",0)>0: host.centered("RESISTÊNCIA %d%% · %d"%[u.fortitude,u.fortitude_hits],status_y,9,GOLD,p.x)
	elif int(u.get("hook_momentum_until",-1))>=u.turns: host.centered("ÍMPETO · +8 ÁREA",status_y,9,GOLD,p.x)
	elif u.kind=="signaller" and u.signal_pending and u.cell==u.signal_origin: host.centered("SINAL · INTERROMPER",status_y,9,GOLD,p.x)
	elif model.order_bonus(id)>0: host.centered("ORDEM · +6 PODER",status_y,9,GOLD,p.x)
	elif u.kind=="boarder": host.centered("GANCHO · 3 CASAS",status_y,9,RED,p.x)
	elif u.guard: host.centered("GUARDA",status_y,9,JADE,p.x)
	elif u.firm>0: host.centered("FIRME",status_y,9,GOLD,p.x)
	elif u.opening>0: host.centered("ABERTURA",status_y,9,JADE,p.x)
	if phase in ["timing_defend","timing_volley"] and not plan.targets.is_empty() and plan.targets[defense_index]==id:
		host.draw_arc(p+Vector2(0,-19),26,0,TAU,32,PAPER,2)
	if active and phase in ["timing_defend","timing_volley"]: host.centered("INIMIGO",p.y+21,9,RED,p.x)

func effect_kind(actor: int, skill: int) -> String:
	if skill<0:
		if skill==-5: return "heal"
		if skill==-4 and plan.get("kind","") in ["recover","reclaim"]: return "breath"
		if skill==-4 and model.units[actor].kind=="signaller": return "signal"
		if skill==-4: return "charge" if model.units[actor].kind in ["boss","bombard"] else "brace"
		if skill==-3: return "ranged"
		if skill==-2: return "heavy"
		return "cut"
	var definition: Dictionary=model.skill_def(actor,skill)
	if definition.get("hook",false): return "hook"
	if not definition.is_empty(): return definition.get("effect","cut")
	return "cut"

func effect_colour(kind: String) -> Color:
	return {"cut":PAPER,"sweep":JADE,"line":GOLD,"stun":Color("ba9ada"),"bleed":RED,"cover":JADE,"breaker":GOLD,"hook":GOLD,"root":GOLD,"step":Color("a4dfcf"),"breath":JADE,"heal":Color("9edc94"),"qi":Color("74b5d0"),"brace":JADE,"ranged":Color("efc68d"),"heavy":RED,"leap":GOLD}.get(kind,PAPER)

func effect_shield(centre: Vector2, radius: float, colour: Color, width: float) -> void:
	var points:=PackedVector2Array([centre+Vector2(-radius,-radius*0.65),centre+Vector2(0,-radius),centre+Vector2(radius,-radius*0.65),centre+Vector2(radius*0.8,radius*0.35),centre+Vector2(0,radius),centre+Vector2(-radius*0.8,radius*0.35),centre+Vector2(-radius,-radius*0.65)])
	host.draw_polyline(points,colour,width,true)

func impact_sparks(centre: Vector2, colour: Color, progress: float, count: int) -> void:
	for i in count:
		var direction:=Vector2.RIGHT.rotated(i*TAU/count+0.35)
		var at:=centre+direction*(5+progress*23)
		host.draw_line(at,at+direction*(5-progress*3),colour,1.5,true)

func draw_motion_trail(points: PackedVector2Array, window: Vector2, colour: Color, width: float, reduced: bool) -> void:
	var shown:=SkillMotion.subpath(points,window)
	if shown.size()<2 or colour.a<=0: return
	for i in range(1,shown.size()):
		var along:=i/float(shown.size()-1)
		var taper:=sin(along*PI)*0.7+0.3
		var ink:=Color(colour,colour.a*(0.3+along*0.7))
		if not reduced: host.draw_line(shown[i-1],shown[i],Color(ink,ink.a*0.16),width*taper+3,true)
		host.draw_line(shown[i-1],shown[i],ink,maxf(0.6,width*taper),true)

func draw_skill_travel(kind: String, actor: Vector2, aim: Vector2, direction: Vector2, tint: Color, reduced: bool) -> void:
	var alpha:=SkillMotion.trail_alpha(clock)*(0.65 if reduced else 1.0)
	var colour:=Color(tint,alpha)
	var window:=SkillMotion.path_window(clock,0.30,0.60,reduced)
	match kind:
		"cut","bleed":
			var radius:=42.0 if result.actor in [0,1] and Rules.Catalog.is_ultimate(result.skill) else 30.0
			draw_motion_trail(SkillMotion.slash_path(kind,aim,direction,radius),window,colour,3.0,reduced)
		"sweep":
			var radius:=clampf(actor.distance_to(aim),36,95)
			for cell in result.get("cells",[]): radius=maxf(radius,minf(95,actor.distance_to(screen(cell)+Vector2(0,-17))))
			var arc:=PackedVector2Array()
			for i in 33: arc.append(actor+Vector2.from_angle(direction.angle()-1.25+i/32.0*2.5)*radius)
			draw_motion_trail(arc,window,colour,3.5,reduced)
		"line":
			var last: Vector2=screen(result.cells[-1])+Vector2(0,-17) if not result.cells.is_empty() else aim
			var head:=SkillMotion.release(clock,0.30)
			var tail:=smoothstep(ActorMotion.IMPACT,0.72,clock)
			if head>tail:
				var tip:=actor.lerp(last,head)
				draw_motion_trail(PackedVector2Array([actor,last]),Vector2(tail,head),colour,3.0,reduced)
				var cross:=direction.orthogonal()*4
				host.draw_polyline(PackedVector2Array([tip-direction*9+cross,tip,tip-direction*9-cross]),colour,1.5,true)
		"ranged":
			if clock<ActorMotion.PROJECTILE_RELEASE or clock>ActorMotion.IMPACT: return
			var flight:=SkillMotion.projectile(clock)
			var release_point:=actor+direction*10+Vector2(0,-3)
			var tip:=release_point.lerp(aim,flight)
			var length:=minf(22,release_point.distance_to(tip))
			host.draw_line(tip-direction*length,tip,Color(BG,0.85),2.8,true)
			host.draw_line(tip-direction*length,tip,Color(tint,0.95),1.3,true)
			var arrowhead:=PackedVector2Array([tip-direction*5+direction.orthogonal()*2,tip,tip-direction*5-direction.orthogonal()*2])
			host.draw_polyline(arrowhead,Color(BG,0.85),2.5,true)
			host.draw_polyline(arrowhead,Color(PAPER,0.95),1.2,true)
		"stun","breaker","heavy":
			var fall:=SkillMotion.release(clock,0.30)
			var end:=smoothstep(ActorMotion.IMPACT,0.66,clock)
			var path:=PackedVector2Array([aim+Vector2(-8,-38),aim+Vector2(-4,-18),aim,aim+Vector2(7,12)])
			draw_motion_trail(path,Vector2(end*0.85,fall),colour,4.0,reduced)
		"leap":
			if clock<0.25: return
			var ground:=screen(result.get("movement_destination",selected_cell))
			var fall:=SkillMotion.release(clock,0.25)
			draw_motion_trail(PackedVector2Array([ground+Vector2(0,-46),ground]),Vector2(smoothstep(ActorMotion.IMPACT,0.64,clock),fall),colour,3.0,reduced)
		"hook":
			var extend:=SkillMotion.release(clock,0.29)
			var retract:=smoothstep(ActorMotion.IMPACT,0.72,clock)
			var tip:=actor.lerp(aim,extend*(1-retract))
			if tip.distance_to(actor)>3:
				host.draw_line(actor,tip,colour,2,true)
				var hook:=PackedVector2Array([tip-direction*7-direction.orthogonal()*5,tip+direction.orthogonal()*5,tip+direction*4,tip-direction.orthogonal()*3])
				host.draw_polyline(hook,colour,2,true)
		"step":
			var origin:=screen(result.get("movement_origin",model.units[result.actor].cell))+Vector2(0,-17)
			if origin.distance_to(actor)>2:
				if not reduced: host.draw_line(origin,actor,Color(tint,alpha*0.22),2,true)
				if result.skill>=0 and model.skill_def(result.actor,result.skill).get("flank_attack",false):
					draw_motion_trail(SkillMotion.slash_path("cut",aim,direction,24),window,colour,2.5,reduced)

func draw_ground_wave(ground: Vector2, radius: float, progress: float, colour: Color, width:=2.0) -> void:
	var wave:=PackedVector2Array()
	for i in 33:
		var angle:=TAU*i/32.0
		wave.append(ground+Vector2(cos(angle),sin(angle)*0.48)*radius*(0.25+progress*0.75))
	host.draw_polyline(wave,colour,width,true)

func draw_skill_effect() -> void:
	if result.is_empty(): return
	var kind:=effect_kind(result.actor,result.skill)
	var actor:=unit_position(result.actor)+Vector2(0,-17)
	var aim: Vector2=screen(selected_cell)+Vector2(0,-17) if result.skill>=0 and model.inside(selected_cell) else (screen(plan.cells[0])+Vector2(0,-17) if not plan.get("cells",[]).is_empty() else actor)
	if kind in ["root","step","breath","brace"] and not (result.skill>=0 and model.skill_def(result.actor,result.skill).get("flank_attack",false)): aim=actor
	var reduced: bool=host.progress.data.options.reduced_fx
	var tint:=effect_colour(kind)
	if result.actor in [0,1]: tint=tint.lerp(JADE if result.actor==0 else RED,0.2)
	if kind in ["charge","signal"]: tint=RED
	var direction: Vector2=(aim-actor).normalized()
	if direction==Vector2.ZERO: direction=visual_direction(result.actor,Vector2.RIGHT)
	if result.actor in [0,1] and Rules.Catalog.is_ultimate(result.skill): draw_supreme_signature(actor,aim,reduced)
	if result.get("lance_throw",false) or result.get("lance_return",false):
		var source: Vector2=screen(result.get("projectile_origin",result.get("source_cells",{}).get(result.actor,model.units[result.actor].cell)))+Vector2(0,-20)
		var end: Vector2=screen(result.get("lance_end",model.units[result.actor].cell))+Vector2(0,-20)
		var point: Vector2=source.lerp(end,SkillMotion.projectile(clock))
		var axis: Vector2=(end-source).normalized()
		host.draw_line(source,point,Color(GOLD,0.4),1,true)
		if clock>=0.28 and clock<=0.65:
			host.draw_line(point-axis*29,point,GOLD,3,true); host.draw_circle(point,3,PAPER)
		if clock>=ActorMotion.IMPACT:
			for hit in result.get("hits",[]): impact_sparks(unit_position(hit.id)+Vector2(0,-18),GOLD,clampf((clock-ActorMotion.IMPACT)/0.4,0,1),3)
		return
	if clock<ActorMotion.IMPACT: draw_skill_anticipation(kind,actor,aim,direction,clock/ActorMotion.IMPACT,tint,reduced)
	if result.has("bounce_cell") and kind=="ranged":
		var bank: Vector2=screen(result.bounce_cell)+Vector2(0,-17)
		var flight: float=SkillMotion.projectile(clock)
		var first_leg: float=actor.distance_to(bank)/maxf(1,actor.distance_to(bank)+bank.distance_to(aim))
		var point: Vector2=actor.lerp(bank,clampf(flight/maxf(0.01,first_leg),0,1)) if flight<first_leg else bank.lerp(aim,clampf((flight-first_leg)/maxf(0.01,1-first_leg),0,1))
		var axis: Vector2=(bank-actor).normalized() if flight<first_leg else (aim-bank).normalized()
		if clock>0.28 and clock<=ActorMotion.IMPACT:
			host.draw_line(point-axis*13,point,GOLD,2,true)
			host.draw_circle(point,2,PAPER)
	else: draw_skill_travel(kind,actor,aim,direction,tint,reduced)
	if clock<ActorMotion.IMPACT: return
	var progress:=SkillMotion.settling(clock)
	var opacity: float=(1-progress)*(0.6 if reduced else 1.0)
	if opacity<=0: return
	var colour:=Color(tint,opacity)
	var soft:=Color(tint,opacity*0.4)
	var contact:=SkillMotion.contact(clock)
	match kind:
		"charge","signal":
			draw_ground_wave(actor+Vector2(0,17),43,progress,colour)
			if kind=="signal" and not reduced:
				for offset in [-8,8]: host.draw_line(actor+Vector2(offset,-30-progress*15),actor+Vector2(offset,-15-progress*15),soft,1.5,true)
		"stun":
			for i in (1 if reduced else 3):
				var star:=aim+Vector2(cos(progress*4+i*TAU/3)*16,-24+sin(progress*4+i*TAU/3)*5)
				host.draw_line(star-Vector2(3,0),star+Vector2(3,0),colour,1.5,true)
				host.draw_line(star-Vector2(0,3),star+Vector2(0,3),colour,1.5,true)
		"breaker","heavy":
			var cells: Array=result.get("cells",[])
			if kind=="breaker": cells=[selected_cell]
			for cell in cells:
				var ground:=screen(cell)
				draw_ground_wave(ground,32 if kind=="breaker" else 40,progress,soft)
				if not reduced:
					for side in [-1,1]:
						var crack:=PackedVector2Array([ground,ground+Vector2(side*7,-3),ground+Vector2(side*15,2),ground+Vector2(side*23,-1)])
						var shown:=SkillMotion.subpath(crack,Vector2(0,smoothstep(0,0.22,clock-ActorMotion.IMPACT)))
						if shown.size()>1: host.draw_polyline(shown,soft,1.5,true)
		"cover":
			effect_shield(aim,20+progress*3,colour,2)
			if not reduced: host.draw_line(actor,aim,Color(tint,opacity*0.15),1,true)
		"root","brace":
			effect_shield(actor,20,colour,2)
			draw_ground_wave(actor+Vector2(0,17),25,progress,soft,1.5)
		"step":
			var origin:=screen(result.get("movement_origin",model.units[result.actor].cell))+Vector2(0,1)
			if not reduced: host.draw_line(origin,actor+Vector2(0,18),soft,1.5,true)
			draw_ground_wave(actor+Vector2(0,17),25,progress,soft,1.5)
		"breath":
			draw_ground_wave(actor+Vector2(0,17),27,progress,soft)
			host.draw_arc(actor,7+progress*18,0,TAU,24,colour,1.5,true)
		"heal","qi":
			draw_ground_wave(aim+Vector2(0,17),25,progress,soft,1.5)
			for i in (1 if reduced else 3):
				var point:=aim+Vector2(sin(i*2.4)*13,-smoothstep(0,1,progress)*25+i%2*8)
				var ink:=Color(tint,opacity*(0.6+i*0.15))
				if kind=="heal":
					host.draw_line(point-Vector2(3,0),point+Vector2(3,0),ink,1.5,true)
					host.draw_line(point-Vector2(0,3),point+Vector2(0,3),ink,1.5,true)
				else:
					host.draw_polyline(PackedVector2Array([point+Vector2(0,-4),point+Vector2(3,0),point+Vector2(0,4),point+Vector2(-3,0),point+Vector2(0,-4)]),ink,1.5,true)
		"leap":
			var ground:=screen(result.get("movement_destination",selected_cell))
			draw_ground_wave(ground,64,progress,colour)
			if not reduced: draw_ground_wave(ground,40,progress,soft,1.5)
	var signature_aim:=screen(selected_cell)+Vector2(0,-17) if kind=="step" and model.inside(selected_cell) else aim
	draw_technique_signature(actor,signature_aim,progress,colour,reduced)
	for hit in result.get("hits",[]):
		var centre:=unit_position(hit.id)+Vector2(0,-18)
		if hit.get("breaks",false):
			effect_shield(centre,17+progress*20,Color(GOLD,opacity*0.35),1)
		if hit.side=="Contra-ataque" or (hit.damage==0 and hit.get("resource","").is_empty()):
			host.draw_arc(centre,12+progress*15,0,TAU,24,Color(GOLD,opacity),1.5,true)
		elif hit.damage>0 and contact>0:
			impact_sparks(centre,Color(tint,contact*(0.6 if reduced else 1.0)),1-contact,2 if reduced else (7 if kind in ["heavy","breaker","leap"] else 4))

func draw_technique_signature(actor: Vector2, aim: Vector2, progress: float, colour: Color, reduced: bool) -> void:
	if result.actor not in [0,1] or result.skill<0: return
	var d: Dictionary=model.skill_def(result.actor,result.skill)
	var signature: String=d.get("signature","")
	var ground:=aim+Vector2(0,17)
	var soft:=Color(colour,colour.a*0.55)
	match signature:
		"anchor":
			host.draw_arc(ground,10+progress*18,0,PI,24,colour,2,true)
			host.draw_line(ground+Vector2(-14,0),ground+Vector2(14,0),soft,2,true)
		"guard_break":
			for side in [-1,1]:
				var offset:=Vector2(side*(5+progress*16),0)
				host.draw_polyline(PackedVector2Array([aim+offset+Vector2(0,-20),aim+offset+Vector2(side*14,-12),aim+offset+Vector2(side*10,7),aim+offset+Vector2(0,16)]),colour,2,true)
		"heavy_commit":
			var radius:=12+progress*35
			draw_ground_wave(ground,radius,progress,soft,3.0 if not reduced else 1.0)
			host.draw_line(aim+Vector2(-12,-34),ground+Vector2(8,2),Color(colour,colour.a*SkillMotion.contact(clock)),3,true)
		"reach_step","opening_step","expose_step","escape_step":
			var origin: Vector2=screen(result.get("movement_origin",model.units[result.actor].cell))+Vector2(0,-17)
			if not reduced: host.draw_line(origin,actor,soft,2,true)
			if signature=="opening_step":
				for offset in [-5,5]: host.draw_line(aim+Vector2(-17,offset+12),aim+Vector2(18,offset-16),colour,2,true)
			elif signature=="expose_step":
				var r:=12+progress*12
				host.draw_polyline(PackedVector2Array([aim+Vector2(-r,0),aim+Vector2(0,-r),aim+Vector2(r,0),aim+Vector2(0,r),aim+Vector2(-r,0)]),colour,2,true)
			elif signature=="escape_step":
				var foot:=actor+Vector2(-8-progress*16,18)
				host.draw_polyline(PackedVector2Array([foot+Vector2(9,-5),foot,foot+Vector2(9,5)]),colour,2,true)
			else: host.draw_line(actor,aim,colour,2,true)

func draw_supreme_signature(actor: Vector2, aim: Vector2, reduced: bool) -> void:
	var d: Dictionary=model.skill_def(result.actor,result.skill)
	var before:=clock<0.45
	var progress:=clampf(clock/0.45 if before else (clock-0.45)/0.7,0,1)
	var alpha: float=(0.25+progress*0.35 if before else (1-progress)*0.8)*(0.6 if reduced else 1.0)
	var colour:=Color(JADE if result.actor==0 else RED,alpha)
	var centre:=actor if before else aim
	var radius: float=18+progress*(16 if before else 46)
	var wave:=PackedVector2Array()
	for i in 41:
		var angle:=TAU*i/40.0
		wave.append(centre+Vector2(cos(angle)*radius,sin(angle)*radius*0.48))
	host.draw_polyline(wave,colour,2 if reduced else 3,true)
	if d.get("requires_partner",false) and model.units[1-result.actor].hp>0:
		var partner:=screen(model.units[1-result.actor].cell)+Vector2(0,-17)
		host.draw_line(partner,actor,Color(GOLD,alpha*0.7),1 if reduced else 2,true)
		if not reduced: effect_shield(partner,14,Color(GOLD,alpha),1)

func draw_skill_anticipation(kind: String, actor: Vector2, aim: Vector2, direction: Vector2, progress: float, tint: Color, reduced: bool) -> void:
	var gather:=smoothstep(0,0.65,progress)
	var alpha: float=(0.14+gather*0.28)*(1-smoothstep(0.68,1,progress))*(0.6 if reduced else 1.0)
	var colour:=Color(tint,alpha)
	var cross:=direction.orthogonal()
	for cell in result.get("cells",[]):
		var outline:=tile_points(cell,7); outline.append(outline[0])
		host.draw_polyline(outline,Color(tint,(0.12+gather*0.10)*(0.6 if reduced else 1.0)),1,true)
	match kind:
		"line","ranged","hook":
			host.draw_line(actor-direction*(6+gather*9),actor+direction*10,colour,1.5,true)
			if not reduced:
				for side in [-1,1]: host.draw_line(actor+cross*side*(12-gather*5),actor+direction*10+cross*side*3,colour,1,true)
		"cut","bleed","sweep","step":
			if not reduced: host.draw_arc(actor,14+gather*5,direction.angle()-1.8,direction.angle()-1.0,12,colour,1.5,true)
		"stun","breaker","heavy","charge","leap","signal":
			host.draw_arc(actor+Vector2(0,-19),5+gather*4,-PI*0.9,-PI*0.1,16,colour,1.5,true)
		"cover":
			effect_shield(aim,8+gather*10,Color(tint,(0.16+gather*0.24)*(0.6 if reduced else 1.0)),1)
			var bead:=actor.lerp(aim,SkillMotion.release(clock,0.08))
			host.draw_circle(bead,2,Color(tint,0.55 if reduced else 0.8))
			if not reduced: host.draw_line(actor,bead,colour,1,true)
		"root","brace":
			effect_shield(actor,9+gather*10,Color(tint,(0.16+gather*0.24)*(0.6 if reduced else 1.0)),1)
		"breath":
			host.draw_arc(actor,22-gather*13,0,TAU,24,Color(tint,(0.2+gather*0.25)*(0.6 if reduced else 1.0)),1,true)
		"heal","qi":
			var bead:=actor.lerp(aim,SkillMotion.release(clock,0.10))
			host.draw_circle(bead,2,Color(tint,0.55 if reduced else 0.8))
			host.draw_arc(aim,16-gather*6,0,TAU,24,colour,1,true)

func collect_passive_feedback() -> void:
	passive_feedback.push(model.drain_passive_feedback())

func passive_feedback_readable() -> bool:
	return phase in ["choose","animate_player","animate_enemy","enemy_wait","skip","facing"]

func draw_passive_feedback() -> void:
	var page: Dictionary=passive_feedback.pages[0]
	host.panel(Rect2(16,287,222,109),BG,JADE)
	host.text_at("EFEITOS DE EQUIPAMENTO" if page.rows.any(func(row): return Rules.Catalog.ITEMS.has(row.passive)) else "PASSIVAS ACTIVADAS",Vector2(29,303),10,JADE)
	if passive_feedback.pages.size()>1:
		host.text_at("+%d"%(passive_feedback.pages.size()-1),Vector2(206,303),9,MUTED)
	for i in page.rows.size():
		var row: Dictionary=page.rows[i]
		var y: float=321+i*35
		var tint:=PassiveFeedback.colour(row.effects)
		var name: String=model.units[row.actor].name+" · "+Rules.Catalog.combat_effect_def(row.passive).name
		host.draw_rect(Rect2(23,y-10,2,29),tint)
		host.text_at(host.fit_text(name,195,10),Vector2(29,y),10,PAPER)
		var lines:=wrap_hint(PassiveFeedback.summary(row,host.localization),195,9,2)
		for j in lines.size(): host.text_at(lines[j],Vector2(29,y+12+j*10),9,tint)
	var progress: float=clampf(float(page.life)/PassiveFeedback.HOLD,0,1)
	host.draw_rect(Rect2(24,392,206*progress,2),Color(JADE,0.5))

func draw_passive_pulse(actor: int, position: Vector2) -> void:
	if not passive_feedback.pulses.has(actor): return
	var pulse: Dictionary=passive_feedback.pulses[actor]
	var progress: float=1.0-float(pulse.life)/1.25
	var reduced: bool=host.progress.data.options.reduced_fx
	var tint:=PassiveFeedback.colour(pulse.effects)
	tint.a=minf(1,float(pulse.life)*3)
	var radius: float=23 if reduced else 20+progress*15
	var ring:=PackedVector2Array()
	for i in 41:
		var angle: float=TAU*i/40.0
		ring.append(position+Vector2(cos(angle)*radius,sin(angle)*radius*0.48))
	host.draw_polyline(ring,tint,1.5,true)

func draw_passive_badge(actor: int) -> void:
	var pulse: Dictionary=passive_feedback.pulses[actor]
	var tint:=PassiveFeedback.colour(pulse.effects)
	tint.a=minf(1,float(pulse.life)*3)
	var badge:=unit_position(actor)+Vector2(28,-22)
	host.draw_circle(badge,9,BG)
	host.draw_arc(badge,9,0,TAU,24,tint,1.5,true)
	host.centered(PassiveFeedback.symbol(pulse.effects),badge.y+4,12,tint,badge.x)

func draw_enemy_attributes(actor: int) -> void:
	var enemy: Dictionary=model.units[actor]
	var intent: Dictionary=model.enemy_intent(actor)
	host.panel(Rect2(16,86,222,310),BG,RED)
	host.text_at("INSPECÇÃO DO ADVERSÁRIO",Vector2(29,106),10,GOLD)
	host.text_at(host.fit_text(enemy.name,196,16),Vector2(29,130),16,PAPER)
	host.text_at(model.role_name(actor),Vector2(29,150),11,MUTED)
	var rows: Array=["Vida %d/%d · postura %d/%d"%[enemy.hp,enemy.max_hp,enemy.posture,enemy.max_posture],"Iniciativa %d · movimento %d"%[enemy.speed,enemy.movement],"Dano ×%.2f · quebra ×%.2f"%[enemy.get("challenge_power",1.0),enemy.get("posture_pressure",1.0)]]
	for i in rows.size(): host.text_at(host.fit_text(rows[i],196,11),Vector2(29,174+i*20),11,PAPER)
	host.text_at("PERFIL E RESPOSTA",Vector2(29,239),10,GOLD)
	var weakness: Array[String]=wrap_hint(model.EnemyAttributes.weakness(enemy.kind),195,11,2)
	for i in weakness.size(): host.text_at(weakness[i],Vector2(29,258+i*16),11,JADE)
	host.text_at(host.fit_text(intent.title,195,11),Vector2(29,302),11,GOLD)
	var lines: Array[String]=wrap_hint(intent.detail,195,10,4)
	for i in lines.size(): host.text_at(lines[i],Vector2(29,322+i*16),10,PAPER)

func draw_sidebar() -> void:
	if phase=="aim":
		draw_preview_sidebar()
		return
	var inspected: int=model.unit_at(hover_cell) if model.inside(hover_cell) else -1
	if phase=="choose" and inspected>=0 and model.units[inspected].team==1 and passive_feedback.pages.is_empty():
		draw_enemy_attributes(inspected); return
	var u: Dictionary=model.current()
	host.panel(Rect2(16,86,222,198),BG,GOLD if is_player() else RED)
	host.text_at("A TUA VEZ" if is_player() else "TURNO INIMIGO",Vector2(30,107),10,GOLD)
	host.text_at(host.fit_text(u.name,193,19),Vector2(30,131),19,PAPER)
	host.text_at(model.boss_phase_name(u.id) if Rules.Identity.is_boss(u) else "Inic. %d · %s"%[u.speed,model.role_name(u.id)],Vector2(30,149),11,MUTED)
	for entry in [["VIDA",u.hp,u.max_hp,JADE],["ALENTO",u.qi,u.max_qi,Color("74b5d0")],["POSTURA",u.posture,u.max_posture,GOLD]]:
		var i: int=[["VIDA"],["ALENTO"],["POSTURA"]].find([entry[0]])
		var y:=170+i*29
		host.text_at(entry[0],Vector2(30,y),10,MUTED)
		host.text_at("%d / %d"%[entry[1],entry[2]],Vector2(158,y),11,PAPER)
		host.bar(Vector2(30,y+5),Vector2(193,5),entry[1],maxi(1,entry[2]),entry[3])
	if is_player():
		var states: Array=[{"label":"MOV %d"%u.moves,"ready":u.moves>0},{"label":"AÇÃO","ready":not u.acted},{"label":"RÁPIDA","ready":not u.get("quick_used",false)}]
		for i in states.size():
			var item: Dictionary=states[i]
			var x: float=30+i*68
			host.draw_rect(Rect2(x,246,63,25),Color("315c54") if item.ready else Color("25383e"))
			host.text_at(host.fit_text(item.label,55,9),Vector2(x+4,263),9,JADE if item.ready else MUTED)
	else: host.text_at("Mov. %d/%d · Acção %s"%[u.moves,u.movement,"usada" if u.acted else "livre"],Vector2(30,257),11,MUTED if u.acted else GOLD)
	if is_player():
		var passive_labels: Array[String]=[]
		for id in u.get("passives",[]):
			var duration:int=int(model.Catalog.passive_def(id).get("cooldown",model.Catalog.RARITY_COOLDOWN.get(model.Catalog.passive_def(id).get("rarity","Comum"),0)))
			var remaining:int=mini(duration,maxi(0,int(u.passive_cooldowns.get(id,0))-int(u.turns)))
			passive_labels.append(model.Catalog.passive_def(id).name+(" (%d turnos)"%remaining if remaining>0 else ""))
		host.text_at(host.fit_text(" · ".join(passive_labels),193,8),Vector2(30,279),8,MUTED)
	if passive_feedback_readable() and not passive_feedback.pages.is_empty():
		draw_passive_feedback()
		return
	if exploration_notice_time>0 and phase=="choose":
		draw_exploration_notice(); return
	if not model.optional_objective.is_empty() and phase=="choose" and (not model.inside(hover_cell) or model.unit_at(hover_cell)<0):
		draw_optional_sidebar(); return
	host.panel(Rect2(16,287,222,109),BG,EDGE)
	var aim:=preview_cell()
	var lines: Array[String]=[]
	var title:="LEITURA DO CAMPO"
	if phase=="aim" and not model.skill_def(model.current_id,selected_skill).shape in ["self","ally","friend"]:
		title="PREVISÃO · SEM BÓNUS / PERFEITO"
		var hits: Array=model.targets(model.current_id,model.area(model.current_id,selected_skill,aim))
		for id in hits:
			var low: Dictionary=model.predict(model.current_id,id,selected_skill,0,preview_cell())
			var high: Dictionary=model.predict(model.current_id,id,selected_skill,2,preview_cell())
			lines.append("%s · %s"%[model.units[id].name,low.side])
			lines.append("%d–%d dano · %d–%d postura"%[low.damage,high.damage,low.posture,high.posture])
			if high.breaks: lines.append("Quebra possível" if not low.breaks else "Quebra garantida")
			elif high.stun: lines.append("Atordoa: perde um turno")
			elif model.has_effect(model.skill_def(model.current_id,selected_skill),"stun"): lines.append("Resiste ao atordoamento")
			elif high.bleed: lines.append("Sangramento: 8 × 3 turnos")
		if lines.is_empty(): lines.assign(["Escolhe um alvo no alcance.","Dourado: casas atingidas.","Obstáculos bloqueiam a linha."])
	elif phase=="move":
		var path: Array=model.path_to(model.current_id,aim) if model.inside(aim) else []
		lines.assign(["Sem caminho disponível" if path.is_empty() and aim!=model.current().cell else "Caminho: %d casa(s)"%path.size(),"Verde: movimento disponível.","Vermelho: golpe anunciado.","Enter confirma · botão direito cancela"])
	elif model.inside(hover_cell) and model.unit_at(hover_cell)>=0:
		var hovered: Dictionary=model.units[model.unit_at(hover_cell)]
		title=hovered.name.to_upper()
		lines.assign(["Vida %d/%d · postura %d"%[hovered.hp,hovered.max_hp,hovered.posture],model.role_name(hovered.id),"Resposta frontal: 9 de dano" if hovered.riposte else ("Firme: resiste a quebra e atordoar" if hovered.firm>0 else "Abertura: estocada de Inês reforçada" if hovered.opening>0 else "Resistência a atordoar: %d"%hovered.resist)])
		if hovered.team==1:
			var intent: Dictionary=model.enemy_intent(hovered.id)
			lines.assign(["Vida %d/%d · postura %d"%[hovered.hp,hovered.max_hp,hovered.posture],intent.title])
			lines.append_array(wrap_hint(intent.detail,197,10,2))
	elif not is_player():
		var intent: Dictionary=model.enemy_intent(u.id)
		title="INTENÇÃO DO ADVERSÁRIO"
		lines.assign([intent.title]); lines.append_array(wrap_hint(intent.detail,197,10,3))
	else:
		lines.assign(["Podes mover antes e depois de agir.","Q / E escolhe a orientação final.","Costas: mais dano e postura.","Lê a técnica e castiga a recuperação."])
		for enemy in model.enemies:
			if enemy.hp>0 and enemy.charging:
				title=model.boss_phase_name(enemy.id)
				lines.assign(["Vermelho: "+enemy.warning_name,"Sai antes do próximo turno.","Âmbar / 2: "+enemy.next_name if not enemy.followup.is_empty() else "Interromper cancela a preparação.","Duas áreas fixas, dois turnos." if not enemy.followup.is_empty() else "Firme impede nova interrupção."])
	if not lesson and phase=="choose" and (not model.inside(hover_cell) or model.unit_at(hover_cell)<0):
		for enemy in model.enemies:
			if Rules.Identity.is_boss(enemy) and enemy.hp>0 and not enemy.charging:
				title=enemy.name
				lines=wrap_hint(model.boss_hint(enemy.id),197,10,4)
				break
	var tip:=tutorial_tip()
	if not tip.is_empty() and (lesson or not model.enemies.any(func(e): return Rules.Identity.is_boss(e) and e.hp>0)) and phase!="move" and (not model.inside(hover_cell) or model.unit_at(hover_cell)<0):
		title=tip[0]; lines.assign(tip.slice(1))
	host.text_at(host.fit_text(title,197,9),Vector2(29,307),9,GOLD)
	for i in mini(4,lines.size()): host.text_at(host.fit_text(lines[i],197,10),Vector2(29,327+i*18),10,PAPER)

func wrap_hint(value: String, width: float, size: int, limit: int) -> Array[String]:
	value=host.localization.text(value)
	var lines: Array[String]=[]
	var line:=""
	for word in value.split(" "):
		var candidate: String=word if line.is_empty() else line+" "+word
		if host.font.get_string_size(candidate,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x>width and not line.is_empty():
			lines.append(line); line=word
		else: line=candidate
	if not line.is_empty(): lines.append(line)
	if lines.size()>limit:
		lines[limit-1]=host.fit_text(" ".join(lines.slice(limit-1)),width,size)
		lines.resize(limit)
	return lines

func tutorial_tip() -> Array:
	if phase=="timing_defend" and double_defense_timing():
		return ["DEFESA EM %d TEMPOS"%defense_beat_count(),"Prime Espaço em cada tempo.","Todos perfeitos: aparar pela frente.","Pelas costas só podes reduzir dano."]
	if not lesson:
		if model.objective.get("kind","")=="changing_deck": return ["ESTEBAN · TRÊS FASES","Mastro e carga alteram a cobertura.","Cuidado com os golpes anunciados.","O poder conjunto exige a dupla viva."]
		if model.objective.get("kind","")=="capture":
			return ["CAPTURAR O MENSAGEIRO","Segue a rota vermelha até à saída.","Derrota, quebra ou atordoa-o.","O guarda é opcional."]
		if model.objective.get("kind","")=="protect":
			if model.objective.get("asset_kind","")=="civilians": return ["DEFENDE A RETIRADA","Yusuf abriu a passagem civil.","Interrompe o incendiário marcado.","As famílias têm de sobreviver."]
			return ["SALVA AS PROVAS","O inimigo marcado ameaça os livros.","Quebra, atordoa ou derrota-o.","A perda prevista aparece no tabuleiro."]
		if model.objective.get("kind","")=="escort":
			var support: String=String(model.objective.get("support",""))
			var support_line: String="A Armada distrai os arqueiros." if support=="armada" else ("O Lastro reforçou o casco." if support=="lastro" else "Duas ameaças procuram os civis.")
			return ["ESCOLTA A BARCA",support_line,"A rota avança quando está livre.","Neutraliza quem chega à barca."]
		if model.encounter=="saint_roman": return ["RESGATE DA CAPELA","Seis soldados guardam a praça.","Dois atiradores e um socorrista.","A torre abre após o segundo grupo."]
		if model.encounter=="stronghold": return ["CATARINA · TORRE","A salva evolui entre fases.","Sem arqueiros: procura os teus flancos.","Resposta frontal: flanqueia ou quebra."]
		if model.encounter=="vigia_sentinel": return ["GALERIA EXTERIOR","Cinco guardas, com arqueiros nos patamares.","Usa as colunas partidas para cortar a linha de tiro.","Depois da vitória, lê a inscrição dos três canais."]
		if model.encounter=="vigia_guard": return ["GUARDIÃO DA ROSA","Haste, três atiradores e um bombardeiro.","Sai das áreas anunciadas e avança pela cobertura.","Guarda recursos para a fuga que vem a seguir."]
		if model.encounter=="cove_trial_1": return ["PROVA 1 · GUARDA","Cinco rivais; dois atacam de longe.","A Sentinela protege os aliados.","Quebra a guarda e procura cobertura."]
		if model.encounter=="cove_trial_2" and not learned.cover and not skill_key(0,4).is_empty():
			if phase=="timing_defend": return ["PROTEGE A DUPLA","Espaço no centro dourado.","Aparar de frente reduz o golpe.","Guarda de maré cobre Inês","se estiver até duas casas."]
			return ["GUARDA DE MARÉ","Os arqueiros procuram uma linha livre.","Duarte: tecla %s para proteger."%skill_key(0,4),"Apoio rápido: podes também atacar.","Mantém Inês até duas casas."]
		if model.encounter=="cove_trial_2": return ["PROVA 2 · LINHA DE TIRO","Seis rivais; três são arqueiros.","Usa obstáculos para cortar a linha.","Aproxima-te sem expor os dois heróis."]
		if model.encounter=="cove_trial_3": return ["PROVA 3 · FLANCO","Sete rivais cercam a dupla.","O duelista responde pela frente.","Corta as linhas dos arqueiros."]
		if model.encounter=="cove_trial": return ["PROVA 4 · GRÃO-MESTRE","Cinco arqueiros apoiam o mestre.","Sai do golpe anunciado e quebra linhas.","As fases mudam com a vida dele."]
		if model.encounter=="patrol" and not learned.combo and model.enemies.any(func(u): return u.hp>0 and u.opening>0):
			return ["UMA ABERTURA PARA INÊS","Duarte abriu a guarda do rival.","Estocada de Inês nesse alvo:","+35% dano e +14 postura.","Aproveita antes de desaparecer."]
		return []
	if phase=="timing_defend":
		return ["APARAR E RESPONDER","Espaço quando passar no dourado.","De frente e junto ao adversário:","perfeito apara e contra-ataca.","Só conta a primeira pressão."]
	if phase=="timing_attack": return ["ENCONTRA O RITMO","Espera pelo centro dourado.","Prime Espaço uma única vez.","O ritmo melhora dano e postura.","Um erro não cancela o golpe."]
	if phase=="facing" or (is_player() and model.current().acted): return ["PROTEGE A TUA GUARDA","Ainda podes mover e usar rápida.","T: terminar; Q / E: virar.","Aponta a seta ao adversário.","Enter confirma a orientação."]
	if not learned.move: return ["1 · APROXIMA-TE","Prime G e escolhe uma casa verde.","Confirma o caminho com Enter.","Mover não gasta a tua acção.","Podes recuar depois de atacar."]
	if not learned.attack:
		var thrust_key:=skill_key(model.current_id,2)
		return ["2 · ESCOLHE O TEU GOLPE","1: Talho junto ao adversário.","%s: Estocada até 3 casas."%thrust_key if not thrust_key.is_empty() else "Lê o alcance das técnicas equipadas.","Tab alterna os alvos válidos.","Vê o dano; Enter confirma."]
	if not learned.posture: return ["3 · QUEBRA A POSTURA","A barra dourada é a postura.","Varrimento de Duarte pressiona-a.","Ao quebrar, o rival perde um turno.","Respirar recupera o teu alento."]
	return ["4 · COMBINA AS DUAS LÂMINAS","Varrimento de Duarte abre o alvo.","Estocada de Inês aproveita-o.","Flancos e costas aumentam o dano.","H: consulta a ajuda quando quiseres."]

func draw_aim_hero_hud() -> void:
	var hero: Dictionary=model.current()
	var box:=Rect2(241,107,178,100)
	host.panel(box,BG,GOLD)
	host.text_at(host.fit_text(hero.name+" · ESTADO",154,11),Vector2(252,127),11,GOLD)
	var rows: Array=[["VIDA",hero.hp,hero.max_hp,JADE],["ALENTO",hero.qi,hero.max_qi,Color("74b5d0")],["POSTURA",hero.posture,hero.max_posture,GOLD]]
	for i in rows.size():
		var row: Array=rows[i]
		var y: float=145+i*22
		host.text_at(row[0],Vector2(252,y),9,MUTED)
		host.text_at("%d/%d"%[row[1],row[2]],Vector2(363,y),9,PAPER)
		host.bar(Vector2(252,y+5),Vector2(154,5),row[1],maxi(1,row[2]),row[3])

func draw_preview_sidebar() -> void:
	host.panel(Rect2(16,86,222,310),BG,GOLD)
	host.text_at(model.current().name+" · PREVISÃO",Vector2(29,108),12,GOLD)
	var definition: Dictionary=model.skill_def(model.current_id,selected_skill)
	host.text_at(host.fit_text(definition.name,197,16),Vector2(29,131),16,PAPER)
	host.text_at("%d alento · 1 %s"%[definition.cost,action_kind(definition)],Vector2(29,152),11,JADE if definition.get("quick",false) else MUTED)
	if definition.shape in ["self","ally","friend"]:
		draw_support_preview(definition)
		return
	var hits: Array=model.targets(model.current_id,model.area(model.current_id,selected_skill,preview_cell()))
	var summary: String=preview_consequence(hits)
	if not summary.is_empty():
		host.draw_rect(Rect2(27,166,200,25),Color("315c54"))
		host.text_at(host.fit_text(summary,190,11),Vector2(32,183),11,JADE)
	for i in mini(3,hits.size()):
		var id: int=hits[i]
		var low: Dictionary=model.predict(model.current_id,id,selected_skill,0,preview_cell())
		var high: Dictionary=model.predict(model.current_id,id,selected_skill,2,preview_cell())
		var y:=205+i*56
		host.text_at(host.fit_text("%s · %s"%[model.units[id].name,low.side],197,11),Vector2(29,y),11,GOLD)
		host.text_at("Vida: −%d a −%d"%[low.damage,high.damage],Vector2(29,y+16),12,PAPER)
		host.text_at("Postura: −%d a −%d"%[low.posture,high.posture],Vector2(29,y+31),11,MUTED)
		var status: String="Quebra garantida" if low.breaks else ("Quebra se o golpe for preciso" if high.breaks else "")
		if model.has_effect(definition,"stun") and not high.lethal: status+=(" · " if status!="" else "")+("Atordoa" if high.stun else "Resiste ao atordoamento")
		if high.get("applies_exposed",false): status+=(" · " if status!="" else "")+"Expõe"
		if high.bleed: status+=(" · " if status!="" else "")+"Sangra 8 × %d"%int(definition.get("bleed_turns",3))
		if high.get("consumes_bleed",false): status="Consome Sangramento"
		if high.combo: status="Abertura consumida"
		elif high.reply>0: status="Cuidado: resposta de 9 de dano"
		elif high.get("exposed",false): status="Exposto: +35% postura neste golpe; depois é consumido"
		elif high.get("anchored",false): status="Escudo frontal: −35% postura"
		elif high.get("ward",false): status="Escolta: −20% dano frontal"
		elif high.get("prism",false): status="Baluarte: −30% pressão frontal"
		elif high.get("shielded",false): status="Protegido: −25% dano frontal"
		elif high.opening: status="Abre o alvo para Inês"
		elif high.firm: status="Firme: não quebra nem atordoa"
		if high.get("read",false): status="Golpe reconhecido: varia a técnica ou flanqueia"
		if int(high.get("redirect",-1))>=0: status="Intercepta: "+model.units[int(high.redirect)].name
		if high.get("last_stand",false): status="Yusuf prepara o Último vendaval"
		if high.lethal: status="Derrota garantida" if low.lethal else "Pode derrotar com bom ritmo"
		host.text_at(host.fit_text(status,197,10),Vector2(29,y+42),10,JADE)
	if hits.is_empty():
		var feedback: Dictionary=model.aim_feedback(model.current_id,selected_skill,preview_cell())
		var reason: String=model.attack_reason(selected_skill,preview_cell())
		if not feedback.is_empty(): reason=feedback.label
		if reason.is_empty(): reason="Escolhe uma aterragem livre." if definition.shape=="leap" else "Escolhe uma casa no alcance."
		var lines:=wrap_hint(reason,197,12,4)
		for i in lines.size(): host.text_at(lines[i],Vector2(29,190+i*18),12,RED if not feedback.is_empty() else PAPER)
		host.text_at("Contorno tracejado: alcance.",Vector2(29,282),11,MUTED)
		host.text_at("Dourado: casas atingidas.",Vector2(29,306),11,MUTED)
	var footer: String="+%d alvos na área"%(hits.size()-3) if hits.size()>3 else "Sem ritmo → perfeito · Tab: alvos"
	if definition.shape=="leap": footer="Aterragem: −%d%% · 2 golpes"%(25 if model.has_passive(model.current_id,"duarte_landing") else int(definition.get("fortitude",0)))
	host.text_at(host.fit_text(footer,197,10),Vector2(29,381),10,GOLD if definition.shape=="leap" else MUTED)

func preview_consequence(hits: Array) -> String:
	if hits.is_empty(): return ""
	var objective_id: int=int(model.objective.get("actor_id",-1))
	var defeats:=0
	var breaks:=0
	var possible_breaks:=0
	var interrupts:=false
	for id in hits:
		var low: Dictionary=model.predict(model.current_id,id,selected_skill,0,preview_cell())
		var high: Dictionary=model.predict(model.current_id,id,selected_skill,2,preview_cell())
		if int(low.get("redirect",-1))>=0: return "GUARDA INTERCEPTA O GOLPE"
		if low.get("last_stand",false): return "YUSUF PREPARA O VENDAVAL"
		if low.lethal: defeats+=1
		elif low.breaks: breaks+=1
		elif high.breaks: possible_breaks+=1
		if id==objective_id and (low.lethal or low.breaks or low.stun): interrupts=true
	if interrupts: return "INTERROMPE O OBJECTIVO"
	if defeats>0: return "DERROTA %d ALVO%s"%[defeats,"" if defeats==1 else "S"]
	if breaks>0: return "QUEBRA %d ALVO%s"%[breaks,"" if breaks==1 else "S"]
	if possible_breaks>0: return "QUEBRA POSSÍVEL"
	return "%d ALVO%s ATINGIDO%s"%[hits.size(),"" if hits.size()==1 else "S","" if hits.size()==1 else "S"]

func draw_support_preview(definition: Dictionary) -> void:
	var preview: Dictionary=model.support_preview(model.current_id,selected_skill,preview_cell())
	var reason: String=model.attack_reason(selected_skill,preview_cell())
	var target: int=preview.get("target",-1)
	if target>=0 and (model.units[target].team!=model.current().team or (definition.shape=="ally" and target==model.current_id)): target=-1
	var lines: Array[String]=[]
	if target>=0:
		var recipient: Dictionary=model.units[target]
		host.text_at(recipient.name,Vector2(29,180),16,GOLD)
		if selected_skill in [6,7]:
			var resource: String=preview.get("resource","hp")
			var resource_name:="vida" if resource=="hp" else "alento"
			var before: int=recipient[resource]
			var amount: int=preview.get("amount",0)
			lines.append("%s: %d → %d / %d"%[resource_name.capitalize(),before,before+amount,recipient["max_"+resource]])
			lines.append("Recupera %d de %s."%[amount,resource_name])
			if preview.get("waste",0)>0: lines.append("Excedente perdido: %d."%preview.waste)
			var stock: int=model.potions if selected_skill==6 else model.tonics
			lines.append("Bolsa partilhada: %d → %d."%[stock,maxi(0,stock-1) if reason.is_empty() else stock])
			lines.append("Consome a acção; podes mover." if reason.is_empty() else "Alvo inválido: sem gasto.")
		elif definition.has("recovery"):
			for resource in definition.recovery:
				lines.append("+%d %s"%[preview[resource],model.Catalog.STAT_NAMES[resource]])
			if definition.get("cleanse",false): lines.append("Remove Sangramento.")
			if preview.get("guard",false): lines.append("Assume a guarda.")
			if preview.get("cover",false): lines.append("Cobre o aliado contra o próximo golpe.")
			if preview.get("movement",0)>0: lines.append("+%d movimento neste turno."%preview.movement)
			if preview.get("counter",false): lines.append("Prepara contra-ataque.")
			lines.append("Recarga: %d turnos próprios."%definition.cooldown)
		elif preview.get("cover",false):
			lines.assign(["Inês recebe metade do dano.","Duarte recebe um quarto.","Protege contra um golpe.","Expira no próximo turno de Duarte.","Até %d casas e sem obstáculos."%definition.range,"Preserva a tua acção principal." if definition.get("quick",false) else "Consome a acção principal."])
		else:
			if selected_skill==5:
				lines.append("Alento: %d → %d / %d"%[recipient.qi,recipient.qi+preview.get("qi",0),recipient.max_qi])
				lines.append("Postura: %d → %d / %d"%[recipient.posture,recipient.posture+preview.get("posture",0),recipient.max_posture])
			elif preview.get("posture",0)>0: lines.append("Recupera %d de postura."%preview.posture)
			elif selected_skill==9 and model.current_id==0: lines.append("Postura já está no máximo.")
			if preview.get("movement",0)>0: lines.append("Movimento: %d → %d casas."%[recipient.moves,recipient.moves+preview.movement])
			if int(definition.get("fortitude",0))>0: lines.append("Resistência %d%% · 2 golpes"%definition.fortitude)
			if int(definition.get("fortitude",0))>0: lines.append("Resistência %d%% · 2 golpes"%definition.fortitude)
			if preview.get("guard",false):
				lines.append("Guarda: metade do próximo dano.")
				lines.append("Anula a perda de postura.")
			lines.append("Preserva a tua acção principal." if definition.get("quick",false) else "Consome a acção; podes mover.")
	else:
		host.text_at("Selecciona um aliado",Vector2(29,180),14,PAPER)
		lines.assign(["Pontos verdes: alvos válidos.","Alcance: %d casas, linha livre."%definition.range,"Tab alterna entre alvos válidos.","Prime Enter para confirmar."])
	for i in mini(7,lines.size()): host.text_at(host.fit_text(lines[i],197,11),Vector2(29,207+i*22),11,GOLD if lines[i].begins_with("Excedente") else PAPER)
	host.text_at(host.fit_text("Enter confirma · Tab muda de alvo" if reason.is_empty() else reason,197,10),Vector2(29,381),10,JADE if reason.is_empty() else RED)

func draw_controls() -> void:
	host.panel(Rect2(16,408,928,118),BG,EDGE)
	if phase=="items":
		draw_item_button(6,1,Rect2(30,419,434,48),model.potions)
		draw_item_button(7,2,Rect2(482,419,445,48),model.tonics)
		host.text_at("Bolsa partilhada. Escolhe um item; só é gasto ao confirmar o alvo.",Vector2(32,492),12,PAPER)
		host.text_at("Mostramos a recuperação exacta e o excedente. Itens não reanimam.",Vector2(32,513),10,MUTED)
		host.button("t_cancel","Cancelar",Rect2(776,486,150,30))
		return
	if phase=="telegraph":
		host.centered("GOLPE ANUNCIADO · "+plan.name.to_upper(),442,20,RED)
		host.centered("Prepara ESPAÇO / SPACE: prime quando o cursor passar no dourado.",475,13,PAPER)
		host.centered("Tiro acelera · finta trava · golpe pesado dá mais tempo",509,11,MUTED)
		return
	if phase.begins_with("timing"):
		draw_timing(); return
	if phase in ["cutin","walk","enemy_wait","skip","animate_enemy","animate_player"]:
		var title: String=quality_label if phase.begins_with("animate") and not quality_label.is_empty() else "O RITMO DO COMBATE"
		if phase=="walk": title="A reposicionar…"
		if phase=="animate_player" and Rules.Catalog.is_ultimate(result.get("skill",-1)): title="SUPREMA · "+model.units[result.actor].name.to_upper()
		host.centered(title,442,21,GOLD)
		var message: String=log_lines[-1] if not log_lines.is_empty() else ""
		host.centered(host.fit_text(message,884,13),475,13,PAPER)
		host.centered("Postura dourada · alento azul · vida verde · sangramento rubro",509,11,MUTED)
		return
	var commands: Array=model.commands(model.current_id)
	var command_boxes: Array[Rect2]=command_rects(commands)
	var hovered_skill:=-1
	var hovered_items:=false
	for i in commands.size():
		var id: int=commands[i]
		var rect: Rect2=command_boxes[i]
		if i==commands.size()-1 and not model.profile.is_empty():
			draw_icon_button("t_items",9,6,rect,Color("9aa6a8"),not model.current().acted and is_player() and phase!="facing","%d/%d"%[model.potions,model.tonics],"Itens")
			hovered_items=rect.has_point(host.get_global_mouse_position())
			continue
		if id<0:
			host.button("t_empty",str(i+1),rect,false)
			host.draw_rect(Rect2(rect.position+Vector2(4,4),Vector2(rect.size.x-8,3)),Color("385059"))
			continue
		var s: Dictionary=model.skill_def(model.current_id,id)
		var detail: String=button_status(id,s)
		draw_icon_button("t_skill_%d"%id,i+1,id,rect,Color(s.rarity_color),model.available(id) and phase!="facing",detail,s.name)
		if rect.has_point(host.get_global_mouse_position()): hovered_skill=id
	hovered_detail_skill=hovered_skill
	draw_action_detail(hovered_skill,hovered_items)
	if phase in ["choose","move"]:
		host.button("t_undo","Z · Desfazer",Rect2(600,478,95 if not model.optional_objective.is_empty() else 140,37),can_undo_move())
	if phase=="choose":
		if not model.boss_loot.is_empty(): host.button("t_loot","B · Bolsa",Rect2(488,478,106,37),model.loot_reason().is_empty())
		if not model.optional_objective.is_empty(): host.button("t_optional","R · Extra",Rect2(701,478,102,37),model.optional_reason().is_empty())
		host.button("t_end","Fim do turno",Rect2(810,478,113,37))
	elif phase in ["move","aim"]:
		var valid: bool=(phase=="aim" and model.valid_attack(selected_skill,selected_cell)) or (phase=="move" and not model.path_to(model.current_id,selected_cell).is_empty())
		host.button("t_confirm","Confirmar",Rect2(747,478,103,37),valid)
		host.button("t_cancel","Voltar",Rect2(857,478,66,37))
	elif phase=="facing":
		host.button("t_confirm","Terminar",Rect2(747,478,103,37))
		host.button("t_cancel","Voltar",Rect2(857,478,66,37))

func draw_action_detail(hovered_skill: int, hovered_items: bool) -> void:
	host.panel(Rect2(25,468,910,55),Color("183640"),EDGE)
	if phase=="move":
		host.text_at("MOVIMENTO",Vector2(39,490),14,GOLD)
		host.text_at("Casa verde + Enter: mover · Z: desfazer movimento",Vector2(39,508),11,PAPER)
		return
	if phase=="facing":
		host.text_at("ORIENTAÇÃO FINAL",Vector2(39,490),14,GOLD)
		host.text_at("Clica na direcção da guarda ou usa Q / E. Enter termina o turno.",Vector2(39,508),11,PAPER)
		return
	var skill: int=selected_skill if phase=="aim" else (hovered_skill if hovered_skill>=0 else selected_skill)
	var definition: Dictionary=model.skill_def(model.current_id,skill) if skill>=0 else {}
	if definition.is_empty():
		host.text_at("ITENS" if hovered_items else "ESCOLHE UMA ACÇÃO",Vector2(39,490),14,GOLD)
		host.text_at("Infusão e Tónico na bolsa partilhada." if hovered_items else "G: mover · Z: desfazer movimento · T: terminar turno",Vector2(39,508),11,PAPER)
		return
	var icon: Texture2D=icon_texture(model.current_id,skill)
	presentation.draw_icon(host,icon,Rect2(34,476,40,40))
	host.text_at(host.fit_text(definition.name,220,14),Vector2(83,489),14,GOLD)
	var range_label: String="próprio" if definition.shape=="self" else "%d casas"%definition.range
	var meta: String="%d AL · %s · %s"%[definition.cost,range_label,"rápida" if definition.get("quick",false) else "acção"]
	if definition.cooldown>0: meta+=" · %dt"%definition.cooldown
	host.text_at(host.fit_text(meta,220,10),Vector2(83,508),10,MUTED)
	var reason: String=model.availability_reason(skill)
	host.button("t_details","F · Detalhes da técnica",Rect2(318,477,266,38),true,"Disponível" if reason.is_empty() else "Indisponível · ver motivo")

func open_details() -> void:
	if not is_player() or phase not in ["choose","move","aim"]: return
	detail_skill=hovered_detail_skill if hovered_detail_skill>=0 else selected_skill
	if model.skill_def(model.current_id,detail_skill).is_empty(): detail_skill=-1

func draw_details() -> void:
	var d: Dictionary=model.skill_def(model.current_id,detail_skill)
	host.buttons.clear()
	host.draw_rect(Rect2(0,0,960,540),Color(0.01,0.03,0.04,0.78))
	host.panel(Rect2(146,82,668,376),BG,Color(d.rarity_color))
	presentation.draw_icon(host,icon_texture(model.current_id,detail_skill),Rect2(165,103,55,55))
	host.text_at(host.fit_text(d.name,562,21),Vector2(234,123),21,GOLD)
	host.text_at("%d alento · %d casas · %d turnos de recarga"%[d.cost,d.range,d.cooldown],Vector2(234,148),13,MUTED)
	var reason: String=model.availability_reason(detail_skill)
	if reason.is_empty(): reason="Apoio rápido · preserva a acção principal" if d.get("quick",false) else "Consome a acção principal"
	var status_lines:=wrap_hint(reason,620,14,100)
	for i in status_lines.size(): host.text_at(status_lines[i],Vector2(165,182+i*20),14,JADE if model.available(detail_skill) else RED)
	var lines:=wrap_hint(d.description,620,15,100)
	for i in lines.size(): host.text_at(lines[i],Vector2(165,239+i*22),15,PAPER)
	if d.get("requires_partner",false): host.text_at("Exige os dois heróis conscientes.",Vector2(165,381),13,GOLD)
	host.text_at("F / Esc · voltar ao combate",Vector2(165,433),12,MUTED)
	host.button("t_detail_close","Voltar",Rect2(620,403,170,36))

func command_rects(commands: Array) -> Array[Rect2]:
	var result: Array[Rect2]=[]
	var weights: Array[float]=[]
	var total:=0.0
	for i in commands.size():
		var weight:=0.43 if int(commands[i])<0 else (0.85 if i==commands.size()-1 or int(commands[i])==5 else 1.0)
		weights.append(weight)
		total+=weight
	var group_gap:=8.0 if commands.size()>=8 else 0.0
	var available:=910.0-3.0*group_gap
	var x:=25.0
	for i in commands.size():
		if group_gap>0 and i in [1,commands.size()-2,commands.size()-1]: x+=group_gap
		var width: float=available*weights[i]/total
		result.append(Rect2(x,415,width-4,46))
		x+=width
	return result

func icon_texture(actor: int, skill: int) -> Texture2D:
	var key: String="item_%d"%skill if skill in [6,7] else ("duarte_%d"%skill if actor==0 else "ines_%d"%skill)
	if skill_icons.has(key): return skill_icons[key]
	var path: String="res://assets/skill_icons/"+key+".png"
	var texture:=presentation.icon(path)
	skill_icons[key]=texture
	return texture

func button_status(skill: int, definition: Dictionary) -> String:
	var reason: String=model.availability_reason(skill)
	if reason.is_empty(): return "%d AL"%definition.cost
	var remaining: int=model.cooldown_remaining(model.current_id,skill)
	if remaining>0: return "%d t"%remaining
	if reason.begins_with("Alento insuficiente"): return "Alento"
	if reason.begins_with("Já usaste a técnica rápida"): return "Rápida"
	if reason.begins_with("A acção principal"): return "Acção"
	return "Bloqueio"

func draw_icon_button(button_id: String, shortcut: int, skill: int, rect: Rect2, rarity: Color, enabled: bool, detail: String, fallback_name: String) -> void:
	var texture: Texture2D=icon_texture(model.current_id,skill)
	if texture==null:
		host.button(button_id,"%d %s"%[shortcut,compact_command_name(skill,fallback_name)],rect,enabled,detail)
		if button_id.begins_with("t_skill_"): host.buttons[-1]["inspect_skill"]=skill
		return
	host.button(button_id,"",rect,enabled)
	if button_id.begins_with("t_skill_"): host.buttons[-1]["inspect_skill"]=skill
	var supreme: bool=Rules.Catalog.is_ultimate(skill)
	host.draw_rect(Rect2(rect.position+Vector2(4,4),Vector2(rect.size.x-8,2)),rarity)
	if supreme: host.draw_rect(rect.grow(-3),rarity,false,1)
	host.text_at(str(shortcut),rect.position+Vector2(7,21),12,PAPER if enabled else MUTED)
	var icon_rect:=Rect2(rect.position+Vector2(rect.size.x/2-19,6),Vector2(38,38))
	presentation.draw_icon(host,texture,icon_rect,Color.WHITE if enabled else Color(0.64,0.70,0.72,0.7))
	var badge:=Rect2(rect.position+Vector2(rect.size.x-49,29),Vector2(45,14))
	host.draw_rect(badge,BG)
	host.text_at(host.fit_text(detail,41,9),badge.position+Vector2(2,11),9,PAPER if enabled else RED)

func draw_item_button(skill: int, shortcut: int, rect: Rect2, stock: int) -> void:
	var enabled: bool=model.available(skill)
	var label: String="Infusão" if skill==6 else "Tónico"
	var detail: String="%d na bolsa · %s"%[stock,"+65–110 vida" if skill==6 else "+6–10 alento"] if enabled else model.availability_reason(skill)
	host.button("t_item_%d"%skill,"",rect,enabled)
	host.draw_rect(Rect2(rect.position+Vector2(4,4),rect.size-Vector2(8,8)),Color("315c54") if enabled else Color("25383e"))
	var icon: Texture2D=icon_texture(model.current_id,skill)
	if icon!=null: host.draw_texture_rect(icon,Rect2(rect.position+Vector2(19,7),Vector2(32,32)),false)
	host.text_at("%d  %s"%[shortcut,label],rect.position+Vector2(63,22),15,PAPER if enabled else MUTED)
	host.text_at(host.fit_text(detail,rect.size.x-76,10),rect.position+Vector2(63,39),10,MUTED)

func compact_command_name(skill: int, full_name: String) -> String:
	var common: Dictionary={0:"Corte" if model.current_id==1 else "Haste",1:"Dança" if model.current_id==1 else "Varred.",2:"Estoc." if model.current_id==1 else "Ponta",3:"Atord.",4:"Guarda" if model.current_id==0 else "Fio",5:"Respira",12:"Juramento" if model.current_id==0 else "Lua",24:"Âncora" if model.current_id==0 else "Maré"}
	if common.has(skill): return common[skill]
	var extra: Dictionary={8:"Âncora" if model.current_id==0 else "Agulha",9:"Raiz" if model.current_id==0 else "Passo",10:"Desafio" if model.current_id==0 else "Dança",11:"Peso" if model.current_id==0 else "Corte",21:"Muralha" if model.current_id==0 else "Véu"}
	if extra.has(skill): return extra[skill]
	return full_name if full_name.length()<=7 else full_name.substr(0,6)+"."

func timing_title() -> String:
	# While defending, the acting unit is the enemy: asking it for the hero's own
	# technique returns no definition, so the defence names the incoming blow instead.
	if phase in ["timing_defend","timing_volley"]: return "Defender %s · %s"%[model.units[plan.targets[defense_index]].name,plan.name]
	return model.skill_def(model.current_id,selected_skill).get("name","")

func draw_timing() -> void:
	if phase=="timing_volley": draw_volley(); return
	var defend:=phase=="timing_defend"
	var title: String=timing_title()
	host.text_at(host.fit_text(title,885,18),Vector2(34,435),18,RED if defend else GOLD)
	var pace: String="RITMO %.2fs · %s"%[duration,timing_label]
	if defend: pace="DEFESA DINÂMICA · %.2fs · %s"%[duration,timing_label]
	host.draw_rect(Rect2(34,449,278,31),GOLD)
	host.text_at("ESPAÇO / SPACE",Vector2(66,471),19,BG)
	host.text_at(pace,Vector2(34,492),10,MUTED)
	host.text_at("Prime uma vez em cada tempo." if defend and double_defense_timing() else "Prime uma vez no dourado.",Vector2(34,510),11,PAPER)
	host.text_at("PRIME NO DOURADO · PERFEITO",Vector2(331,446),11,GOLD)
	var rect:=Rect2(331,454,587,23)
	var windows:=timing_windows()
	var good:=windows.x
	var perfect:=windows.y
	host.draw_rect(rect,Color("071f29"))
	host.draw_rect(Rect2(rect.position+Vector2(rect.size.x*(timing_center-good),0),Vector2(rect.size.x*good*2,23)),Color("467e72"))
	if perfect>0.0: host.draw_rect(Rect2(rect.position+Vector2(rect.size.x*(timing_center-perfect),0),Vector2(rect.size.x*perfect*2,23)),GOLD)
	host.draw_line(rect.position+Vector2(rect.size.x*timing_center,-4),rect.position+Vector2(rect.size.x*timing_center,27),PAPER,1)
	var x:=rect.position.x+timing_progress(clock/duration)*rect.size.x
	host.draw_rect(Rect2(x-2,449,4,33),PAPER)
	if defend and double_defense_timing() and defense_beat>0:
		host.text_at(host.localization.text("Sequência: %s · %d/%d")%[host.localization.text(["FALHOU","BOM","PERFEITO"][first_defense_grade]),defense_beat+1,defense_beat_count()],Vector2(331,492),11,PAPER)
	var hint:="Golpe perfeito: mais dano, mais postura e +1 alento"
	if defend:
		var p: Dictionary=model.defense_preview(model.current_id,plan.targets[defense_index],plan,2)
		hint=p.side+": "+("APARA + CONTRA-ATAQUE automático" if p.counter else ("sem perfeito; melhor defesa reduz dano a %d"%p.cover.remaining if p.side=="Costas" else "perfeito apara, sem contra-ataque"))
		if plan.get("universal_parry",false): hint="Perfeito bloqueia este golpe."+(" A sequência continua." if plan.get("no_counter",false) else "")
		if double_defense_timing() and p.side!="Costas": hint=host.localization.text("%d perfeitos · ")%defense_beat_count()+host.localization.text(hint)
	host.text_at(host.fit_text(hint,587,12),Vector2(331,510),12,GOLD)

func show_cutin(actor: Dictionary, name: String, resume: String) -> void:
	cutin_resume=resume
	var sprite_kind: String=host.art.ActorCatalog.NAMED_COMBAT.get(actor.name,actor.kind)
	var combat_image: Texture2D=host.art.hero_frames[sprite_kind][0] if host.art.hero_frames.has(sprite_kind) else null
	cutin.begin(actor,name,host.progress.data.options.reduced_fx,presentation_speed()>1.0,combat_image)
	host.supreme_opening_sound(actor.name,name,cutin.duration<=2.0)
	phase="cutin"; clock=0; detail_skill=-1
	host.buttons.clear()
	log_message(actor.name+" · "+name)

func finish_cutin() -> void:
	if phase!="cutin": return
	host.end_supreme_opening_sound()
	host.combat_effect("opening_exit",-20)
	cutin.clear()
	var resume: String=cutin_resume
	cutin_resume=""
	if resume=="player":
		phase="timing_attack"; clock=0; duration=attack_timing_duration(); prepare_timing(false); quality_label=""
		host.tone(410,0.07)
	elif resume=="sequence":
		if model.begin_sequence(plan): sequence_active=true; advance_sequence()
		else: sequence_active=false; next_turn()
	elif resume=="enemy": plan.intro_shown=true; enemy_action()

func advance_sequence() -> void:
	var next: Dictionary=model.prepare_sequence_step()
	if next.is_empty():
		sequence_active=false
		observe_boss_phase()
		if not host.check_outcome(): next_turn()
		return
	plan=next
	var origin: Vector2i=model.current().cell
	var path: Array[Vector2i]=model.move_sequence_step()
	if not path.is_empty():
		walk_path.assign([origin]); walk_path.append_array(path)
		walk_actor=model.current_id; walking_enemy=true; phase="walk"; clock=0
	else: enemy_action()

func begin_volley() -> void:
	phase="timing_volley"; clock=0; defense_index=0; stream_resolved=0
	duration=float(plan.get("stream_duration",3.4))
	stream_grades.clear(); stream_events.clear()
	for mark in plan.marks: stream_grades.append(-1)
	timing_direction=-1 if plan.get("reverse_stream",false) else 1
	timing_curve="linear"; quality_label=""
	host.buttons.clear()

func volley_windows() -> Vector2:
	var windows:=Vector2(0.050,0.020)
	if plan.get("fencing",false): windows=Vector2(0.045,0.018)
	if host.progress.data.options.wide_timing: windows*=1.65
	if host.progress.data.options.get("difficulty","normal")=="challenging": windows*=0.88
	return windows

func commit_volley(forced := -1) -> void:
	if phase!="timing_volley": return
	for i in stream_grades.size():
		if stream_grades[i]>=0: continue
		var distance: float=absf(clock/duration-float(plan.marks[i]))
		var windows:=volley_windows()
		var grade: int=forced if forced>=0 else (2 if distance<=windows.y else (1 if distance<=windows.x else 0))
		stream_grades[i]=clampi(grade,0,2)
		if host.has_method("record_playtest_timing"): host.record_playtest_timing(true,stream_grades[i])
		quality_label=["FALHOU","BOM","PERFEITO"][stream_grades[i]]+" · %d/%d"%[i+1,stream_grades.size()]

		learned.defend=true
		return

func update_volley(delta: float) -> void:
	clock+=delta
	var windows:=volley_windows()
	for i in plan.marks.size():
		var moment: float=float(plan.marks[i])*duration
		if stream_events.size()<=i and clock>=moment-0.16:
			stream_events.append({"born":moment-0.16,"from":screen(model.current().cell)+Vector2(0,-28),"to":screen(model.units[plan.target].cell)+Vector2(0,-20),"hits":[]})
			host.combat_action_sound(-1 if plan.get("fencing",false) or plan.has("mirror_hero") else -3,model.current_id,"windup",plan)
		if stream_grades[i]<0 and clock>moment+windows.x*duration:
			stream_grades[i]=0
			if host.has_method("record_playtest_timing"): host.record_playtest_timing(true,0)
		if i==stream_resolved and clock>=moment and stream_grades[i]>=0:
			var shot: Dictionary=model.resolve_volley_shot(plan,i,stream_grades[i])
			stream_resolved+=1
			if stream_events.size()>i: stream_events[i].hits=shot.get("hits",[])
			for hit in shot.get("hits",[]):
				floats.append({"id":hit.id,"text":("APARADO" if hit.damage==0 else "−%d"%hit.damage)+(" · SANGRA" if hit.get("bleed",false) else ""),"color":GOLD if hit.damage==0 else RED,"life":1.25,"offset":i*10})
				if hit.get("breaks",false): learned.posture=true
			host.combat_impact_sound(shot,plan,{int(plan.target):int(stream_grades[i])})
			collect_passive_feedback()
	if clock>=duration and stream_resolved>=stream_grades.size():
		model.complete_volley_step()
		stream_events.clear()
		if host.check_outcome(): return
		if sequence_active: advance_sequence()
		else: next_turn()

func draw_volley() -> void:
	host.text_at(host.fit_text("DEFENDER · "+model.units[plan.target].name+" · "+plan.name,880,18),Vector2(34,435),18,RED)
	host.text_at("ESPAÇO · um aperto por marca",Vector2(34,472),16,PAPER)
	host.text_at("Cada golpe tem defesa própria.",Vector2(34,499),11,MUTED)
	var rect:=Rect2(331,454,587,23)
	host.draw_rect(rect,Color("071f29"))
	var windows:=volley_windows()
	for i in plan.marks.size():
		var mark: float=float(plan.marks[i])
		if timing_direction<0: mark=1.0-mark
		var x: float=rect.position.x+rect.size.x*mark
		var col: Color=GOLD if stream_grades[i]<0 else [RED,JADE,PAPER][stream_grades[i]]
		host.draw_rect(Rect2(x-rect.size.x*windows.x,rect.position.y,rect.size.x*windows.x*2,23),Color(JADE,0.25))
		host.draw_rect(Rect2(x-rect.size.x*windows.y,rect.position.y,rect.size.x*windows.y*2,23),Color(col,0.6))
		host.draw_line(Vector2(x,448),Vector2(x,482),col,2)
		host.text_at(str(i+1),Vector2(x-3,496),10,col)
	var progress: float=clampf(clock/duration,0,1)
	if timing_direction<0: progress=1.0-progress
	var cursor: float=rect.position.x+rect.size.x*progress
	host.draw_rect(Rect2(cursor-2,447,4,35),PAPER)
	host.text_at("← REFLEXO · direita para esquerda" if timing_direction<0 else "→ SEQUÊNCIA CONTÍNUA · sem reiniciar",Vector2(331,519),11,GOLD)

func draw_volley_effects() -> void:
	var reduced: bool=host.progress.data.options.reduced_fx
	if plan.has("mirror_hero"):
		var ghost: int=int(plan.mirror_hero)
		host.art.actor(screen(model.current().cell)+Vector2(20,-8),model.heroes[ghost].kind,motion_clock,false,false,1.6,false,"attack",fmod(clock,0.6),Color(JADE,0.35))
	for event in stream_events:
		var elapsed: float=clock-float(event.born)
		if elapsed<0 or elapsed>0.48: continue
		var direction: Vector2=(event.to-event.from).normalized()
		if plan.get("fencing",false) or plan.has("mirror_hero"):
			host.draw_arc(event.to,18,atan2(direction.y,direction.x)-1.1,atan2(direction.y,direction.x)+1.1,16,Color(GOLD,maxf(0,1-elapsed/0.48)),2,true)
		else:
			var point: Vector2=event.from.lerp(event.to,clampf(elapsed/0.16,0,1))
			host.draw_line(point-direction*18,point,GOLD,2,true); host.draw_circle(point,2,PAPER)
		for hit in event.hits:
			var centre:=unit_position(hit.id)+Vector2(0,-20)
			if hit.damage==0: host.draw_arc(centre,18,0,TAU,24,Color(GOLD,0.7),2,true)
			elif not reduced: impact_sparks(centre,RED,clampf(elapsed/0.48,0,1),3)

