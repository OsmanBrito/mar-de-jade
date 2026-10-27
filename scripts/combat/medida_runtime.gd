extends RefCounted
const Book=preload("res://scripts/chapter/order_techniques.gd")
const Dev=preload("res://scripts/chapter/character_development.gd")
const STEP=["ES08","ES14","PU10"]
const GUARDS={"LA08":[.30,1,"advance"],"PU08":[.30,1,"contact"],"ES13":[.25,1,"ranged"],"MC13":[.30,1,"physical"],"ES57":[.35,2,"three"],"MC57":[.35,2,"three"]}
const WATCH={"LA01":[2,1],"LA11":[2,1],"LA57":[3,2],"FO11":[3,1],"FO57":[4,2]}
static func row(action: int) -> Dictionary: return Book.rows().get(Book.id_for(action),{})
static func handles(action: int) -> bool: return not row(action).is_empty()
static func definition(m,action: int,base: Dictionary) -> Dictionary:
	var r: Dictionary=row(action); var d: Dictionary=base.duplicate(true)
	var grade: int=Dev.grade(m.combat_progress(),r.id)
	d.content_id=r.id; d.name=r.name; d.cost=r.cost; d.level=grade; d.rarity="Comum"; d.rarity_color="e6cb8d"; d.cooldown=0
	d.description=r.effect+" "+r.limit+" Grau "+["I","II","III"][grade-1]+"."
	d.shape="single"; d.range=4 if r.style=="FO" else 2 if r.style=="LA" else 1
	d.effect="ranged" if r.style=="FO" else "cut"; d.uses_opening=false; d.posture=18
	d.power=0
	if r.factor>0:
		d.power=roundi(r.factor*Dev.power(m.combat_progress(),r.style,"hero",{},r.attributes)*(1.0+.05*(grade-1)))+int(m.equipment_bonus.get("attack",0))
	elif not GUARDS.has(r.id): d.cost=maxi(1,int(d.cost)-(grade-1))
	if m.passive_active("GE22") and not m.technique_evaluated and m.previous_action==0 and m.previous_action_turn==m.current().turns-1:
		d.cost=maxi(maxi(1,int(r.cost)-2),int(d.cost)-1)
	if GUARDS.has(r.id) or WATCH.has(r.id): d.shape="self"; d.range=0; d.effect="brace"
	if r.id in ["LA13","PU13"]: d.shape="ally"; d.range=1; d.effect="cover"
	if r.id in ["MC10","MC11"]: d.range=1
	if r.id=="LA14": d.range=3
	if r.id=="LA56": d.range=3
	if r.id=="FO12" or r.id=="FO13": d.range=3
	if r.id in ["MC14","MC12"]: d.range=2
	if r.id in ["PU15","PU57"]: d.range=3
	return d
static func trajectory(m,origin: Vector2i,end: Vector2i,pierce: bool) -> bool:
	if not pierce: return m.clear_line(origin,end,0)
	if not m.clear_line(origin,end,0,true): return false
	var steps: int=maxi(absi(end.x-origin.x),absi(end.y-origin.y))
	for i in range(1,steps):
		var cell: Vector2i=Vector2i(Vector2(origin).lerp(Vector2(end),float(i)/steps).round())
		var unit: int=m.unit_at(cell)
		if unit>=0 and m.units[unit].team==0: return false
	return true
static func cells(m,action: int,aim: Vector2i) -> Array[Vector2i]:
	var r: Dictionary=row(action); var d: Dictionary=m.skill_def(0,action)
	var result: Array[Vector2i]=[]; var origin: Vector2i=m.units[0].cell
	if d.shape=="self": result.append(origin); return result
	if d.shape=="ally": result.append(aim); return result
	if not m.inside(aim) or m.distance(origin,aim)>int(d.range) or not trajectory(m,origin,aim,r.id in ["MC12","LA14"]): return result
	if m.obstacles.has(aim): return result
	result.append(aim)
	var targets: Array=[]
	for enemy in m.units:
		if enemy.team==1 and enemy.hp>0 and enemy.cell!=aim and m.distance(origin,enemy.cell)<=int(d.range) and trajectory(m,origin,enemy.cell,r.id in ["MC12","LA14"]): targets.append(enemy)
	targets.sort_custom(func(a,b): return int(a.id)<int(b.id))
	for enemy in targets:
		var delta: Vector2i=enemy.cell-origin; var first: Vector2i=aim-origin
		var include:=false
		match r.id:
			"ES12": include=m.distance(origin,aim)==1 and m.distance(origin,enemy.cell)==1 and Vector2(first).dot(Vector2(delta))==0
			"PU14": include=m.distance(origin,aim)==1 and m.distance(origin,enemy.cell)==1 and Vector2(first).dot(Vector2(delta))<0
			"MC12","LA14": include=first.x*delta.y==first.y*delta.x and Vector2(first).dot(Vector2(delta))>0
			"FO12": include=true
			"LA06","MC14": include=Vector2(m.DIRECTIONS[m.direction_index(first)]).dot(Vector2(delta))>0
		if include and result.size()<(3 if r.id=="LA06" else 2): result.append(enemy.cell)
	return result
