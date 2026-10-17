extends "res://scripts/combat/mar_de_ferro/tactical_view.gd"
const COMBAT_ART = preload("res://scripts/combat/portugal_actor_art.gd")
const BOARD = preload("res://scripts/combat/portugal_board.gd")
const FEEL = preload("res://scripts/combat/portugal_motion.gd")
var arena = preload("res://scripts/combat/portugal_arena.gd").new()
var portugal_icons: Dictionary = {}
var icon_paths: Dictionary = {}
var release_sound_played := false
var weapon_tips: Dictionary = {}
var field = preload("res://scripts/combat/portugal_field.gd").new()
var field_state: Dictionary = {}
## Keep reference input, previews, movement, facing, timing and impact pipeline.
func tutorial_timing() -> bool:
	return model.encounter!="portugal_duel"

func screen(cell: Vector2i) -> Vector2: return BOARD.screen(cell)
func cell_at(point: Vector2) -> Vector2i: return BOARD.cell_at(point)
func tile_points(cell: Vector2i,inset := 0.0) -> PackedVector2Array: return BOARD.polygon(cell,inset)

func timing_windows() -> Vector2:
	var windows: Vector2 = super.timing_windows()
	if phase == "timing_defend" and not model.perfect_defense_enabled: windows.y = 0.0
	return windows

func begin() -> void:
	release_sound_played = false
	if arena.c==null: arena.setup(host)
	battlefield = arena
	super.begin()
	lesson = false
	onboarding.skip()
	log_lines.clear()
	log_message("Escolhe movimento e ataque. A defesa acontece durante o golpe adversário.")
	if model.encounter=="portugal_duel":
		log_message("Avaliação: experimenta a distância e responde ao golpe. A derrota do aprendiz continua a história; não é preciso gastar suprimentos.")
	elif model.get("mode")=="practice": log_message("Dois alvos mostram a área; Tomé anuncia um contacto controlado. No comando: X básico, Y percorre técnicas, L3 detalhes, Select sai.")

func weapon_style(actor: int) -> String:
	if actor==0 and model.get("style")!=null: return model.style
	return "LA" if actor==1 else "ES"

func attacking_animation() -> bool:
	return phase.begins_with("animate") and not result.is_empty() and effect_kind(result.actor,result.skill) not in ["cover","brace","root","breath","heal","qi","charge","signal"]

func strike_direction(actor: int) -> Vector2:
	var origin: Vector2 = screen(result.get("movement_origin",model.units[actor].cell))
	var aim: Vector2i = selected_cell if result.skill>=0 else (plan.cells[0] if not plan.get("cells",[]).is_empty() else model.units[actor].cell)
	var direction := (screen(aim)-origin).normalized() if model.inside(aim) else Vector2.ZERO
	if direction==Vector2.ZERO:
		var face: Vector2i = Rules.DIRECTIONS[model.units[actor].face]
		direction = Vector2(face.x-face.y,(face.x+face.y)*0.5).normalized()
	return direction

func start_animation(data: Dictionary,enemy: bool) -> void:
	release_sound_played = false
	super.start_animation(data,enemy)

func update(delta: float) -> void:
	if host.ending.running(): host.update_ending(delta); return
	if attacking_animation() and not release_sound_played and weapon_style(result.actor)=="FO" and clock+maxf(0,delta-hit_pause)>=FEEL.RELEASE:
		release_sound_played = true
		host.combat_release_sound(weapon_style(result.actor))
	super.update(delta)

func apply_impact() -> void:
	super.apply_impact()
	if not (sequence_active and plan.get("no_counter",false)):
		hit_pause = FEEL.hit_pause(weapon_style(result.actor),result,host.progress.data.options.reduced_fx,model.encounter.begins_with("portugal_child"))

