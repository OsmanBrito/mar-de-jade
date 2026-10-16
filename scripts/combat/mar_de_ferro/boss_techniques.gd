extends RefCounted
## Authored boss mechanics. Planning stays read-only; effects live in the rules.
const DATA={
	"boss":["Tratado das três respostas","Varia as técnicas: Ferro lê golpes repetidos. A sequência termina com uma abertura."],
	"lisbon_avelar":["Cinco penas de sangue","Uma barra, cinco flechas no mesmo herói. Cada defesa conta; flechas que ferem causam Sangramento. Encurrala Avelar para impedir o recuo."],
	"stronghold":["Valsa da lâmina velada","Catarina finta e troca o ritmo. Reconhece técnicas repetidas de Inês; varia ataques e procura o flanco."],
	"cove_trial":["Peso de uma maré","Cada ataque acumula esforço e poder. Depois da descarga fica cansado: mais pressão de postura."],
	"vigia_guard":["Espinho lançado","A lança atravessa uma linha e fica cravada no campo. Rosa avança desarmado para a recuperar; sai da linha entre ele e a lança antes do retorno."],
	"ceuta_depot":["Dobro ou nada","Contratos finitos: caçada, interceptação e ataque de dois mercenários. Quebra o chefe e recolhe a bolsa para cortar contratos."],
	"coast_yusuf":["Cortar a retirada","O capitão afasta os heróis das famílias. Guarda, cobertura ou perfeito impedem o empurrão."],
	"storm_mate":["Travessia das amarras","O imediato puxa com a corda e atravessa o convés. Guarda ou perfeito impedem o puxão; castiga a aterragem."],
	"final_esteban":["Última ordem do almirante","Começa com salvas dos aliados e esgrima; a fase final encadeia seis cortes com fintas e pressão de guarda. Varia técnicas e castiga a recuperação."],
	"refuge_trial":["Contracanto da primeira maré","Devolve técnicas dos dois heróis numa barra que corre da direita para a esquerda. Repetições alimentam o reflexo: varia técnicas, flanqueia e quebra o véu."]
}
static func key(b, u: Dictionary) -> String:
	if u.name=="Yusuf ibn Rami": return "yusuf"
	if (u.kind=="boss" or u.name=="Rui de Avelar") and DATA.has(b.encounter): return b.encounter
	return ""
static func ready(u: Dictionary, turn: int) -> bool:
	return u.get("phase_pending",false) or turn>=int(u.get("technique_ready",2)) or (u.name=="Yusuf ibn Rami" and u.hp<=u.max_hp*0.35 and not u.get("last_stand_used",false))
static func title(b, u: Dictionary) -> String:
	if key(b,u)=="yusuf": return "Último vendaval" if u.hp<=u.max_hp*0.35 else "Dança das duas lâminas"
	return DATA.get(key(b,u),["",""])[0]
static func hint(b, u: Dictionary) -> String:
	if key(b,u)=="yusuf": return "Avança entre os dois heróis: 2 golpes, ou 4 com pouca vida. Perfeito bloqueia apenas esse golpe, sem parar a dança. Depois fica Exposto."
	var message: String=DATA.get(key(b,u),["",""])[1]
	match key(b,u):
		"ceuta_depot": message+=" Contratos: %d moedas."%int(u.get("contract_coins",6))
		"cove_trial": message+=" Esforço acumulado: %d/3."%int(u.get("strain",0))
		"vigia_guard": message+=" Lança: "+("cravada em %d,%d."%[u.lance_cell.x+1,u.lance_cell.y+1] if u.get("lance_cell",Vector2i(-1,-1))!=Vector2i(-1,-1) else "em mãos.")
		"refuge_trial":
			if b.rose_veil(u.id): message+=" Véu activo: −40% dano de vida; derrota as memórias ou aplica Exposto."
	return message
static func step(actor: int, target: int, name: String, power: int, posture: int, extra: Dictionary={}) -> Dictionary:
	var s={"actor":actor,"target":target,"name":name,"power":power,"posture":posture,"reach":1,"budget":5,"defense_beats":1,"no_counter":false}
	s.merge(extra,true); return s
