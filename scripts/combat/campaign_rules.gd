extends "res://scripts/combat/portugal_rules.gd"
const Medida = preload("res://scripts/combat/medida_runtime.gd")
var medida_state: Dictionary={}
var low_cover: Array[Vector2i]=[]
const Development = preload("res://scripts/chapter/character_development.gd")
var battle_practice: Dictionary = {}
const Firearm = preload("res://scripts/combat/firearm_skills.gd")
const OrderStudies = preload("res://scripts/combat/order_studies.gd")
var order_guard := ""
var order_guard_face := 0
var order_exposed_face := -1
var order_trial_positioned := false
var order_trial_defended := false
const ORDER_TRIAL_CELL := Vector2i(4,4)
const STYLES := {"ES":{"name":"Espada","range":1,"power":22},"LA":{"name":"Lança","range":2,"power":20},"MC":{"name":"Machado","range":1,"power":28},"FO":{"name":"Arma de fogo","range":4,"power":20},"PU":{"name":"Desarmado","range":1,"power":18}}
const FIRST := {"ES":"ES07","LA":"LA07","MC":"MC08","FO":"FO07","PU":"PU07"}
## Local practice drills, not entries or unlocks from the canonical skill catalogue.
const DEMO := {"ES":["C01-DEMO-ES-01","C01-DEMO-ES-02"],"LA":["C01-DEMO-LA-01","C01-DEMO-LA-02"],"MC":["C01-DEMO-MC-01","C01-DEMO-MC-02"],"FO":["C01-DEMO-FO-01","C01-DEMO-FO-02"],"PU":["C01-DEMO-PU-01","C01-DEMO-PU-02"]}
const DEMO_NAMES := {"ES":["Corte concentrado","Corte em arco"],"LA":["Linha de haste","Pressão de haste"],"MC":["Impacto concentrado","Talho em arco"],"FO":["Disparo imóvel","Disparo móvel"],"PU":["Palma curta","Entrada de flanco"]}
const PRACTICE_TIPS := {"ES":"precisão e passagem","LA":"distância e linha","MC":"impacto e área","FO":"linha de tiro e preparação","PU":"interrupção e flanco"}
var mode := ""
var style := "ES"
var moved_in_battle := false
var correct_sequence := false
var previous_action := -1
var previous_action_turn := -1
var technique_evaluated := false
var technique_used := false
var support_used := false
var skill_names: Dictionary = {}
var stationary_eligible := false
var stationary_cell := Vector2i(-1,-1)
var protective_ready := false
var contact_weakened := false
var preparation := false
var prepared_contact := false
var approach_weakened := false
var weakened_target := -1
var equipment_bonus: Dictionary = {}
var firearm_guard := false
var firearm_moved := false
## Optional read-only snapshot for encounters outside Portugal (e.g. quick tests).
var progress_override: Dictionary = {}
func combat_progress():
	return ChapterProgress if progress_override.is_empty() else progress_override
func weapon_techniques_available() -> bool: return mode in ["school","practice","boarding","order_trial"]
func companion_support_available() -> bool: return mode in ["duarte_support","boarding"]