func unit_position(id: int) -> Vector2:
	var point: Vector2 = super.unit_position(id)
	if not attacking_animation(): return point
	var reduced: bool = host.progress.data.options.reduced_fx
	if id==result.actor:
		var origin: Vector2i = result.get("movement_origin",model.units[id].cell)
		if origin==result.get("movement_destination",origin) and not result.has("reposition_path"):
			point = screen(model.units[id].cell)+FEEL.actor_offset(weapon_style(id),clock,strike_direction(id),reduced)
	else:
		for hit in result.get("hits",[]):
			if hit.id==id and hit.damage>0:
				var away: Vector2 = (screen(model.units[id].cell)-screen(model.units[result.actor].cell)).normalized()
				var contact := maxf(0,sin(clampf((clock-ActorMotion.IMPACT)/0.28,0,1)*PI)) if result.get("impacted",false) else 0.0
				point += away*contact*(4.0 if weapon_style(result.actor)=="MC" else 2.0)*(0.4 if reduced else 1.0)
	return point

func draw() -> void:
	weapon_tips.clear()
	arena.draw_ground(model.encounter,motion_clock,host.progress.data.options.reduced_fx)
	draw_board()
	draw_header()
	draw_sidebar()
	if phase == "aim" and is_player(): draw_aim_hero_hud()
	draw_controls()
	if detail_skill >= 0: draw_details()

func draw_board() -> void:
	field_state = field.snapshot(self)
	# Other encounter types retain the inherited objectives and telegraphs.
	if not model.objective.is_empty() or not model.optional_objective.is_empty(): super.draw_board(); return
	field.draw_ground(self,field_state)
	var objects: Array = []
	for cell in model.obstacles: objects.append({"cell":cell,"obstacle":true,"id":-1})
	for unit in model.units:
		if unit.get("withdrawn",false): continue
		if unit.hp>0 or (phase.begins_with("animate") and result.get("hits",[]).any(func(hit): return hit.id==unit.id)):
			objects.append({"cell":unit.cell,"obstacle":false,"id":unit.id})
	objects.sort_custom(func(a,b): return a.cell.x+a.cell.y<b.cell.x+b.cell.y)
	for object in objects:
		if object.obstacle: battlefield.draw_obstacle(model.encounter,object.cell)
		else: draw_unit(object.id)
	field.draw_annotations(self,field_state)
	if phase.begins_with("animate"): draw_skill_effect()
	for actor in passive_feedback.pulses: draw_passive_badge(actor)
	for item in floats:
		var point: Vector2 = unit_position(item.id)+Vector2(0,-53-(1.5-item.life)*23-item.get("offset",0))
		host.centered(item.text,point.y,12,item.color,point.x)

func draw_unit(id: int) -> void:
	var unit: Dictionary = model.units[id]
	var p: Vector2 = unit_position(id)
	var colour: Color = JADE if unit.team == 0 else Color("bb969e")
	var face: int = facing if phase == "facing" and id == model.current_id else unit.face
	var direction: Vector2i = Rules.DIRECTIONS[face]
	var vector: Vector2 = visual_direction(id,Vector2((direction.x-direction.y)*BOARD.STEP.x,(direction.x+direction.y)*BOARD.STEP.y).normalized())
	var child: bool = model.encounter.begins_with("portugal_child")
	var height := 44.0 if child else 60.0
	var reaction := damage_reaction(id)
	draw_passive_pulse(id,p)
	if unit.kind == "target":
		arena.draw_target(p,reaction,clock)
		height = 59
	else:
		var pose := "ready"
		var pose_time := motion_clock
		var style := weapon_style(id)
		if phase=="walk" and walk_actor==id: pose = "walk"; pose_time = clock
		if phase.begins_with("animate") and result.get("actor",-1)==id:
			pose = "guard" if effect_kind(id,result.skill) in ["cover","brace","root","breath"] else {"LA":"thrust","MC":"crush","FO":"shoot","PU":"punch"}.get(style,"attack")
			pose_time = clock
		elif phase=="timing_defend" and plan.get("targets",[]).has(id): pose = "parry"; pose_time = 0.2
		elif phase.begins_with("animate") and result.get("impacted",false):
			for hit in result.get("hits",[]):
				if hit.id==id and hit.damage==0: pose = "parry"; pose_time = clock-ActorMotion.IMPACT
		if reaction>0: pose = "hurt"; pose_time = maxf(0,clock-ActorMotion.IMPACT)
		if unit.hp<=0 and reaction<0.3: pose = "kneel"
		weapon_tips[id] = draw_combat_actor(unit,p,vector,pose,pose_time,style,reaction)
	var arrow := p+vector*19
	host.draw_colored_polygon(PackedVector2Array([arrow+vector*4,arrow-vector*3+vector.orthogonal()*3,arrow-vector*3-vector.orthogonal()*3]),GOLD if id==model.current_id else colour)
	if id == model.current_id:
		host.centered("▼ "+unit.name,p.y-height-16,10,GOLD,p.x)
	elif (phase=="aim" and preview_cell()==unit.cell) or (phase=="choose" and hover_cell==unit.cell): host.centered(unit.name,p.y-height-16,10,PAPER,p.x)
	host.bar(p+Vector2(-18,-height-10),Vector2(36,3),unit.hp,unit.max_hp,JADE if unit.team==0 else RED)
	host.bar(p+Vector2(-18,-height-5),Vector2(36,2),unit.posture,unit.max_posture,GOLD)

