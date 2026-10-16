extends RefCounted
const BossTechniques=preload("res://scripts/combat/mar_de_ferro/boss_techniques.gd")
const EnemyMoves=preload("res://scripts/combat/mar_de_ferro/enemy_moves.gd")
const EnemyAttributes=preload("res://scripts/combat/mar_de_ferro/enemy_attributes.gd")
## Deterministic tactical simulation. Coordinates and damage are shared by preview,
## player execution, AI and tests; animations never decide game rules.

const SIZE := Vector2i(9,8)
const Catalog=preload("res://scripts/combat/mar_de_ferro/rpg_catalog.gd")
const Progression=preload("res://scripts/combat/mar_de_ferro/progression.gd")
const Identity=preload("res://scripts/combat/mar_de_ferro/battle_identity.gd")
const Missions=preload("res://scripts/combat/mar_de_ferro/mission_catalog.gd")
const DIRECTIONS := [Vector2i(1,0),Vector2i(0,1),Vector2i(-1,0),Vector2i(0,-1)]

# Enemy combat definitions are intentionally separate from HERO_SKILLS.
# AI still uses the classic IDs 0..4 for its geometry/preview calculations.
const ENEMY_SKILLS := {
	0:{"name":"Talho rival","cost":0,"power":19,"posture":13,"shape":"single","range":1,"status":"","cooldown":0},
	1:{"name":"Varrimento rival","cost":0,"power":19,"posture":13,"shape":"arc","range":1,"status":"","cooldown":0},
	2:{"name":"Estocada rival","cost":0,"power":19,"posture":13,"shape":"line","range":3,"status":"","cooldown":0},
	3:{"name":"Pancada rival","cost":0,"power":15,"posture":19,"shape":"single","range":1,"status":"stun","cooldown":0},
	4:{"name":"Fio rival","cost":0,"power":19,"posture":9,"shape":"single","range":1,"status":"bleed","cooldown":0}
}

var heroes: Array = []
var enemies: Array = []
var units: Array = []
var obstacles: Array[Vector2i] = []
var order: Array[int] = []
var order_index := -1
var current_id := -1
var round_no := 1
var potions := 3
var level := 0
var encounter := ""
var counters := 0
var perfects := 0
var turn_events: Array = []
var passive_feedback: Array[Dictionary] = []
var enemy_turns := 0
var profile: Dictionary={}
var tonics:=2
var tech_uses: Array=[{},{}]
var sequence: Dictionary={}
var boss_loot: Array[Dictionary]=[]
var objective: Dictionary={}
var optional_objective: Dictionary={}
var exploration_notes: Array[String]=[]

func challenging() -> bool:
	return not profile.is_empty() and profile.get("options",{}).get("difficulty","normal")=="challenging"

func difficulty_target_priority(target: int) -> float:
	if not challenging(): return 0.0
	var target_health: float=float(units[target].hp)/maxf(1.0,float(units[target].max_hp))
	var priority: float=(1.0-target_health)*28.0
	if units[target].posture<=int(units[target].max_posture*0.35): priority+=12
	if units[target].guard: priority-=10
	return priority

func make_unit(label: String, hp: int, qi: int, posture: int, kind: String, cell: Vector2i, speed: int, movement: int, team: int) -> Dictionary:
	return {
		"id":units.size(),"name":label,"hp":hp,"max_hp":hp,"qi":qi,"max_qi":qi,
		"posture":posture,"max_posture":posture,"kind":kind,"cell":cell,"home":cell,
		"speed":speed,"movement":movement,"moves":movement,"team":team,
		"face":2 if team==1 else 0,"acted":false,"quick_used":false,"broken":false,
		"stun":0,"resist":0,"bleed":0,"guard":false,"warning":[],"followup":[],
		"warning_name":"","next_name":"","warning_power":0,"charging":false,"turns":0,
		"firm":0,"opening":0,"cover_target":-1,"riposte":false,"boss_phase":1,
		"exposed":false,"counter_ready":{},"flank_proc_turn":false,
		"fortitude":0,"fortitude_hits":0,"hook_momentum_until":-1,
		"signal_pending":false,"signal_origin":cell,"order_source":-1,"order_until":-1,
		"phase_pending":false,"signature_pending":false,"warning_push_steps":1,"charge_ready_turn":0,
		"technique_ready":2,"read_skills":{},"strain":0,"lance_form":0,"contract_coins":6,
		"paid_intercept":false,"bounty_target":-1,"bounty_power":0,"last_skill":0,
		"rooted_until":-1,"moved_last_turn":false,"turn_origin":cell,"last_stand_used":false,
		"recent_skills":[],"lance_cell":Vector2i(-1,-1)
	}

func add(label: String, hp: int, qi: int, posture: int, kind: String, cell: Vector2i, speed: int, movement: int, team: int) -> void:
	var u := make_unit(label,hp,qi,posture,kind,cell,speed,movement,team)
	u.cooldowns={}; u.passive_cooldowns={}
	units.append(u)
	if team==0: heroes.append(u)
	else: enemies.append(u)

func start(id: String, mastery := 0, preparation: Dictionary={}) -> void:
	profile=preparation.duplicate(true); tech_uses=[{},{}]; tonics=2
	sequence.clear(); boss_loot.clear()
	passive_feedback.clear(); exploration_notes.clear()
	optional_objective=Missions.OPTIONAL_OBJECTIVES.get(id,{}).duplicate(true)
	if not optional_objective.is_empty(): optional_objective.completed=false
	encounter=id; level=mastery
	units.clear(); heroes.clear(); enemies.clear(); order.clear(); obstacles.clear(); objective.clear()
	add("Duarte",166+mastery*12,12,60,"duarte",Vector2i(1,3),12,4,0)
	add("Inês",146+mastery*12,14,48,"ines",Vector2i(1,5),18,5,0)
	var encounter_data: Dictionary=Catalog.ENCOUNTERS.get(id,Catalog.ENCOUNTERS.boss)
	for u in encounter_data.units: add(u[0],u[1],0,u[2],u[3],u[4],u[5],u[6],1)
	# The opening boarding is a readable tutorial even when the campaign is set to
	# Desafiante. The selected difficulty starts applying from the next encounter.
	if challenging() and id!="prologue_raid":
		for u in encounter_data.get("challenge_units",[]): add(u[0],u[1],0,u[2],u[3],u[4],u[5],u[6],1)
	var encounter_power: float=Catalog.encounter_power(id)
	for enemy in enemies:
		EnemyAttributes.apply(enemy,id,encounter_power)
		var growth: float=float(Catalog.ENCOUNTER_GROWTH.get(id,1.0))
		enemy.hp=roundi(enemy.hp*growth); enemy.max_hp=enemy.hp
		enemy.posture=roundi(enemy.posture*(1.0+(growth-1.0)*0.35)); enemy.max_posture=enemy.posture
		enemy.challenge_power*=1.0+(growth-1.0)*0.35
		enemy.posture_pressure*=1.0+(growth-1.0)*0.25
		EnemyMoves.setup(enemy,id)
		if enemy.kind=="defender" and id not in ["training","prologue_raid"]:
			enemy.protects_allies=true; enemy.guard=true
	obstacles.assign(encounter_data.obstacles)
	if id=="cove_trial_1":
		units[2].protects_allies=true; units[2].guard=true
	if id=="cove_trial_2": units[2].disrupts_qi=true
	objective=Missions.objective_for(id)
	if not objective.is_empty():
		var actor_id: int=int(objective.get("actor_id",-1))
		if actor_id>=0 and actor_id<units.size(): units[actor_id].objective_actor=true
		if objective.get("kind","")=="capture": objective.target_id=actor_id
		if objective.get("kind","")=="protect" and not obstacles.has(objective.asset_cell): obstacles.append(objective.asset_cell)
		if objective.get("kind","")=="escort":
			objective.asset_cell=objective.get("asset_cell",Vector2i(1,4))
			objective.progress=0
			var campaign_flags: Dictionary=profile.get("_campaign_flags",{})
			if campaign_flags.get("armada_trust",false):
				objective.support="armada"
				objective.siege_damage=22
			elif campaign_flags.get("lastro_trust",false):
				objective.support="lastro"
				objective.hp+=60; objective.max_hp+=60
			if not obstacles.has(objective.asset_cell): obstacles.append(objective.asset_cell)
			for siege_id in objective.get("siege_ids",[]):
				if siege_id>=0 and siege_id<units.size(): units[siege_id].siege_actor=true
	order_index=-1; current_id=-1; round_no=1; counters=0; perfects=0; potions=3; enemy_turns=0
	if not profile.is_empty():
		var progress=Progression.new(); progress.data=profile
		potions=int(profile.bag.heal); tonics=int(profile.bag.qi)
		for hero in 2:
			var stats: Dictionary=progress.stats(hero)
			for key in ["hp","qi","posture"]: units[hero][key]=stats[key]; units[hero]["max_"+key]=stats[key]
			var condition: Dictionary=profile.heroes[hero].get("condition",{})
			for key in ["hp","qi","posture"]:
				if condition.has(key): units[hero][key]=clampi(int(condition[key]),1 if key!="qi" else 0,int(stats[key]))
			for key in ["attack","defense","break_power","speed","movement"]: units[hero][key]=int(stats[key])
			units[hero].spirit_recovery=Catalog.spirit_recovery(int(profile.heroes[hero].alloc[2]))
			units[hero].moves=units[hero].movement
			units[hero].equipment_effects=[]
			for gear in profile.heroes[hero].gear.values():
				if Catalog.ITEMS[gear].has("combat_effect"): units[hero].equipment_effects.append(gear)
			units[hero].passive=profile.heroes[hero].passive
			units[hero].passives=profile.heroes[hero].get("passives",[profile.heroes[hero].passive]).duplicate()
	apply_exploration_preparation()
	rebuild_order()
	next_turn()

func apply_exploration_preparation() -> void:
	var flags: Dictionary=profile.get("_campaign_flags",{})
	if flags.get("manual",false) and encounter in ["patrol","secret","boss"]:
		for hero in heroes: hero.guard=true
		exploration_notes.append("Manual estudado: a dupla começa em guarda.")
	if flags.get("cove_cache",false) and encounter=="lisbon_pursuit":
		for hero in 2:
			var cell:=Vector2i(2,3 if hero==0 else 5)
			if passable(cell,hero): units[hero].cell=cell; units[hero].home=cell
		exploration_notes.append("Carta da Enseada: entrada lateral, uma casa mais perto do mensageiro.")
	if flags.get("ceuta_receipt",false) and encounter=="ceuta_depot":
		optional_objective.cell=Vector2i(4,1)
		exploration_notes.append("Recibo comparado: o selo de comando está na mesa lateral, mais acessível.")

func optional_status() -> String:
	if optional_objective.is_empty(): return ""
	if optional_objective.completed: return "Concluído"
	return "Perdido" if round_no>int(optional_objective.deadline) else "Disponível"

func optional_reason() -> String:
	if optional_status()!="Disponível": return "Este objectivo opcional já terminou."
	if current_id<0 or current().team!=0 or current().hp<=0 or current().stun>0 or current().broken or not outcome().is_empty(): return "Espera pelo turno de um herói."
	if current().quick_used: return "Já usaste a acção rápida deste turno."
	var cell: Vector2i=optional_objective.cell
	var occupant:=unit_at(cell)
	if occupant>=0 and units[occupant].team!=0: return "Afasta o inimigo que ocupa o objectivo."
	if distance(current().cell,cell)>1 or not clear_line(current().cell,cell,current_id): return "Aproxima-te até 1 casa do marcador R."
	return ""

func complete_optional() -> Dictionary:
	var reason:=optional_reason()
	if not reason.is_empty(): return {"error":reason}
	current().quick_used=true; optional_objective.completed=true
	if optional_objective.effect=="repair" and objective.get("kind","")=="escort":
		objective.hp=mini(int(objective.max_hp),int(objective.hp)+25)
	return {"text":optional_objective.title+" · concluído. Recompensa extra ao vencer."}

func rebuild_order() -> void:
	order.clear()
	for u in units:
		if u.hp>0: order.append(u.id)
	order.sort_custom(func(a,b): return units[a].speed>units[b].speed if units[a].speed!=units[b].speed else a<b)

func current() -> Dictionary:
	return units[current_id]

func inside(cell: Vector2i) -> bool:
	return cell.x>=0 and cell.y>=0 and cell.x<SIZE.x and cell.y<SIZE.y

func unit_at(cell: Vector2i, excluding := -1) -> int:
	for u in units:
		if u.hp>0 and u.id!=excluding and u.cell==cell: return u.id
	return -1

func passable(cell: Vector2i, actor: int) -> bool:
	return inside(cell) and not obstacles.has(cell) and unit_at(cell,actor)<0

func distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x-b.x)+absi(a.y-b.y)

func reachable(id: int, budget := -1) -> Dictionary:
	var u: Dictionary=units[id]
	var limit: int=u.moves if budget<0 else budget
	var parents: Dictionary={u.cell:u.cell}
	var costs: Dictionary={u.cell:0}
	var queue: Array[Vector2i]=[u.cell]
	var head:=0
	while head<queue.size():
		var at: Vector2i=queue[head]; head+=1
		if costs[at]>=limit: continue
		for dir in DIRECTIONS:
			var next: Vector2i=at+dir
			if parents.has(next) or not passable(next,id): continue
			parents[next]=at; costs[next]=costs[at]+1; queue.append(next)
	return {"parents":parents,"costs":costs}

func path_to(id: int, destination: Vector2i, budget := -1) -> Array[Vector2i]:
	var graph:=reachable(id,budget)
	var path: Array[Vector2i]=[]
	if not graph.parents.has(destination): return path
	var at:=destination
	while at!=units[id].cell:
		path.push_front(at); at=graph.parents[at]
	return path

func move_to(destination: Vector2i) -> Array[Vector2i]:
	var path:=path_to(current_id,destination)
	if path.is_empty(): return path
	var u:=current()
	u.face=direction_index(destination-u.cell)
	u.moves-=path.size()
	u.cell=destination
	u.moved_last_turn=true
	return path

func direction_index(delta: Vector2i) -> int:
	if absi(delta.x)>=absi(delta.y): return 0 if delta.x>=0 else 2
	return 1 if delta.y>=0 else 3