static func special(b, actor: int, nearest: int) -> Dictionary:
	var u: Dictionary=b.units[actor]
	var k=key(b,u)
	var opponents: Array=b.living(0)
	var other: int=opponents[1] if opponents.size()>1 and opponents[0]==nearest else opponents[0]
	var steps: Array=[]
	match k:
		"yusuf":
			var count: int=4 if u.hp<=u.max_hp*0.35 else 2
			for i in count: steps.append(step(actor,nearest if i%2==0 else other,"Lâmina %d/%d"%[i+1,count],22,16,{"no_counter":true,"universal_parry":true,"budget":7,"bleed":i==count-1,"timing_curve":"accelerate" if i%2==0 else "brake"}))
		"boss":
			steps=[step(actor,nearest,"Medir o fio",23,14,{"timing_curve":"brake","prefer_front":true}),step(actor,nearest,"Desviar a guarda",19,24,{"guard_pressure":true,"prefer_front":true}),step(actor,nearest,"Resposta do mestre",30,22,{"timing_curve":"accelerate","prefer_front":true})]
		"lisbon_avelar":
			steps=[step(actor,nearest,"Cinco penas de sangue",15,8,{"budget":2,"ranged":true,"reach":5,"min_reach":2,"volley":true,"marks":[0.18,0.40,0.59,0.75,0.89],"stream_duration":3.4,"bleed":true,"no_counter":true}),step(actor,nearest,"Recuo do arqueiro",0,0,{"retreat":true,"budget":3})]
		"stronghold":
			steps=[step(actor,nearest,"Finta da torre",16,14,{"timing_curve":"brake","budget":6}),step(actor,other,"Reverso de Catarina",24,22,{"timing_curve":"accelerate","budget":6})]
			if u.boss_phase==3: steps.append(step(actor,nearest,"Último compasso",23,20,{"timing_curve":"brake","budget":6}))
		"cove_trial":
			steps=[step(actor,nearest,"Descarga do Lastro",32+int(u.get("strain",0))*4,30,{"reach":2,"push_on_hit":true,"push_steps":2,"defense_beats":2})]
		"vigia_guard":
			steps=[step(actor,nearest,"Arremesso do espinho",39,32,{"reach":5,"min_reach":2,"budget":3,"ranged":true,"lance_throw":true,"guard_pressure":true,"defense_beats":2}),step(actor,other,"Avanço sem haste",27,24,{"budget":4,"unarmed":true,"timing_curve":"brake"})]
		"ceuta_depot":
			var allies: Array=b.enemies.filter(func(e): return e.id!=actor and not e.get("objective_actor",false) and e.hp>0 and not e.broken and e.stun==0)
			if int(u.get("contract_coins",6))>0 and not allies.is_empty():
				steps.append(step(allies[0].id,nearest,"Mercenário · abrir a guarda",24,20,{"push_on_hit":true,"budget":5,"ranged":allies[0].kind in ["archer","bombard"],"reach":4 if allies[0].kind in ["archer","bombard"] else 1}))
				if allies.size()>1: steps.append(step(allies[1].id,nearest,"Mercenário · cobrar a abertura",30,20,{"budget":6}))
			else: steps.append(step(actor,nearest,"Cobrança por mão própria",31,24,{"reach":2,"qi_drain":3}))
		"coast_yusuf":
			if b.objective.has("asset_cell"):
				for h in opponents:
					if b.distance(b.units[h].cell,b.objective.asset_cell)<b.distance(b.units[nearest].cell,b.objective.asset_cell): nearest=h
			other=opponents[1] if opponents.size()>1 and opponents[0]==nearest else opponents[0]
			steps=[step(actor,nearest,"Romper o resgate",25,22,{"push_on_hit":true,"push_steps":2,"budget":6}),step(actor,other,"Separar a dupla",25,20,{"push_on_hit":true,"budget":6})]
		"storm_mate":
			steps=[step(actor,nearest,"Corda de abordagem",22,18,{"reach":3,"pull_on_hit":true,"rope":true}),step(actor,other,"Balanço nas amarras",30,24,{"budget":7,"rope":true,"rope_swing":true,"push_on_hit":true,"push_steps":2})]
		"final_esteban":
			if u.boss_phase<3:
				var escorts: Array=b.enemies.filter(func(e): return e.id!=actor and e.hp>0 and not e.broken and e.stun==0)
				escorts.sort_custom(func(a,c): return (0 if a.kind in ["archer","bombard"] else 1)<(0 if c.kind in ["archer","bombard"] else 1))
				for i in mini(2,escorts.size()):
					var ally: Dictionary=escorts[i]
					steps.append(step(ally.id,nearest if i==0 else other,"Ordem · fogo cruzado",27,20,{"ranged":ally.kind in ["archer","bombard"],"reach":5 if ally.kind in ["archer","bombard"] else 1,"budget":4,"no_counter":true,"defense_beats":2}))
			var cuts: int=6 if u.boss_phase==3 else (4 if u.boss_phase==2 else 3)
			steps.append(step(actor,nearest,"Esgrima · último comando" if u.boss_phase==3 else "Esgrima do almirante",25+u.boss_phase*2,16+u.boss_phase*2,{"budget":6,"reach":2,"volley":true,"marks":[0.14,0.30,0.56,0.68,0.85,0.93].slice(0,cuts) if cuts==6 else ([0.22,0.46,0.68,0.88] if cuts==4 else [0.24,0.55,0.85]),"stream_duration":4.0 if cuts==6 else 2.8,"guard_pressure":true,"qi_drain":1,"no_counter":true,"fencing":true,"bleed_last":u.boss_phase==3}))
			if u.boss_phase>=2: steps.append(step(actor,other,"Fechar o socorro",34,28,{"budget":6,"guard_pressure":true,"timing_curve":"brake","push_on_hit":true}))
		"refuge_trial":
			for hero in [nearest,other]:
				if hero==nearest and not steps.is_empty(): continue
				var mirror: int=b.heroes[hero].get("last_skill",0)
				var copied: Dictionary=b.skill_def(hero,mirror)
				var repeated: bool=b.heroes[hero].get("recent_skills",[]).size()>=2 and b.heroes[hero].recent_skills[-1]==b.heroes[hero].recent_skills[-2]
				var count: int=4 if repeated or b.Catalog.is_ultimate(mirror) else 3
				steps.append(step(actor,hero,"Reflexo · "+str(copied.get("name","Talho")),clampi(int(copied.get("power",30))/2+(4 if repeated else 0),15,26),clampi(int(copied.get("posture",20))/2,10,20),{"reach":clampi(int(copied.get("range",1)),1,3),"budget":6,"volley":true,"marks":[0.20,0.46,0.69,0.88] if count==4 else ([0.23,0.59,0.87] if hero==0 else [0.33,0.65,0.87]),"stream_duration":2.8 if hero==0 else 2.45,"reverse_stream":true,"bleed":copied.get("status","")=="bleed" or copied.get("effects",[]).has("bleed"),"pull_on_hit":copied.get("hook",false),"guard_pressure":copied.get("posture_only",false),"no_counter":true,"mirror_hero":hero}))
			if u.boss_phase>=2: steps.append(step(actor,other,"Ressaca das memórias",36,30,{"reach":3,"guard_pressure":true,"timing_curve":"brake"}))
	return {"kind":"sequence","path":[],"targets":opponents.duplicate(),"cells":opponents.map(func(id): return b.units[id].cell),"name":title(b,u),"cinematic":true,"steps":steps,"boss":actor}