func draw_combat_actor(unit: Dictionary,point: Vector2,direction: Vector2,pose: String,time: float,style: String,reaction: float) -> Vector2:
	return COMBAT_ART.draw_actor(host,COMBAT_ART.identity(model,unit),point,direction.x<0,pose,time,style,model.safe_training,reaction,host.progress.data.options.reduced_fx,direction)

func icon_texture(actor: int, skill: int) -> Texture2D:
	if icon_paths.is_empty():
		for row in JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_01/skill_icons.json")).skills: icon_paths[row.id] = row.icon
	var key := "basic"
	if skill==0:
		key = {"ES":"ES01","LA":"LA01","MC":"MC07","FO":"FO07","PU":"PU07"}.get(weapon_style(actor),"ES01")
	if skill in [6,7]:
		var items: Dictionary = preload("res://scripts/chapter/player_items.gd").items()
		for entry in items.values():
			if entry.has("recovery") and ((skill==6 and entry.recovery.has("hp")) or (skill==7 and entry.recovery.has("qi"))):
				var item_path: String = entry.icon
				if not portugal_icons.has(item_path): portugal_icons[item_path] = load(item_path)
				return portugal_icons[item_path]
	if skill==4 and actor==1: key = "DU01"
	elif skill==1 and model.get("style")!=null: key = model.FIRST[model.style]
	elif skill in [2,3] and model.get("mode")=="practice": key = model.FIRST[model.style]
	var path: String = "res://assets/art/combat/portugal/basic-attack.png" if key=="basic" else icon_paths.get(key,"")
	if path.is_empty(): return null
	if not portugal_icons.has(path): portugal_icons[path] = load(path) if ResourceLoader.exists(path) else ImageTexture.create_from_image(Image.load_from_file(path))
	return portugal_icons[path]

func draw_header() -> void:
	host.panel(Rect2(16,12,928,61),BG,EDGE)
	host.text_at(encounter_location()+" · RONDA %02d"%model.round_no,Vector2(30,33),10,GOLD)
	host.text_at(host.fit_text(encounter_caption(),210,14),Vector2(30,56),14,PAPER)
	host.draw_line(Vector2(250,25),Vector2(250,61),Color(EDGE,0.65),1,true)
	host.text_at("ORDEM DOS TURNOS",Vector2(267,30),9,MUTED)
	var living: Array = model.order.filter(func(id): return model.units[id].hp>0 and not model.units[id].get("withdrawn",false))
	var width := minf(148,floorf(590.0/maxi(1,living.size())))
	var shown := 0
	for offset in model.order.size():
		var id: int = model.order[(model.order_index+offset)%model.order.size()]
		if not living.has(id): continue
		var unit: Dictionary = model.units[id]
		var x := 267+shown*width
		if shown==0: host.draw_rect(Rect2(x,36,width-8,28),Color("34564f"))
		host.draw_line(Vector2(x,64),Vector2(x+width-8,64),JADE if unit.team==0 else RED,2,true)
		host.text_at(host.fit_text(unit.name,width-22,11),Vector2(x+7,54),11,PAPER if shown==0 else MUTED)
		shown += 1
	host.text_at("Esc · pausa",Vector2(864,31),9,MUTED)

func encounter_location() -> String:
	return preload("res://scripts/combat/battle_maps.gd").profile(arena.map_id).title