func direction_to(actor: int, target: Vector2i) -> Vector2i:
	return DIRECTIONS[direction_index(target-units[actor].cell)]

func skill_def(actor: int, skill: int) -> Dictionary:
	# Enemies do not use HERO_SKILLS. Their AI still asks for classic skill IDs
	# (notably ID 1 to preview a guard's sweep), so resolve those here first.
	if actor>=2 and ENEMY_SKILLS.has(skill):
		return mastered(actor,skill,ENEMY_SKILLS[skill].duplicate(true))
	if skill in [5,6,7]:
		var utility: Dictionary=Catalog.extra_skill(actor,skill)
		if skill==5:
			utility.description="Respirar: até %d alento, 18 postura e Guarda."%breathe_amount(actor)
		if skill==6 and not profile.is_empty():
			utility.shape="friend"; utility.range=2
			utility.description=Catalog.ITEMS.heal.description
		return mastered(actor,skill,utility)
	var definition: Dictionary=Catalog.extra_skill(actor,skill)
	if definition.is_empty(): return definition
	return mastered(actor,skill,definition)

func mastered(actor: int, skill: int, definition: Dictionary) -> Dictionary:
	if definition.is_empty(): return definition
	var uses:=0 if profile.is_empty() or actor>=2 else int(profile.heroes[actor].uses.get(str(skill),0))
	var mastery_level:=1 if definition.get("ultimate",false) else mini(3,1+int(uses/3))
	definition["level"]=mastery_level
	definition["rarity"]=Catalog.TECHNIQUE_RARITY.get(skill,"Comum")
	definition["rarity_color"]=Catalog.TECHNIQUE_RARITY_COLOR.get(definition.rarity,"9aa6a8")
	definition["cooldown"]=int(definition.get("cooldown",Catalog.RARITY_COOLDOWN.get(definition.rarity,0)))
	if not definition.get("ultimate",false):
		if mastery_level>=2:
			if int(definition.get("power",0))>0: definition.power+=2
			if int(definition.get("posture",0))>0: definition.posture+=3
			if definition.has("recovery"):
				var rec2: Dictionary=definition.recovery.duplicate(true)
				if rec2.has("hp"): rec2.hp+=4
				if rec2.has("posture"): rec2.posture+=4
				if rec2.has("qi"): rec2.qi+=1
				definition.recovery=rec2
		if mastery_level>=3:
			if int(definition.get("power",0))>0: definition.power+=3
			if int(definition.get("posture",0))>0: definition.posture+=4
			if definition.has("recovery"):
				var rec3: Dictionary=definition.recovery.duplicate(true)
				if rec3.has("hp"): rec3.hp+=6
				if rec3.has("posture"): rec3.posture+=5
				definition.recovery=rec3
		if uses>=3:
			definition.cost=maxi(0,int(definition.cost)-1)
			definition.description+=" Domínio: −1 alento."
	return definition

func commands(actor: int) -> Array:
	if profile.is_empty() or actor>=2: return [0,1,2,3,4,5,6,7]
	return [0]+profile.heroes[actor].slots+[Catalog.prepared_ultimate(profile.heroes[actor]),5,6]

func has_passive(actor: int, id: String) -> bool:
	return units[actor].get("passives",[units[actor].get("passive","")]).has(id)

# Temporary, bounded resilience: reapplication refreshes two hits, never stacks.
func grant_fortitude(actor: int, percent: int) -> void:
	var u: Dictionary=units[actor]
	if u.hp<=0 or u.broken or u.stun>0: return
	u.fortitude=maxi(int(u.get("fortitude",0)),clampi(percent,0,25))
	u.fortitude_hits=2

func fortitude_preview(actor: int, damage: int, posture: int) -> Dictionary:
	var u: Dictionary=units[actor]
	var percent: int=int(u.get("fortitude",0)) if u.get("fortitude_hits",0)>0 and not u.broken and u.stun==0 else 0
	return {"damage":ceili(damage*(1.0-percent/100.0)),"posture":ceili(posture*(1.0-percent/100.0)),"percent":percent}

func consume_fortitude(actor: int, damage: int, posture: int) -> void:
	var u: Dictionary=units[actor]
	if damage<=0 and posture<=0: return
	if u.get("fortitude_hits",0)>0 and not u.broken and u.stun==0:
		u.fortitude_hits-=1
		if u.fortitude_hits==0: u.fortitude=0

func hook_momentum(actor: int, definition: Dictionary) -> bool:
	return units[actor].hp>0 and has_passive(actor,"duarte_hook") and int(units[actor].get("hook_momentum_until",-1))>=units[actor].turns and definition.shape in ["arc","line","leap"]

func cooldown_remaining(actor: int, skill: int) -> int:
	var remaining:=maxi(0,int(units[actor].cooldowns.get(skill,0))-int(units[actor].turns))
	var definition: Dictionary=skill_def(actor,skill)
	return mini(remaining,int(definition.get("cooldown",0)))

# Execution-only feedback. Predictions never enqueue visual events.
func record_passive(actor: int, id: String, effects: Dictionary, target := -1) -> void:
	var actual: Dictionary={}
	for key in effects:
		if int(effects[key])>0: actual[key]=int(effects[key])
	if actual.is_empty(): return
	passive_feedback.append({"actor":actor,"passive":id,"effects":actual,"target":target})
	# Keep unattended simulations bounded; the view drains once per impact/turn.
	if passive_feedback.size()>64: passive_feedback.pop_front()

func drain_passive_feedback() -> Array[Dictionary]:
	var events: Array[Dictionary]=passive_feedback.duplicate(true)
	passive_feedback.clear()
	return events

func recover_passive(actor: int, id: String, resource: String, amount: int) -> void:
	var u: Dictionary=units[actor]
	var recovered: int=mini(amount,int(u["max_"+resource])-int(u[resource]))
	u[resource]+=recovered
	record_passive(actor,id,{resource:recovered})

func trigger_passives(actor: int, event: String) -> Array:
	var u:Dictionary=units[actor]
	var fired:Array=[]
	if u.hp<=0: return fired
	# Evaluate the health threshold before any equipped passive heals the actor.
	var low_health: bool=float(u.hp)/u.max_hp<=0.35
	for id in u.get("passives",[]):
		if not Catalog.PROC_PASSIVES.has(id): continue
		var d:Dictionary=Catalog.PROC_PASSIVES[id]
		if int(d.get("hero",actor))!=actor: continue
		if d.event!=event or int(u.passive_cooldowns.get(id,0))>u.turns: continue
		if d.get("low_health",false) and not low_health: continue
		var effects: Dictionary={}
		for resource in d.recovery:
			if id=="duarte_sweep_recovery" and resource=="posture" and u.broken: continue
			var before: int=u[resource]
			u[resource]=mini(u["max_"+resource],u[resource]+d.recovery[resource])
			effects[resource]=u[resource]-before
		if d.get("cleanse",false):
			effects.cleanse=u.bleed
			u.bleed=0
		record_passive(actor,id,effects)
		var cd: int=int(d.get("cooldown",Catalog.RARITY_COOLDOWN.get(d.rarity,0)))
		u.passive_cooldowns[id]=u.turns+cd+1
		fired.append(d.name)
	trigger_equipment(actor,event)
	return fired

func trigger_equipment(actor: int, event: String) -> void:
	var u: Dictionary=units[actor]
	if u.hp<=0: return
	for id in u.get("equipment_effects",[]):
		var d: Dictionary=Catalog.ITEMS[id].combat_effect
		if d.event!=event or int(u.passive_cooldowns.get(id,0))>u.turns: continue
		if d.get("near_ally",false) and not heroes.any(func(h): return h.id!=actor and h.hp>0 and distance(u.cell,h.cell)<=2): continue
		var effects: Dictionary={}
		for resource in d.get("recovery",{}):
			var restored: int=mini(int(d.recovery[resource]),int(u["max_"+resource])-int(u[resource]))
			u[resource]+=restored; effects[resource]=restored
		if d.get("movement",0)>0: u.moves+=int(d.movement); effects.movement=int(d.movement)
		if d.get("cleanse",false): effects.cleanse=u.bleed; u.bleed=0
		record_passive(actor,id,effects)
		u.passive_cooldowns[id]=u.turns+int(d.get("cooldown",0))+1

func has_effect(definition: Dictionary, effect: String) -> bool:
	return definition.get("effects",[definition.get("status","")]).has(effect)

func clear_line(from: Vector2i, to: Vector2i, ignore_id := -1, over_units := false) -> bool:
	if not inside(from) or not inside(to): return false
	return line_blocker(from,to,ignore_id,over_units)==Vector2i(-1,-1)

func line_blocker(from: Vector2i, to: Vector2i, ignore_id := -1, over_units := false) -> Vector2i:
	# Shared with the map preview: keep the exact sampling and endpoint semantics.
	if not inside(from) or not inside(to): return Vector2i(-1,-1)
	var steps:=maxi(absi(to.x-from.x),absi(to.y-from.y))*4
	for i in range(1,steps):
		var cell:=Vector2i(Vector2(from).lerp(Vector2(to),float(i)/steps).round())
		if cell==from or cell==to: continue
		if obstacles.has(cell) or (not over_units and unit_at(cell,ignore_id)>=0): return cell
	return Vector2i(-1,-1)

func aim_range(actor: int, skill: int) -> int:
	var s:=skill_def(actor,skill)
	if s.is_empty(): return 0
	# Arc aiming accepts a direction up to two cells, even for a one-row arc.
	return 2 if s.shape=="arc" else int(s.range)

func aim_feedback(actor: int, skill: int, aim: Vector2i) -> Dictionary:
	if actor<0 or actor>=units.size() or not inside(aim): return {}
	var s:=skill_def(actor,skill)
	if s.is_empty() or s.shape=="self": return {}
	var origin: Vector2i=units[actor].cell
	if aim==origin: return {}
	var reach:=aim_range(actor,skill)
	if s.shape=="line" and aim.x!=origin.x and aim.y!=origin.y:
		return {"kind":"alignment","cell":aim,"label":"Alinha com uma linha ou coluna."}
	if s.shape=="leap" and not passable(aim,actor):
		return {"kind":"obstacle" if obstacles.has(aim) else "unit","cell":aim,"label":"Aterragem ocupada"}
	if distance(origin,aim)>reach:
		return {"kind":"range","cell":aim,"range":reach,"label":"Fora do alcance · máximo %d"%reach}
	var blocker:=Vector2i(-1,-1)
	if s.shape=="line":
		# A line pierces units and stops at the first obstacle, even beyond the cursor.
		var direction:=direction_to(actor,aim)
		for i in range(1,reach+1):
			var cell:=origin+direction*i
			if not inside(cell): break
			if obstacles.has(cell): blocker=cell; break
	elif s.shape=="arc":
		var centre:=origin+direction_to(actor,aim)
		if obstacles.has(centre): blocker=centre
	else:
		blocker=line_blocker(origin,aim,actor,s.shape=="leap")
		if blocker==Vector2i(-1,-1) and s.shape=="single" and obstacles.has(aim): blocker=aim
	if blocker!=Vector2i(-1,-1):
		var terrain:=obstacles.has(blocker)
		return {"kind":"obstacle" if terrain else "unit","cell":blocker,"label":("Linha termina no obstáculo" if s.shape=="line" else "Obstáculo bloqueia a técnica") if terrain else "Unidade bloqueia a linha"}
	if s.get("flank_attack",false) and unit_at(aim)>=0 and units[unit_at(aim)].team!=units[actor].team and dash_destination(actor,aim,reach)==Vector2i(-1,-1):
		return {"kind":"flank","cell":aim,"label":"Sem flanco livre para aterrar"}
	return {}

func suggested_facing(actor: int) -> int:
	var nearest:=1000
	var face: int=units[actor].face
	for u in units:
		if u.hp<=0 or u.team==units[actor].team: continue
		var d:=distance(units[actor].cell,u.cell)
		if d<nearest: nearest=d; face=direction_index(Vector2i(u.cell)-Vector2i(units[actor].cell))
	return face

func role_name(id: int) -> String:
	return {"signaller":"Coordenação","boarder":"Puxão e separação","duarte":"Tank de área","ines":"Flanqueadora","defender":"Defensor","archer":"Longo alcance","duelist":"Contra-ataque","boss":"Mestre","pikeman":"Alcance e postura","bombard":"Explosão anunciada","medic":"Socorro aos aliados"}.get(units[id].kind,"Espadachim")

func update_boss_phase(u: Dictionary) -> void:
	if not Identity.is_boss(u): return
	var fraction: float=float(u.hp)/u.max_hp
	var previous: int=u.boss_phase
	var final_threshold: float=0.45 if encounter=="final_esteban" else 0.34
	u.boss_phase=maxi(u.boss_phase,3 if fraction<=final_threshold else (2 if fraction<=0.67 else 1))
	if u.boss_phase>previous and u.hp>0: u.phase_pending=true
	u.movement=4 if is_avelar(u.id) else 3+u.boss_phase
	if encounter=="final_esteban" and objective.get("kind","")=="changing_deck" and u.boss_phase>int(objective.deck_phase):
		# Falling spars block empty cells only: phase transitions never crush a unit.
		for phase in range(int(objective.deck_phase)+1,u.boss_phase+1):
			var proposed: Array=[Vector2i(4,2),Vector2i(5,5)] if phase==2 else [Vector2i(3,6),Vector2i(6,1)]
			for landing in proposed:
				var chosen: Vector2i=landing
				var best:=1000
				for x in SIZE.x:
					for y in SIZE.y:
						var cell:=Vector2i(x,y)
						if unit_at(cell)<0 and not obstacles.has(cell) and distance(cell,landing)<best:
							chosen=cell; best=distance(cell,landing)
				if best<1000: obstacles.append(chosen); objective.deck_cells.append(chosen)
		objective.deck_phase=u.boss_phase

func boss_phase_name(id: int) -> String:
	return Identity.BOSSES.get(encounter,Identity.BOSSES.boss).phases[units[id].boss_phase-1]