func start_encounter(kind: String, hero_name: String, chosen_style: String = "ES") -> void:
	medida_state.clear(); low_cover.clear()
	order_guard="";order_exposed_face=-1;order_trial_positioned=false;order_trial_defended=false
	super.start_lesson(1,hero_name)
	mode = kind; style = chosen_style
	battle_practice.clear()
	firearm_guard = false; firearm_moved = false
	moved_in_battle = false; correct_sequence = false; previous_action = -1; previous_action_turn = -1
	technique_evaluated = false; technique_used = false; support_used = false
	stationary_eligible = false; protective_ready = false; contact_weakened = false; preparation = false; prepared_contact = false; approach_weakened = false
	weakened_target = -1
	perfect_defense_enabled = kind == "perfect_defense" or combat_progress().flags.get("perfect_defense",false)
	safe_training = kind != "duel"
	encounter = "portugal_"+kind
	caption = {"adult_basic":"Repetir com Duarte","adult_defense":"Ler o golpe de Duarte","duel":"A distância · Leonor","style_test":"Experimentar · "+STYLES[style].name,"school":"Básico → técnica · "+STYLES[style].name,"perfect_defense":"Defesa Perfeita · Tomé","duarte_support":"Proteção de Duarte"}.get(kind,"Treino")
	units[0].kind = "hero"
	units[0].qi = 8; units[0].max_qi = 20
	units[0].cell = Vector2i(4,3)
	units[2].name = "Duarte" if kind.begins_with("adult_") else ("Leonor" if kind == "duel" else "Tomé")
	units[2].kind = "leonor" if kind == "duel" else "tome"
	if kind in ["adult_basic","style_test","school","practice"]:
		lesson = 0; units[2].name = "Alvo de treino"; units[2].kind = "target"
	if kind == "adult_basic": units[0].cell = Vector2i(2,5)
	if kind in ["style_test","school","practice"] and style in ["LA","FO"]:
		units[0].cell = Vector2i(3,3); obstacles.erase(Vector2i(3,3))
	if kind == "school" and style == "MC": units[2].name = "Tomé"; units[2].kind = "tome"; lesson = 1
	if kind == "duel":
		units[0].hp = 90; units[0].max_hp = 90
		units[2].hp = 4000; units[2].max_hp = 4000
		units[2].defense = 28; units[2].movement = 8; units[2].moves = 8
		units[2].posture = 600; units[2].max_posture = 600
	if companion_support_available():
		heroes[1].hp = 120; heroes[1].max_hp = 120; heroes[1].qi = 12; heroes[1].max_qi = 12
		heroes[1].posture = 100; heroes[1].max_posture = 100
		heroes[1].kind = "duarte"; heroes[1].name = "Duarte"; heroes[1].withdrawn = false
		heroes[1].movement = 5; heroes[1].moves = 5
		heroes[1].cell = Vector2i(4,4); heroes[1].face = 0; heroes[1].speed = 24
		order_index = -1; rebuild_order(); next_turn()
	for unit in units: unit.turn_origin = unit.cell; unit.home = unit.cell
	for row in JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_01/skill_icons.json")).skills:
		skill_names[row.id] = row.name
	if kind=="practice":
		if style=="FO":
			units[0].cell = Vector2i(4,3); units[0].turn_origin = units[0].cell; units[0].home = units[0].cell
		caption = "Prática livre · "+STYLES[style].name
		units[0].qi = 40; units[0].max_qi = 40
		units[2].hp = 9999; units[2].max_hp = 9999; units[2].posture = 9999; units[2].max_posture = 9999
		add("Segundo alvo",9999,0,9999,"target",Vector2i(6,3),10,0,1)
		add("Tomé · golpe de contacto",9999,0,9999,"tome",Vector2i(7,5),10,3,1)
		order_index = -1; rebuild_order(); next_turn()
	equipment_bonus = {}
	if kind in ["school","perfect_defense","duarte_support","boarding"] and combat_progress().flags.get("recovered",false):
		var stats: Dictionary = preload("res://scripts/chapter/player_items.gd").stats(combat_progress())
		equipment_bonus = stats
		var weapon: String = combat_progress().equipment.get("weapon","")
		if not weapon.is_empty() and preload("res://scripts/chapter/player_items.gd").items()[weapon].get("style","") != style:
			equipment_bonus.attack = 0
		for key in ["hp","qi","posture"]:
			units[0]["max_"+key] = stats[key]
			units[0][key] = mini(int(stats[key]),int(combat_progress().vitals[key])) if kind=="boarding" else int(stats[key])
		# Lessons use a separate exercise budget. Comparing or retrying weapons
		# must neither exhaust nor heal the resources carried into the voyage.
		if kind!="boarding": units[0].qi = mini(8,int(stats.qi))
		if kind!="boarding":
			units[0].hp = maxi(1,int(units[0].hp)); units[0].posture = maxi(1,int(units[0].posture))
		units[0].defense = stats.defense; units[0].speed = stats.speed
		if companion_support_available() and not Development.member(combat_progress(),"duarte").is_empty():
			var companion: Dictionary = Development.base_stats(combat_progress(),"duarte")
			for key in ["hp","qi","posture"]:
				units[1]["max_"+key] = companion[key]; units[1][key] = companion[key]
			units[1].defense = companion.defense; units[1].speed = companion.speed
		rebuild_order()

func passive_active(id: String) -> bool:
	return combat_progress().equipped_passives.has(id) and mode in ["school","perfect_defense","duarte_support","boarding"]

func commands(actor: int) -> Array:
	if actor==0 and mode in ["boarding","practice"]:
		var record: Dictionary=Development.member(combat_progress())
		var prepared: Array=record.get("active_skills",[])
		if prepared.any(func(id): return Medida.Book.rows().has(id) and not Medida.Book.LEGACY.has(id)):
			var selected: Array=[0]
			for id in prepared:
				if not str(id).begins_with(style) or not combat_progress().skills.has(id): continue
				if id==OrderStudies.IDS[style]: selected.append(100)
				elif id==FIRST[style]: selected.append(1)
				elif style=="FO" and Firearm.IDS.values().has(id): selected.append(Firearm.IDS.find_key(id))
				elif Medida.Book.rows().has(id): selected.append(Medida.Book.action(id))
			return selected
	var result: Array = _original_commands(actor)
	if actor==0 and weapon_techniques_available() and combat_progress().skills.has(OrderStudies.IDS[style]) and Development.equipped(combat_progress(),OrderStudies.IDS[style]): result.append(OrderStudies.ACTION)
	if actor==0 and weapon_techniques_available():
		for id in Medida.Book.rows():
			if Medida.Book.LEGACY.has(id): continue
			if id.begins_with(style) and combat_progress().skills.has(id) and Development.equipped(combat_progress(),id): result.append(Medida.Book.action(id))
	return result
func _original_commands(actor: int) -> Array:
	if actor==0 and style=="FO" and weapon_techniques_available():
		var actions: Array = [0]
		for action in Firearm.IDS:
			if mode in ["school","practice"] or (combat_progress().skills.has(Firearm.IDS[action]) and Development.equipped(combat_progress(),Firearm.IDS[action])): actions.append(action)
		return actions
	if actor==0 and mode=="practice": return [0,1,2,3]
	if actor == 1 and companion_support_available(): return [0,4] if mode!="boarding" or (combat_progress().skills.has("DU01") and Development.equipped(combat_progress(),"DU01","duarte")) else [0]
	return [0,1] if weapon_techniques_available() and (mode!="boarding" or (combat_progress().skills.has(FIRST[style]) and Development.equipped(combat_progress(),FIRST[style]))) else [0]

