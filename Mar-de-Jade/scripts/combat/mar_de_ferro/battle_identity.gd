extends RefCounted
## Encounter rules shared by intent, preview and execution. No presentation state.
const BOSSES := {
	"refuge_trial":{"pattern":"memory","name":"Contracanto da primeira maré","phases":["I · AS MEMÓRIAS","II · O REFLEXO","III · A PRIMEIRA MARÉ"],"hint":"Devolve técnicas dos dois heróis. O cursor do reflexo corre para a esquerda; repetições fortalecem a cópia. Elimina os apoios e varia técnicas."},
	"lisbon_avelar":{"pattern":"archer","name":"Cinco penas de sangue","phases":["I · PERSEGUIÇÃO","II · FLECHAS DE AMARRA","III · CAÇADA FINAL"],"hint":"Cinco flechas no mesmo herói, com cinco marcas numa barra contínua. Flechas que ferem causam Sangramento. Encurrala-o para negar o recuo."},
	"boss":{"pattern":"duel","name":"Tratado das três respostas","phases":["I · LEITURA DO FIO","II · GUARDA TÉCNICA","III · ÚLTIMA RESPOSTA"],"hint":"Começa com uma linha, cruza-a na segunda fase e encadeia duas áreas na última. Sai dos avisos e castiga a recuperação."},
	"cove_trial":{"pattern":"ring","name":"Peso de uma maré","phases":["I · O ESFORÇO","II · O PESO","III · A DESCARGA"],"hint":"Reposiciona o centro antes de anunciar o anel. Na última fase, o centro também é anunciado para o golpe seguinte."},
	"stronghold":{"pattern":"volley","name":"Valsa da lâmina velada","phases":["I · A FINTA","II · O REVERSO","III · ÚLTIMO COMPASSO"],"hint":"Primeiro uma linha; depois uma cruz com dois arqueiros activos. A última salva encadeia outra linha. Sem a escolta, Catarina procura os flancos e responde pela frente."},
	"vigia_guard":{"pattern":"prism","name":"Espinho lançado","phases":["I · A HASTE","II · O BALUARTE","III · A CAÇA"],"hint":"Arremessa a lança, atravessa a linha e avança desarmado. Observa a lança cravada: a linha de retorno é outra ameaça."},
	"ceuta_depot":{"pattern":"duel","name":"Dobro ou nada","phases":["I · O PREÇO","II · OS CONTRATOS","III · A CONTA"],"hint":"Enquanto o incendiário puder agir, o chefe recebe −20% dano frontal. Neutraliza-o ou flanqueia. Sem as ordens, o cobrador avança com alcance 2 e drena mais alento."},
	"coast_yusuf":{"pattern":"cross","name":"Cortar a retirada","phases":["I · A ORDEM","II · A REPRESÁLIA","III · A RETIRADA"],"hint":"Marca uma cruz e, na última fase, uma segunda linha. O capitão pressiona a zona da retirada; sai dos avisos e protege as famílias."},
	"storm_mate":{"pattern":"swell","name":"Travessia das amarras","phases":["I · A CORDA","II · A TRAVESSIA","III · A AMURADA"],"hint":"A vaga alarga-se e empurra até 2 casas nas fases avançadas. Guarda, cobertura ou defesa perfeita impedem o empurrão; o bordo nunca causa queda."},
	"final_esteban":{"pattern":"final","name":"Última ordem do almirante","phases":["I · O LIVRO E A LÂMINA","II · O MASTRO CEDE","III · CONVÉS PARTIDO"],"hint":"O almirante coordena ataques dos aliados. Abaixo de 45% de vida, seis cortes numa barra contínua e um golpe contra o outro herói. Flanqueia e castiga a recuperação."}
}

static func is_boss(u: Dictionary) -> bool:
	return u.kind=="boss" or u.name=="Rui de Avelar"

static func preparing(u: Dictionary, turn: int) -> bool:
	if not is_boss(u) or (u.kind!="boss" and u.boss_phase<2) or u.get("signature_pending",false): return false
	if u.get("phase_pending",false): return true
	# Leave one ordinary action after a completed sequence, including two-hit finales.
	var ready: int=int(u.get("charge_ready_turn",0))
	return turn>=ready if ready>0 else turn%3==2

static func active(u: Dictionary) -> bool:
	return u.hp>0 and not u.broken and u.stun==0