func boss_hint(id: int) -> String:
	if not BossTechniques.key(self,units[id]).is_empty(): return BossTechniques.hint(self,units[id])
	if is_avelar(id): return Identity.BOSSES.lisbon_avelar.hint
	if units[id].kind=="boss" and catarina_duelist():
		return "Catarina procura flancos. Resposta frontal: 9 dano e 8 postura. Flanqueia, quebra ou atordoa para a evitar. A última salva anuncia dois golpes."
	return Identity.BOSSES.get(encounter,Identity.BOSSES.boss).hint+" "+EnemyMoves.BOSSES.get(encounter,EnemyMoves.BOSSES.boss).hint if Identity.is_boss(units[id]) else ""

func payment_orders_active() -> bool:
	if encounter=="ceuta_depot" and enemies.any(func(e): return e.kind=="boss" and int(e.get("contract_coins",6))<=0): return false
	return encounter=="ceuta_depot" and not optional_objective.get("completed",false) and Identity.active(units[int(objective.get("actor_id",2))])

func boss_ward(target: int, side: String) -> bool:
	if units[target].kind!="boss" or side!="Frente" or not Identity.active(units[target]) or units[target].exposed: return false
	return payment_orders_active()

func push_destination(actor: int, target: int, steps := 1) -> Vector2i:
	var direction: Vector2i=DIRECTIONS[direction_index(Vector2i(units[target].cell)-Vector2i(units[actor].cell))]
	var cell: Vector2i=units[target].cell
	for step in clampi(steps,1,2):
		var next: Vector2i=cell+direction
		if not passable(next,target): break
		cell=next
	return cell if cell!=units[target].cell else Vector2i(-1,-1)

func area(actor: int, skill: int, aim: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i]=[]
	var origin: Vector2i=units[actor].cell
	var s: Dictionary=skill_def(actor,skill)
	# Invalid/missing definitions should never crash AI previews.
	if s.is_empty() or not s.has("shape"):
		return result
	var shape: String=str(s.get("shape",""))
	if shape=="self": return [origin]
	if shape in ["ally","friend"]:
		if distance(origin,aim)<=s.range and clear_line(origin,aim,actor): result.append(aim)
		return result
	if aim==origin or not inside(aim): return result
	if shape=="leap":
		if not leap_reason(actor,skill,aim).is_empty(): return result
		for x in range(-1,2):
			for y in range(-1,2):
				if x==0 and y==0: continue
				if not s.get("diagonal_blast",false) and absi(x)+absi(y)>1: continue
				var cell:=aim+Vector2i(x,y)
				if inside(cell) and not obstacles.has(cell) and clear_line(aim,cell,actor,true): result.append(cell)
		return result
	var delta:=aim-origin
	if shape=="single":
		if distance(origin,aim)<=s.range and not obstacles.has(aim) and clear_line(origin,aim,actor): result.append(aim)
	elif shape=="line":
		if delta.x!=0 and delta.y!=0: return result
		if distance(origin,aim)>s.range: return result
		var dir:=direction_to(actor,aim)
		for i in range(1,s.range+1):
			var cell: Vector2i=origin+dir*i
			if not inside(cell) or obstacles.has(cell): break
			result.append(cell)
	elif shape=="arc":
		if distance(origin,aim)>2: return result
		var dir:=direction_to(actor,aim)
		var cross:=Vector2i(-dir.y,dir.x)
		var centre:=origin+dir
		if obstacles.has(centre): return result
		for cell in [centre-cross,centre,centre+cross]:
			if inside(cell) and not obstacles.has(cell): result.append(cell)
		if s.range>=2:
			for cell in [centre+dir-cross,centre+dir,centre+dir+cross]:
				if inside(cell) and not obstacles.has(cell): result.append(cell)
	return result

func targets(actor: int, cells: Array) -> Array[int]:
	var result: Array[int]=[]
	for u in units:
		if u.hp>0 and u.team!=units[actor].team and cells.has(u.cell): result.append(u.id)
	return result

func availability_reason(skill: int) -> String:
	if current_id<0 or current_id>=units.size(): return "Não há um turno activo."
	var u:=current()
	if skill<0 or (not Catalog.TECHNIQUES.has(skill) and skill not in [0,5,6,7]): return "Escolhe uma técnica preparada."
	if Catalog.is_ultimate(skill):
		if profile.is_empty() or current_id not in [0,1] or not profile.heroes[current_id].known.has(skill): return "Esta suprema ainda não foi aprendida."
		if Catalog.prepared_ultimate(profile.heroes[current_id])!=skill: return "Esta suprema não está preparada. Escolhe-a no menu Técnicas."
	if cooldown_remaining(current_id,skill)>0: return "Recarga: %d turno(s) próprio(s)."%cooldown_remaining(current_id,skill)
	if u.team!=0 or u.hp<=0: return "Aguarda o turno de um herói."
	if u.broken or u.stun>0: return "Este herói não pode agir enquanto estiver incapacitado."
	if not profile.is_empty() and not skill in [0,5,6,7] and not Catalog.is_ultimate(skill) and not profile.heroes[current_id].slots.has(skill): return "Esta técnica não está preparada."
	var s:=skill_def(current_id,skill)
	if s.is_empty(): return "Técnica sem definição para este herói."
	if s.get("requires_partner",false) and units[1-current_id].hp<=0: return "Esta técnica exige os dois heróis conscientes."
	if s.get("quick",false):
		if u.quick_used: return "Já usaste a técnica rápida deste turno."
	elif u.acted: return "A acção principal deste turno já foi usada."
	if u.qi<s.cost: return "Alento insuficiente: precisas de %d."%s.cost
	if skill==6 and potions<=0: return "Não restam infusões na bolsa."
	if skill==7 and tonics<=0: return "Não restam tónicos na bolsa."
	return ""

func available(skill: int) -> bool:
	return availability_reason(skill).is_empty()

func attack_reason(skill: int, aim: Vector2i) -> String:
	var reason:=availability_reason(skill)
	if not reason.is_empty(): return reason
	var s:=skill_def(current_id,skill)
	if s.get("requires_partner",false):
		var partner: int=1-current_id
		if partner<0 or partner>=units.size() or units[partner].hp<=0:
			return "Esta técnica exige os dois heróis conscientes."
	if s.shape in ["self","ally","friend"]:
		var ally: int=current_id if s.shape=="self" else unit_at(aim)
		if ally<0 or units[ally].team!=current().team: return "Selecciona um aliado vivo."
		if s.shape=="ally" and ally==current_id: return "Selecciona Inês para a proteger."
		if s.shape!="self":
			if distance(current().cell,aim)>s.range: return "O aliado está fora do alcance de %d casas."%s.range
			if not clear_line(current().cell,aim,current_id): return "Um obstáculo ou outra unidade bloqueia a linha."
		if skill in [6,7] and units[ally][s.resource]>=units[ally]["max_"+s.resource]:
			return "Este aliado já tem a vida completa." if skill==6 else "Este aliado já tem o alento completo."
		return ""
	if not inside(aim): return "Selecciona uma casa da grelha."
	if s.shape=="leap":
		var landing_reason:=leap_reason(current_id,skill,aim)
		if not landing_reason.is_empty(): return landing_reason
	if s.shape=="line" and aim.x!=current().cell.x and aim.y!=current().cell.y: return "Alinha a técnica com uma linha ou coluna."
	var cells:=area(current_id,skill,aim)
	if cells.is_empty(): return "Casa fora do alcance ou bloqueada por um obstáculo."
	var victims:=targets(current_id,cells)
	if victims.is_empty(): return "A área não atinge nenhum adversário."
	if s.get("flank_attack",false):
		if victims.size()!=1: return "Selecciona um único adversário para o ataque de flanco."
		if dash_destination(current_id,aim,int(s.range))==Vector2i(-1,-1):
			return "Não existe uma casa de flanco livre e alcançável para aterrar."
	if s.get("hook",false):
		var target: int=victims[0]
		if not hook_resisted(target) and hook_destination(current_id,target)==Vector2i(-1,-1):
			return "O Gancho não tem uma casa livre junto de Duarte para puxar o alvo."
	return ""

func valid_attack(skill: int, aim: Vector2i) -> bool:
	return attack_reason(skill,aim).is_empty()

# Leaps aim at empty ground. They vault units, but never walls or occupied landings.
func leap_reason(actor: int, skill: int, aim: Vector2i) -> String:
	var origin: Vector2i=units[actor].cell
	if aim==origin or not passable(aim,actor): return "Escolhe uma casa livre para aterrar."
	if distance(origin,aim)>int(skill_def(actor,skill).range): return "A aterragem está fora do alcance do salto."
	if not clear_line(origin,aim,actor,true): return "Um obstáculo bloqueia o trajecto do salto."
	return ""

func breathe_amount(actor: int) -> int:
	return 5+int(units[actor].get("spirit_recovery",0))+(2 if has_passive(actor,"breath") else 0)

func support_preview(actor: int, skill: int, aim: Vector2i) -> Dictionary:
	var s:=skill_def(actor,skill)
	var target: int=actor if s.shape=="self" else unit_at(aim)
	var preview: Dictionary={"target":target,"resource":"","amount":0,"capacity":0,"waste":0,"qi":0,"hp":0,"posture":0,"movement":0,"guard":false,"cover":false,"counter":false,"quick":s.get("quick",false),"cost":s.cost}
	if target<0 or units[target].team!=units[actor].team: return preview
	var recipient: Dictionary=units[target]
	if skill in [6,7]:
		preview.resource=s.resource
		preview.capacity=Catalog.consumable_restore("heal" if skill==6 else "qi",int(recipient["max_"+s.resource]))
		preview.amount=mini(int(preview.capacity),maxi(0,int(recipient["max_"+s.resource])-int(recipient[s.resource])))
		preview.waste=int(preview.capacity)-int(preview.amount)
		if skill==7: preview.qi=preview.amount
	elif skill==5:
		preview.qi=mini(int(recipient.max_qi)-int(recipient.qi),breathe_amount(target))
		preview.posture=mini(int(recipient.max_posture)-int(recipient.posture),18); preview.guard=true
	else:
		preview.movement=int(s.get("movement",0))
		preview.guard=s.get("guard",false) or s.shape=="self" or s.get("counter",false) or s.get("status","")=="cover"
		preview.cover=s.shape=="ally" or s.get("status","")=="cover"
		preview.counter=s.get("counter",false)
		if s.has("recovery"):
			for resource in s.recovery:
				# Self recovery happens after paying the technique's stamina cost.
				var current_resource: int=int(recipient[resource])-(int(s.cost) if resource=="qi" and target==actor else 0)
				preview[resource]=mini(int(s.recovery[resource]),maxi(0,int(recipient["max_"+resource])-current_resource))
			if s.recovery.has("hp"): preview.resource="hp"; preview.amount=preview.hp; preview.capacity=s.recovery.hp
	return preview

func flank(actor: int, target: int, origin := Vector2i(-1,-1)) -> String:
	var at: Vector2i=units[actor].cell if origin.x<0 else origin
	var relative:=at-Vector2i(units[target].cell)
	var facing: Vector2i=DIRECTIONS[units[target].face]
	var dot:=relative.x*facing.x+relative.y*facing.y
	if dot<0: return "Costas"
	if dot==0: return "Flanco"
	return "Frente"

func dash_destination(actor: int, aim: Vector2i, budget := 3) -> Vector2i:
	var target:=unit_at(aim)
	if target<0 or units[target].team==units[actor].team: return Vector2i(-1,-1)
	for delta in DIRECTIONS:
		var cell: Vector2i=aim+delta
		if inside(cell) and not obstacles.has(cell) and unit_at(cell,actor)<0 and flank(actor,target,cell)!="Frente" and distance(units[actor].cell,cell)<=budget and clear_line(units[actor].cell,cell,actor):
			return cell
	return Vector2i(-1,-1)

func hook_destination(actor: int, target: int) -> Vector2i:
	if target<0 or target>=units.size(): return Vector2i(-1,-1)
	var dir:=direction_to(actor,units[target].cell)
	var destination: Vector2i=units[actor].cell+dir
	if not inside(destination) or obstacles.has(destination): return Vector2i(-1,-1)
	var occupant:=unit_at(destination,actor)
	if occupant>=0 and occupant!=target: return Vector2i(-1,-1)
	return destination

func hook_resisted(target: int) -> bool:
	var victim: Dictionary=units[target]
	return victim.kind=="boss" or (victim.kind=="defender" and victim.guard) or victim.get("anchored",false)