func skill_def(actor: int, skill: int) -> Dictionary:
	if actor >= 2: return super.skill_def(actor,skill)
	var definition: Dictionary = Catalog.HERO_SKILLS[1][0].duplicate(true)
	definition.name = "Ataque básico"; definition.description = "Ataque básico com alcance do manejo. Recupera 1 energia."
	definition.uses_opening = false
	if actor==0 and Medida.handles(skill): return Medida.definition(self,skill,definition)
	if actor==0 and skill==OrderStudies.ACTION and weapon_techniques_available():
		var study: Dictionary=OrderStudies.definition(style,definition)
		if passive_active("GE22") and not technique_evaluated and previous_action==0 and previous_action_turn==current().turns-1:study.cost=maxi(1,int(study.cost)-1)
		return mastered(actor,skill,study)
	if actor==0 and style=="FO" and (skill==0 or (Firearm.IDS.has(skill) and weapon_techniques_available())):
		definition = Firearm.definition(skill,definition,not firearm_moved and units[actor].cell==units[actor].turn_origin)
		if Firearm.IDS.has(skill) and passive_active("GE22") and not technique_evaluated and previous_action==0 and previous_action_turn==current().turns-1: definition.cost -= 1
		if skill==2 and not Development.member(combat_progress()).is_empty():
			definition.power = 21
			definition.chapter_power_factor = 1.15 if not firearm_moved and units[actor].cell==units[actor].turn_origin else 1.0
		if skill==1 and passive_active("FO-P11") and not firearm_moved and units[actor].cell==units[actor].turn_origin: definition.chapter_power_factor = 1.05
		if definition.power>0: definition.power += int(equipment_bonus.get("attack",0))
		return mastered(actor,skill,definition)
	definition.power = STYLES[style].power if actor == 0 else 20
	definition.range = STYLES[style].range if actor == 0 else 1
	definition.effect = "ranged" if style == "FO" and actor == 0 else "cut"
	if skill == 1 and weapon_techniques_available():
		definition.name = skill_names.get(FIRST[style],FIRST[style]); definition.content_id = FIRST[style]
		definition.cost = 4 if style != "MC" else 7
		definition.power = 18 if style != "MC" else 0
		definition.range = 2 if style == "LA" else (3 if style == "FO" else 1)
		definition.description = "Básico no turno anterior prepara o fundamento. "+{"ES":"Menos potência que o básico; acertar reduz em 10% a potência do próximo golpe de contacto.","LA":"Exige duas casas; acertar enfraquece em 10% o próximo contacto. Mantém distância fora do básico curto.","MC":"Não causa dano: prepara redução de 30% do próximo impacto recebido. Não é uma ação Defender.","FO":"Linha livre e até três casas; acertar reduz pela metade o bónus de aproximação do próximo ataque.","PU":"Contacto curto: acertar enfraquece em 10% a potência do próximo golpe."}[style]
		if style == "MC": definition.shape = "self"; definition.range = 0; definition.effect = "brace"
		if style == "LA": definition.description += " Exige alvo a exatamente duas casas."
		if passive_active("GE22") and not technique_evaluated and previous_action == 0 and previous_action_turn == current().turns-1:
			definition.cost = maxi(1,definition.cost-1)
		if (style == "LA" and passive_active("LA-P11")) or (style == "FO" and passive_active("FO-P11")):
			if not firearm_moved and current().cell == current().turn_origin: definition.chapter_power_factor = 1.05
	elif skill == 4 and actor == 1 and companion_support_available():
		definition.name = "Guarda Companheira"; definition.content_id = "DU01"
		definition.cost = 5 if not support_used and combat_progress().duarte_equipped_passives.has("DU-P09") else 6
		definition.shape = "ally"; definition.range = 1; definition.power = 0; definition.effect = "cover"
		definition.description = "Prepara uma interceptação próxima: 60% do residual para o aliado e 40% para Duarte."
	elif skill in [2,3] and actor==0 and mode=="practice":
		definition.content_id = DEMO[style][skill-2]; definition.name = "Exercício · "+DEMO_NAMES[style][skill-2]
		definition.cost = 5 if skill==2 else 7
		definition.power = 30 if skill==2 else 22; definition.posture = 24 if skill==2 else 18
		definition.description = "Exercício do pátio com arma emprestada; não concede uma técnica do catálogo. "
		if style=="ES":
			definition.shape = "single" if skill==2 else "arc"
			definition.description += "Precisão concentra potência num alvo." if skill==2 else "O corte em arco alcança os alvos adjacentes na direção escolhida."
		elif style=="LA":
			definition.shape = "line" if skill==2 else "single"; definition.range = 3 if skill==2 else 2
			definition.description += "A ponta percorre três casas em linha; unidades não interrompem a haste." if skill==2 else "Golpe de haste a até duas casas; mais pressão sobre a postura."
			if skill==3: definition.posture = 36
		elif style=="MC":
			definition.shape = "single" if skill==2 else "arc"; definition.power = 38 if skill==2 else 26
			definition.posture = 38 if skill==2 else 26
			definition.description += "Cunha sacrifica alento para concentrar dano e pressão." if skill==2 else "Talho amplo atinge a área frontal; confere os alvos na previsão."
		elif style=="FO":
			definition.shape = "single"; definition.range = 5 if skill==2 else 3; definition.effect = "ranged"
			definition.power = 36 if skill==2 else 25
			definition.description += "Tiro longo exige ficar imóvel neste turno e linha livre." if skill==2 else "Tiro curto permite reposicionar antes da ação; mantém linha livre."
		else:
			definition.shape = "single"; definition.range = 1 if skill==2 else 3
			if skill==2: definition.posture = 42
			else: definition.flank_attack = true
			definition.description += "Palma curta pressiona a postura, sem ampliar alcance." if skill==2 else "Passo de lado exige uma casa de flanco livre e desloca antes do golpe."
	elif skill != 0: return {}
	if actor == 0 and definition.power > 0: definition.power += int(equipment_bonus.get("attack",0))
	return mastered(actor,skill,definition)