static func escort(m,ally: int) -> Array[Vector2i]:
	if ally<=0 or ally>=m.units.size() or m.units[ally].hp<=0: return []
	var origin: Vector2i=m.units[0].cell; var partner: Vector2i=m.units[ally].cell
	for direction in m.DIRECTIONS:
		var a: Vector2i=origin+direction; var b: Vector2i=partner+direction
		if m.passable(a,0) and m.passable(b,ally) and m.clear_line(origin,a,0) and m.clear_line(partner,b,ally): return [a,b]
	return []
static func landing(m,id: String,aim: Vector2i) -> Vector2i:
	var origin: Vector2i=m.units[0].cell
	if STEP.has(id):
		if id=="ES14":
			var back: Vector2i=-m.DIRECTIONS[m.direction_index(aim-origin)]
			var destination:=origin
			for i in mini(2,int(m.current().moves)):
				if m.segment_open(destination,destination+back): destination+=back
			return destination if destination!=origin else Vector2i(-1,-1)
		if m.current().moves<1: return Vector2i(-1,-1)
		return m.Firearm.side_step(m,0,aim)
	if id in ["PU15","PU57"]:
		var best: Vector2i=Vector2i(-1,-1); var length:=999
		for dir in m.DIRECTIONS:
			var end: Vector2i=aim+dir
			if not m.passable(end,0): continue
			var path: Array=m.path_to(0,end)
			if path.size()>0 and path.size()<=mini(2,int(m.current().moves)) and path.size()<length: best=end; length=path.size()
		if m.distance(origin,aim)==1: return origin
		return best
	return Vector2i(-1,-1)
static func watch_exits(m) -> Array:
	var result: Array=[]
	var direction: Vector2i=m.DIRECTIONS[int(m.units[0].face)]
	for cover in m.low_cover:
		var exit: Vector2i=cover+direction
		if m.inside(exit) and not m.obstacles.has(exit) and not m.low_cover.has(exit) and m.distance(m.units[0].cell,exit)<=4 and m.clear_line(m.units[0].cell,exit,0,true):
			result.append({"from":cover,"to":exit})
		if result.size()==2: break
	return result
static func reason(m,action: int,aim: Vector2i) -> String:
	var r: Dictionary=row(action); var d: Dictionary=m.skill_def(0,action)
	var available: String=m.availability_reason(action)
	if not available.is_empty(): return available
	if r.id=="FO57" and watch_exits(m).is_empty(): return "Escolhe uma posição com uma saída de cobertura baixa ao alcance da mira."
	if d.shape=="self": return ""
	if d.shape=="ally":
		var ally: int=m.unit_at(aim)
		if ally<=0 or m.units[ally].team!=0 or m.units[ally].hp<=0 or m.distance(m.current().cell,aim)!=1: return "Escolhe outro aliado consciente em contacto."
		if m.current().moves<1 or escort(m,ally).is_empty(): return "A escolta precisa de duas posições livres e um ponto de movimento."
		return ""
	if m.targets(0,cells(m,action,aim)).is_empty(): return "Escolhe um adversário ao alcance, com linha livre."
	if r.id=="MC12" and m.distance(m.current().cell,aim)!=1: return "O primeiro alvo do Corte da Trave precisa estar em contacto."
	if r.id in ["LA12","LA15"] and m.distance(m.current().cell,aim)!=2: return "Esta técnica exige a medida de duas casas."
	if STEP.has(r.id) or r.id in ["PU15","PU57"]:
		if landing(m,r.id,aim)==Vector2i(-1,-1): return "Não há trajeto livre dentro do orçamento de movimento."
	return ""