func predict(actor: int, target: int, skill: int, quality: int, aim := Vector2i(-1,-1)) -> Dictionary:
	var a: Dictionary=units[actor]
	var e: Dictionary=units[target]
	var s: Dictionary=skill_def(actor,skill)
	var side_origin: Vector2i=a.cell
	if s.shape=="leap" and inside(aim): side_origin=aim
	# Only project the dash while the attacker is still in front: once she has
	# landed, her real cell decides the side, or execution would out-run the preview.
	if s.get("flank_attack",false) and flank(actor,target,a.cell)=="Frente":
		var landing:=dash_destination(actor,e.cell,int(s.range))
		if landing!=Vector2i(-1,-1): side_origin=landing
	var side:=flank(actor,target,side_origin)
	var multiplier: float=[0.9,1.15,1.4][quality] if a.team==0 else [0.8,1.1,1.4][quality]
	var positional: float=1.35 if side=="Costas" else (1.15 if side=="Flanco" else 1.0)
	if a.kind=="ines" and side!="Frente": positional+=0.15
	var passive_bonuses: Dictionary={}
	var base_power: int=int(s.power)+level*3+int(a.get("attack",0))
	if hook_momentum(actor,s): base_power+=8; passive_bonuses.duarte_hook={"damage_base":8}
	if e.bleed>0:
		base_power=int(base_power*float(s.get("bleeding_power_mult",1.0)))
		base_power+=mini(3,int(e.bleed))*int(s.get("bleed_burst",0))
	if has_passive(actor,"riposte") and a.posture==a.max_posture: base_power+=4; passive_bonuses.riposte={"damage_base":4}
	if has_passive(actor,"precision") and quality==2: base_power+=5; passive_bonuses.precision={"damage_base":5}
	if a.kind=="ines" and side!="Frente" and e.bleed>0 and has_passive(actor,"open_vein"): base_power+=5; passive_bonuses.open_vein={"damage_base":5}
	var posture_power: int=maxi(1,int(s.posture)+int(a.get("break_power",0)))
	if a.kind=="duarte" and distance(side_origin,e.cell)>=2 and has_passive(actor,"long_reach"): posture_power+=5; passive_bonuses.long_reach={"posture_base":5}
	if has_passive(actor,"red_edge") and e.bleed>0: posture_power+=4; passive_bonuses.red_edge={"posture_base":4}
	if has_passive(actor,"sword_eye") and side!="Frente" and e.exposed: posture_power+=4; passive_bonuses.sword_eye={"posture_base":4}
	if side!="Frente": posture_power+=int(s.get("flank_posture_bonus",0))
	var opening_combo: bool=e.opening>0 and s.get("uses_opening",false)
	if opening_combo:
		base_power=int(base_power*float(s.get("opening_power_mult",1.0)))
		posture_power+=int(s.get("opening_posture_bonus",0))
	var exposed: bool=e.exposed and not e.broken
	if exposed and float(s.get("exposed_power_mult",1.0))>1.0:
		base_power=int(base_power*float(s.exposed_power_mult))
	var broken_mult: float=1.55 if e.broken else 1.0
	if e.broken and a.kind=="ines" and has_passive(actor,"execution_line"): broken_mult*=1.10; passive_bonuses.execution_line={"damage_percent":10}
	var hp_damage:=int(base_power*multiplier*positional*broken_mult)
	if s.get("posture_only",false): hp_damage=0
	var posture_damage:=int(posture_power*multiplier*(1.5 if side=="Costas" else (1.2 if side=="Flanco" else 1.0)))
	if exposed: posture_damage=int(posture_damage*1.35)
	if e.guard and side=="Frente": hp_damage=int(hp_damage*0.7)
	var shielded:=false
	if side=="Frente":
		for protector in enemies:
			if protector.id!=target and protector.get("protects_allies",false) and protector.hp>0 and protector.guard and not protector.broken and protector.stun==0 and distance(protector.cell,e.cell)<=2 and clear_line(protector.cell,e.cell,protector.id): shielded=true
	if shielded: hp_damage=int(hp_damage*0.75)
	var ward: bool=boss_ward(target,side)
	if ward: hp_damage=int(hp_damage*0.8)
	var prism: bool=encounter=="vigia_guard" and e.get("lance_form",0)==1 and e.kind=="boss" and e.lance_cell==Vector2i(-1,-1) and Identity.active(e) and not e.exposed and side=="Frente"
	if prism: posture_damage=int(posture_damage*0.7)
	var anchored: bool=e.kind=="defender" and e.guard and side=="Frente"
	if anchored and not s.get("anti_guard",false): posture_damage=int(posture_damage*0.65)
	if e.firm>0: posture_damage=mini(int(posture_damage*0.5),maxi(0,e.posture-1))
	var veil:=rose_veil(target)
	if veil: hp_damage=int(hp_damage*0.6)
	var technique_factor: float=BossTechniques.mitigation(self,actor,target,skill,side)
	hp_damage=int(hp_damage*technique_factor); posture_damage=int(posture_damage*technique_factor)
	var redirect: int=BossTechniques.intercept(self,target,side)
	if redirect>=0:
		var protected: Dictionary=predict(actor,redirect,skill,quality,aim)
		protected.redirect=redirect; protected.intercepted=true
		return protected
	var last_stand: bool=e.name=="Yusuf ibn Rami" and not e.get("last_stand_used",false) and objective.get("kind","")=="duel_rescue" and e.hp-hp_damage<=e.max_hp*0.15
	var survives: bool=hp_damage<e.hp or last_stand
	var stun: bool=survives and has_effect(s,"stun") and e.resist==0 and e.firm==0
	var breaks: bool=survives and not e.broken and e.firm==0 and posture_damage>=e.posture
	var reply: bool=e.riposte and not e.broken and not breaks and not stun and hp_damage<e.hp and side=="Frente" and distance(side_origin,e.cell)==1
	var creates_opening: bool=survives and a.kind=="duarte" and (s.get("creates_opening",false) or breaks or stun or s.get("taunt",false))
	var applies_expose: bool=survives and (has_effect(s,"expose") or (s.get("flank_expose",false) and side!="Frente"))
	return {
		"last_stand":last_stand,"redirect":redirect,"read":technique_factor<1.0,"damage":hp_damage,"posture":posture_damage,"breaks":breaks,"side":side,"stun":stun,
		"bleed":survives and has_effect(s,"bleed"),"applies_exposed":applies_expose,
		"consumes_bleed":e.bleed>0 and int(s.get("bleed_burst",0))>0,
		"combo":opening_combo,"opening":creates_opening,"reply":9 if reply else 0,
		"firm":e.firm>0,"lethal":not survives,"anchored":anchored,"exposed":exposed,
		"rose_veil":veil,"shielded":shielded,"ward":ward,"prism":prism,"passive_bonuses":passive_bonuses
	}

func hurt(target: int, hp: int, posture: int) -> bool:
	var u: Dictionary=units[target]
	u.hp=maxi(0,u.hp-hp)
	if u.hp<=0: u.lance_cell=Vector2i(-1,-1)
	if u.name=="Yusuf ibn Rami" and objective.get("kind","")=="duel_rescue" and not u.last_stand_used and u.hp<=u.max_hp*0.15:
		u.hp=maxi(1,u.hp); u.phase_pending=true
	if objective.get("kind","")=="duel_rescue" and target==int(objective.actor_id) and u.hp<=u.max_hp*0.15 and u.get("last_stand_used",false):
		# Yusuf leaves the duel alive to lead the evacuation; his death is narrated after it.
		u.hp=0; u.withdrawn=true; u.charging=false
		objective=objective.rescue.duplicate(true)
		if unit_at(objective.asset_cell)>=0 or obstacles.has(objective.asset_cell):
			var landing: Vector2i=objective.asset_cell
			var best_distance:=1000
			for x in SIZE.x:
				for y in SIZE.y:
					var cell:=Vector2i(x,y)
					if unit_at(cell)<0 and not obstacles.has(cell) and distance(cell,landing)<best_distance:
						objective.asset_cell=cell; best_distance=distance(cell,landing)
		units[int(objective.actor_id)].objective_actor=true
		if not obstacles.has(objective.asset_cell): obstacles.append(objective.asset_cell)
	if hp>0 and u.hp>0 and has_passive(target,"iron_breath") and not u.get("breath_used",false):
		recover_passive(target,"iron_breath","qi",1); u.breath_used=true
	update_boss_phase(u)
	if u.broken:
		if hp>0: trigger_passives(target,"hurt")
		return false
	u.posture=maxi(1 if u.firm>0 else 0,u.posture-posture)
	var broke:bool=u.posture==0 and u.hp>0
	if broke:
		u.signal_pending=false
		u.broken=true; u.fortitude=0; u.fortitude_hits=0
		if BossTechniques.key(self,u)=="ceuta_depot" and u.contract_coins>0:
			var coins: int=mini(2,u.contract_coins); u.contract_coins-=coins
			boss_loot.append({"cell":u.cell,"coins":coins,"owner":target})
	if hp>0: trigger_passives(target,"hurt")
	return broke

func perform(skill: int, aim: Vector2i, quality: int) -> Dictionary:
	var was_duel: bool=objective.get("kind","")=="duel_rescue"
	var reason:=attack_reason(skill,aim)
	if not reason.is_empty(): return {"error":reason}
	var u:=current()
	var s:=skill_def(current_id,skill)
	var result: Dictionary={"actor":current_id,"skill":skill,"hits":[],"cells":area(current_id,skill,aim),"text":"","quality":quality}
	var passive_events: Array[String]=[]
	var uses_momentum:=hook_momentum(current_id,s)
	var support:=support_preview(current_id,skill,aim)
	u.qi-=s.cost
	if s.cooldown>0: u.cooldowns[skill]=u.turns+s.cooldown+1
	result.quick=s.get("quick",false)
	if result.quick: u.quick_used=true
	else: u.acted=true
	if Catalog.TECHNIQUES.has(skill): tech_uses[current_id][skill]=int(tech_uses[current_id].get(skill,0))+1

	# Universal/support commands.
	if skill==5:
		if has_passive(current_id,"breath"): record_passive(current_id,"breath",{"qi":maxi(0,int(support.qi)-5)})
		u.qi+=support.qi; u.posture+=support.posture; u.guard=true
		append_recovery(result.hits,current_id,support.qi,"qi")
		append_recovery(result.hits,current_id,support.posture,"posture")
		result.text=u.name+" recuperou alento e assumiu a guarda."
		trigger_passives(current_id,"breathe")
		return result
	if skill in [6,7]:
		var recipient_item: int=support.target
		var h_item: Dictionary=units[recipient_item]
		var resource_item: String=support.resource
		var amount_item: int=support.amount
		h_item[resource_item]+=amount_item
		if skill==6: potions-=1
		else: tonics-=1
		append_recovery(result.hits,recipient_item,amount_item,resource_item)
		result.text="%s recuperou %d de %s."%[h_item.name,amount_item,"vida" if skill==6 else "alento"]
		return result

	if s.shape in ["self","ally","friend"]:
		var recipient_id: int=support.target
		var recipient: Dictionary=units[recipient_id]
		for resource in ["hp","qi","posture"]:
			var amount: int=int(support.get(resource,0))
			if amount>0:
				recipient[resource]+=amount
				append_recovery(result.hits,recipient_id,amount,resource)
		if s.get("cleanse",false): recipient.bleed=0
		if int(support.movement)>0: recipient.moves+=int(support.movement)
		if support.guard: recipient.guard=true
		if int(s.get("fortitude",0))>0: grant_fortitude(current_id,int(s.fortitude))
		if support.cover and recipient_id!=current_id:
			u.cover_target=recipient_id; u.cover_range=int(s.range); u.guard=true
			result.cover=true
		if s.get("counter",false):
			u.counter_ready={
				"power":int(s.power),"posture":int(s.posture),"range":int(s.get("counter_range",1)),
				"perfect_only":s.get("counter_on_perfect",false),"name":s.name
			}
			u.guard=true
		result.text=u.name+" · "+s.name+(" · rápida" if s.get("quick",false) else "")
		return result

	# Flank attacks relocate before damage is resolved so preview and execution agree.
	# An attacker who already holds the angle keeps it instead of dashing again.
	if s.shape=="leap":
		result["movement_origin"]=u.cell
		u.cell=aim
		result["movement_destination"]=aim
		var resistance: int=int(s.get("fortitude",0))
		if has_passive(current_id,"duarte_landing"):
			resistance+=10
			if not u.broken and u.stun==0: record_passive(current_id,"duarte_landing",{"resistance_percent":resistance,"resistance_hits":2})
		grant_fortitude(current_id,resistance)
	if s.get("flank_attack",false):
		var victims:=targets(current_id,result.cells)
		if not victims.is_empty() and flank(current_id,victims[0],u.cell)=="Frente":
			var landing:=dash_destination(current_id,aim,int(s.range))
			if landing!=Vector2i(-1,-1):
				result["movement_origin"]=u.cell
				u.cell=landing
				result["movement_destination"]=landing

	for target in targets(current_id,result.cells):
		var was_bleeding: bool=units[target].bleed>0
		if was_bleeding: trigger_passives(current_id,"bleed_hit")
		var preview:=predict(current_id,target,skill,quality)
		var original_target: int=target
		if int(preview.get("redirect",-1))>=0:
			target=int(preview.redirect); units[target].paid_intercept=false
			preview=predict(current_id,target,skill,quality)
			result.text+=" · interceptado por "+units[target].name
		units[original_target].read_skills[current_id]=skill
		for id in preview.passive_bonuses:
			var bonus: Dictionary=preview.passive_bonuses[id]
			if bonus.has("damage_base") or bonus.has("damage_percent"):
				if preview.damage<=0: continue
			elif units[target].broken or preview.posture<=0: continue
			record_passive(current_id,id,bonus,target)
		var broke:=hurt(target,preview.damage,preview.posture)
		if preview.consumes_bleed: units[target].bleed=0
		if preview.exposed and units[target].hp>0: units[target].exposed=false
		if broke and current_id==0 and has_passive(current_id,"haft_hand") and not u.get("haft_proc_turn",false):
			recover_passive(current_id,"haft_hand","qi",1); u.haft_proc_turn=true
		if preview.stun and units[target].hp>0: units[target].stun=1
		if preview.bleed and units[target].hp>0:
			units[target].bleed=maxi(units[target].bleed,int(s.get("bleed_turns",3)))
		if quality==2 and was_bleeding and not preview.consumes_bleed and current_id==1 and has_passive(current_id,"clean_cut") and units[target].hp>0:
			record_passive(current_id,"clean_cut",{"bleed_turns":maxi(0,4-int(units[target].bleed))},target)
			units[target].bleed=4
		if preview.applies_exposed and units[target].hp>0: units[target].exposed=true
		if preview.combo: units[target].opening=0
		if preview.opening and units[target].hp>0: units[target].opening=2
		if s.get("taunt",false) and current_id==0 and units[target].hp>0: units[target].taunted_by=0
		if s.get("hook",false) and units[target].hp>0 and not hook_resisted(target):
			var pulled_to:=hook_destination(current_id,target)
			if pulled_to!=Vector2i(-1,-1) and pulled_to!=units[target].cell:
				units[target].cell=pulled_to
				passive_events.append("pull")
				preview["pulled"]=true
				preview["pull_destination"]=pulled_to
				if has_passive(current_id,"duarte_hook"):
					u.hook_momentum_until=u.turns+1
					record_passive(current_id,"duarte_hook",{"momentum":8})
		units[target].guard=false
		preview.id=target; preview.breaks=broke
		result.hits.append(preview)
		# Per-passive cooldowns cap multi-target attacks and quick/main-action chains.
		if broke: passive_events.append("break")
		if preview.combo: passive_events.append("opening_hit")
		if preview.exposed and units[target].hp>0: passive_events.append("exposed_hit")
		if units[target].hp<=0 and not units[target].get("withdrawn",false): passive_events.append("kill")
		if preview.damage>0 and preview.side!="Frente": passive_events.append("flank")
		if quality==2 and preview.side!="Frente": passive_events.append("flank_perfect")
		if preview.side!="Frente" and current_id==1 and has_passive(current_id,"sure_step") and not u.flank_proc_turn:
			u.moves+=1; u.flank_proc_turn=true
			record_passive(current_id,"sure_step",{"movement":1})
		if preview.reply>0:
			units[target].riposte=false
			apply_intercepted_hit(current_id,preview.reply,8,result.hits,"Resposta do duelista")

	# Resolve recoveries after the whole attack: filling posture must not change
	# Resposta veloz halfway through a line and invalidate its damage preview.
	if result.hits.filter(func(hit): return units[hit.id].team!=u.team and hit.get("damage",0)>0).size()>=2:
		passive_events.append("multi_hit")
	for event in passive_events: trigger_passives(current_id,event)
	u.last_skill=skill
	u.recent_skills.append(skill)
	if u.recent_skills.size()>3: u.recent_skills.pop_front()
	if uses_momentum: u.hook_momentum_until=-1
	if aim!=u.cell: u.face=direction_index(aim-u.cell)
	elif s.shape=="leap": u.face=direction_index(aim-Vector2i(result.movement_origin))
	if skill==0: u.qi=mini(u.max_qi,u.qi+1)
	if quality==2:
		u.qi=mini(u.max_qi,u.qi+1); perfects+=1
		trigger_passives(current_id,"perfect")
		if current_id==1 and has_passive(current_id,"house_rhythm"):
			var recovered:=mini(5,u.max_posture-u.posture)
			u.posture+=recovered
			append_recovery(result.hits,current_id,recovered,"posture")
			record_passive(current_id,"house_rhythm",{"posture":recovered})
	result.text="%s · %s"%[u.name,s.name]
	if u.hp>0 and int(s.get("movement_after",0))>0:
		u.moves+=int(s.movement_after)
		result.text+=" · +%d movimento"%int(s.movement_after)
	if was_duel and objective.get("kind","")=="protect": result.text+=" · YUSUF ABRE A PASSAGEM. PROTEGE AS FAMÍLIAS."
	if s.get("cover_after",false) and current_id==0 and units[1].hp>0:
		u.cover_target=1; u.cover_range=3; u.guard=true; result.cover=true
	if s.get("duarte_cover_after",false) and current_id==1 and units[0].hp>0 and not units[0].broken and units[0].stun==0:
		units[0].cover_target=1; units[0].cover_range=3; units[0].guard=true; result.cover=true
	if result.hits.any(func(h): return h.get("combo",false)): result.text+=" · ABERTURA CONSUMIDA"
	return result