func availability_reason(skill: int) -> String:
	var u: Dictionary = current()
	if u.team != 0: return "Aguarda o teu turno."
	if u.hp<=0 or u.broken or u.stun>0: return "Este personagem não pode agir enquanto estiver incapacitado."
	if not commands(current_id).has(skill): return "Esta ação não está disponível."
	if u.acted: return "A acção principal deste turno já foi usada."
	if u.qi < skill_def(current_id,skill).cost: return "Alento insuficiente. Usa o ataque básico."
	return ""

func attack_reason(skill: int, aim: Vector2i) -> String:
	if current_id==0 and Medida.handles(skill): return Medida.reason(self,skill,aim)
	if current_id==0 and skill==OrderStudies.ACTION and style=="PU":
		var available:=availability_reason(skill)
		if not available.is_empty():return available
		if distance(current().cell,aim)!=1 or current().moves<1 or not segment_open(current().cell,aim):return "Escolhe uma casa adjacente livre, com movimento disponível e trajeto aberto."
		return ""
	var reason: String = super.attack_reason(skill,aim)
	if reason.is_empty() and current_id==0 and skill==OrderStudies.ACTION:
		if style in ["LA","MC"] and Firearm.side_step(self,0,aim)==Vector2i(-1,-1): return "O estudo exige um passo lateral livre após o golpe."
		if style=="PU" and (distance(current().cell,aim)>current().moves or not segment_open(current().cell,aim)):return "O passo exige movimento disponível e trajeto livre."
	if reason.is_empty() and current_id==0 and style=="FO" and skill==3 and Firearm.side_step(self,0,aim)==Vector2i(-1,-1):
		return "Tiro de Passagem exige uma casa lateral livre."
	if reason.is_empty() and weapon_techniques_available() and skill == 1 and style == "LA" and distance(current().cell,aim) != 2:
		return "Ponta de Medida exige exatamente duas casas."
	if reason.is_empty() and weapon_techniques_available() and skill == 1 and style == "FO" and aim.x != current().cell.x and aim.y != current().cell.y:
		return "O disparo precisa de uma linha livre."
	return reason

func move_to(destination: Vector2i) -> Array[Vector2i]:
	if current_id==medida_state.get("mark_target",-1) and destination!=current().cell: medida_state.erase("mark_target")
	if current_id>=2 and medida_state.has("watch"):
		var path: Array[Vector2i]=path_to(current_id,destination)
		var hits: Array=Medida.before_enemy(self,{"path":path,"destination":destination})
		if not hits.is_empty():
			medida_state.pending_hits=hits
			if medida_state.get("watch",{}).get("id","")=="LA11" and path.size()>0:
				destination=path[-2] if path.size()>1 else current().cell
				current().medida_intercepted_stop=true
		if current().hp<=0: return []
	var result: Array[Vector2i] = super.move_to(destination)
	if current_id==0 and not result.is_empty(): firearm_moved = true
	if current_id == 0 and not result.is_empty(): moved_in_battle = true; stationary_eligible = false
	if current_id==0 and mode=="order_trial" and current().cell==ORDER_TRIAL_CELL:order_trial_positioned=true
	return result