## Resolve geometry anew for each leg. Dead targets and blocked routes cannot cause teleportation.
static func plan_step(b, template: Dictionary) -> Dictionary:
	var s: Dictionary=template.duplicate(true)
	var actor: int=s.actor
	var target: int=s.target
	s.kind="ranged" if s.get("ranged",false) else "attack"
	s.path=[]; s.targets=[]; s.cells=[]; s.sequence_step=true; s.universal_parry=true
	var u: Dictionary=b.units[actor]
	s.destination=u.cell
	if s.get("retreat",false): return retreat_plan(b,actor,int(s.get("budget",3)))
	if u.hp<=0 or u.stun>0 or u.broken or b.units[target].hp<=0: s.kind="wait"; return s
	var graph: Dictionary=b.reachable(actor,int(s.get("budget",5)))
	var best: Vector2i=u.cell
	var best_score: float=-INF
	var pivot:=Vector2i(-1,-1)
	for cell in graph.costs:
		var d: int=b.distance(cell,b.units[target].cell)
		if d<int(s.get("min_reach",1)) or d>int(s.reach): continue
		if s.get("lance_throw",false) and cell.x!=b.units[target].cell.x and cell.y!=b.units[target].cell.y: continue
		var route_origin: Vector2i=cell
		var bounce:=Vector2i(-1,-1)
		if s.get("ricochet",false): bounce=ricochet(b,actor,cell,b.units[target].cell)
		if not b.clear_line(cell,b.units[target].cell,actor,s.get("lance_throw",false)) and bounce==Vector2i(-1,-1): continue
		if bounce!=Vector2i(-1,-1): route_origin=bounce
		var side: String=b.flank(actor,target,route_origin)
		var score: float=-float(graph.costs[cell])*2+(12 if side=="Costas" else (6 if side=="Flanco" else 0))
		if s.get("prefer_front",false): score=-float(graph.costs[cell])*2+(12 if side=="Frente" else 0)
		if s.get("ranged",false):
			score-=absf(d-3)*3
			for h in b.living(0):
				if b.distance(cell,b.units[h].cell)<=1: score-=50
		if s.get("lance_throw",false):
			var shaft_cells:=spear_ray(b,cell,b.units[target].cell,5)
			for h in b.living(0):
				if shaft_cells.has(b.units[h].cell): score+=16
		if score>best_score: best=cell; best_score=score; pivot=bounce
	if best_score==-INF:
		s.kind="approach"
		var near: int=b.distance(best,b.units[target].cell)
		for cell in graph.costs:
			var d: int=b.distance(cell,b.units[target].cell)
			if d<near: near=d; best=cell
	else: s.targets=[target]; s.cells=[b.units[target].cell]
	s.path=b.path_to(actor,best,int(s.get("budget",5))); s.destination=best
	if pivot!=Vector2i(-1,-1): s.projectile_origin=pivot; s.bounce_cell=pivot
	if not s.targets.is_empty() and s.get("volley",false): s.kind="volley"
	if not s.targets.is_empty() and s.get("lance_throw",false):
		s.cells=spear_ray(b,best,b.units[target].cell,5); s.targets=b.targets(actor,s.cells); s.lance_end=s.cells[-1]
	return s