static func is_contact(attack: Dictionary) -> bool: return attack.get("kind","")!="ranged" and not attack.get("projection",false)
static func predict(m,target: int,action: int,quality: int,aim: Vector2i) -> Dictionary:
	var r: Dictionary=row(action); var d: Dictionary=m.skill_def(0,action)
	var u: Dictionary=m.units[0]; var e: Dictionary=m.units[target]
	var origin: Vector2i=u.cell
	if r.id in ["PU15","PU57"]:
		var arrival: Vector2i=landing(m,r.id,aim)
		if arrival!=Vector2i(-1,-1): origin=arrival
	var side: String=m.flank(0,target,origin)
	var power: float=d.power
	if r.id=="ES01" and e.get("recovery_announced",false): power*=1.2
	if r.id=="ES06" and u.get("medida_defended",-1)==target and u.get("medida_defended_until",-1)>=u.turns: power*=1.8/1.3
	if r.id=="ES56" and m.medida_state.get("sequence_target",-1)==target and m.medida_state.get("sequence_count",0)>=2: power*=1.2
	if r.id=="PU06" and side!="Frente": power*=1.9/1.6
	if r.id in ["PU15","PU57"] and avoids_warning(m,r.id,aim): power*=1.2 if r.id=="PU15" else 1.0
	if r.style=="MC" and u.get("medida_weight_until",-1)>=int(u.turns): power*=1.15
	if r.style=="FO" and m.medida_state.get("mark_target",-1)==target and m.medida_state.get("mark_cell",Vector2i(-1,-1))==e.cell and m.medida_state.get("mark_until",-1)>=u.turns: power*=1.35
	var armor: float=maxi(0,int(e.get("defense",0))); var ignore:=0.0
	if r.id=="MC01": ignore=.25
	if r.id=="PU06": ignore=.30
	if r.id=="LA56" and m.distance(origin,e.cell)==2: ignore=.20
	if r.id=="FO56" and m.distance(origin,e.cell)==3: ignore=.25
	if r.id=="PU56" and m.medida_state.get("focus","armor")=="armor": ignore=.25
	if r.id=="FO15" and m.medida_state.get("blocked_target",-1)==target: ignore=.25
	var guard:=.30 if e.guard and side=="Frente" else 0.0
	if quality>=1:
		if r.id=="ES10" and e.kind=="boss": guard*=.8
		if r.id=="MC12" and e.cell!=aim: guard*=.8
		if r.id in ["LA12","PU12"] and side!="Frente" and e.guard: guard=(.30*(.8 if r.id=="LA12" else .75))
	var cover_penalty: float=.20 if (u.get("partial_cover",false) or m.low_cover.has(u.cell)) and r.style=="FO" else 0.0
	if r.id=="FO14": cover_penalty*=.5
	if r.id!="LA14" and (e.get("partial_cover",false) or m.low_cover.has(e.cell)): cover_penalty+=.20
	var damage: int=maxi(0,roundi((power*[.9,1.15,1.4][clampi(quality,0,2)]*(1.35 if side=="Costas" else 1.15 if side=="Flanco" else 1.0)-armor*(1.0-ignore))*(1.0-guard)*(1.0-cover_penalty)))
	return {"damage":damage,"posture":roundi(d.posture*[.9,1.15,1.4][clampi(quality,0,2)]),"side":side,"breaks":not e.broken and e.posture<=d.posture,"reply":0,"id":target,"armor_ignored":ignore,"guard_reduction":guard,"movement_destination":landing(m,r.id,aim),"passive_bonuses":{},"lethal":damage>=e.hp,"stun":false,"bleed":false,"applies_exposed":false,"consumes_bleed":false,"combo":false,"opening":false,"firm":false,"anchored":false,"exposed":false,"rose_veil":false,"shielded":false,"ward":false,"prism":false,"read":false,"redirect":-1,"last_stand":false}
static func avoids_warning(m,id: String,aim: Vector2i) -> bool:
	var destination: Vector2i=landing(m,id,aim)
	if destination==Vector2i(-1,-1): return false
	var path: Array=m.path_to(0,destination)
	for enemy in m.enemies:
		var warning: Array=enemy.get("warning",[])
		if warning.is_empty(): continue
		if warning.has(m.units[0].cell) and not warning.has(destination) and not path.any(func(cell): return warning.has(cell)): return true
	return false
static func guard(m,id: String,owner: int,percent: float,count: int,kind: String) -> void:
	m.medida_state["guard_"+str(owner)]={"id":id,"percent":percent,"remaining":count,"kind":kind,"face":m.units[owner].face,"expires":int(m.units[0].turns)+1}