func perform(skill: int, aim: Vector2i, quality: int) -> Dictionary:
	if current_id==0 and Medida.handles(skill): return Medida.perform(self,skill,aim,quality)
	if current_id==0 and skill==OrderStudies.ACTION and style=="PU":
		var reason:=attack_reason(skill,aim)
		if not reason.is_empty():return {"error":reason}
		var origin: Vector2i=current().cell;order_guard="PU09";order_guard_face=current().face
		var cost: int=skill_def(0,skill).cost
		if cost<7:record_passive(0,"GE22",{"qi":1})
		current().qi-=cost;current().acted=true;current().moves-=1;current().cell=aim;firearm_moved=true;moved_in_battle=true
		technique_evaluated=true;technique_used=true;previous_action=skill;previous_action_turn=current().turns
		return {"actor":0,"skill":skill,"hits":[],"cells":[aim],"text":"Passo de Lado · proteção preparada de 20% da antiga frente", "quality":quality,"movement_origin":origin,"movement_destination":aim}
	var qualifying: bool = previous_action == 0 and previous_action_turn == current().turns-1
	var definition: Dictionary = skill_def(current_id,skill)
	var actor := current_id
	var firing_origin: Vector2i = current().cell
	var study_face: int = current().face
	var study_landing: Vector2i=Firearm.side_step(self,0,aim) if current_id==0 and skill==OrderStudies.ACTION and style in ["LA","MC"] else Vector2i(-1,-1)
	var landing: Vector2i = Firearm.side_step(self,0,aim) if actor==0 and style=="FO" and skill==3 else Vector2i(-1,-1)
	var result: Dictionary = super.perform(skill,aim,quality)
	if result.has("error"): return result
	if actor==0:
		Medida.track(self,skill,aim)
		if int(definition.power)>0:
			if style=="MC": current().erase("medida_weight_until")
			if style=="FO":
				medida_state.erase("mark_target")
				medida_state.blocked_target=unit_at(aim) if result.get("hits",[]).any(func(h): return h.get("damage",0)==0) else -1
	if mode=="order_trial" and actor==0 and result.get("hits",[]).any(func(h):return h.get("damage",0)>0):valid_hits+=1
	if actor==0 and skill==OrderStudies.ACTION:
		if definition.cost<OrderStudies.COSTS[OrderStudies.IDS[style]]:record_passive(0,"GE22",{"qi":1})
		technique_evaluated=true;technique_used=true
		if style in ["ES","PU"]:
			order_guard=OrderStudies.IDS[style];order_guard_face=study_face;current().guard=false
			if style=="PU": current().moves=maxi(0,int(current().moves)-distance(firing_origin,current().cell))
		if study_landing!=Vector2i(-1,-1):
			current().cell=study_landing;result.movement_origin=firing_origin;result.movement_destination=study_landing;firearm_moved=true;moved_in_battle=true
			if style=="MC":order_exposed_face=direction_index(aim-firing_origin)
		if style=="FO" and quality>=1:
			for hit in result.get("hits",[]):
				var target: Dictionary=units[int(hit.id)]
				if hit.get("damage",0)>0 and OrderStudies.eligible_weapon(target):
					if target.kind=="boss":target.order_weapon_weakened=true
					elif int(target.turns)>=int(target.get("order_disarm_immune_until",0)):
						target.order_disarmed=true;target.order_disarm_immune_until=int(target.turns)+2
					result.text+=" · arma enfraquecida" if target.kind=="boss" else " · desarme até recompor a pega" if target.get("order_disarmed",false) else " · protegido contra reaplicação de desarme"
	if definition.power>0 and result.get("hits",[]).any(func(h): return h.get("damage",0)>0): _record_development_use(actor,skill)
	if actor==0 and style=="FO":
		if Firearm.IDS.has(skill):
			if definition.cost<Firearm.COSTS[skill]: record_passive(0,"GE22",{"qi":1})
			if skill!=1: technique_evaluated = true; technique_used = true
		if skill==8:
			firearm_guard = true; current().guard = false
		if skill==3:
			current().cell = landing; moved_in_battle = true; stationary_eligible = false; firearm_moved = true
			result.firearm_origin = firing_origin; result.firearm_landing = landing
			result.text += " · passo lateral após o disparo"
	if actor==0 and skill==1:
		if style!="FO" and definition.cost<(7 if style=="MC" else 4): record_passive(0,"GE22",{"qi":1})
		if style in ["LA","FO"] and passive_active(style+"-P11") and not firearm_moved and current().cell==current().turn_origin:
			record_passive(0,style+"-P11",{"damage_base":int(definition.get("passive_power_bonus",0))})
	if actor==1 and skill==4 and definition.cost==5: record_passive(1,"DU-P09",{"qi":1})
	if current_id == 0:
		if skill == 1:
			technique_evaluated = true; technique_used = true
			correct_sequence = qualifying and (quality >= 1 or style == "MC")
			if style in ["ES","LA","PU"] and quality >= 1: contact_weakened = true
			protective_ready = quality >= 1 and ((style == "ES" and passive_active("ES-P11")) or (style == "PU" and passive_active("PU-P11")))
			if style == "MC": preparation = true; current().guard = false
			if style == "FO" and quality >= 1: approach_weakened = true
			if style in ["ES","LA","PU","FO"] and quality>=1 and not result.hits.is_empty(): weakened_target = int(result.hits[0].id)
		previous_action = skill; previous_action_turn = current().turns
	if current_id == 1 and skill == 4: support_used = true
	return result

func end_turn(face: int) -> Dictionary:
	if current_id==0 and order_guard=="ES09":order_guard_face=face
	if current_id==0:
		for key in ["guard_0","watch"]:
			if medida_state.has(key): medida_state[key].face=face
	if current_id == 0:
		stationary_eligible = current().cell == current().turn_origin and passive_active("GE21")
		stationary_cell = current().cell
	return super.end_turn(face)

func ai_plan() -> Dictionary:
	if current_id>=2 and current().get("order_disarmed",false):return {"kind":"brace","path":[],"destination":current().cell,"targets":[],"cells":[current().cell],"name":"Recompor a pega · desarme", "order_disarm_recovery":true}
	if mode=="practice" and current_id==4:
		var previous_lesson := lesson; lesson = 1
		var contact: Dictionary = super.ai_plan(); lesson = previous_lesson
		contact.power = 12; contact.posture = 4; contact.name = "Contacto controlado de Tomé"
		if not contact.get("path",[]).is_empty():
			contact.approach_bonus = 4; contact.power += 4
		if contact_weakened and current_id==weakened_target: contact.power = roundi(contact.power*0.9)
		return _medida_plan(contact)
	if lesson == 0: return _medida_plan(super.ai_plan())
	var result: Dictionary = super.ai_plan()
	if uses_training_ai():
		result.power = 90 if mode == "duel" else 8
		result.posture = 18 if mode == "duel" else 3
		result.name = "Avaliação de Leonor" if mode == "duel" else "Golpe anunciado"
		if mode == "school" and not result.get("path",[]).is_empty():
			result.approach_bonus = 4; result.power += 4
	if contact_weakened and current_id==weakened_target and result.has("power"): result.power = roundi(result.power*0.9)
	return _medida_plan(result)