func append_recovery(hits: Array, target: int, amount: int, resource: String) -> void:
	if amount<=0: return
	hits.append({"id":target,"damage":-amount,"posture":0,"breaks":false,"side":"","stun":false,"bleed":false,"resource":resource})

func next_turn() -> Dictionary:
	turn_events.clear()
	if not outcome().is_empty(): return {"finished":true}
	var safety:=0
	while safety<units.size()*3:
		safety+=1; order_index+=1
		if order_index>=order.size():
			if objective.get("kind","")=="escort":
				advance_escort()
				if not outcome().is_empty(): return {"finished":true}
			round_no+=1; rebuild_order(); order_index=0
		current_id=order[order_index]
		var u:=current()
		if u.hp<=0: continue
		u.moved_last_turn=u.cell!=u.get("turn_origin",u.cell); u.turn_origin=u.cell
		u.moves=u.movement; u.acted=false; u.quick_used=false; u.turns+=1
		if u.turns<=int(u.get("rooted_until",-1)): u.moves=maxi(0,u.moves-2)
		u.haft_proc_turn=false; u.flank_proc_turn=false; u.breath_used=false
		u.cover_target=-1; u.riposte=false; u.exposed=false; u.counter_ready={}
		u.fortitude=0; u.fortitude_hits=0
		if u.turns>int(u.get("hook_momentum_until",-1)): u.hook_momentum_until=-1
		if u.team==0 and has_passive(current_id,"tide_anchor") and u.posture<=int(u.max_posture*0.5):
			var restored:=mini(8,u.max_posture-u.posture)
			u.posture+=restored
			record_passive(current_id,"tide_anchor",{"posture":restored})
		if u.firm>0: u.firm-=1
		if u.opening>0: u.opening-=1
		if u.resist>0: u.resist-=1
		if u.bleed>0:
			u.bleed-=1
			if u.name=="Yusuf ibn Rami" and objective.get("kind","")=="duel_rescue": hurt(u.id,8,0)
			else: u.hp=maxi(0,u.hp-8)
			update_boss_phase(u)
			turn_events.append({"id":u.id,"text":"−8 SANGRAMENTO","damage":8})
		if u.hp<=0:
			if not outcome().is_empty(): return {"finished":true}
			continue
		trigger_passives(current_id,"turn_start")
		if u.stun>0 or u.broken:
			u.signal_pending=false
			u.taunted_by=-1
			var reason: String="atordoado" if u.stun>0 else "sem postura"
			if u.stun>0: u.resist=2
			if Identity.is_boss(u) or BossTechniques.key(self,u)=="yusuf": u.firm=2; u.resist=maxi(2,u.resist)
			u.stun=0; u.broken=false; u.posture=u.max_posture
			u.warning.clear(); u.followup.clear(); u.charging=false; u.signature_pending=false; u.charge_ready_turn=u.turns+2; u.technique_ready=u.turns+2; u.phase_pending=false; u.acted=true; u.quick_used=true; u.moves=0
			return {"skip":true,"text":"%s perde o turno: %s."%[u.name,reason]}
		return {"skip":false,"text":"É a vez de %s."%u.name}
	return {"finished":true}

func end_turn(face: int) -> Dictionary:
	var u:=current()
	u.face=clampi(face,0,3)
	if u.turns>=int(u.get("hook_momentum_until",-1)): u.hook_momentum_until=-1
	if u.team==0 and has_passive(current_id,"duarte_iron_guard") and u.kind=="duarte" and u.posture==u.max_posture:
		if not u.guard: record_passive(current_id,"duarte_iron_guard",{"guard":1})
		u.guard=true
	return next_turn()

func advance_escort() -> void:
	if objective.get("kind","")!="escort": return
	var cell: Vector2i=objective.asset_cell
	var next_cell: Vector2i=cell+Vector2i(1,0)
	var threatened:=false
	for enemy in enemies:
		if enemy.hp>0 and (distance(enemy.cell,cell)<=1 or (enemy.get("siege_actor",false) and distance(enemy.cell,cell)<=3)): threatened=true; break
	if threatened or unit_at(next_cell)>=0 or obstacles.has(next_cell): return
	obstacles.erase(cell)
	objective.asset_cell=next_cell
	objective.progress=int(objective.get("progress",0))+1
	obstacles.append(next_cell)

func living(team: int) -> Array[int]:
	var result: Array[int]=[]
	for u in units:
		if u.hp>0 and u.team==team: result.append(u.id)
	return result

func outcome() -> String:
	if living(0).is_empty(): return "defeat"
	if objective.get("kind","")=="capture":
		var target: Dictionary=units[int(objective.target_id)]
		if target.hp<=0 or target.broken or target.stun>0: return "victory"
		if objective.get("escaped",false): return "defeat"
	if objective.get("kind","")=="protect" and int(objective.get("hp",0))<=0: return "defeat"
	if objective.get("kind","")=="escort":
		if int(objective.get("hp",0))<=0: return "defeat"
		if objective.asset_cell==objective.exit: return "victory"
		return ""
	if living(1).is_empty(): return "victory"
	return ""

func objective_status() -> Dictionary:
	match objective.get("kind",""):
		"changing_deck":
			var target: Dictionary=units[int(objective.actor_id)]
			return {"title":boss_phase_name(target.id),"detail":objective.detail,"value":target.hp,"maximum":target.max_hp}
		"duel_rescue":
			var target: Dictionary=units[int(objective.actor_id)]
			return {"title":objective.title,"detail":objective.detail,"value":target.hp,"maximum":target.max_hp}
		"capture":
			var target: Dictionary=units[int(objective.target_id)]
			return {"title":objective.get("title","CAPTURA"),"detail":objective.get("detail","Interrompe o alvo antes da fuga."),"value":distance(target.cell,objective.exit),"maximum":8}
		"protect":
			return {"title":objective.get("title","PROTEGE O OBJECTIVO"),"detail":objective.get("detail","Impede a destruição."),"value":int(objective.hp),"maximum":int(objective.max_hp)}
		"escort":
			var detail: String=objective.get("detail","Defende a embarcação e abre caminho.")
			if objective.get("support","")=="armada": detail+=" A Armada distrai os atacantes: sofrem menos dano de cerco."
			elif objective.get("support","")=="lastro": detail+=" O Lastro reforçou o casco: a barca tem integridade adicional."
			return {"title":objective.get("title","ESCOLTA"),"detail":detail,"value":int(objective.hp),"maximum":int(objective.max_hp),"progress":int(objective.get("progress",0)),"distance":distance(objective.asset_cell,objective.exit)}
	return {}

func rose_veil(target: int) -> bool:
	if encounter!="refuge_trial" or target!=2: return false
	var u: Dictionary=units[target]
	return u.hp>0 and not u.broken and not u.exposed and enemies.any(func(e): return e.id in [3,4] and e.hp>0)

func order_bonus(actor: int) -> int:
	var u: Dictionary=units[actor]
	var source: int=int(u.get("order_source",-1))
	var paid_bonus: int=int(u.get("bounty_power",0))
	if source<0 or source>=units.size(): return paid_bonus
	var leader: Dictionary=units[source]
	return paid_bonus+(6 if Identity.active(leader) and leader.cell==leader.signal_origin and leader.turns<=int(u.order_until) and distance(u.cell,leader.cell)<=3 and clear_line(leader.cell,u.cell,source) else 0)

func enemy_intent(id: int) -> Dictionary:
	# A read-only explanation of the next decision, using the same conditions as AI.
	var intent: Dictionary={"title":"","detail":"","plan_kind":"wait"}
	if id<0 or id>=units.size() or units[id].team!=1 or units[id].hp<=0: return intent
	var u: Dictionary=units[id]
	if u.stun>0 or u.broken:
		return {"title":"Turno interrompido","detail":"Perde o próximo turno. Aproveita para te preparares.","plan_kind":"skip"}
	if objective.get("kind","")=="escort" and u.get("siege_actor",false):
		var d:=distance(u.cell,objective.asset_cell)
		return {"title":"Atacar a barca" if d==1 else "Aproximar-se da barca","detail":"A integridade da barca diminui %d no próximo golpe."%int(objective.get("siege_damage",30)),"plan_kind":"asset_attack" if d==1 else "asset_approach"}
	if u.kind=="signaller" and enemies.any(func(e): return e.id!=id and e.hp>0) and not living(0).has(u.get("taunted_by",-1)):
		return {"title":"Executar a ordem" if u.signal_pending and u.cell==u.signal_origin else "Preparar sinal","detail":"Ordem no próximo turno: +6 poder aos aliados até 3 casas. Quebra, atordoa ou desloca o sinaleiro.","plan_kind":"signal"}
	if not BossTechniques.key(self,u).is_empty():
		var boss_turn: int=u.turns+(0 if id==current_id and not u.acted else 1)
		if BossTechniques.key(self,u)=="vigia_guard" and u.lance_cell!=Vector2i(-1,-1):
			return {"title":"Regresso do espinho","detail":BossTechniques.hint(self,u)+" Afasta-te da linha entre a lança e o guardião.","plan_kind":"ranged"}
		if BossTechniques.key(self,u) in ["cove_trial","lisbon_avelar"] and boss_turn<=int(u.get("fatigued_until",-1)):
			return {"title":"Rearmar a caçada" if is_avelar(id) else "Recuperar o fôlego","detail":"Recupera sem atacar nem recuar. Postura exposta: aproxima-te e castiga a recuperação.","plan_kind":"recover"}
		return {"title":BossTechniques.title(self,u) if BossTechniques.ready(u,boss_turn) else ("Exposto" if u.exposed else "Técnica · "+u.name),"detail":BossTechniques.hint(self,u),"plan_kind":"sequence" if BossTechniques.ready(u,boss_turn) else "attack"}
	if encounter=="refuge_trial" and id==2 and rose_veil(id) and not u.charging:
		return {"title":"Véu da Rosa · −40% dano de vida","detail":"Derrota as duas memórias, quebra a postura ou aplica Exposto. O véu não reduz pressão de postura.","plan_kind":"heavy" if u.charging else "attack"}
	if u.kind=="boarder":
		return {"title":"Gancho de abordagem","detail":"Ataca até 3 casas em linha livre e puxa para junto de si. Guarda, cobertura ou defesa perfeita impedem o puxão.","plan_kind":"attack"}
	if u.charging:
		return {"title":u.warning_name,"detail":"Golpe nas casas vermelhas; não segue a dupla."+(" O âmbar anuncia o golpe seguinte." if not u.followup.is_empty() else " Depois fica exposto."),"plan_kind":"heavy"}
	if u.exposed:
		return {"title":"Exposto","detail":"O próximo golpe recebido ganha +35% dano de postura e consome Exposto; também expira no próximo turno.","plan_kind":"recover"}
	if objective.get("kind","")=="capture" and id==int(objective.target_id) and not living(0).has(u.get("taunted_by",-1)):
		return {"title":objective.get("move_name","Fugir"),"detail":"Corre para a saída. Se começar o próximo turno na casa marcada, escapa.","plan_kind":"flee"}
	if objective.get("kind","")=="protect" and id==int(objective.actor_id) and not living(0).has(u.get("taunted_by",-1)):
		return {"title":objective.get("action_name","Destruir o objectivo"),"detail":"Cada ataque retira %d de integridade. Interrompe este adversário primeiro."%int(objective.get("damage",34)),"plan_kind":"burn"}
	if u.get("protects_allies",false):
		return {"title":"Formação de protecção","detail":"Em guarda: aliados até 2 casas recebem −25% dano frontal. Flanqueia, quebra ou atordoa o protector.","plan_kind":"attack" if distance(u.cell,heroes[0].cell)<=u.movement+1 else "brace"}
	if u.get("disrupts_qi",false):
		var adjacent: bool=heroes.any(func(h): return h.hp>0 and distance(u.cell,h.cell)<=1)
		return {"title":"Recuar sob pressão" if adjacent else "Flecha de interrupção","detail":"Tiro com dano retira 2 Qi. Guarda, defesa perfeita ou cobertura evitam a perda. Adjacente: recua sem disparar.","plan_kind":"approach" if adjacent else "ranged"}
	var nearest:=1000
	for hero in heroes:
		if hero.hp>0: nearest=mini(nearest,distance(u.cell,hero.cell))
	var turn: int=u.turns+(0 if id==current_id and not u.acted else 1)
	if u.kind=="medic": return {"title":"Socorro aos aliados","detail":"Reposiciona-se para tratar um aliado: +%d vida, alcance 3 e linha livre. Estanca também a hemorragia. Pressiona ou interrompe o socorrista."%enemy_healing_power(id),"plan_kind":"heal"}
	if u.kind=="bombard": return {"title":"Pote de pólvora","detail":"Anuncia uma explosão em cruz, fixa no chão, antes de a detonar. Sai das casas vermelhas.","plan_kind":"charge"}
	if u.kind=="pikeman": return {"title":"Pique de alcance","detail":"Ameaça até duas casas com linha livre. Pressiona a posição e ataca pelos flancos.","plan_kind":"attack"}
	if u.kind=="defender":
		var can_strike:=false
		var routes:=reachable(id,u.moves if id==current_id and not u.acted else u.movement)
		for cell in routes.costs:
			for hero in heroes:
				if hero.hp>0 and distance(cell,hero.cell)==1: can_strike=true
		return {"title":"Talho do baluarte" if can_strike else "Fechar a passagem","detail":"Recompõe a guarda após atacar. Flanqueia ou abre-a com um golpe." if can_strike else "Avança em guarda. Flanqueia ou abre a guarda com um golpe.","plan_kind":"attack" if can_strike else "brace"}
	if is_avelar(id):
		var preparing: bool=Identity.preparing(u,turn)
		var shot:=avelar_shot(turn,u.boss_phase)
		if id==current_id and not u.acted:
			var actual: Dictionary=ai_plan()
			return {"title":actual.get("name",shot.name),"detail":Identity.BOSSES.lisbon_avelar.hint+" Alcance 2–5; encurralado: adaga a 1 casa.","plan_kind":actual.kind}
		return {"title":Identity.BOSSES.lisbon_avelar.name if preparing else shot.name,"detail":Identity.BOSSES.lisbon_avelar.hint+" Tiro: alcance 2–5; %d tempos. Se encurralado, responde com a adaga."%shot.defense_beats,"plan_kind":"charge" if preparing else "ranged"}
	if u.kind=="archer":
		return {"title":"Recuar sob pressão" if nearest<=1 else "Procurar linha de tiro","detail":"Está adjacente: recua sem disparar neste turno." if nearest<=1 else "Procura tiro livre entre 2 e 5 casas. Encosta-te para forçar o recuo.","plan_kind":"approach" if nearest<=1 else "ranged"}
	if u.kind=="duelist":
		var brace: bool=turn%2==0 and nearest<=2
		if EnemyMoves.is_yusuf(u):
			return {"title":"Guarda de resposta" if brace or u.riposte else EnemyMoves.move(u,encounter,turn).name,"detail":"Resposta frontal: 9 dano. Flanqueia, quebra ou atordoa." if brace or u.riposte else ("4 tempos; empurra 1 casa e causa hemorragia por 2 turnos. Guarda, cobertura ou defesa perfeita evitam os efeitos." if turn%3==0 else "3 tempos; procura os teus flancos. Vira-te para ele ou prepara cobertura."),"plan_kind":"brace" if brace else "attack"}
		return {"title":"Guarda de resposta" if brace or u.riposte else "Procurar o flanco","detail":"Resposta frontal: 9 dano. Evita pelo flanco, quebra ou atordoa." if brace or u.riposte else "Procura as costas da dupla. Termina o turno virado para ele.","plan_kind":"brace" if brace else "attack"}
	if u.kind=="boss":
		var preparing: bool=Identity.preparing(u,turn)
		return {"title":Identity.BOSSES.get(encounter,Identity.BOSSES.boss).name if preparing else boss_move(u,turn).name,"detail":Identity.BOSSES.get(encounter,Identity.BOSSES.boss).hint if preparing else (boss_hint(id) if u.get("signature_pending",false) or catarina_duelist() or encounter=="ceuta_depot" else EnemyMoves.intent_hint(u,encounter,turn)),"plan_kind":"charge" if preparing else "attack"}
	return {"title":"Aproximar e atacar","detail":"Protege a frente e procura uma posição lateral.","plan_kind":"attack"}