static func perform(m,action: int,aim: Vector2i,quality: int) -> Dictionary:
	var error: String=reason(m,action,aim)
	if not error.is_empty(): return {"error":error}
	var r: Dictionary=row(action); var d: Dictionary=m.skill_def(0,action); var u: Dictionary=m.units[0]
	var result: Dictionary={"actor":0,"skill":action,"hits":[],"cells":cells(m,action,aim),"text":r.name,"quality":quality}
	var avoided: bool=avoids_warning(m,r.id,aim) if r.id in ["PU15","PU57"] else false
	var initial: Vector2i=u.cell; var arrival: Vector2i=landing(m,r.id,aim)
	var guard_before: Dictionary={}
	for target in m.targets(0,result.cells): guard_before[target]=bool(m.units[target].guard)
	var planned_hits: Array=[]
	if d.shape not in ["self","ally"]:
		for target in m.targets(0,result.cells): planned_hits.append(predict(m,target,action,quality,aim))
	u.qi-=int(d.cost); u.acted=true; m.technique_used=true; m.technique_evaluated=true
	if r.id in ["PU15","PU57"] and arrival!=initial:
		var path: Array=m.path_to(0,arrival); u.moves-=path.size(); u.cell=arrival; m.firearm_moved=true; m.moved_in_battle=true
		result.movement_origin=initial; result.movement_destination=arrival
	if GUARDS.has(r.id):
		var g: Array=GUARDS[r.id]; var rank: int=Dev.grade(m.combat_progress(),r.id)
		guard(m,r.id,0,float(g[0])+[0.0,.03,.05][rank-1],g[1],g[2]); u.guard=false
	if WATCH.has(r.id):
		m.medida_state.watch={"id":r.id,"action":action,"face":u.face,"origin":u.cell,"range":WATCH[r.id][0],"remaining":WATCH[r.id][1],"hit":[],"expires":int(u.turns)+1,"power":int(d.power),"exits":watch_exits(m) if r.id=="FO57" else [],"used_exits":[]}
	if r.id in ["LA13","PU13"]:
		var ally: int=m.unit_at(aim); var positions: Array[Vector2i]=escort(m,ally)
		u.cell=positions[0]; m.units[ally].cell=positions[1]; u.moves-=1; m.firearm_moved=true; m.moved_in_battle=true
		guard(m,r.id,ally,.15 if r.id=="LA13" else .20,1,"physical" if r.id=="LA13" else "contact_any")
		result.movement_origin=initial; result.movement_destination=u.cell; result.cells=positions
	if d.shape not in ["self","ally"]:
		# Compute every hit before mutating any target, preserving a single timing and prediction.
		result.hits=planned_hits
		for hit in result.hits:
			var e: Dictionary=m.units[int(hit.id)]; var had_guard: bool=guard_before.get(hit.id,false)
			m.hurt(hit.id,hit.damage,hit.posture)
			if hit.damage>0:
				if quality>=1:
					match r.id:
						"ES10":
							if e.kind!="boss": e.guard=false
						"ES11":
							if (e.get("advance_response",false) or e.get("counter_on_advance",false)) and e.get("response_vulnerable",true): e.riposte=false; e.counter_ready={}; e.advance_response=false
						"PU01":
							if e.kind!="boss" and not e.get("energy_preparation",false) and e.get("preparation_interruptible",true): e.counter_ready={}; e.charging=false; e.warning=[]
						"MC07": e.medida_no_charge=true
						"ES12":
							if e.cell!=aim: weaken(e,.10)
						"MC10","PU11":
							if (r.id=="PU11" or had_guard) and e.kind not in ["archer"]: disarm(e)
						"PU10": e.medida_slow=1
						"FO13":
							if m.heroes.any(func(h): return h.id!=0 and h.hp>0 and m.distance(u.cell,h.cell)==1 and e.get("warning",[]).has(h.cell)): weaken(e,.15)
						"ES15":
							if u.has("offensive_mark"): u.erase("offensive_mark")
							else: u.exposed=false
				if r.id=="MC11" and not m.firearm_moved and initial==u.turn_origin: e.medida_slow=1
				if r.id=="LA10" or r.id=="LA06":
					if (quality>=1 or r.id=="LA06") and e.kind!="boss":
						var push: Vector2i=m.push_destination(0,hit.id,1)
						if push!=Vector2i(-1,-1): e.cell=push
				if r.id=="LA56" and m.distance(initial,e.cell)==1: weaken(e,.15)
				if r.id=="FO56" and m.distance(initial,e.cell)==2: weaken(e,.15)
				if r.id=="PU56" and m.medida_state.get("focus","armor")=="weaken": weaken(e,.15)
		if result.hits.any(func(h): return h.damage>0): m._record_development_use(0,action)
		if r.style=="MC": u.erase("medida_weight_until")
		if quality==2: u.qi=mini(int(u.max_qi),int(u.qi)+1)
		var target: int=m.unit_at(aim)
		if r.style=="FO": m.medida_state.blocked_target=target if result.hits.any(func(h): return h.get("damage",0)==0) else -1
		if r.id=="FO06": m.medida_state.mark_target=target; m.medida_state.mark_cell=aim; m.medida_state.mark_until=int(u.turns)+1
		elif r.style=="FO": m.medida_state.erase("mark_target")
		if r.id=="ES56": m.medida_state.sequence_count=0
		else:
			m.medida_state.sequence_count=int(m.medida_state.get("sequence_count",0))+1 if m.medida_state.get("sequence_target",-1)==target else 1
			m.medida_state.sequence_target=target
	if STEP.has(r.id):
		u.cell=arrival; u.moves-=m.distance(initial,arrival); result.movement_origin=initial; result.movement_destination=arrival; m.firearm_moved=true; m.moved_in_battle=true
	if r.id in ["MC06","MC14","MC56"]: m.medida_state.exposure={"percent":.20 if r.id=="MC06" else .15 if r.id=="MC14" else .25,"ranged":r.id=="MC14"}
	if r.id=="PU14": u.medida_anchor_steps=1
	if r.id=="MC15": u.medida_anchor_front=true
	if r.id in ["ES13","LA15","MC15","MC56"] or (r.id=="PU56" and m.medida_state.get("focus","armor")=="anchor"): u.medida_anchor=1
	if r.id in ["PU15","PU57"] and avoided:
		guard(m,r.id,0,.15 if r.id=="PU15" else .30,1,"contact_any")
		if r.id=="PU57":
			for enemy in m.enemies:
				if enemy.get("warning",[]).has(initial): m.medida_state.guard_0.source=enemy.id; break
	m.previous_action=action; m.previous_action_turn=u.turns
	return result