func encounter_caption() -> String:
	return model.caption


func compact_command_name(skill: int, full_name: String) -> String:
	return "Básico" if skill == 0 else full_name

func draw_icon_button(button_id: String,shortcut: int,skill: int,rect: Rect2,rarity: Color,enabled: bool,detail: String,fallback_name: String) -> void:
	host.button(button_id,"",rect,enabled)
	host.buttons[-1]["inspect_skill"] = skill
	host.draw_rect(Rect2(rect.position+Vector2(4,4),Vector2(2,rect.size.y-8)),rarity)
	presentation.draw_icon(host,icon_texture(model.current_id,skill),Rect2(rect.position+Vector2(12,5),Vector2(36,36)))
	var key_label: String = str(shortcut)
	if GamePreferences.controller: key_label = {1:"X",2:"Y",3:"Y → 2",4:"Y → 3",9:"Select"}.get(shortcut,str(shortcut))
	host.text_at(host.fit_text("%s · %s"%[key_label,fallback_name],rect.size.x-80,14),rect.position+Vector2(60,21),14,PAPER if enabled else MUTED)
	host.text_at(host.fit_text(detail,rect.size.x-72,10),rect.position+Vector2(60,38),10,MUTED)

func timing_title() -> String:
	if phase=="timing_defend": return "Reagir ao golpe · "+plan.name
	return super.timing_title()

func effect_kind(actor: int,skill: int) -> String:
	if actor==0 and skill in [0,1] and model.get("style")!=null:
		if skill==1 and model.style=="MC": return "brace"
		return {"ES":"cut","LA":"line","MC":"heavy","FO":"ranged","PU":"punch"}.get(model.style,"cut")
	return super.effect_kind(actor,skill)

func draw_skill_effect() -> void:
	if not attacking_animation(): super.draw_skill_effect(); return
	var actor: int = result.actor
	var style := weapon_style(actor)
	var reduced: bool = host.progress.data.options.reduced_fx
	var chest := 23.0 if model.encounter.begins_with("portugal_child") else 32.0
	var source: Vector2 = unit_position(actor)+Vector2(0,-chest)
	var aim: Vector2i = selected_cell if result.skill>=0 else (plan.cells[0] if not plan.get("cells",[]).is_empty() else model.units[actor].cell)
	var target: Vector2 = screen(aim)+Vector2(0,-chest)
	var direction := strike_direction(actor)
	var kind := effect_kind(actor,result.skill)
	var tint := Color("efe7cf") if style in ["ES","PU"] else Color("d6c394")
	if style=="PU":
		var punch := FEEL.extension(style,clock)
		if clock>=0.34 and clock<0.58:
			host.draw_line(source.lerp(target,0.5),source.lerp(target,punch),Color(tint,0.45*(1.0-smoothstep(ActorMotion.IMPACT,0.58,clock))),1.7,true)
	else: draw_skill_travel(kind,source,target,direction,tint,reduced)
	if not result.get("impacted",false): return
	var progress := clampf((clock-ActorMotion.IMPACT)/0.24,0,1)
	var fade := (1.0-progress)*(0.55 if reduced else 1.0)
	if fade<=0: return
	for hit in result.get("hits",[]):
		var centre: Vector2 = unit_position(hit.id)+Vector2(0,-chest)
		if hit.damage==0 and hit.get("resource","").is_empty():
			var perfect: bool = int(result.get("defense_grades",{}).get(hit.id,0))==2
			var ink := Color(GOLD if perfect else JADE,fade)
			var angle := direction.angle()+PI
			host.draw_arc(centre,10+progress*5,angle-0.7,angle+0.7,12,ink,2.0,true)
			if perfect: impact_sparks(centre,Color(PAPER,fade),progress,2 if reduced else 4)
		elif hit.damage>0:
			impact_sparks(centre,Color(tint,fade),progress,2 if reduced else (5 if style=="MC" else 3))
			if style=="MC" and not reduced:
				var ground: Vector2 = unit_position(hit.id)
				for side in [-1,1]: host.draw_circle(ground+Vector2(side*(4+progress*10),-progress*3),1+progress*2,Color(0.64,0.58,0.43,fade*0.22))
		if hit.get("breaks",false):
			for side in [-1,1]: host.draw_line(centre+Vector2(side*7,-9),centre+Vector2(side*(10+progress*9),1+progress*4),Color(GOLD,fade),1.8,true)