func cover_info(target: int, damage: int) -> Dictionary:
	if not companion_support_available(): return super.cover_info(target,damage)
	if target == 0 and units[1].cover_target == 0 and units[1].hp > 0 and distance(units[1].cell,units[0].cell) <= 1 and clear_line(units[1].cell,units[0].cell,1):
		return {"id":1,"remaining":int(ceil(damage*0.6)),"damage":int(ceil(damage*0.4))}
	return {"id":-1,"remaining":damage,"damage":0}

func defense_preview(actor: int, target: int, attack: Dictionary, grade: int) -> Dictionary:
	var effective: Dictionary = attack.duplicate(true)
	if units[actor].get("medida_no_charge",false) and effective.get("approach_bonus",0)>0: effective.power=maxi(0,int(effective.power)-int(effective.approach_bonus))
	if units[actor].get("medida_weaken",0)>0 and Medida.is_contact(attack): effective.power=roundi(float(effective.power)*(1.0-float(units[actor].medida_weaken)))
	if units[actor].get("order_weapon_weakened",false) and OrderStudies.physical_attack(attack):effective.power=roundi(float(attack.power)*.9)
	if approach_weakened and actor==weakened_target:
		if attack.get("approach_bonus",0)>0: effective.power = maxi(0,int(attack.power)-int(ceil(float(attack.approach_bonus)*0.5)))
	var result: Dictionary = Medida.defense(self,actor,target,effective,super.defense_preview(actor,target,effective,grade))
	if target != 0 or mode == "duel":
		result.raw_damage=result.damage; result.cover=cover_info(target,result.damage)
		return result
	if attack.get("kind","")!="ranged":
		var incoming: int=direction_index(units[actor].cell-units[0].cell)
		if not order_guard.is_empty() and (incoming==order_guard_face or (order_guard=="ES09" and incoming==(order_guard_face+1)%4)):
			var rank: int=Development.grade(combat_progress(),order_guard)
			var protection: float=(.30 if order_guard=="ES09" else .20)+([0.0,.03,.05][rank-1])
			result.damage=roundi(result.damage*(1.0-protection));result.order_guard_used=true
		if incoming==order_exposed_face:result.damage=roundi(result.damage*1.1);result.order_exposure_used=true
	var reduction := 0.0
	var active_ids: Array[String] = []
	if stationary_eligible and units[0].cell == stationary_cell and attack.kind != "ranged": reduction += 0.05
	if reduction>0: active_ids.append("GE21")
	if result.side == "Frente" and attack.kind != "ranged":
		if firearm_guard: result.damage = roundi(result.damage*(1.0-_guard_protection("FO08")))
		if protective_ready: reduction += 0.05
		if protective_ready: active_ids.append(style+"-P11")
		if preparation and passive_active("MC-P11"): reduction += 0.05
		if preparation and passive_active("MC-P11"): active_ids.append("MC-P11")
		if preparation: result.damage = roundi(result.damage*(1.0-_guard_protection("MC08")))
	result.chapter_passives = {}
	for i in active_ids.size():
		result.chapter_passives[active_ids[i]] = roundi(result.damage*(1.0-i*0.05))-roundi(result.damage*(1.0-(i+1)*0.05))
	result.damage = roundi(result.damage*(1.0-minf(reduction,0.2)))
	result.raw_damage = result.damage
	result.cover = cover_info(target,result.damage)
	return result