static func weaken(enemy: Dictionary,percent: float) -> void:
	enemy.medida_weaken=maxf(float(enemy.get("medida_weaken",0)),percent)
static func disarm(enemy: Dictionary) -> void:
	if not preload("res://scripts/combat/order_studies.gd").eligible_weapon(enemy): return
	if enemy.kind=="boss": enemy.order_weapon_weakened=true; return
	if int(enemy.turns)<int(enemy.get("order_disarm_immune_until",0)): return
	enemy.order_disarmed=true; enemy.order_disarm_immune_until=int(enemy.turns)+3
static func defense(m,actor: int,target: int,attack: Dictionary,result: Dictionary) -> Dictionary:
	var key: String="guard_"+str(target)
	if m.medida_state.has(key) and not attack.get("projection",false) and preload("res://scripts/combat/order_studies.gd").physical_attack(attack):
		var g: Dictionary=m.medida_state[key]; var incoming: int=m.direction_index(m.units[actor].cell-m.units[target].cell)
		var contact: bool=is_contact(attack)
		var eligible: bool=incoming==int(g.face)
		if g.kind=="three": eligible=incoming!=(int(g.face)+2)%4
		if g.kind=="contact": eligible=eligible and contact and m.distance(m.units[actor].cell,m.units[target].cell)==1
		if g.kind=="contact_any": eligible=contact and m.distance(m.units[actor].cell,m.units[target].cell)==1
		if g.has("source"): eligible=eligible and int(g.source)==actor
		if g.kind=="ranged": eligible=attack.get("kind","")=="ranged"
		if g.kind=="advance": eligible=eligible and contact and attack.get("path",[]).size()>0 and m.distance(m.units[actor].turn_origin,m.units[target].cell)>1
		if eligible and int(result.damage)>0:
			result.damage=roundi(int(result.damage)*(1.0-float(g.percent))); result.medida_guard=key
	if target==0 and m.medida_state.has("exposure"):
		var exposure: Dictionary=m.medida_state.exposure
		if not exposure.ranged or attack.get("kind","")=="ranged": result.damage=roundi(int(result.damage)*(1.0+float(exposure.percent))); result.medida_exposed=true
	return result