func draw_skill_travel(kind: String,actor: Vector2,aim: Vector2,direction: Vector2,tint: Color,reduced: bool) -> void:
	if kind=="ranged" and result.get("actor",-1)==0 and model.get("style")=="FO":
		if clock>=ActorMotion.PROJECTILE_RELEASE and clock<ActorMotion.IMPACT:
			var muzzle: Vector2 = weapon_tips.get(result.actor,actor+direction*28)
			var progress := (clock-ActorMotion.PROJECTILE_RELEASE)/(ActorMotion.IMPACT-ActorMotion.PROJECTILE_RELEASE)
			host.draw_line(muzzle,muzzle.lerp(aim,progress),Color(GOLD,0.7*(1-progress)),1.5,true)
			host.draw_circle(muzzle,4*(1-progress),Color(1,0.84,0.45,0.8*(1-progress)))
			if not reduced: host.draw_circle(muzzle+Vector2(progress*7,-progress*8),3+progress*5,Color(0.83,0.81,0.7,0.18*(1-progress)))
		if not reduced and clock>=ActorMotion.PROJECTILE_RELEASE and clock<0.9:
			var age := (clock-ActorMotion.PROJECTILE_RELEASE)/(0.9-ActorMotion.PROJECTILE_RELEASE)
			var muzzle: Vector2 = weapon_tips.get(result.actor,actor+direction*28)
			host.draw_circle(muzzle+Vector2(age*10,-age*14),3+age*7,Color(0.84,0.82,0.75,0.20*(1-age)))
		return
	super.draw_skill_travel(kind,actor,aim,direction,tint,reduced)

func draw_sidebar() -> void:
	if phase=="aim": draw_preview_sidebar(); return
	var unit: Dictionary = model.current()
	var accent := JADE if is_player() else RED
	host.panel(Rect2(16,86,222,198),BG,EDGE)
	host.draw_line(Vector2(29,99),Vector2(29,139),accent,2,true)
	host.text_at("A TUA VEZ" if is_player() else "TURNO ADVERSÁRIO",Vector2(39,107),10,accent)
	var name_size := 19
	while name_size>12 and host.font.get_string_size(unit.name,HORIZONTAL_ALIGNMENT_LEFT,-1,name_size).x>184: name_size -= 1
	host.text_at(host.fit_text(unit.name,184,name_size),Vector2(39,131),name_size,PAPER)
	host.text_at(host.fit_text(model.role_name(unit.id),194,11),Vector2(30,151),11,MUTED)
	var rows: Array = [["VIDA",unit.hp,unit.max_hp,JADE],["ALENTO",unit.qi,unit.max_qi,Color("74b5d0")],["POSTURA",unit.posture,unit.max_posture,GOLD]]
	for i in rows.size():
		var row: Array = rows[i]
		var y := 171+i*29
		host.text_at(row[0],Vector2(30,y),10,MUTED)
		host.text_at("%d / %d"%[row[1],row[2]],Vector2(155,y),11,PAPER)
		host.bar(Vector2(30,y+6),Vector2(193,4),row[1],row[2],row[3])
	host.text_at("%d casas  ·  %s"%[unit.moves,"ação usada" if unit.acted else "ação disponível"],Vector2(30,267),11,accent)
	if passive_feedback_readable() and not passive_feedback.pages.is_empty():
		draw_passive_feedback(); return
	host.panel(Rect2(16,295,222,101),BG,EDGE)
	if is_player() and phase=="move":
		var state: Dictionary = field_state
		host.text_at("MOVIMENTO",Vector2(29,315),10,JADE)
		if not model.inside(state.focus):
			host.text_at("Escolhe uma casa no campo.",Vector2(29,339),11,PAPER)
		elif state.valid or not state.path.is_empty():
			host.text_at("Percurso: %d casa%s"%[state.cost,"" if state.cost==1 else "s"],Vector2(29,339),12,PAPER)
			var budget: String = "Movimento: %d → %d"%[state.budget,state.budget-state.cost] if state.valid else "Disponível: %d · faltam %d"%[state.budget,state.cost-state.budget]
			host.text_at(budget,Vector2(29,360),11,JADE if state.valid else RED)
		else:
			var lines := wrap_hint(state.reason,195,11,3)
			for i in lines.size(): host.text_at(lines[i],Vector2(29,339+i*17),11,RED if state.focus!=state.origin else PAPER)
		return
	var tip: Array = tutorial_tip()
	host.text_at(host.fit_text(tip[0],195,10),Vector2(29,315),10,GOLD)
	var lines: Array[String] = []
	for i in range(1,tip.size()): lines.append_array(wrap_hint(tip[i],195,10,2))
	for i in mini(4,lines.size()): host.text_at(lines[i],Vector2(29,335+i*16),10,PAPER)

