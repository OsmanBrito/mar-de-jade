extends RefCounted
## Local additions around the approved childhood scenes; no adult unlocks.
static func hint(stage:int) -> String:
	return ["Combina a procura com Leonor; podes examinar os recantos antes de seguir o trilho.","Na lama, procura dois cascos estreitos entre os sulcos largos da carroça.","O ramo partido fica junto da curva. Compara a altura com o tamanho de um corço.","A ponte é a única passagem da água. As travessas sustentam os pés.","Leonor viu algo claro acima das raízes. Aproxima-te para combinarem o caminho.","Leonor subiu para espreitar. A clareira tem um lobo; guarda voltada para ele.","Leonor regressou. No próximo combate controlas Leonor, com todas as suas técnicas.","Para lá das marcas largas, os cascos estreitos seguem para a clareira alta.","Podes explorar o regresso ou falar com Leonor para voltarem juntos."][clampi(stage,0,8)]
static func parting(p) -> Array:
	if p.choices.get("hunt_departure","")=="signs":
		return [["Herói criança","E os sinais que combinámos?"],["Leonor criança","Deixo o ramo na subida. Só vou ver o que há do outro lado."]]
	return [["Herói criança","Dissemos que íamos juntos."],["Leonor criança","É só até ao alto. Mostro-te a passagem e voltamos a ir os dois."]]
static func apology(p) -> Array:
	return [["Herói criança","Não bastou "+("deixar um sinal. Precisava de te ouvir." if p.choices.get("hunt_departure","")=="signs" else "dizer que voltavas. Não sabia onde estavas.")],["Leonor criança","Eu ouvi o lobo e voltei. Devia ter esperado por ti antes de subir."]]
static func promise(p) -> Array:
	if not p.flags.get("hunt_completed",false):return []
	return [{"type":"line","speaker":"Narrador","text":"De volta à praça, os dois pousaram os instrumentos. A água chegou depois da poeira do caminho."},{"type":"line","speaker":"Herói criança","text":"Consegui enfrentar o lobo. Ainda estou a pensar no urso."},{"type":"line","speaker":"Leonor criança","text":"E eu no momento em que te deixei sozinho. Amanhã treinamos outra vez."}]

static func environment_hint(stage: int,at: Vector2) -> String:
	var clues: Dictionary={
		1:[Vector2(600,1050),"Dois cascos finos cruzam os sulcos largos da carroça."],
		2:[Vector2(1000,700),"Um ramo claro está partido à altura do dorso de um animal pequeno."],
		3:[Vector2(1460,730),"As tábuas claras unem as duas margens; a água continua para os lados."],
		7:[Vector2(2350,350),"Os cascos estreitos sobem a clareira; a marca larga ficou para trás."]
	}
	if not clues.has(stage) or at.distance_to(clues[stage][0])>260:return ""
	return clues[stage][1]

static func departure(p,original:Array) -> Array:
	if not p.flags.get("child_forest_invited",false):return original
	return [["Herói criança","Foi aqui que o viram?"],["Leonor criança","Perto da ponte. Não disseram de que lado."],["Herói criança","Se houver pegadas, encontramos."],["Leonor criança","Tu olhas para o chão. Eu vejo o caminho."],["Herói criança","E não te afastes."],["Leonor criança","Está bem."]]

static func discovery(id:String) -> Array:
	return {
		"shelter":[["Herói criança","Há ovos aqui."],["Leonor criança","Não mexas no ramo."],["Herói criança","Eu só queria ver."],["Leonor criança","Então vê daqui."]],
		"charcoal":[["Herói criança","Isto ardeu?"],["Leonor criança","Faziam carvão aqui. Olha para as marcas das rodas."],["Herói criança","Também vieram atrás do corço?"],["Leonor criança","Acho que vieram trabalhar."]],
		"tracks":[["Herói criança","Estas não são iguais."],["Leonor criança","Aquelas são muito maiores."],["Herói criança","Não era só o corço que vinha beber aqui."],["Leonor criança","Ficamos no caminho."]]
	}.get(id,[])