func resolve_enemy(plan: Dictionary, grades: Dictionary) -> Dictionary:
	if current().get("medida_slow",0)>0:
		plan=plan.duplicate(true)
		var path: Array=plan.get("path",[])
		if not path.is_empty() and distance(path[-1],units[0].cell)<distance(current().turn_origin,units[0].cell):
			plan.medida_advance_reduced=true
	if current().get("medida_intercepted_stop",false):
		plan=plan.duplicate(true)
		if Medida.is_contact(plan) and distance(current().cell,units[0].cell)>1: plan.targets=[]; plan.cells=[]; plan.kind="approach"
		current().erase("medida_intercepted_stop")
	var medida_previews: Dictionary={}
	for target in plan.get("targets",[]): medida_previews[target]=defense_preview(current_id,target,plan,int(grades.get(target,0)))
	var watched: Array=medida_state.get("pending_hits",[]).duplicate(true)
	medida_state.erase("pending_hits")
	watched.append_array(Medida.before_enemy(self,plan))
	if current().hp<=0:
		current().acted=true
		return {"actor":current_id,"skill":-1,"hits":watched,"cells":[],"text":"Interrompido pela vigia","quality":0}
	var order_guard_used: bool=plan.get("targets",[]).has(0) and defense_preview(current_id,0,plan,int(grades.get(0,0))).get("order_guard_used",false)
	var order_exposure_used: bool=plan.get("targets",[]).has(0) and defense_preview(current_id,0,plan,int(grades.get(0,0))).get("order_exposure_used",false)
	var consumes_firearm_guard: bool = firearm_guard and plan.get("targets",[]).has(0) and plan.get("kind","")!="ranged" and flank(current_id,0)=="Frente"
	var passive_changes: Dictionary = {}
	if plan.get("targets",[]).has(0):
		passive_changes = defense_preview(current_id,0,plan,int(grades.get(0,0))).get("chapter_passives",{})
	var had_support: bool = companion_support_available() and units[1].cover_target == 0
	var had_preparation: bool = preparation and plan.get("targets",[]).has(0) and plan.get("kind","")!="ranged" and flank(current_id,0)=="Frente"
	if weapon_techniques_available() and style == "MC" and preparation and plan.get("targets",[]).has(0): prepared_contact = true
	var result: Dictionary = super.resolve_enemy(plan,grades)
	if not result.has("error"):
		result.hits.append_array(watched)
		if not watched.is_empty(): result.text+=" · Vigia da Medida"; result.medida_watch_hits=watched
		Medida.after_enemy(self,plan,grades,medida_previews)
	if not result.has("error"):
		if order_guard_used:_record_development_use(0,OrderStudies.ACTION);order_guard=""
		if order_exposure_used:order_exposed_face=-1
		if current().get("order_disarmed",false):current().erase("order_disarmed")
		if OrderStudies.physical_attack(plan):current().erase("order_weapon_weakened")
		if mode=="order_trial" and plan.get("targets",[]).has(0) and int(grades.get(0,0))>=1 and flank(current_id,0)=="Frente":order_trial_defended=true
	if not result.has("error"):
		var hero_hit: bool = result.get("hits",[]).any(func(h): return h.get("id",-1)==0 and h.get("damage",0)>0)
		var companion_hit: bool = result.get("hits",[]).any(func(h): return h.get("id",-1)==1 and h.get("damage",0)>0)
		if consumes_firearm_guard and hero_hit: _record_development_use(0,8)
		if had_preparation and hero_hit: _record_development_use(0,1)
		if had_support and companion_hit: _record_development_use(1,4)
	if consumes_firearm_guard and not result.has("error"):
		firearm_guard = false; result.text += " · Guarda do Cano consumida"
	if not result.has("error"):
		for id in passive_changes:
			record_passive(0,id,{"mitigated_damage":passive_changes[id],"condition":1})
	if had_support and plan.get("targets",[]).has(0): defense_success = true
	if mode == "perfect_defense":
		defense_success = int(grades.get(0,0)) == 2 and flank(current_id,0) == "Frente"
		defense_failed = not defense_success
	if plan.get("targets",[]).has(0): stationary_eligible = false; protective_ready = false; preparation = false
	if current_id==weakened_target:
		contact_weakened = false; approach_weakened = false; weakened_target = -1
	return result

func enemy_intent(_id: int) -> Dictionary:
	if mode=="order_trial":return {"title":"A medida do serviço","detail":"Alcança a casa dourada, acerta um golpe e responde de frente com Bom ou Perfeito. Recursos emprestados; R / Select sai sem penalidade."}
	if mode=="practice": return {"title":"Armas emprestadas · "+PRACTICE_TIPS[style],"detail":"Compara alcance, área, custo e postura na previsão. R / Select sai durante qualquer ação. Nenhuma técnica é aprendida aqui."}
	return {"title":caption,"detail":"Objetivo: experimentar a distância e responder ao golpe. Leonor tem Plenitude 3; a derrota continua a história, sem exigir vitória ou consumo de itens." if mode == "duel" else ("Básico num turno, técnica no seguinte. Espaço confirma o timing." if mode == "school" else "Observa o golpe e a orientação. A defesa acontece no timing inimigo.")}

func lesson_result() -> Dictionary:
	if mode=="order_trial":return {"finished":units[0].hp<=0 or (order_trial_positioned and order_trial_defended and valid_hits>0),"success":units[0].hp>0 and order_trial_positioned and order_trial_defended and valid_hits>0}
	var finished := false
	var success := true
	match mode:
		"adult_basic": finished = moved_in_battle and valid_hits >= 1
		"adult_defense": finished = defense_success
		"style_test": finished = valid_hits >= 1
		"school": finished = correct_sequence and (style != "MC" or prepared_contact)
		"perfect_defense": finished = defense_success or defense_failed; success = defense_success
		"duarte_support": finished = defense_success
		"duel": finished = units[0].hp <= 0; success = true
	return {"finished":finished,"success":success}

func next_turn() -> Dictionary:
	var result: Dictionary = super.next_turn()
	Medida.turn(self)
	if mode=="practice" and current_id==0: current().qi = current().max_qi
	if current_id == 0:
		order_guard="";order_exposed_face=-1
		firearm_guard = false; firearm_moved = false
		stationary_eligible = false; protective_ready = false; preparation = false
	return result





func role_name(id: int) -> String:
	if id == 0: return "Aprendiz"
	if id == 1: return "Companheiro"
	if mode == "duel": return "Plenitude 3"
	return "Alvo imóvel" if units[id].kind == "target" else "Instrutor"