func medic_plan(actor: int) -> Dictionary:
	var graph:=reachable(actor)
	var best: Dictionary={}
	var best_score:=-INF
	for cell in graph.costs:
		var danger:=0
		for hero in heroes:
			if hero.hp>0 and distance(cell,hero.cell)<=1: danger+=1
		for ally in enemies:
			if ally.id==actor or ally.hp<=0 or ally.max_hp-ally.hp<35: continue
			if distance(cell,ally.cell)>3 or not clear_line(cell,ally.cell,actor): continue
			var score: float=mini(enemy_healing_power(actor),int(ally.max_hp-ally.hp))-danger*24-int(graph.costs[cell])*2
			if score>best_score:
				best_score=score
				best={"kind":"heal","path":path_to(actor,cell),"destination":cell,"targets":[],"patient":ally.id,"cells":[ally.cell],"name":"Estancar e tratar","power":enemy_healing_power(actor)}
	return best

func is_avelar(actor: int) -> bool:
	return encounter=="lisbon_avelar" and units[actor].name=="Rui de Avelar"

func avelar_shot(turn: int, phase := 1) -> Dictionary:
	var cycle:=posmod(maxi(1,turn)-1,4)
	if cycle==1: return {"name":"Flecha rompe-guarda","power":25,"posture":28,"defense_beats":4,"guard_pressure":true}
	if cycle==3: return {"name":"Saraivada de Avelar","power":32,"posture":22,"defense_beats":5}
	return {"name":"Disparo triplo","power":23+(phase-1)*3,"posture":16+(phase-1)*2,"defense_beats":3}

func catarina_duelist() -> bool:
	return encounter=="stronghold" and enemies.filter(func(e): return e.kind=="archer" and Identity.active(e)).size()<2

func boss_move(u: Dictionary, turn: int) -> Dictionary:
	var move_turn: int=4 if u.get("signature_pending",false) else turn
	var move: Dictionary=EnemyMoves.move(u,encounter,move_turn)
	if encounter=="stronghold" and catarina_duelist():
		move.name="Resposta da antiga discípula" if move.get("guard_after",false) else "Estocada de perseguição"
		move.power+=u.boss_phase*2; move.posture+=3
		move.riposte_after=true
	if encounter=="ceuta_depot" and u.kind=="boss" and not payment_orders_active():
		move.name="Cobrança sem escolta"
		move.power+=4; move.posture+=4; move.qi_drain=3
	return move

func ai_plan() -> Dictionary:
	var u:=current()
	if u.team!=1 or u.hp<=0 or u.acted or u.stun>0 or u.broken: return {"kind":"wait"}
	if objective.get("kind","")=="capture" and current_id==int(objective.target_id) and not living(0).has(u.get("taunted_by",-1)):
		var exit_cell: Vector2i=objective.exit
		if u.cell==exit_cell:
			return {"kind":"flee","path":[],"destination":exit_cell,"targets":[],"cells":[exit_cell],"name":objective.get("flee_name","Fugir"),"escape_now":true}
		var escape_path:=path_to(current_id,exit_cell,SIZE.x*SIZE.y)
		var steps: int=mini(u.moves,escape_path.size())
		var destination: Vector2i=escape_path[steps-1] if steps>0 else u.cell
		return {"kind":"flee","path":escape_path.slice(0,steps),"destination":destination,"targets":[],"cells":[exit_cell],"name":objective.get("move_name","Correr para a saída"),"escape_now":false}
	if objective.get("kind","")=="protect" and current_id==int(objective.actor_id) and not living(0).has(u.get("taunted_by",-1)):
		var asset: Vector2i=objective.asset_cell
		var graph:=reachable(current_id,SIZE.x*SIZE.y)
		var best: Vector2i=u.cell
		var best_cost:=999
		for cell in graph.costs:
			if distance(cell,asset)==1 and int(graph.costs[cell])<best_cost:
				best=cell; best_cost=int(graph.costs[cell])
		var burn_path:=path_to(current_id,best,SIZE.x*SIZE.y)
		burn_path=burn_path.slice(0,mini(u.moves,burn_path.size()))
		var destination: Vector2i=burn_path[-1] if not burn_path.is_empty() else u.cell
		return {"kind":"burn" if distance(destination,asset)==1 else "approach","path":burn_path,"destination":destination,"targets":[],"cells":[asset],"name":objective.get("action_name","Destruir o objectivo") if distance(destination,asset)==1 else objective.get("approach_name","Aproximar-se do objectivo"),"power":int(objective.get("damage",34))}
	if objective.get("kind","")=="escort" and u.get("siege_actor",false) and not living(0).has(u.get("taunted_by",-1)):
		var asset: Vector2i=objective.asset_cell
		var graph:=reachable(current_id,SIZE.x*SIZE.y)
		var best: Vector2i=u.cell
		var best_cost:=999
		for cell in graph.costs:
			if distance(cell,asset)==1 and int(graph.costs[cell])<best_cost:
				best=cell; best_cost=int(graph.costs[cell])
		var route:=path_to(current_id,best,SIZE.x*SIZE.y).slice(0,mini(u.moves,path_to(current_id,best,SIZE.x*SIZE.y).size()))
		var destination: Vector2i=route[-1] if not route.is_empty() else u.cell
		return {"kind":"asset_attack" if distance(destination,asset)==1 else "approach","path":route,"destination":destination,"targets":[],"cells":[asset],"name":"Atacar a barca" if distance(destination,asset)==1 else "Fechar-se à barca","power":int(objective.get("siege_damage",30))}
	if BossTechniques.key(self,u)=="vigia_guard" and u.lance_cell!=Vector2i(-1,-1): return BossTechniques.lance_return(self,current_id)
	if BossTechniques.key(self,u)=="ceuta_depot":
		for bag in boss_loot:
			if int(bag.owner)==current_id and distance(u.cell,bag.cell)<=1:
				return {"kind":"reclaim","path":[],"targets":[],"cells":[bag.cell],"name":"Recuperar a bolsa"}
	if BossTechniques.key(self,u) in ["cove_trial","lisbon_avelar"] and u.turns<=int(u.get("fatigued_until",-1)):
		return {"kind":"recover","path":[],"targets":[],"cells":[],"name":"Rearmar a caçada" if is_avelar(current_id) else "Recuperar o fôlego"}
	if u.get("paid_intercept",false) and encounter=="ceuta_depot":
		var clients: Array=enemies.filter(func(e): return e.kind=="boss" and Identity.active(e))
		if not clients.is_empty():
			var positions:=reachable(current_id)
			var guard_cell: Vector2i=u.cell
			var nearest_client: int=distance(u.cell,clients[0].cell)
			for cell in positions.costs:
				var d: int=distance(cell,clients[0].cell)
				if d<nearest_client: guard_cell=cell; nearest_client=d
			return {"kind":"brace","path":path_to(current_id,guard_cell),"destination":guard_cell,"targets":[],"cells":[guard_cell],"name":"Tu recebes para isto · guardar o chefe"}
	if u.charging:
		return {"kind":"heavy","path":[],"cells":u.warning.duplicate(),"targets":targets(current_id,u.warning),"name":u.warning_name,"power":u.warning_power,"posture":28,"push_steps":u.warning_push_steps}
	var opponents:=living(0)
	var taunt: int=u.get("taunted_by",-1)
	if opponents.has(taunt): opponents=[taunt]
	elif opponents.has(int(u.get("bounty_target",-1))): opponents=[int(u.bounty_target)]
	if opponents.is_empty(): return {"kind":"wait"}
	var nearest: int=opponents[0]
	for target in opponents:
		if distance(u.cell,units[target].cell)<distance(u.cell,units[nearest].cell): nearest=target
	if u.kind=="signaller" and not opponents.has(taunt) and enemies.any(func(e): return e.id!=current_id and e.hp>0):
		return {"kind":"signal","path":[],"targets":[],"cells":[u.cell],"name":"Ordem de abordagem" if u.signal_pending and u.cell==u.signal_origin else "Preparar sinal"}
	if u.kind=="boarder" and distance(u.cell,units[nearest].cell) in [2,3] and clear_line(u.cell,units[nearest].cell,current_id):
		return {"kind":"attack","path":[],"targets":[nearest],"target":nearest,"cells":[units[nearest].cell],"name":"Gancho de abordagem","power":20,"posture":16,"pull_on_hit":true,"defense_beats":3}
	if u.kind=="medic" and not opponents.has(taunt):
		var care:=medic_plan(current_id)
		if not care.is_empty(): return care
	if u.kind=="bombard":
		# Find a firing position before announcing; the warning remains fixed.
		var firing_graph:=reachable(current_id)
		var firing_cell: Vector2i=u.cell
		var firing_score:=-INF
		for cell in firing_graph.costs:
			var d:=distance(cell,units[nearest].cell)
			if d<2 or d>5 or not clear_line(cell,units[nearest].cell,current_id): continue
			var score: float=-absf(d-4)*8-int(firing_graph.costs[cell])
			for target in opponents:
				if distance(cell,units[target].cell)<=1: score-=60
			if score>firing_score: firing_score=score; firing_cell=cell
		if firing_score>-INF:
			var blast: Array[Vector2i]=[]
			for x in SIZE.x:
				for y in SIZE.y:
					var cell:=Vector2i(x,y)
					if distance(cell,units[nearest].cell)<=1 and not obstacles.has(cell): blast.append(cell)
			return {"kind":"charge","path":path_to(current_id,firing_cell),"destination":firing_cell,"targets":[],"cells":blast,"name":"Pote de pólvora","power":34}
	if not BossTechniques.key(self,u).is_empty() and BossTechniques.ready(u,u.turns):
		return BossTechniques.special(self,current_id,nearest)
	if BossTechniques.key(self,u).is_empty() and Identity.preparing(u,u.turns):
		return Identity.charge(self,current_id,nearest)
	if u.kind=="duelist" and u.name!="Yusuf ibn Rami" and u.turns%2==0 and distance(u.cell,units[nearest].cell)<=2:
		return {"kind":"brace","path":[],"targets":[],"cells":[u.cell],"name":"Guarda de resposta"}
	var attack_reach:=EnemyMoves.reach(u,encounter)
	if BossTechniques.key(self,u)=="vigia_guard": attack_reach=3 if u.lance_form==0 else 1
	if encounter=="ceuta_depot" and u.kind=="boss" and not boss_ward(u.id,"Frente"): attack_reach=2
	var graph:=reachable(current_id,mini(u.moves,1) if BossTechniques.key(self,u)=="vigia_guard" and u.lance_form==1 else u.moves)
	var best: Vector2i=u.cell
	var best_target:=nearest
	var best_score:=-100000.0
	for cell in graph.costs:
		for target in opponents:
			var d:=distance(cell,units[target].cell)
			var score: float= -d*12-graph.costs[cell]*0.3
			if u.kind=="defender": score-=distance(cell,u.home)*3
			if u.kind in ["archer","pikeman","boarder"]:
				var ideal: int=2 if u.kind in ["pikeman","boarder"] else 3
				var reach: int=2 if u.kind=="pikeman" else (3 if u.kind=="boarder" else 5)
				score=-absf(d-ideal)*9-graph.costs[cell]*0.5
				if d>=2 and d<=reach and clear_line(cell,units[target].cell,current_id): score+=130
				for opponent in opponents:
					if distance(cell,units[opponent].cell)<=1: score-=90
			if d>=1 and d<=attack_reach and clear_line(cell,units[target].cell,current_id):
				score+=100+(units[target].max_hp-units[target].hp)*0.06
				var side:=flank(current_id,target,cell)
				if u.kind=="duelist" or (u.kind=="boss" and catarina_duelist()): score+=42 if side=="Costas" else (22 if side=="Flanco" else 0)
				else: score+=18 if side=="Costas" else (8 if side=="Flanco" else 0)
			score+=difficulty_target_priority(target)+Identity.support_score(self,current_id,cell,target)
			if score>best_score: best_score=score; best=cell; best_target=target
	var path:=path_to(current_id,best)
	if u.kind=="boarder":
		var can_hook: bool=distance(best,units[best_target].cell) in [2,3] and clear_line(best,units[best_target].cell,current_id)
		return {"kind":"attack" if can_hook else "approach","path":path,"destination":best,"target":best_target,"targets":[best_target] if can_hook else [],"cells":[units[best_target].cell],"name":"Gancho de abordagem","power":20,"posture":16,"pull_on_hit":true,"defense_beats":3}
	if u.kind=="pikeman":
		var can_thrust: bool=distance(best,units[best_target].cell)<=2 and clear_line(best,units[best_target].cell,current_id)
		return {"kind":"attack" if can_thrust else "approach","path":path,"destination":best,"target":best_target,"targets":[best_target] if can_thrust else [],"cells":[units[best_target].cell],"name":"Ponta da paliçada","power":21,"posture":22}
	if u.kind=="archer":
		if distance(u.cell,units[nearest].cell)<=1 and not is_avelar(current_id):
			return {"kind":"approach","path":path,"destination":best,"targets":[],"cells":[],"name":"Recuar sob pressão"}
		var can_shoot: bool=distance(best,units[best_target].cell)<=5 and distance(best,units[best_target].cell)>=2 and clear_line(best,units[best_target].cell,current_id)
		var shot: Dictionary={"kind":"ranged" if can_shoot else "approach","path":path,"destination":best,"target":best_target,"targets":[best_target] if can_shoot else [],"cells":[units[best_target].cell],"name":"Flecha do cais","power":18,"posture":10}
		if is_avelar(current_id):
			if not can_shoot and distance(u.cell,units[nearest].cell)==1:
				return {"kind":"attack","path":[],"destination":u.cell,"target":nearest,"targets":[nearest],"cells":[units[nearest].cell],"name":"Adaga de emergência","power":20,"posture":18,"defense_beats":3}
			shot.merge(avelar_shot(u.turns,u.boss_phase),true)
		elif u.get("disrupts_qi",false): shot.name="Flecha de interrupção"; shot.qi_drain=2
		return BossTechniques.normal(self,u,shot) if is_avelar(current_id) else shot
	var can_strike: bool=distance(best,units[best_target].cell)<=attack_reach and clear_line(best,units[best_target].cell,current_id)
	var strike: Dictionary={"kind":"attack" if can_strike else "approach","path":path,"destination":best,"target":best_target,"targets":[best_target] if can_strike else [],"cells":[units[best_target].cell],"name":"Corte de revés" if u.kind=="boss" else "Talho rival","power":27 if u.kind=="boss" else 19,"posture":19 if u.kind=="boss" else 13,"bleed":false,"arc":false}
	if u.kind=="defender" and strike.kind=="approach": strike.kind="brace"; strike.name="Fechar a passagem"
	elif u.kind=="defender":
		strike.name="Talho do baluarte"; strike.power=23; strike.posture=20
	if strike.kind=="attack" and u.kind=="rogue" and u.turns%2==0:
		strike.name="Fio da névoa"; strike.bleed=true
	if strike.kind=="attack" and u.kind=="guard":
		var old_cell: Vector2i=u.cell
		u.cell=best
		var sweep:=area(current_id,1,units[best_target].cell)
		u.cell=old_cell
		var victims:=targets(current_id,sweep)
		if victims.size()>1:
			strike.name="Varrimento rival"; strike.cells=sweep; strike.targets=victims; strike.arc=true
	if strike.kind=="attack": strike.merge(boss_move(u,u.turns) if u.kind=="boss" else EnemyMoves.move(u,encounter,u.turns),true)
	if strike.kind=="attack" and not BossTechniques.key(self,u).is_empty(): strike=BossTechniques.normal(self,u,strike)
	if strike.kind=="attack" and int(u.get("bounty_power",0))>0:
		strike.name="Preço pela cabeça · "+strike.name
	return strike