static func before_enemy(m,plan: Dictionary) -> Array:
	var hits: Array=[]
	if not m.medida_state.has("watch"): return hits
	var w: Dictionary=m.medida_state.watch; var enemy: Dictionary=m.current()
	if m.units[0].hp<=0 or m.units[0].cell!=w.origin: m.medida_state.erase("watch"); return hits
	if w.remaining<=0 or w.hit.has(enemy.id) or enemy.hp<=0: return hits
	var path: Array=plan.get("path",[])
	if path.is_empty(): return hits
	var qualifies:=false
	for cell in path:
		var delta: Vector2i=cell-w.origin; var dir: Vector2i=m.DIRECTIONS[int(w.face)]
		if w.id!="FO57" and (delta.x*dir.y!=delta.y*dir.x or Vector2(delta).dot(Vector2(dir))<=0 or m.distance(w.origin,cell)>int(w.range)): continue
		if not m.clear_line(w.origin,cell,enemy.id): continue
		if w.id=="FO11" and cell!=plan.get("destination",enemy.cell): continue
		if w.id=="LA11":
			var entry: Vector2i=enemy.turn_origin-w.origin
			if entry.x*dir.y==entry.y*dir.x: continue
		if w.id=="LA01" and m.distance(enemy.turn_origin,w.origin)<=int(w.range): continue
		if w.id=="FO57":
			var previous: Vector2i=enemy.turn_origin if path.find(cell)==0 else path[path.find(cell)-1]
			if not w.exits.any(func(exit): return exit.from==previous and exit.to==cell and not w.used_exits.has(cell)): continue
			w.used_exits.append(cell)
		qualifies=true; break
	if not qualifies: return hits
	if w.id=="LA11" and int(enemy.get("medida_slow",0))==0: enemy.medida_slow=1
	var damage: int=maxi(0,roundi(float(w.power)*(1.0 if w.hit.is_empty() else .5))-int(enemy.get("defense",0)))
	m.hurt(enemy.id,damage,12); w.remaining-=1; w.hit.append(enemy.id)
	hits.append({"id":enemy.id,"damage":damage,"posture":12,"side":"Vigia · "+str(w.id),"reply":0})
	m._record_development_use(0,w.action)
	return hits
static func after_enemy(m,plan: Dictionary,grades: Dictionary,previews: Dictionary) -> void:
	for target in previews:
		var preview: Dictionary=previews[target]
		if preview.has("medida_guard"):
			var key: String=preview.medida_guard
			if m.medida_state.has(key):
				var g: Dictionary=m.medida_state[key]; g.remaining-=1
				if g.id=="MC13": m.units[0].medida_weight_until=int(m.units[0].turns)+1
				m._record_development_use(0,Book.action(g.id))
				if g.remaining<=0: m.medida_state.erase(key)
		if plan.get("push_on_hit",false) and int(grades.get(target,0))<2:
			m.units[target].erase("medida_anchor"); m.units[target].erase("medida_anchor_steps"); m.units[target].erase("medida_anchor_front")
		if preview.get("medida_exposed",false): m.medida_state.erase("exposure")
	if plan.get("targets",[]).has(0) and int(grades.get(0,0))>=1:
		m.units[0].medida_defended=m.current_id; m.units[0].medida_defended_until=int(m.units[0].turns)+1
	if plan.get("kind","")=="recover": m.current().recovery_announced=true
	m.current().erase("medida_no_charge")
	m.current().erase("medida_weaken")
	m.current().erase("medida_slow")
static func turn(m) -> void:
	if m.current_id!=0:
		m.current().erase("recovery_announced")
		return
	for key in ["guard_0","guard_1","watch"]:
		if m.medida_state.has(key) and int(m.medida_state[key].expires)<=int(m.units[0].turns): m.medida_state.erase(key)
	m.medida_state.erase("exposure"); m.units[0].erase("medida_anchor"); m.units[0].erase("medida_anchor_steps"); m.units[0].erase("medida_anchor_front")

static func track(m,skill: int,aim: Vector2i) -> void:
	var target: int=m.unit_at(aim)
	if m.style=="ES" and target>=2:
		m.medida_state.sequence_count=int(m.medida_state.get("sequence_count",0))+1 if m.medida_state.get("sequence_target",-1)==target else 1
		m.medida_state.sequence_target=target
	else: m.medida_state.sequence_count=0