static func support_score(b, actor: int, cell: Vector2i, target: int) -> float:
	if b.encounter in ["training","prologue_raid"]: return 0.0
	var u: Dictionary=b.units[actor]
	var score:=0.0
	for ally in b.enemies:
		if ally.id==actor or not active(ally): continue
		if u.kind=="defender" and ally.kind in ["medic","archer","bombard"]:
			var separation: int=b.distance(cell,ally.cell)
			if separation<=2 and b.clear_line(cell,ally.cell,actor):
				score+=18 if ally.kind=="medic" else 10
				if b.distance(cell,b.units[target].cell)<b.distance(ally.cell,b.units[target].cell): score+=8
		if u.kind in ["duelist","rogue"] and ally.kind in ["defender","guard","pikeman"] and b.distance(ally.cell,b.units[target].cell)<=2:
			if b.flank(actor,target,cell)!="Frente": score+=16
		if u.kind=="archer" and ally.kind=="archer":
			if b.distance(cell,ally.cell)<=1: score-=10
			# Complement the other archer's angle rather than crowding one lane.
			if b.direction_index(cell-b.units[target].cell)!=b.direction_index(Vector2i(ally.cell)-Vector2i(b.units[target].cell)): score+=2
	if b.encounter=="lisbon_avelar" and u.kind=="defender":
		for leader in b.enemies:
			if leader.name=="Rui de Avelar" and active(leader):
				if b.distance(cell,leader.cell)<=2 and b.clear_line(cell,leader.cell,actor): score+=24
	if b.encounter=="coast_yusuf" and u.kind=="boss" and b.objective.get("kind","")=="protect":
		# Threaten the heroes guarding the evacuation rather than chase across the map.
		score+=maxf(0,24-b.distance(cell,b.objective.asset_cell)*6)
	if u.kind=="archer": score-=b.distance(cell,u.cell)*2.0
	return clampf(score,-30,35)

static func lane(b, center: Vector2i, vertical: bool, output: Array[Vector2i]) -> void:
	for step in (b.SIZE.y if vertical else b.SIZE.x):
		var cell:=Vector2i(center.x,step) if vertical else Vector2i(step,center.y)
		if not b.obstacles.has(cell) and not output.has(cell): output.append(cell)

static func rays(b, center: Vector2i, directions: Array, output: Array[Vector2i]) -> void:
	if not b.obstacles.has(center) and not output.has(center): output.append(center)
	for direction in directions:
		for step in range(1,5):
			var cell: Vector2i=center+direction*step
			if not b.inside(cell) or b.obstacles.has(cell): break
			if not output.has(cell): output.append(cell)

static func charge(b, actor: int, target: int) -> Dictionary:
	var u: Dictionary=b.units[actor]
	var definition: Dictionary=BOSSES.get(b.encounter,BOSSES.boss)
	var center: Vector2i=b.units[target].cell
	var other: Vector2i=Vector2i(center.x,(center.y+1)%b.SIZE.y)
	for hero in b.heroes:
		if hero.id!=target and hero.hp>0: other=hero.cell
	var cells: Array[Vector2i]=[]
	var follow: Array[Vector2i]=[]
	var path: Array[Vector2i]=[]
	var origin: Vector2i=u.cell
	var pattern: String=definition.pattern
	if pattern=="ring":
		if u.boss_phase>=2:
			# Move at most two houses BEFORE locking the warning. Planning remains read-only.
			var graph: Dictionary=b.reachable(actor,mini(2,u.moves))
			var best_score: float=-INF
			for cell in graph.costs:
				var score: float=-absf(b.distance(cell,center)-2)*10-int(graph.costs[cell])
				if score>best_score: best_score=score; origin=cell
			path=b.path_to(actor,origin,mini(2,u.moves))
		for y in b.SIZE.y:
			for x in b.SIZE.x:
				var cell:=Vector2i(x,y)
				if b.obstacles.has(cell): continue
				var d: int=b.distance(cell,origin)
				if d==(3 if u.boss_phase==3 else 2): cells.append(cell)
				if u.boss_phase==3 and d<=1: follow.append(cell)
	elif pattern=="prism":
		rays(b,center,b.DIRECTIONS,cells)
		var diagonals: Array=[Vector2i(1,1),Vector2i(1,-1),Vector2i(-1,1),Vector2i(-1,-1)]
		if u.boss_phase>=2: rays(b,center,diagonals,cells)
		if u.boss_phase==3: rays(b,other,diagonals,follow)
	else:
		lane(b,center,false,cells)
		var cross: bool=pattern in ["cross","final","archer"] and u.boss_phase>=2
		if pattern=="cross": cross=true
		if pattern=="duel" and b.encounter=="boss": cross=u.boss_phase>=2
		if pattern=="volley": cross=u.boss_phase>=2 and b.enemies.filter(func(e): return e.kind=="archer" and active(e)).size()>=2
		if cross: lane(b,center,true,cells)
		if pattern=="swell" and u.boss_phase>=2:
			lane(b,Vector2i(center.x,clampi(center.y+(-1 if center.y>=b.SIZE.y/2 else 1),0,b.SIZE.y-1)),false,cells)
		if u.boss_phase==3 and (pattern in ["final","archer","volley","swell","cross"] or (pattern=="duel" and b.encounter=="boss")):
			# Advertise both areas now. Never follow a hero after the announcement.
			if other.y==center.y: other.y=(center.y+1)%b.SIZE.y
			if pattern=="archer" and other.x==center.x: other.x+=-1 if center.x>=b.SIZE.x/2 else 1
			lane(b,other,pattern=="archer",follow)
	return {"kind":"charge","path":path,"destination":origin,"cells":cells,"followup":follow,"targets":[],"name":definition.name,"next_name":"Segunda salva" if pattern in ["volley","archer"] else "Ressaca de aço","power":38+u.boss_phase*2,"push_steps":2 if pattern=="swell" and u.boss_phase>=2 else 1}