func mastered(actor: int,skill: int,definition: Dictionary) -> Dictionary:
	var d: Dictionary = super.mastered(actor,skill,definition)
	if actor>=2 or d.is_empty() or mode not in ["school","practice","perfect_defense","duarte_support","boarding","order_trial"]: return d
	var person := "hero" if actor==0 else "duarte"
	if Development.member(combat_progress(),person).is_empty():
		var legacy_power: int = int(d.get("power",0))
		d.power = roundi(legacy_power*float(d.get("chapter_power_factor",1.0)))
		d.passive_power_bonus = int(d.power)-legacy_power
		return d
	var id: String = d.get("content_id","")
	var rank := Development.grade(combat_progress(),id,person)
	d.level = rank
	if id in ["FO08","MC08"]:
		d.protection = _guard_protection(id)
		d.description = d.description.replace("30%",str(roundi(d.protection*100))+"%")
	if id in ["ES09","PU09"]:
		d.protection=(.30 if id=="ES09" else .20)+[0.0,.03,.05][rank-1]
		d.description=d.description.replace("30%" if id=="ES09" else "20%",str(roundi(d.protection*100))+"%")
	if int(d.get("power",0))>0:
		var weapon_style := style if actor==0 else "LA"
		var original_power: float = STYLES[weapon_style].power if actor==0 else 20.0
		var gear: int = int(equipment_bonus.get("attack",0)) if actor==0 else 0
		var attribute_power := Development.power(combat_progress(),weapon_style,person)
		var technique_power: float = (int(d.power)-gear)*attribute_power/original_power
		if Development.SKILL_PROFILES.has(id):
			var profile: Array = Development.SKILL_PROFILES[id]
			technique_power = float(profile[0])*Development.power(combat_progress(),weapon_style,person,{},[profile[1],profile[2]])
		var before_passive: float = (technique_power+gear)*(1.0+0.05*(rank-1))
		if actor==0 and style=="MC" and units[0].get("medida_weight_until",-1)>=units[0].turns: before_passive*=1.15
		d.power = floori(before_passive*float(d.get("chapter_power_factor",1.0)))
		d.passive_power_bonus = int(d.power)-floori(before_passive)
		if actor==0: d.posture += int((int(Development.member(combat_progress()).attributes.FOR)-5)*0.7)
	if id=="DU01" and rank>1: d.cost = maxi(4,int(d.cost)-(rank-1))
	if not id.is_empty():
		var influence := "apoio"
		if int(d.get("power",0))>0:
			var pair: Array = Development.INFLUENCES[style if actor==0 else "LA"]
			if Development.SKILL_PROFILES.has(id): pair = Development.SKILL_PROFILES[id].slice(1)
			influence = "/".join(pair)
		d.description += " Grau %s · %s."%[["I","II","III"][rank-1],influence]
	return d
func segment_open(from: Vector2i,to: Vector2i) -> bool:
	return passable(to,0) and clear_line(from,to,0)
func _guard_protection(id: String) -> float:
	var rank := Development.grade(combat_progress(),id)
	return 0.30+(0.05 if rank==3 else 0.03 if rank==2 else 0.0)
func _record_development_use(actor: int,skill: int) -> void:
	if actor not in [0,1]: return
	var person := "hero" if actor==0 else "duarte"
	if not battle_practice.has(person): battle_practice[person] = {}
	var id: String = skill_def(actor,skill).get("content_id","basic")
	battle_practice[person][id] = mini(6,int(battle_practice[person].get(id,0))+1)

func area(actor: int,skill: int,aim: Vector2i) -> Array[Vector2i]:
	if actor==0 and Medida.handles(skill): return Medida.cells(self,skill,aim)
	return super.area(actor,skill,aim)
func predict(actor: int,target: int,skill: int,quality: int,aim := Vector2i(-1,-1)) -> Dictionary:
	if actor==0 and Medida.handles(skill): return Medida.predict(self,target,skill,quality,units[target].cell if aim==Vector2i(-1,-1) else aim)
	var result: Dictionary=super.predict(actor,target,skill,quality,aim)
	if actor==0 and style=="FO" and medida_state.get("mark_target",-1)==target and medida_state.get("mark_cell",Vector2i(-1,-1))==units[target].cell and medida_state.get("mark_until",-1)>=units[0].turns:
		result.damage=roundi(int(result.damage)*1.35)
	return result
func push_destination(actor: int,target: int,steps := 1) -> Vector2i:
	if units[target].get("medida_anchor",0)>0 and (not units[target].get("medida_anchor_front",false) or direction_index(units[actor].cell-units[target].cell)==int(units[target].face)): return units[target].cell
	steps=maxi(0,steps-int(units[target].get("medida_anchor_steps",0)))
	if steps==0: return units[target].cell
	return super.push_destination(actor,target,steps)

func support_preview(actor: int,skill: int,aim: Vector2i) -> Dictionary:
	var result: Dictionary=super.support_preview(actor,skill,aim)
	if actor==0 and Medida.handles(skill):
		result.guard=false; result.cover=false
		result.medida_effect=Medida.row(skill).effect
		if skill_def(actor,skill).shape=="ally": result.medida_destinations=Medida.escort(self,unit_at(aim))
	return result

func medida_command(command: int) -> bool: return Medida.handles(command)
func _medida_plan(plan: Dictionary) -> Dictionary:
	if current().get("medida_slow",0)<=0: return plan
	var path: Array=plan.get("path",[])
	if not path.is_empty() and distance(path[-1],units[0].cell)<distance(current().cell,units[0].cell):
		plan=plan.duplicate(true); plan.path.pop_back()
		plan.destination=plan.path[-1] if not plan.path.is_empty() else current().cell
		if distance(plan.destination,units[0].cell)>1 and Medida.is_contact(plan): plan.targets=[]; plan.cells=[]; plan.kind="approach"
	return plan