func draw_preview_sidebar() -> void:
	var state: Dictionary = field_state
	if state.is_empty() or state.valid: super.draw_preview_sidebar(); return
	var definition: Dictionary = model.skill_def(model.current_id,selected_skill)
	host.panel(Rect2(16,86,222,310),BG,GOLD)
	host.text_at(host.fit_text(model.current().name+" · PREVISÃO",197,12),Vector2(29,108),12,GOLD)
	host.text_at(host.fit_text(definition.name,197,16),Vector2(29,131),16,PAPER)
	host.text_at("%d alento · 1 ação"%definition.cost,Vector2(29,152),11,MUTED)
	var reason: String = state.reason if not state.reason.is_empty() else "Escolhe um alvo nos cantos dourados."
	var lines := wrap_hint(reason,197,12,5)
	for i in lines.size(): host.text_at(lines[i],Vector2(29,188+i*19),12,RED if model.inside(state.focus) else PAPER)
	host.text_at("Tracejado: alcance máximo.",Vector2(29,304),11,MUTED)
	host.text_at("Dourado: alvo válido.",Vector2(29,326),11,MUTED)
	host.text_at("Tab · percorrer alvos",Vector2(29,381),10,GOLD)

func draw_passive_feedback() -> void:
	var page: Dictionary = passive_feedback.pages[0]
	var names: Dictionary = {}
	for row in JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_01/passives.json")).passives: names[row.id] = row.name
	if not page.rows.any(func(row): return names.has(row.passive)):
		super.draw_passive_feedback(); return
	host.panel(Rect2(16,295,222,101),BG,JADE)
	host.text_at("PASSIVAS · EFEITO REAL",Vector2(29,312),10,JADE)
	for i in mini(2,page.rows.size()):
		var row: Dictionary = page.rows[i]
		var description: String = PassiveFeedback.summary(row,host.localization)
		if row.effects.has("condition"):
			description = "−%d dano recebido"%row.effects.get("mitigated_damage",0)+(" · arredondado" if not row.effects.has("mitigated_damage") else "")
		host.text_at(host.fit_text(names.get(row.passive,row.passive),195,10),Vector2(29,330+i*31),10,PAPER)
		host.text_at(host.fit_text(description,195,9),Vector2(29,343+i*31),9,JADE)