static func ricochet(b, actor: int, origin: Vector2i, target: Vector2i) -> Vector2i:
	for wall in b.obstacles:
		if b.distance(origin,wall)+b.distance(wall,target)>7: continue
		# The bank point is beside solid cover; both legs must be unobstructed.
		for dir in b.DIRECTIONS:
			var pivot: Vector2i=wall+dir
			if not b.inside(pivot) or b.obstacles.has(pivot) or pivot==origin or pivot==target: continue
			if b.unit_at(pivot,actor)>=0: continue
			if b.clear_line(origin,pivot,actor) and b.clear_line(pivot,target,actor): return pivot
	return Vector2i(-1,-1)
static func normal(b, u: Dictionary, attack: Dictionary) -> Dictionary:
	var s: Dictionary=attack.duplicate(true)
	match key(b,u):
		"boss": s.name="Leitura do fio"; s.riposte_after=true; s.guard_after=true
		"stronghold": s.universal_parry=true; s.power=26; s.guard_after=false; s.name="Finta da torre"; s.timing_curve="brake" if u.turns%2==0 else "accelerate"; s.riposte_after=true
		"cove_trial": s.name="Talho de esforço"; s.power+=int(u.get("strain",0))*4
		"vigia_guard":
			var form: int=int(u.get("lance_form",0))
			s.name=["Haste estendida","Baluarte da Rosa","Passo de caça"][form]
			s.guard_after=form==1 and u.get("lance_cell",Vector2i(-1,-1))==Vector2i(-1,-1); s.push_on_hit=form==2
		"lisbon_avelar":
			if s.kind=="ranged":
				s.retreat_after=true
				s.name=["Flecha de perseguição","Flecha de amarra","Flecha rompe-guarda"][u.turns%3]
				s.root_on_hit=u.turns%3==1; s.guard_pressure=u.turns%3==2
				if u.turns%3==0:
					s.power+=6 if b.units[s.target].get("moved_last_turn",false) else 0
					var bounce:=ricochet(b,u.id,s.get("destination",u.cell),b.units[s.target].cell)
					if bounce!=Vector2i(-1,-1): s.universal_parry=true; s.name="Ricochete de perseguição"; s.projectile_origin=bounce; s.bounce_cell=bounce
		"yusuf": s.name="Corte em movimento"; s.riposte_after=false
		"refuge_trial":
			s.name=["Memória da haste","Memória da resposta","Memória da dança"][u.turns%3]
			s.riposte_after=u.turns%3==1; s.push_on_hit=u.turns%3==2; s.defense_beats=3
	return s
static func mitigation(b, actor: int, target: int, skill: int, side: String) -> float:
	var u: Dictionary=b.units[target]
	if u.broken or u.exposed or side!="Frente": return 1.0
	var k=key(b,u)
	if k=="boss" and int(u.get("read_skills",{}).get(actor,-1))==skill: return 0.6
	if k=="stronghold" and actor==1 and int(u.get("read_skills",{}).get(actor,-1))==skill: return 0.85
	if k in ["refuge_trial","final_esteban"] and int(u.get("read_skills",{}).get(actor,-1))==skill: return 0.65
	return 1.0
static func intercept(b, target: int, side: String) -> int:
	if key(b,b.units[target])!="ceuta_depot" or side!="Frente": return -1
	for ally in b.enemies:
		if ally.id!=target and ally.get("paid_intercept",false) and ally.hp>0 and not ally.broken and ally.stun==0 and b.distance(ally.cell,b.units[target].cell)<=2: return ally.id
	return -1