func cover_info(target: int, damage: int) -> Dictionary:
	for u in heroes:
		if damage>0 and u.hp>0 and not u.broken and u.stun==0 and u.id!=target and u.cover_target==target and distance(u.cell,units[target].cell)<=u.get("cover_range",2) and clear_line(u.cell,units[target].cell,u.id):
			return {"id":u.id,"damage":int(ceil(damage*0.25)),"remaining":int(ceil(damage*0.5))}
	return {"id":-1,"damage":0,"remaining":damage}

func apply_intercepted_hit(target: int, damage: int, posture: int, hits: Array, side: String) -> Dictionary:
	var resistance:=fortitude_preview(target,damage,posture)
	consume_fortitude(target,damage,posture)
	damage=resistance.damage; posture=resistance.posture
	var cover:=cover_info(target,damage)
	var target_posture:=posture
	if cover.id>=0:
		units[cover.id].cover_target=-1
		var protector_resistance:=fortitude_preview(cover.id,cover.damage,0)
		consume_fortitude(cover.id,cover.damage,0)
		cover.damage=protector_resistance.damage
		var protector_break:=hurt(cover.id,cover.damage,0)
		hits.append({"id":cover.id,"damage":cover.damage,"posture":0,"breaks":protector_break,"side":"Protecção","stun":false,"bleed":false})
		if units[cover.id].hp>0 and has_passive(cover.id,"protective_instinct"):
			var restored:=mini(6,units[cover.id].max_posture-units[cover.id].posture)
			units[cover.id].posture+=restored
			append_recovery(hits,cover.id,restored,"posture")
			record_passive(cover.id,"protective_instinct",{"posture":restored})
		if has_passive(cover.id,"closed_line") and target==1:
			target_posture=int(target_posture*0.75)
			if not units[target].broken: record_passive(cover.id,"closed_line",{"mitigated_posture":posture-target_posture},target)
		trigger_passives(cover.id,"cover")
	var broke:=hurt(target,cover.remaining,target_posture)
	var hit: Dictionary={"id":target,"damage":cover.remaining,"posture":target_posture,"breaks":broke,"side":side,"stun":false,"bleed":false}
	hits.append(hit)
	return hit

func defense_preview(actor: int, target: int, attack: Dictionary, grade: int) -> Dictionary:
	var h: Dictionary=units[target]
	var side:=flank(actor,target,attack.get("projectile_origin",Vector2i(-1,-1)))
	var factors: Array=[1.0,0.35,0.0] if side=="Frente" or attack.get("universal_parry",false) else ([1.0,0.55,0.0] if side=="Flanco" else [1.0,0.75,0.5])
	var mult:=1.25 if side=="Costas" else (1.1 if side=="Flanco" else 1.0)
	var challenge_power: float=float(units[actor].get("challenge_power",1.0))
	var damage:=int(maxi(1,int(attack.power)+order_bonus(actor)-int(h.get("defense",0)))*mult*factors[clampi(grade,0,2)]*(0.5 if h.guard else 1.0)*challenge_power)
	var po:=int(int(attack.posture)*factors[clampi(grade,0,2)]*float(units[actor].get("posture_pressure",challenge_power))) if not h.guard or attack.get("guard_pressure",false) else 0
	if h.guard and attack.get("guard_pressure",false): po=int(po*0.5)
	var raw_damage:=damage
	var raw_posture:=po
	var resistance:=fortitude_preview(target,damage,po)
	damage=resistance.damage; po=resistance.posture
	var cover:=cover_info(target,damage)
	if cover.id>=0: cover.damage=fortitude_preview(cover.id,cover.damage,0).damage
	var drain_amount: int=int(attack.get("qi_drain",2 if attack.get("kind","")=="ranged" and units[actor].get("disrupts_qi",false) else 0))
	var drain: int=mini(drain_amount,h.qi) if damage>0 and grade<2 and not h.guard and cover.id<0 else 0
	var push:=Vector2i(-1,-1)
	if (attack.get("push_on_hit",false) or (encounter=="storm_mate" and units[actor].kind=="boss" and attack.get("kind","")=="heavy")) and grade<2 and not h.guard and cover.id<0:
		push=push_destination(actor,target,int(attack.get("push_steps",1)))
	var pull:=Vector2i(-1,-1)
	if attack.get("pull_on_hit",false) and grade<2 and not h.guard and cover.id<0 and damage>0 and distance(units[actor].cell,h.cell)<=3 and clear_line(units[actor].cell,h.cell,actor): pull=hook_destination(actor,target)
	return {"pull":pull,"order_bonus":order_bonus(actor),"raw_damage":raw_damage,"raw_posture":raw_posture,"resistance_percent":resistance.percent,"push":push,"side":side,"damage":damage,"posture":po,"counter":not attack.get("no_counter",false) and grade==2 and side=="Frente" and distance(h.cell,units[actor].cell)==1 and units[actor].hp>0,"cover":cover,"qi_loss":drain}

func enemy_healing_power(actor: int) -> int:
	return roundi(90.0*maxf(1.0,float(units[actor].get("region_power",units[actor].get("challenge_power",1.0)))))