func draw_controls() -> void:
	if host.completed and host.ending.has_result:
		host.buttons.clear(); host.ending.draw(host); return
	host.panel(Rect2(16,408,928,118),BG,EDGE)
	if phase=="telegraph":
		host.centered("GOLPE ANUNCIADO · "+plan.name.to_upper(),442,19,RED)
		host.centered(defense_instruction(),475,13,JADE if not model.perfect_defense_enabled else GOLD)
		host.centered("Lê o gesto. A defesa é uma reação ao ataque adversário.",509,11,MUTED)
		return
	if phase.begins_with("timing"): draw_timing(); return
	if phase in ["cutin","walk","enemy_wait","skip","animate_enemy","animate_player"]:
		var title := "A reposicionar…" if phase=="walk" else (quality_label if not quality_label.is_empty() else "O adversário prepara-se" if phase=="enemy_wait" else "O ritmo do combate")
		host.centered(title,452,22,GOLD)
		if not log_lines.is_empty(): host.centered(host.fit_text(log_lines[-1],850,13),486,13,PAPER)
		return
	if phase=="items":
		draw_item_button(6,1,Rect2(30,420,434,47),model.potions)
		draw_item_button(7,2,Rect2(482,420,445,47),model.tonics)
		host.text_at("O item é gasto apenas ao confirmar o alvo.",Vector2(32,500),12,MUTED)
		host.button("t_cancel","Voltar",Rect2(814,478,113,36))
		return
	var commands: Array = model.commands(model.current_id)
	var width := (896.0-maxi(0,commands.size()-1)*8)/maxi(1,commands.size())
	hovered_detail_skill = -1
	for i in commands.size():
		var skill: int = commands[i]
		var rect := Rect2(30+i*(width+8),419,width,47)
		if i==commands.size()-1 and (not model.profile.is_empty() or model.encounter=="atlantic_boarding"):
			draw_icon_button("t_items",9,6,rect,MUTED,not model.current().acted and phase!="facing","%d / %d"%[model.potions,model.tonics],"Bolsa")
			continue
		if skill<0: continue
		var definition: Dictionary = model.skill_def(model.current_id,skill)
		draw_icon_button("t_skill_%d"%skill,i+1,skill,rect,Color(definition.rarity_color),model.available(skill) and phase!="facing",button_status(skill,definition),compact_command_name(skill,definition.name))
		if rect.has_point(host.get_global_mouse_position()): hovered_detail_skill = skill
	host.text_at("ORIENTAÇÃO FINAL" if phase=="facing" else "DESTINO" if phase=="move" else "ALVO" if phase=="aim" else "ESCOLHE A TUA AÇÃO",Vector2(31,488),10,GOLD)
	var help := "Q / E · direção da guarda" if phase=="facing" else "Casa verde e Enter para mover" if phase=="move" else "Escolhe o alvo e confirma" if phase=="aim" else "Mover e agir no mesmo turno"
	host.text_at(help,Vector2(31,508),11,MUTED)
	host.button("t_details","F · Técnica",Rect2(290,478,127,36),phase in ["choose","move","aim"])
	if phase in ["choose","move"]:
		host.button("t_move","G · Mover",Rect2(428,478,116,36),model.current().moves>0)
		host.button("t_undo","Z · Desfazer",Rect2(552,478,127,36),can_undo_move())
	if phase=="choose":
		host.button("t_end","T · Terminar turno",Rect2(690,478,236,36))
	elif phase in ["move","aim","facing"]:
		var valid: bool = phase=="facing" or (phase=="aim" and model.valid_attack(selected_skill,selected_cell)) or (phase=="move" and not model.path_to(model.current_id,selected_cell).is_empty())
		host.button("t_confirm","Terminar" if phase=="facing" else "Confirmar",Rect2(690,478,142,36),valid)
		host.button("t_cancel","Voltar",Rect2(840,478,86,36))