static func after_attack(b, actor: int, plan: Dictionary) -> void:
	var u: Dictionary=b.units[actor]
	var k=key(b,u)
	if u.hp<=0 or u.broken: return
	if k=="cove_trial" and not plan.get("sequence_step",false): u.strain=mini(3,int(u.get("strain",0))+1)
	if k=="vigia_guard" and not plan.get("sequence_step",false):
		if int(u.get("lance_form",0))==2: u.exposed=true
		u.lance_form=(int(u.get("lance_form",0))+1)%3
	if k=="yusuf" and not plan.get("sequence_step",false): u.exposed=true
	if k=="ceuta_depot" and not plan.get("sequence_step",false) and int(u.get("contract_coins",6))>0:
		var allies: Array=b.enemies.filter(func(e): return e.id!=actor and not e.get("objective_actor",false) and e.hp>0 and not e.broken and e.stun==0)
		if not allies.is_empty():
			allies.sort_custom(func(a,c): return (0 if a.kind=="defender" else 1)<(0 if c.kind=="defender" else 1))
			u.contract_coins-=1
			u.contract_orders=int(u.get("contract_orders",0))+1
			if u.contract_orders%2==0: allies[0].paid_intercept=true; allies[0].guard=true; u.contract_note="Tu recebes para isto · interceptação paga"
			else: allies[0].bounty_target=plan.get("target",0); allies[0].bounty_power=8; u.contract_note="Preço pela cabeça · perseguição paga"
	if k=="final_esteban" and not plan.get("sequence_step",false):
		for ally in b.enemies:
			if ally.id!=actor and ally.hp>0: ally.bounty_target=plan.get("target",0); ally.bounty_power=6

static func retreat_plan(b, actor: int, budget: int) -> Dictionary:
	var u: Dictionary=b.units[actor]
	var graph: Dictionary=b.reachable(actor,budget)
	var best: Vector2i=u.cell
	var separation:=99
	for h in b.living(0): separation=mini(separation,b.distance(u.cell,b.units[h].cell))
	var score: float=separation*12.0
	for cell in graph.costs:
		var near:=99
		for h in b.living(0): near=mini(near,b.distance(cell,b.units[h].cell))
		var candidate: float=near*12.0-int(graph.costs[cell])*0.3
		if candidate>score: best=cell; score=candidate
	return {"kind":"reposition","actor":actor,"target":b.living(0)[0] if not b.living(0).is_empty() else 0,"path":b.path_to(actor,best,budget),"destination":best,"targets":[],"cells":[],"name":"Recuo do arqueiro","sequence_step":true}

static func spear_ray(b, origin: Vector2i, aim: Vector2i, reach: int) -> Array[Vector2i]:
	var cells: Array[Vector2i]=[]
	var direction: Vector2i=b.DIRECTIONS[b.direction_index(aim-origin)]
	for i in range(1,reach+1):
		var cell: Vector2i=origin+direction*i
		if not b.inside(cell) or b.obstacles.has(cell): break
		cells.append(cell)
	return cells

static func lance_return(b, actor: int) -> Dictionary:
	var u: Dictionary=b.units[actor]
	var shaft: Vector2i=u.lance_cell
	var graph: Dictionary=b.reachable(actor,u.moves)
	var best: Vector2i=u.cell
	var best_distance: int=b.distance(best,shaft)
	for cell in graph.costs:
		var d: int=b.distance(cell,shaft)
		if d<best_distance: best=cell; best_distance=d
	var cells: Array[Vector2i]=[]
	var delta:=Vector2(best-shaft)
	var steps: int=maxi(absi(best.x-shaft.x),absi(best.y-shaft.y))
	for i in range(1,steps+1):
		var cell:=Vector2i((Vector2(shaft)+delta*float(i)/maxi(1,steps)).round())
		if b.obstacles.has(cell): break
		if not cells.has(cell): cells.append(cell)
	var can_retrieve: bool=best_distance<=3 and b.clear_line(shaft,best,actor,true)
	return {"kind":"ranged" if can_retrieve else "approach","actor":actor,"path":b.path_to(actor,best),"destination":best,"targets":b.targets(actor,cells) if can_retrieve else [],"cells":cells,"name":"Regresso do espinho" if can_retrieve else "Recuperar a lança","power":38,"posture":30,"guard_pressure":true,"defense_beats":2,"lance_return":can_retrieve,"projectile_origin":shaft,"lance_end":best,"universal_parry":true,"no_counter":true}