func resolve_enemy(plan: Dictionary, grades: Dictionary) -> Dictionary:
	if plan.get("kind","")=="sequence": return resolve_sequence(plan,grades)
	if plan.get("kind","")=="volley": return resolve_volley(plan,grades)
	var u:=current()
	var result: Dictionary={"actor":current_id,"skill":-5 if plan.kind=="heal" else (-2 if plan.kind=="heavy" else (-3 if plan.kind=="ranged" else (-4 if plan.kind in ["brace","charge","signal","recover","reclaim"] else -1))),"hits":[],"cells":plan.get("cells",[]),"text":u.name+" · "+plan.get("name","Espera"),"quality":0}
	if u.team!=1 or u.hp<=0 or u.acted or u.stun>0 or u.broken:
		result.error="Este adversário não pode agir."
		return result
	u.acted=true
	if plan.kind=="reposition": return result
	if plan.get("lance_throw",false): u.lance_cell=plan.lance_end; u.guard=false
	if plan.get("lance_return",false): u.lance_cell=Vector2i(-1,-1); u.exposed=true
	if plan.kind=="recover":
		u.exposed=true; u.guard=false
		result.text=u.name+" · "+str(plan.get("name","Recuperar o fôlego"))+" · postura exposta"
		return result
	if plan.kind=="reclaim":
		if BossTechniques.key(self,u)!="ceuta_depot": return result
		for i in boss_loot.size():
			var bag: Dictionary=boss_loot[i]
			if int(bag.owner)==current_id and distance(u.cell,bag.cell)<=1:
				u.contract_coins=mini(6,int(u.contract_coins)+int(bag.coins)); boss_loot.remove_at(i)
				result.text="Bolsa recuperada · os contratos voltam a ter financiamento"
				break
		return result
	if plan.kind=="signal":
		if u.kind!="signaller": return result
		if u.signal_pending and u.cell==u.signal_origin:
			for ally in enemies:
				if ally.id!=current_id and Identity.active(ally) and distance(u.cell,ally.cell)<=3 and clear_line(u.cell,ally.cell,current_id):
					ally.order_source=current_id; ally.order_until=u.turns
			u.signal_pending=false
			result.text="Ordem activa · +6 poder no próximo ataque dos aliados próximos."
		else:
			u.signal_pending=true; u.signal_origin=u.cell
			result.text="Sinal preparado · interrompe ou desloca o sinaleiro antes do próximo turno."
		return result
	if plan.kind=="heal":
		var patient: int=int(plan.get("patient",-1))
		if u.kind!="medic" or patient<0 or patient>=units.size(): return result
		var ally: Dictionary=units[patient]
		if ally.team!=1 or ally.hp<=0 or patient==current_id or distance(u.cell,ally.cell)>3 or not clear_line(u.cell,ally.cell,current_id): return result
		var restored: int=mini(enemy_healing_power(current_id),ally.max_hp-ally.hp)
		ally.hp+=restored
		ally.bleed=0
		append_recovery(result.hits,patient,restored,"hp")
		result.text+=" · %s recupera %d vida"%[ally.name,restored]
		return result
	if plan.kind=="flee":
		if objective.get("kind","")!="capture" or current_id!=int(objective.target_id): return result
		if plan.get("escape_now",false) and u.cell==objective.exit and plan.get("path",[]).is_empty():
			objective.escaped=true
			result.text=objective.get("escaped_text","O alvo escapou.")
		else: result.text=objective.get("near_exit_text","O alvo alcança a saída. Impede-o antes do próximo turno!") if u.cell==objective.exit else objective.get("move_name","O alvo corre para a saída.")
		return result
	if plan.kind=="burn":
		if objective.get("kind","")!="protect" or current_id!=int(objective.actor_id) or distance(u.cell,objective.asset_cell)!=1: return result
		var damage:=int(objective.get("damage",34))
		objective.hp=maxi(0,int(objective.hp)-damage)
		result.text=str(objective.get("damage_text","Integridade %d/%d"))%[objective.hp,objective.max_hp]
		return result
	if plan.kind=="asset_attack":
		if objective.get("kind","")!="escort" or not u.get("siege_actor",false) or distance(u.cell,objective.asset_cell)!=1: return result
		objective.hp=maxi(0,int(objective.hp)-int(plan.get("power",30)))
		result.text="%s · integridade da barca %d/%d"%[u.name,objective.hp,objective.max_hp]
		return result
	if plan.kind=="charge":
		u.charging=true; u.warning=plan.cells.duplicate()
		u.warning_power=plan.get("power",38+u.boss_phase*2)
		u.warning_push_steps=int(plan.get("push_steps",1)); u.phase_pending=false
		u.followup=plan.get("followup",[]).duplicate(); u.warning_name=plan.name; u.next_name=plan.get("next_name","")
		result.text="Sai do vermelho!"+(" Depois, sai do âmbar: segundo golpe anunciado." if not u.followup.is_empty() else (" A pólvora explode no próximo turno." if u.kind=="bombard" else " O chefe ataca no próximo turno."))
		return result
	if plan.kind=="brace":
		u.guard=true; u.riposte=u.kind=="duelist"; u.face=suggested_facing(current_id)
		return result
	if plan.kind=="heavy":
		u.warning=u.followup.duplicate(); u.followup.clear(); u.charging=not u.warning.is_empty(); u.warning_name=u.next_name
	for target in plan.get("targets",[]):
		if units[target].hp<=0: continue
		var h: Dictionary=units[target]
		var grade: int=grades.get(target,0)
		var preview:=defense_preview(current_id,target,plan,grade)
		var bleeds: bool=plan.get("bleed",false) and grade<2 and not h.guard and preview.damage>0 and preview.cover.id<0
		var guarded_before: bool=h.guard
		h.guard=false
		var hit:=apply_intercepted_hit(target,preview.raw_damage,preview.raw_posture,result.hits,preview.side)
		if preview.pull!=Vector2i(-1,-1) and preview.pull!=h.cell and h.hp>0 and passable(preview.pull,target):
			h.cell=preview.pull; hit.pulled=true
		if preview.push!=Vector2i(-1,-1) and h.hp>0 and passable(preview.push,target):
			h.cell=preview.push; hit.pushed=true
			result.text+=" · "+h.name+": empurrado"
		if preview.qi_loss>0:
			h.qi=maxi(0,h.qi-preview.qi_loss)
			result.text+=" · %s perde %d alento"%[h.name,preview.qi_loss]
		if bleeds and h.hp>0: h.bleed=mini(4,maxi(h.bleed,2)+int(plan.get("bleed_add",0)))
		if plan.get("root_on_hit",false) and not guarded_before and grade==0 and preview.damage>0 and preview.cover.id<0 and h.hp>0:
			h.rooted_until=h.turns+1; result.text+=" · amarrado: −2 movimento no próximo turno"
		hit.bleed=bleeds
		if grade==2:
			perfects+=1; h.qi=mini(h.max_qi,h.qi+1)
			if has_passive(target,"parry"): recover_passive(target,"parry","posture",6)
		var stance: Dictionary=h.get("counter_ready",{})
		var stance_counter: bool=not plan.get("no_counter",false) and not stance.is_empty() and preview.side=="Frente" and distance(h.cell,u.cell)<=int(stance.get("range",1)) and (not stance.get("perfect_only",false) or grade==2)
		if (preview.counter or stance_counter) and h.hp>0 and u.hp>0:
			var riposte:=13+level*2
			var riposte_posture:=15
			if stance_counter:
				riposte=int(stance.get("power",riposte))
				riposte_posture=int(stance.get("posture",riposte_posture))
				h.counter_ready={}
			# Both ordinary parries and prepared counters benefit from the weapon.
			riposte=maxi(1,riposte+int(h.get("attack",0)))
			riposte_posture=maxi(1,riposte_posture+int(h.get("break_power",0)))
			if has_passive(target,"iron_answer"):
				riposte_posture+=6
				recover_passive(target,"iron_answer","qi",1)
				if not u.broken: record_passive(target,"iron_answer",{"posture_base":6},current_id)
			if has_passive(target,"mist_return") and h.kind=="ines": recover_passive(target,"mist_return","qi",1)
			var counter_break:=hurt(current_id,riposte,riposte_posture)
			counters+=1
			result.hits.append({"id":current_id,"damage":riposte,"posture":riposte_posture,"breaks":counter_break,"side":"Contra-ataque","stun":false,"bleed":false})
			trigger_passives(target,"counter")
			if counter_break: trigger_passives(target,"break")
			if u.hp<=0 and not u.get("withdrawn",false): trigger_passives(target,"kill")
	if not plan.get("targets",[]).is_empty(): u.order_source=-1; u.order_until=-1
	if plan.has("target"): u.face=direction_index(Vector2i(units[plan.target].cell)-Vector2i(u.cell))
	u.taunted_by=-1
	u.bounty_target=-1; u.bounty_power=0
	if plan.kind in ["attack","ranged"]:
		BossTechniques.after_attack(self,current_id,plan)
		if u.has("contract_note"):
			result.text+=" · "+u.contract_note; u.erase("contract_note")
	if (u.kind=="defender" or plan.get("guard_after",false)) and plan.kind=="attack" and u.hp>0 and not u.broken:
		u.guard=true; result.text+=" · guarda frontal recomposta"
	if plan.get("riposte_after",false) and u.hp>0 and not u.broken: u.riposte=true
	if plan.kind=="attack" and u.get("signature_pending",false): u.signature_pending=false
	if plan.get("retreat_after",false) and not plan.get("sequence_step",false) and u.hp>0 and not u.broken and u.stun==0:
		var recede:=BossTechniques.retreat_plan(self,current_id,mini(2,u.moves))
		var origin: Vector2i=u.cell
		var path:=move_to(recede.destination)
		if not path.is_empty():
			result.reposition_path=[origin]; result.reposition_path.append_array(path)
	if Identity.is_boss(u) and plan.kind=="heavy" and not u.charging and u.hp>0 and not u.broken:
		u.exposed=true; u.guard=false; u.charge_ready_turn=u.turns+2
		if u.kind=="boss": u.signature_pending=true
		result.text+=" · Chefe exposto: +35% de dano de postura até ao próximo turno"
	return result

## A sequence owns one boss action; each leg has its own route, timing and impact.
func begin_sequence(attack: Dictionary) -> bool:
	if not sequence.is_empty() or current_id<0: return false
	var u:=current()
	if u.team!=1 or u.hp<=0 or u.acted or u.broken or u.stun>0 or BossTechniques.key(self,u).is_empty() or attack.get("steps",[]).is_empty(): return false
	sequence={"owner":current_id,"index":0,"steps":attack.steps.duplicate(true),"name":attack.name,"prepared":{},"moved":false}
	u.acted=true; u.phase_pending=false; u.signature_pending=false
	if BossTechniques.key(self,u)=="ceuta_depot" and u.contract_coins>0: u.contract_coins-=1
	return true

func prepare_sequence_step() -> Dictionary:
	if sequence.is_empty(): return {}
	var owner_unit: Dictionary=units[int(sequence.owner)]
	if owner_unit.hp<=0 or owner_unit.broken or owner_unit.stun>0:
		finish_sequence(); return {}
	while int(sequence.index)<sequence.steps.size():
		var template: Dictionary=sequence.steps[sequence.index]
		var p: Dictionary=BossTechniques.plan_step(self,template)
		if p.kind=="wait": sequence.index+=1; continue
		current_id=int(template.actor)
		sequence.prepared=p; sequence.moved=false
		return p.duplicate(true)
	finish_sequence()
	return {}

func move_sequence_step() -> Array[Vector2i]:
	var path: Array[Vector2i]=[]
	if sequence.is_empty() or sequence.prepared.is_empty() or sequence.moved: return path
	var p: Dictionary=sequence.prepared
	var at: Vector2i=current().cell
	for cell in p.path:
		if distance(at,cell)!=1 or not passable(cell,current_id):
			p.kind="approach"; p.targets=[]; p.cells=[]; sequence.moved=true
			return path
		at=cell
	path.assign(p.path)
	if not path.is_empty(): current().face=direction_index(at-current().cell); current().cell=at
	sequence.moved=true
	return path

func resolve_sequence_step(grades: Dictionary) -> Dictionary:
	if sequence.is_empty() or sequence.prepared.is_empty(): return {"error":"Não há golpe da sequência preparado.","hits":[]}
	var p: Dictionary=sequence.prepared
	if not sequence.moved: move_sequence_step()
	var actor: int=int(p.actor)
	current_id=actor
	var acted_before: bool=current().acted
	current().acted=false
	var data: Dictionary
	if p.kind=="approach":
		data={"actor":actor,"skill":-1,"hits":[],"cells":[],"text":current().name+" · caminho bloqueado: não alcança o alvo"}
	else:
		data=resolve_enemy(p,grades)
	current().acted=acted_before if actor!=int(sequence.owner) else true
	for field in ["rope","bounce_cell","projectile_origin","lance_throw","lance_return","lance_end","unarmed"]:
		if p.has(field): data[field]=p[field]
	sequence.index+=1; sequence.prepared={}
	return data

func finish_sequence() -> void:
	if sequence.is_empty(): return
	var owner: int=int(sequence.owner)
	current_id=owner
	var u:=current()
	u.phase_pending=false; u.technique_ready=u.turns+3; u.exposed=u.hp>0 and not u.broken; u.guard=false; u.strain=0
	if BossTechniques.key(self,u) in ["cove_trial","lisbon_avelar"]: u.fatigued_until=u.turns+1
	if BossTechniques.key(self,u) in ["refuge_trial","final_esteban"]: u.technique_ready=u.turns+2
	if u.name=="Yusuf ibn Rami" and sequence.name=="Último vendaval": u.last_stand_used=true
	sequence.clear()
	if objective.get("kind","")=="duel_rescue" and u.name=="Yusuf ibn Rami" and u.last_stand_used: hurt(owner,0,0)

func resolve_sequence(attack: Dictionary, grades: Dictionary) -> Dictionary:
	var data: Dictionary={"actor":current_id,"skill":-2,"hits":[],"cells":[],"text":current().name+" · "+str(attack.get("name",""))}
	if not begin_sequence(attack): data.error="Este adversário não pode iniciar a técnica."; return data
	while not sequence.is_empty():
		var p:=prepare_sequence_step()
		if p.is_empty(): break
		var index: int=int(sequence.index)
		move_sequence_step()
		var step_grades: Dictionary={int(p.target):int(grades.get("step_%d"%index,grades.get(int(p.target),0)))}
		for shot in p.get("marks",[]).size(): step_grades["shot_%d"%shot]=int(grades.get("step_%d_shot_%d"%[index,shot],grades.get("shot_%d"%shot,step_grades[int(p.target)])))
		var leg:=resolve_sequence_step(step_grades)
		data.hits.append_array(leg.get("hits",[]))
	data.text+=" · recuperação: Exposto"
	return data

func loot_reason() -> String:
	if current_id<0 or current().team!=0 or current().quick_used: return "Precisas de uma acção rápida livre."
	for bag in boss_loot:
		if distance(current().cell,bag.cell)<=1 and clear_line(current().cell,bag.cell,current_id): return ""
	return "Aproxima-te da bolsa até 1 casa."

func collect_boss_loot() -> Dictionary:
	var reason:=loot_reason()
	if not reason.is_empty(): return {"error":reason}
	for i in boss_loot.size():
		var bag: Dictionary=boss_loot[i]
		if distance(current().cell,bag.cell)<=1 and clear_line(current().cell,bag.cell,current_id):
			current().quick_used=true; boss_loot.remove_at(i)
			return {"text":"Bolsa recolhida · %d moedas negadas aos mercenários"%int(bag.coins)}
	return {"error":"A bolsa já foi recolhida."}

## Every shot owns a grade and hit; presentation and headless simulations use the same rule.
func resolve_volley_shot(attack: Dictionary, index: int, grade: int) -> Dictionary:
	var u:=current()
	var marks: Array=attack.get("marks",[])
	if index<0 or index>=marks.size() or u.team!=1 or u.hp<=0 or u.broken or u.stun>0:
		return {"actor":current_id,"skill":-3,"hits":[],"cells":[],"text":"Rajada interrompida."}
	var shot: Dictionary=attack.duplicate(true)
	shot.kind="ranged" if not attack.get("fencing",false) and not attack.has("mirror_hero") else "attack"
	shot.name=attack.name+" · %d/%d"%[index+1,marks.size()]
	shot.sequence_step=true; shot.no_counter=true; shot.defense_beats=1
	shot.bleed=attack.get("bleed",false) or (attack.get("bleed_last",false) and index==marks.size()-1)
	shot.bleed_add=1 if BossTechniques.key(self,u)=="lisbon_avelar" else 0
	shot.targets=[]
	for target in attack.get("targets",[]):
		if units[target].hp>0 and distance(u.cell,units[target].cell)<=int(attack.get("reach",5)) and clear_line(u.cell,units[target].cell,current_id): shot.targets.append(target)
	u.acted=false
	var data:=resolve_enemy(shot,{int(attack.target):clampi(grade,0,2)})
	u.acted=true
	data.shot=index
	return data

func resolve_volley(attack: Dictionary, grades: Dictionary) -> Dictionary:
	var data: Dictionary={"actor":current_id,"skill":-3,"hits":[],"cells":attack.get("cells",[]),"text":current().name+" · "+attack.name}
	if current().acted: data.error="Este adversário já agiu."; return data
	for i in attack.get("marks",[]).size():
		var shot:=resolve_volley_shot(attack,i,int(grades.get("shot_%d"%i,grades.get(int(attack.target),0))))
		data.hits.append_array(shot.get("hits",[]))
	return data

func complete_volley_step() -> void:
	if sequence.is_empty() or sequence.prepared.get("kind","")!="volley": return
	sequence.index+=1; sequence.prepared={}