func draw_timing() -> void:
	if phase=="timing_volley": draw_volley(); return
	var defend := phase=="timing_defend"
	var simple: bool = defend and not model.perfect_defense_enabled
	var accent := JADE if simple else GOLD
	host.text_at(host.fit_text(timing_title(),883,18),Vector2(34,435),18,RED if defend else GOLD)
	host.button("t_timing","ESPAÇO / A · reagir" if defend else "ESPAÇO / A · golpear",Rect2(34,449,278,36))
	host.text_at("Também podes clicar neste botão.",Vector2(34,506),10,MUTED)
	host.text_at("FAIXA LARGA · BOM" if simple else "CENTRO ESTREITO · PERFEITO",Vector2(332,447),11,accent)
	var rect := Rect2(332,458,585,23)
	var windows := timing_windows()
	host.draw_rect(rect,Color("091f24"))
	host.draw_rect(Rect2(rect.position+Vector2(rect.size.x*(timing_center-windows.x),0),Vector2(rect.size.x*windows.x*2,23)),Color("467e72"))
	if windows.y>0:
		host.draw_rect(Rect2(rect.position+Vector2(rect.size.x*(timing_center-windows.y),0),Vector2(rect.size.x*windows.y*2,23)),GOLD)
	# Outlines and a centre marker distinguish the zones even without colour.
	host.draw_rect(Rect2(rect.position+Vector2(rect.size.x*(timing_center-windows.x),0),Vector2(rect.size.x*windows.x*2,23)),PAPER,false,1)
	if windows.y>0: host.draw_rect(Rect2(rect.position+Vector2(rect.size.x*(timing_center-windows.y),-2),Vector2(rect.size.x*windows.y*2,27)),PAPER,false,2)
	host.draw_line(rect.position+Vector2(rect.size.x*timing_center,-3),rect.position+Vector2(rect.size.x*timing_center,26),PAPER,1,true)
	var x := rect.position.x+timing_progress(clock/duration)*rect.size.x
	host.draw_rect(Rect2(x-2,453,4,33),PAPER)
	var message := "Bom reduz o impacto. Tomé ensinará a Defesa Perfeita." if simple else "Golpe perfeito: mais dano e recuperação de alento."
	if defend and not simple:
		var preview: Dictionary = model.defense_preview(model.current_id,plan.targets[defense_index],plan,2)
		message = preview.side+" · "+("apara e contra-ataca" if preview.counter else "sem contra-ataque; mantém a guarda")
		if preview.side=="Costas": message = "Costas expostas · a defesa reduz o dano, mas não apara."
	if defend and double_defense_timing(): message = "Golpe %d / %d · prime uma vez por marca."%[defense_beat+1,defense_beat_count()]
	host.text_at(host.fit_text(message,585,11),Vector2(332,507),11,PAPER)

func defense_instruction() -> String:
	return "ESPAÇO no centro estreito · Defesa Perfeita" if model.perfect_defense_enabled else "ESPAÇO na faixa larga · defesa simples"

func tutorial_tip() -> Array:
	if phase=="timing_defend":
		return ["DEFESA PERFEITA" if model.perfect_defense_enabled else "DEFESA SIMPLES",defense_instruction(),"Confirma apenas uma vez.","A orientação final importa."]
	if phase=="timing_attack": return ["O MOMENTO DO GOLPE","Confirma uma vez no centro estreito.","O impacto acontece depois do gesto.","O básico recupera alento."]
	if phase=="facing" or (is_player() and model.current().acted): return ["ORIENTAÇÃO FINAL","Q / E ou clique: escolhe a direção.","Enter termina o turno.","A defesa acontece no golpe inimigo."]
	if model.encounter=="portugal_duel": return ["OBSERVAR E RESPONDER","Experimenta distância e orientação.","Não exige vitória nem itens.","A derrota continua a história."]
	if model.get("mode")=="school": return ["BÁSICO → TÉCNICA","Básico num turno; técnica no seguinte.","Confere custo e alcance antes de agir.","Podes mover antes e depois da ação."]
	return ["UMA AÇÃO POR TURNO","Mover não consome o ataque.","Confirma alcance e alvo antes de agir.","A defesa acontece no turno inimigo."]

func input_event(event: InputEvent) -> void:
	if model.encounter=="atlantic_boarding" and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_9:
		open_items(); return
	# BattleHost maps viewport pixels back to the reference's 960×540 coordinates.
	# Use that event position rather than polling the outer window.
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		super.input_event(event)
		return
	var point: Vector2 = event.position
	if phase.begins_with("timing"):
		for button in host.buttons:
			if button.id=="t_timing" and button.rect.has_point(point): commit_timing(); return
		return
	if detail_skill >= 0:
		for button in host.buttons:
			if button.id == "t_detail_close" and button.rect.has_point(point): detail_skill = -1; return
		return
	if phase == "cutin" or not onboarding.active.is_empty(): return
	for button in host.buttons:
		if not button.rect.has_point(point): continue
		if button.has("inspect_skill") and not button.enabled:
			detail_skill = button.inspect_skill; return
		if button.enabled:
			activate(button.id); return
	if phase not in ["choose","move","aim","facing"] or point.y > 399: return
	var cell: Vector2i = cell_at(point)
	if not model.inside(cell): return
	if phase == "facing":
		if cell != model.current().cell: facing = model.direction_index(cell-Vector2i(model.current().cell))
		return
	select_cell(cell,event.double_click)



