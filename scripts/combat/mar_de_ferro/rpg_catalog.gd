extends RefCounted
## Stable content IDs are saved; presentation order can change independently.
## Combat identities:
## - Duarte / alabarda: alcance, saltos, impacto em área e quebra de formações.
## - Inês / espada: dano, Sangramento, mobilidade, flanco e execução.

const TECHNIQUES := [1,2,3,4,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26]

const TECHNIQUE_RARITY := {
	0:"Comum",1:"Comum",2:"Marcial",3:"Rara",4:"Marcial",5:"Comum",6:"Comum",7:"Comum",
	8:"Rara",9:"Rara",10:"Épica",11:"Rara",12:"Suprema",13:"Épica",14:"Épica",
	15:"Épica",16:"Lendária",17:"Lendária",18:"Lendária",19:"Lendária",20:"Épica",
	21:"Épica",22:"Épica",23:"Lendária",24:"Suprema",25:"Lendária",26:"Lendária"
}
const TECHNIQUE_RARITY_COLOR := {
	"Comum":"9aa6a8","Marcial":"78c5af","Rara":"74b5d0",
	"Épica":"b889e6","Lendária":"e2b66c","Suprema":"f07882"
}
# Kept as a fallback for old UI/save code. Active techniques and proc passives can
# override this with their own "cooldown" value.
const RARITY_COOLDOWN := {"Comum":0,"Marcial":0,"Rara":1,"Épica":2,"Lendária":3,"Suprema":4}
const ALBERGARIA_COST := 35

# Core techniques follow levels; discoveries and supremas keep authored sources.
# Supremas share the seventh command. A saved choice overrides the legacy
# automatic preference for the latest learned supreme.
const MARTIAL_ULTIMATE := 12
const NARRATIVE_ULTIMATE := 24
const ULTIMATES := [MARTIAL_ULTIMATE,NARRATIVE_ULTIMATE]

static func is_ultimate(id: int) -> bool:
	return ULTIMATES.has(id)

# The supreme a hero currently commands, or -1 while neither is learned.
static func ultimate_for(known: Array) -> int:
	if known.has(NARRATIVE_ULTIMATE): return NARRATIVE_ULTIMATE
	return MARTIAL_ULTIMATE if known.has(MARTIAL_ULTIMATE) else -1

static func prepared_ultimate(hero: Dictionary) -> int:
	var selected: int=int(hero.get("ultimate",-1))
	return selected if is_ultimate(selected) and hero.known.has(selected) else ultimate_for(hero.known)

# Guaranteed mastery and optional discoveries share the reward pipeline.
const TECHNIQUE_UNLOCKS := {
	"manual":20, "cargo_weapon":20, "cargo_done":25, "storm_balance":23,
	"final_rhythm":24,
	"boss":12
}
const LEGACY_TECHNIQUE_LEVELS := {
	1:1, 2:1, 3:1, 4:2, 9:2, 8:3, 10:4, 11:4, 13:5, 21:5,
	14:6, 20:6, 15:7, 16:7, 22:8, 17:8, 25:9, 18:10, 23:10, 19:11, 26:12
}
const TECHNIQUE_LEVELS := {
	1:1,2:1,3:1,4:2,9:2,8:3,10:4,11:4,13:5,21:6,
	14:7,15:8,22:10,16:12,17:14,18:16,19:18,26:20
}
const DISCOVERY_SOURCES := {
	20:"Manual da varanda ou arsenal da carga",
	25:"Entrega da carga · rota de Porto Santo",
	23:"Estabilizar o navio · travessia da tempestade"
}

static func techniques_by_level() -> Array:
	var ids: Array=TECHNIQUES.duplicate()
	ids.sort_custom(func(a: int, b: int) -> bool:
		var level_a: int=int(TECHNIQUE_LEVELS.get(a,99))
		var level_b: int=int(TECHNIQUE_LEVELS.get(b,99))
		return level_a<level_b if level_a!=level_b else a<b
	)
	return ids

# IDs 5, 6 and 7 remain universal commands: Respirar, Infusão and Tónico.
# Every other combat ID has a different definition for Duarte and Inês.
const HERO_SKILLS := {
	0:{
		25:{"name":"Travessa do cais","cost":6,"power":43,"posture":50,"shape":"arc","range":1,"status":"","cooldown":3,"effect":"sweep","anti_guard":true,"creates_opening":true,"description":"Varredura lendária curta contra guardas ancorados. Cria Abertura, mas exige aproximar Duarte da formação.","acquisition":"Nível 9 da dupla"},
		26:{"name":"Ponta da alvorada","cost":6,"power":46,"posture":30,"shape":"line","range":4,"status":"","cooldown":3,"effect":"line","exposed_power_mult":1.25,"description":"Estocada lendária numa linha de quatro casas. Consome Exposto para causar mais 25% de dano de vida. Menor quebra que Lança do farol; pára em obstáculos.","acquisition":"Por nível da dupla"},
		0:{"name":"Golpe de haste","cost":0,"power":20,"posture":15,"shape":"single","range":2,"status":"","cooldown":0,"effect":"cut","description":"Golpe básico de alabarda até duas casas. Recupera 1 de alento.","acquisition":"Inicial"},
		1:{"name":"Varredura do cais","cost":3,"power":18,"posture":30,"shape":"arc","range":1,"status":"","cooldown":0,"effect":"sweep","creates_opening":true,"description":"Arco curto com forte pressão de postura. Um bom golpe cria Abertura para Inês.","acquisition":"Inicial"},
		2:{"name":"Ponta comprida","cost":3,"power":28,"posture":18,"shape":"line","range":3,"status":"","cooldown":0,"effect":"line","description":"Estocada de alabarda em linha até três casas. Pára em obstáculos.","acquisition":"Inicial"},
		3:{"name":"Pomo de vigia","cost":4,"power":31,"posture":30,"shape":"single","range":2,"status":"stun","effects":["stun"],"cooldown":2,"effect":"stun","creates_opening":true,"description":"Golpe do conto da haste até duas casas. Atordoa por um turno se o alvo não resistir.","acquisition":"Inicial"},
		4:{"name":"Guarda de maré","cost":3,"power":0,"posture":0,"shape":"ally","range":2,"status":"cover","quick":true,"cooldown":1,"effect":"cover","description":"Cobre Inês contra o próximo golpe. Apoio rápido; exige alcance e linha livre.","acquisition":"C01 · vencer o treino no cais"},
		8:{"name":"Âncora baixa","cost":3,"power":24,"posture":40,"shape":"single","range":2,"status":"","cooldown":1,"effect":"breaker","creates_opening":true,"description":"Quebra económica até duas casas. Pouco dano de vida e forte pressão de postura; cria Abertura. Contra guarda ancorada, prefere Peso do Lastro.","acquisition":"C02 · manual da escola no Porto da Bruma","signature":"anchor"},
		9:{"name":"Salto da rebentação","cost":4,"power":27,"posture":24,"shape":"leap","range":3,"status":"","cooldown":2,"effect":"leap","fortitude":15,"creates_opening":true,"description":"Salta até 3 casas livres, sobre unidades mas não obstáculos. Atinge 4 vizinhos e cria Abertura. Resistência: −15% dano e pressão nos próximos 2 golpes, até ao próximo turno.","acquisition":"Por nível da dupla"},
		10:{"name":"Desafio","cost":4,"power":30,"posture":31,"shape":"arc","range":1,"status":"","cooldown":1,"effect":"sweep","taunt":true,"creates_opening":true,"description":"Varredura curta que provoca os atingidos até ao fim do próximo turno deles.","acquisition":"C02 · vencer a patrulha da Névoa"},
		11:{"name":"Peso do Lastro","cost":4,"power":26,"posture":38,"shape":"single","range":2,"status":"","cooldown":1,"effect":"breaker","creates_opening":true,"anti_guard":true,"description":"Resposta à guarda ancorada até duas casas: ignora a resistência extra à quebra. Cria Abertura; fora dessa guarda, Âncora baixa é mais económica.","acquisition":"Exclusiva Lastro · C02-S04","signature":"guard_break"},
		12:{"name":"Juramento do mestre","cost":7,"power":60,"posture":60,"shape":"arc","range":2,"status":"","cooldown":4,"effect":"heavy","ultimate":true,"cover_after":true,"description":"Suprema marcial. Arco de duas filas com dano e quebra muito altos; Duarte cobre Inês após o golpe.","acquisition":"C02 · derrotar o Mestre de Ferro"},
		13:{"name":"Gancho da alabarda","cost":4,"power":33,"posture":32,"shape":"single","range":3,"status":"","cooldown":2,"effect":"breaker","hook":true,"creates_opening":true,"description":"Puxa um inimigo em linha livre para junto de Duarte. Chefes e defensores ancorados resistem ao deslocamento, mas recebem o golpe.","acquisition":"C03-S03 · manual de cordoaria"},
		14:{"name":"Linha de embarque","cost":5,"power":40,"posture":42,"shape":"line","range":3,"status":"","cooldown":2,"effect":"line","creates_opening":true,"description":"Linha de três casas. A quebra interrompe ataques anunciados pela regra normal de postura.","acquisition":"C04-S02 · proteger o barco no Douro"},
		15:{"name":"Guarda de ferro","cost":3,"power":34,"posture":26,"shape":"self","range":0,"status":"","cooldown":2,"effect":"root","quick":true,"counter":true,"counter_on_perfect":false,"counter_range":2,"fortitude":25,"description":"Postura rápida: guarda e contra-ataque frontal até 2 casas. Resistência: −25% dano e pressão nos próximos 2 golpes, até ao próximo turno. Preserva a acção principal.","acquisition":"C04-S04 · observar o duelo de Catarina"},
		16:{"name":"Chamado da Maré","cost":6,"power":49,"posture":47,"shape":"arc","range":2,"status":"","cooldown":3,"effect":"sweep","taunt":true,"creates_opening":true,"description":"Maré Velada em arco de duas filas. Rompe formações e chama a pressão inimiga para Duarte.","acquisition":"C06-S03 · salvar a embarcação à deriva"},
		17:{"name":"Queda da maré","cost":6,"power":43,"posture":38,"shape":"leap","range":3,"status":"","cooldown":3,"effect":"leap","fortitude":15,"diagonal_blast":true,"creates_opening":true,"description":"Salto lendário até 3 casas livres, sem obstáculos. Atinge 8 vizinhos e cria Abertura. Resistência: −15% dano e pressão nos próximos 2 golpes, até ao próximo turno.","acquisition":"Por nível da dupla"},
		18:{"name":"Ferro contra a maré","cost":7,"power":60,"posture":58,"shape":"single","range":2,"status":"","cooldown":3,"effect":"breaker","anti_guard":true,"creates_opening":true,"description":"Impacto pesado até duas casas, com dano e quebra elevados. Ignora guarda ancorada e cria Abertura. Exige 7 alento e 3 turnos de recarga.","acquisition":"C08-S03 · conter Yusuf","signature":"heavy_commit"},
		19:{"name":"Lança do farol","cost":6,"power":44,"posture":48,"shape":"line","range":4,"status":"","cooldown":3,"effect":"line","creates_opening":true,"description":"Estocada de Maré Velada que atravessa inimigos numa linha de quatro casas. Causa dano de vida e forte quebra; cria Abertura. Pára em obstáculos.","acquisition":"Por nível da dupla"},
		20:{"name":"Fôlego de bordo","cost":3,"power":0,"posture":0,"shape":"friend","range":2,"status":"","quick":true,"guard":true,"cooldown":2,"effect":"heal","recovery":{"hp":18,"posture":24},"description":"Apoio rápido a Duarte ou Inês: recupera vida e postura e assume a guarda. Menor que uma Infusão.","acquisition":"Opcional · ajudar calafates e marinheiros"},
		21:{"name":"Muralha da Armada","cost":4,"power":30,"posture":30,"shape":"line","range":3,"status":"","cooldown":1,"effect":"line","cover_after":true,"description":"Exclusiva Armada. Golpe leve em linha; depois Duarte cobre Inês contra o próximo ataque.","acquisition":"Exclusiva Armada · C02-S04"},
		22:{"name":"Salto rompe-guarda","cost":5,"power":32,"posture":44,"shape":"leap","range":2,"status":"","cooldown":2,"effect":"leap","fortitude":15,"anti_guard":true,"creates_opening":true,"description":"Salta até 2 casas livres, sem obstáculos; atinge 4 vizinhos, ignora guarda ancorada e cria Abertura. Resistência: −15% dano e pressão nos próximos 2 golpes, até ao próximo turno.","acquisition":"Por nível da dupla"},
		23:{"name":"Olho da tormenta","cost":5,"power":0,"posture":0,"shape":"ally","range":4,"status":"cover","quick":true,"cooldown":3,"effect":"cover","recovery":{"posture":22},"description":"Apoio lendário: cobre Inês a longa distância e reforça a postura dela sem gastar a acção principal.","acquisition":"Opcional · treino após C06-S03"},
		24:{"name":"Âncora da Ordem","cost":8,"power":62,"posture":72,"shape":"arc","range":2,"status":"","cooldown":4,"effect":"heavy","ultimate":true,"narrative_ultimate":true,"cover_after":true,"requires_partner":true,"creates_opening":true,"description":"Suprema narrativa da Maré Velada. Prende a frente em duas filas, causa enorme quebra e cobre Inês. Exige os dois conscientes.","acquisition":"C10-S03 · dominar o Chamado com Inês"}
	},
	1:{
		25:{"name":"Finta do estaleiro","cost":4,"power":28,"posture":20,"shape":"single","range":3,"status":"","cooldown":2,"effect":"step","flank_attack":true,"flank_expose":true,"description":"Preparação até três casas: avança para um flanco livre e aplica Exposto ao acertar de lado. Dano leve; gasta a acção principal.","acquisition":"Nível 9 da dupla","signature":"expose_step"},
		26:{"name":"Fio da alvorada","cost":6,"power":47,"posture":18,"shape":"single","range":1,"status":"bleed","effects":["bleed"],"cooldown":3,"effect":"heavy","exposed_power_mult":1.25,"description":"Corte adjacente com Sangramento. Consome Exposto para aumentar o dano, preparando pressão continuada em vez de uma execução imediata.","acquisition":"Nível 12 da dupla"},
		0:{"name":"Corte medido","cost":0,"power":22,"posture":11,"shape":"single","range":1,"status":"","cooldown":0,"effect":"cut","uses_opening":true,"opening_power_mult":1.18,"description":"Corte básico adjacente. Recupera 1 de alento; aproveita uma Abertura para causar mais dano.","acquisition":"Inicial"},
		1:{"name":"Dança da lâmina","cost":3,"power":19,"posture":9,"shape":"arc","range":1,"status":"bleed","effects":["bleed"],"cooldown":0,"effect":"bleed","description":"Arco adjacente. Aplica Sangramento aos alvos atingidos.","acquisition":"Inicial"},
		2:{"name":"Estocada do cabo","cost":3,"power":31,"posture":13,"shape":"line","range":3,"status":"","cooldown":0,"effect":"line","uses_opening":true,"opening_power_mult":1.35,"opening_posture_bonus":10,"description":"Estocada em linha até três casas. Consome Abertura para dano e quebra adicionais.","acquisition":"Inicial"},
		3:{"name":"Ponta veloz","cost":4,"power":34,"posture":18,"shape":"single","range":1,"status":"","cooldown":1,"effect":"line","exposed_power_mult":1.20,"description":"Estocada rápida contra alvo adjacente. Causa dano extra se consumir Exposto.","acquisition":"Inicial"},
		4:{"name":"Fio rubro","cost":2,"power":22,"posture":8,"shape":"single","range":1,"status":"bleed","effects":["bleed"],"cooldown":0,"effect":"bleed","description":"Corte económico adjacente. Aplica Sangramento por três turnos para preparar a Dança ou o Fio de sal.","acquisition":"C01 · vencer o treino no cais"},
		8:{"name":"Agulha do vento","cost":4,"power":33,"posture":14,"shape":"line","range":4,"status":"","cooldown":1,"effect":"line","uses_opening":true,"opening_power_mult":1.22,"description":"Estocada de alcance quatro. Menos explosiva que Estocada do cabo, mas alcança muito mais longe.","acquisition":"C02 · manual da escola no Porto da Bruma"},
		9:{"name":"Passo da bruma","cost":3,"power":0,"posture":0,"shape":"self","range":0,"status":"","quick":true,"cooldown":1,"effect":"step","movement":2,"recovery":{"posture":8},"description":"Ganha duas casas de movimento, recupera alguma postura e assume a guarda. Apoio rápido.","acquisition":"C02 · entregar a encomenda da mercadora"},
		10:{"name":"Dança — corte sangrento","cost":4,"power":28,"posture":12,"shape":"arc","range":1,"status":"bleed","effects":["bleed"],"cooldown":2,"effect":"bleed","description":"Varredura com Sangramento. Causa mais 30% de dano a quem já sangra; combina com Fio rubro e Corrente rubra.","acquisition":"C02 · vencer a patrulha da Névoa","bleeding_power_mult":1.3},
		11:{"name":"Corte do Lastro","cost":4,"power":32,"posture":30,"shape":"single","range":1,"status":"","cooldown":1,"effect":"breaker","flank_posture_bonus":16,"uses_opening":true,"opening_posture_bonus":12,"description":"Exclusiva Lastro. Corte curto que converte flanco e Abertura em quebra elevada.","acquisition":"Exclusiva Lastro · C02-S04"},
		12:{"name":"Lua sobre o Tejo","cost":7,"power":62,"posture":28,"shape":"arc","range":2,"status":"bleed","effects":["bleed","expose"],"cooldown":4,"effect":"bleed","ultimate":true,"description":"Suprema marcial. Arco de duas filas com Sangramento e Exposto. Muito dano, menor quebra que a suprema de Duarte.","acquisition":"C02 · derrotar o Mestre de Ferro"},
		13:{"name":"Passo — ataque impossível","cost":4,"power":30,"posture":16,"shape":"single","range":4,"status":"","cooldown":1,"effect":"step","flank_attack":true,"description":"Avanço de alcance: chega a um flanco livre até quatro casas e ataca. Dano moderado e recarga curta; gasta a acção principal.","acquisition":"C03-S03 · página da Ordem","signature":"reach_step"},
		14:{"name":"Memória da Ordem","cost":4,"power":36,"posture":20,"shape":"single","range":2,"status":"","cooldown":2,"effect":"step","flank_attack":true,"uses_opening":true,"opening_power_mult":1.5,"description":"Ataque de combinação até duas casas. Reposiciona para o flanco e consome Abertura para mais 50% de potência. Gasta a acção principal.","acquisition":"C04-S02 · proteger o barco no Douro","signature":"opening_step"},
		15:{"name":"Corte da ressaca","cost":5,"power":46,"posture":20,"shape":"single","range":1,"status":"bleed","effects":["bleed","expose"],"cooldown":2,"effect":"bleed","description":"Golpe preciso adjacente. Aplica Sangramento e Exposto para preparar a execução seguinte.","acquisition":"C04-S05 · prática após o duelo"},
		16:{"acquisition":"C06-S03 · salvar a embarcação à deriva","name":"Valsa da Ordem","cost":6,"power":40,"posture":18,"shape":"arc","range":2,"status":"","cooldown":3,"effect":"sweep","uses_opening":true,"opening_power_mult":1.3,"movement_after":1,"description":"Arco de duas filas. Consome Abertura para mais 30% de dano e concede uma casa de movimento após atingir. Gasta a acção principal."},
		17:{"acquisition":"C07-S02 · retirar reféns","name":"Travessia cortante","cost":5,"power":40,"posture":24,"shape":"line","range":3,"status":"","cooldown":3,"effect":"line","uses_opening":true,"opening_posture_bonus":16,"movement_after":2,"description":"Corta uma linha de três casas. Consome Abertura para mais 16 de quebra e concede duas casas de movimento após atingir, para sair do cerco."},
		18:{"name":"Lâmina entre marés","cost":6,"power":58,"posture":22,"shape":"single","range":1,"status":"","cooldown":2,"effect":"heavy","exposed_power_mult":1.35,"description":"Execução lendária. Consome Exposto para grande aumento de dano de vida além da quebra de postura normal.","acquisition":"C08-S02 · defesa da aldeia"},
		19:{"name":"Fio de sal","cost":6,"power":45,"posture":22,"shape":"line","range":4,"status":"","cooldown":3,"effect":"line","flank_expose":true,"description":"Linha de quatro casas. Consome Sangramento para acrescentar 6 de potência por turno restante, até 18; um acerto de flanco aplica Exposto.","acquisition":"C09-S04 · duelo no convés","bleed_burst":6},
		20:{"name":"Corte de retorno","cost":4,"power":44,"posture":20,"shape":"self","range":0,"status":"","quick":true,"cooldown":2,"effect":"root","counter":true,"counter_on_perfect":true,"counter_range":1,"description":"Prepara uma resposta de espada. O próximo aparo perfeito frontal adjacente devolve um contra-ataque muito mais forte.","acquisition":"Opcional · treino com Beatriz após C03-S04"},
		21:{"name":"Véu da Armada","cost":3,"power":0,"posture":0,"shape":"self","range":0,"status":"","quick":true,"cooldown":2,"effect":"step","recovery":{"posture":18,"qi":2},"description":"Apoio rápido: remove Sangramento, recupera 18 postura e 2 alento e assume a guarda. Custa 3 alento; preserva a acção principal.","acquisition":"Exclusiva Armada · C02-S04","cleanse":true},
		22:{"name":"Corrente rubra","cost":5,"power":36,"posture":16,"shape":"line","range":3,"status":"bleed","effects":["bleed"],"cooldown":2,"effect":"line","description":"Linha de três casas que aplica Sangramento durante quatro turnos. Prepara vários alvos para Dança ou Fio de sal.","acquisition":"Opcional · notas de Lourenço em São Romão","bleed_turns":4},
		23:{"name":"Passo seguro","cost":4,"power":16,"posture":14,"shape":"single","range":3,"status":"","quick":true,"cooldown":3,"effect":"step","flank_attack":true,"description":"Reposicionamento rápido até um flanco livre a três casas, com corte leve. Após atingir, ganha uma casa para recuar. Preserva a acção principal; 3 turnos de recarga.","acquisition":"Opcional · retirar todos os reféns em C07-S02","movement_after":1,"signature":"escape_step"},
		24:{"name":"Maré Partilhada","cost":8,"power":72,"posture":34,"shape":"single","range":4,"status":"bleed","effects":["bleed","expose"],"cooldown":4,"effect":"heavy","ultimate":true,"narrative_ultimate":true,"requires_partner":true,"flank_attack":true,"duarte_cover_after":true,"description":"Suprema narrativa. Inês avança para um flanco livre e desfere o golpe conjunto; Duarte cobre a aterragem. Exige os dois conscientes.","acquisition":"C10-S03 · dominar a tempestade com Duarte"}
	}
}

# Legacy name kept because presentation code may still query it.
# New content lives in HERO_SKILLS; this dictionary only marks the extended ID range.
const NEW_SKILLS := {13:true,14:true,15:true,16:true,17:true,18:true,19:true,20:true,22:true,23:true,24:true,25:true,26:true}

const LEGACY_PROC_LEVELS := {"duarte_sweep_recovery": 1, "steady_pulse": 2, "salt_skin": 2, "red_horizon": 3, "safe_harbour": 3, "iron_will": 5, "storm_eye": 5, "steady_rhythm": 6, "oath_blood": 7, "last_light": 7, "duarte_breakwater": 10, "ines_opening_flow": 10, "emergency_reserve": 10, "duarte_shelter": 11, "ines_flank_rhythm": 11, "victory_breath": 11, "duarte_counter_oath": 12, "ines_exposed_flow": 12, "new_dawn": 12}
const PROC_PASSIVES := {
	"duarte_sweep_recovery":{"name":"Fôlego de batalha","rarity":"Marcial","hero":0,"level":1,"event":"multi_hit","cooldown":0,"recovery":{"posture":8},"description":"Ao atingir pelo menos dois inimigos numa técnica: recupera até 8 postura. Uma vez por turno; não reverte uma quebra."},
	"steady_pulse":{"name":"Pulso firme","rarity":"Rara","level":2,"event":"perfect","cooldown":1,"recovery":{"qi":1,"posture":6},"description":"Ao acertar um ritmo perfeito: +1 alento e +6 postura. Recarga: 1 turno próprio."},
	"salt_skin":{"name":"Pele de sal","rarity":"Rara","level":2,"event":"hurt","cooldown":1,"recovery":{"posture":8},"description":"Ao sofrer dano e sobreviver: +8 postura. Recarga: 1 turno próprio."},
	"red_horizon":{"name":"Horizonte rubro","rarity":"Épica","level":3,"event":"bleed_hit","cooldown":2,"recovery":{"hp":12,"qi":1},"description":"Ao atingir um alvo que já sangra: +12 vida e +1 alento. Recarga: 2 turnos próprios."},
	"safe_harbour":{"name":"Porto seguro","rarity":"Épica","level":3,"event":"breathe","cooldown":2,"recovery":{"hp":16,"posture":8},"cleanse":true,"description":"Ao Respirar: +16 vida, +8 postura e remove Sangramento. Recarga: 2 turnos próprios."},
	"iron_will":{"name":"Vontade de ferro","rarity":"Lendária","level":9,"event":"hurt","cooldown":2,"recovery":{"hp":14,"posture":10},"description":"Ao sofrer dano e sobreviver: +14 vida e +10 postura. Recarga: 2 turnos próprios."},
	"storm_eye":{"name":"Centro da tormenta","rarity":"Lendária","level":11,"event":"perfect","cooldown":2,"recovery":{"qi":3,"posture":12},"description":"Ao acertar um ritmo perfeito: +3 alento e +12 postura. Recarga: 2 turnos próprios."},
	"steady_rhythm":{"name":"Cadência inquebrável","rarity":"Lendária","level":12,"event":"perfect","cooldown":0,"recovery":{},"description":"Cada perfeito consecutivo alarga 8% a janela do próximo ritmo, até três vezes."},
	"oath_blood":{"name":"Sangue do juramento","rarity":"Suprema","level":15,"event":"bleed_hit","cooldown":3,"recovery":{"hp":24,"qi":3},"description":"Ao atingir um alvo que já sangra: +24 vida e +3 alento. Recarga: 3 turnos próprios."},
	"last_light":{"name":"Última luz","rarity":"Suprema","level":15,"event":"hurt","cooldown":4,"low_health":true,"recovery":{"hp":32,"posture":20},"cleanse":true,"description":"Ao sobreviver a dano com até 35% de vida: +32 vida, +20 postura e remove Sangramento. Recarga: 4 turnos próprios."},
	"duarte_breakwater":{"name":"Fôlego da ruptura","rarity":"Lendária","hero":0,"level":13,"event":"break","cooldown":1,"recovery":{"qi":1,"posture":8},"description":"Ao quebrar a postura de um inimigo com um ataque: +1 alento e +8 postura. Recarga: 1 turno próprio."},
	"ines_opening_flow":{"name":"Compasso da dupla","rarity":"Lendária","hero":1,"level":13,"event":"opening_hit","cooldown":1,"recovery":{"qi":2},"description":"Ao consumir Abertura com um ataque: +2 alento. Recarga: 1 turno próprio."},
	"emergency_reserve":{"name":"Reserva de emergência","rarity":"Lendária","level":14,"event":"hurt","cooldown":3,"low_health":true,"recovery":{"qi":2,"posture":6},"description":"Ao sobreviver a dano com até 35% de vida: +2 alento e +6 postura. Recarga: 3 turnos próprios."},
	"duarte_shelter":{"name":"Vigília partilhada","rarity":"Lendária","hero":0,"level":16,"event":"cover","cooldown":2,"recovery":{"hp":12,"qi":1},"description":"Ao interceptar um golpe pela cobertura e sobreviver: Duarte recupera 12 vida e 1 alento. Recarga: 2 turnos próprios."},
	"ines_flank_rhythm":{"name":"Passo harmonioso","rarity":"Lendária","hero":1,"level":16,"event":"flank_perfect","cooldown":2,"recovery":{"hp":8,"posture":10},"description":"Ao acertar um ataque perfeito de flanco ou costas: +8 vida e +10 postura. Recarga: 2 turnos próprios."},
	"victory_breath":{"name":"Fôlego da vitória","rarity":"Lendária","level":17,"event":"kill","cooldown":2,"recovery":{"hp":14,"posture":8},"description":"Ao derrotar um inimigo com um ataque: +14 vida e +8 postura. Recarga: 2 turnos próprios. Não activa por Sangramento."},
	"duarte_counter_oath":{"name":"Juramento da guarda","rarity":"Suprema","hero":0,"level":19,"event":"counter","cooldown":2,"recovery":{"hp":16,"posture":10},"description":"Ao executar um contra-ataque: +16 vida e +10 postura. Recarga: 2 turnos próprios."},
	"ines_exposed_flow":{"name":"Fio da oportunidade","rarity":"Suprema","hero":1,"level":19,"event":"exposed_hit","cooldown":2,"recovery":{"qi":2,"posture":8},"description":"Ao consumir Exposto num inimigo com um ataque: +2 alento e +8 postura. Recarga: 2 turnos próprios."},
	"new_dawn":{"name":"Alvorada persistente","rarity":"Suprema","level":20,"event":"turn_start","cooldown":3,"low_health":true,"recovery":{"hp":18},"cleanse":true,"description":"Ao começar o turno vivo, após o Sangramento, com até 35% de vida: +18 vida e remove Sangramento. Recarga: 3 turnos próprios. Não evita perder o turno por quebra."}
}

# General passives plus seven weapon passives for each hero (three core + four new).
const PASSIVES := {
	"duarte_landing":{"name":"Aterragem de ferro","hero":0,"description":"A resistência concedida pelos saltos passa de 15% para 25%. Protege vida e postura nos próximos 2 golpes, até ao início do próximo turno."},
	"duarte_hook":{"name":"Ímpeto do gancho","hero":0,"description":"Um puxão bem sucedido prepara +8 dano base na próxima técnica em arco, linha ou salto. Não acumula; expira no fim do próximo turno próprio."},
	"precision":{"name":"Precisão serena","description":"+5 dano base ao acertar o ritmo perfeito."},
	"parry":{"name":"Guarda serena","description":"Defesa perfeita recupera 6 de postura."},
	"breath":{"name":"Fôlego profundo","description":"Respirar recupera mais 2 de alento."},
	"stride":{"name":"Pés de marinheiro","description":"Mais uma casa de movimento por turno."},
	"anchor":{"name":"Âncora · Guarda firme","description":"+8 postura máxima. Aguenta mais pressão antes de quebrar."},
	"focus":{"name":"Maré · Reserva de Qi","description":"+2 alento máximo. Permite usar mais técnicas antes de respirar."},
	"riposte":{"name":"Resposta veloz","description":"+4 dano base enquanto a postura estiver cheia."},
	"sailor_eye":{"name":"Olho · Primeiro passo","description":"+3 iniciativa. Age mais cedo no combate."},
	"iron_breath":{"name":"Pulmão de ferro","description":"Recebe 1 alento ao sofrer dano, uma vez por turno."},
	"red_edge":{"name":"Fio · Ferida aberta","description":"+4 quebra contra inimigos com Sangramento."},

	"haft_hand":{"name":"Mão de haste","hero":0,"description":"A primeira quebra de postura com alabarda em cada turno recupera 1 alento."},
	"duarte_iron_guard":{"name":"Guarda plena","hero":0,"description":"Ao terminar o turno com postura cheia, Duarte assume a guarda contra o próximo golpe."},
	"closed_line":{"name":"Linha fechada","hero":0,"description":"Quando Duarte cobre Inês, ela recebe 25% menos pressão de postura desse golpe."},
	"long_reach":{"name":"Alcance disciplinado","hero":0,"description":"Ataques de alabarda feitos a duas ou mais casas causam +5 de quebra."},
	"tide_anchor":{"name":"Âncora viva","hero":0,"description":"Ao começar o turno com metade ou menos da postura, Duarte recupera 8 de postura."},
	"iron_answer":{"name":"Resposta de ferro","hero":0,"description":"Contra-ataques de Duarte causam +6 de quebra e recuperam 1 alento."},
	"protective_instinct":{"name":"Instinto de guarda","hero":0,"description":"Quando a cobertura de Duarte intercepta um golpe, ele recupera 6 de postura."},

	"sword_eye":{"name":"Fio atento","hero":1,"description":"Ataques de espada pelo flanco contra alvo Exposto causam +4 de quebra."},
	"sure_step":{"name":"Passo certo","hero":1,"description":"Depois de atingir por flanco ou costas, Inês recupera 1 casa de movimento, uma vez por turno."},
	"clean_cut":{"name":"Corte limpo","hero":1,"description":"Um ritmo perfeito prolonga o Sangramento existente até 4 turnos, excepto se a técnica o consumir."},
	"open_vein":{"name":"Ferida certa","hero":1,"description":"Ataques pelo flanco contra alvo já a sangrar ganham +5 dano base."},
	"house_rhythm":{"name":"Ritmo da Ordem","hero":1,"description":"Um ritmo perfeito com espada recupera 5 de postura."},
	"execution_line":{"name":"Linha de execução","hero":1,"description":"Inês recebe +10% dano de vida adicional contra inimigos com postura quebrada."},
	"mist_return":{"name":"Retorno da bruma","hero":1,"description":"Depois de um contra-ataque bem sucedido, Inês recupera 1 alento."}
}

const WEAPON_PASSIVE_LEVELS := {
	"duarte_landing":2,"duarte_hook":5,
	"haft_hand":2,"sword_eye":2,
	"duarte_iron_guard":3,"closed_line":4,"long_reach":5,"tide_anchor":6,
	"iron_answer":8,"protective_instinct":9,
	"sure_step":3,"clean_cut":4,"open_vein":5,"house_rhythm":6,
	"execution_line":8,"mist_return":9
}

# Kept for external code that expects a seven-entry base array.
const SKILLS := [
	{"name":"Ataque básico","cost":0,"power":0,"posture":0,"shape":"single","range":1,"status":"","description":"Definido pela arma de cada herói."},
	{"name":"Técnica I","cost":0,"power":0,"posture":0,"shape":"single","range":1,"status":"","description":"Definida pela arma de cada herói."},
	{"name":"Técnica II","cost":0,"power":0,"posture":0,"shape":"single","range":1,"status":"","description":"Definida pela arma de cada herói."},
	{"name":"Técnica III","cost":0,"power":0,"posture":0,"shape":"single","range":1,"status":"","description":"Definida pela arma de cada herói."},
	{"name":"Técnica IV","cost":0,"power":0,"posture":0,"shape":"single","range":1,"status":"","description":"Definida pela arma de cada herói."},
	{"name":"Respirar","cost":0,"power":0,"posture":0,"shape":"self","range":0,"status":"","description":"+5 alento, +18 postura. Guarda até ao próximo golpe."},
	{"name":"Infusão","cost":0,"power":0,"posture":0,"shape":"self","range":0,"status":"","resource":"hp","restore":65,"description":"Cura até 65 de vida. Selecciona um aliado ao usar a bolsa da campanha."}
]

# Regional attack pressure. Every playable encounter must declare its multiplier.
const ENCOUNTER_POWER := {"prologue_raid":1.0,"training":1.08,"patrol":1.20,"secret":1.25,"boss":1.35,"cove_trial_1":1.20,"cove_trial_2":1.30,"cove_trial_3":1.40,"cove_trial":1.50,"lisbon_pursuit":1.35,"lisbon_fire":1.45,"lisbon_avelar":1.55,"douro_blockade":1.48,"saint_roman":1.55,"stronghold":1.65,"vigia_sentinel":1.70,"vigia_guard":1.80}
const LATE_ENCOUNTER_POWER := {
	"refuge_trial":2.40,"refuge_threat":2.30,
	"ceuta_patrol":1.82,"ceuta_hostages":1.87,"ceuta_depot":1.92,
	"coast_convoy":1.95,"coast_yusuf":2.00,
	"cargo_boarding":1.52,"cargo_signals":1.58,"cargo_return":1.62,
	"storm_escort":2.04,"storm_mate":2.10,
	"final_boarding":2.14,"final_esteban":2.22
}

static func encounter_power(id: String) -> float:
	return float(LATE_ENCOUNTER_POWER.get(id,ENCOUNTER_POWER.get(id,1.0)))

const ENCOUNTERS := {
	"refuge_trial":{"units":[["Eco da Primeira Maré",1900,160,"boss",Vector2i(7,3),26,4],["Memória da guarda",520,100,"defender",Vector2i(5,5),22,3],["Memória do passo",450,90,"duelist",Vector2i(6,1),25,4]],"challenge_units":[["Memória da distância",360,75,"archer",Vector2i(8,7),24,3]],"obstacles":[Vector2i(3,1),Vector2i(3,6)]},
	"refuge_threat":{"units":[["Incendiário do arquivo",460,95,"rogue",Vector2i(7,6),24,3],["Sinaleiro dos perseguidores",440,85,"signaller",Vector2i(7,1),25,3],["Abordador do refúgio",580,105,"boarder",Vector2i(5,3),25,3],["Guarda da passagem",550,110,"defender",Vector2i(6,5),23,3]],"obstacles":[Vector2i(3,1),Vector2i(4,5)]},
	"cargo_boarding":{"units":[["Abordador da amurada",205,55,"boarder",Vector2i(5,3),18,3],["Sinaleiro da escolta",170,42,"signaller",Vector2i(7,4),20,2],["Guarda da carga",190,55,"guard",Vector2i(6,5),16,3]],"obstacles":[Vector2i(4,1),Vector2i(4,6)]},
	"cargo_signals":{"units":[["Sinaleiro do ancoradouro",210,48,"signaller",Vector2i(6,3),20,2],["Abordador do cais",240,60,"boarder",Vector2i(5,4),19,3],["Besteiro dos selos",185,45,"archer",Vector2i(7,1),18,3],["Guarda dos mantimentos",220,62,"defender",Vector2i(6,5),16,2]],"obstacles":[Vector2i(3,1),Vector2i(5,6),Vector2i(8,4)]},
	"cargo_return":{"units":[["Incendiário das cópias",240,56,"guard",Vector2i(7,6),17,2],["Sinaleiro da retaguarda",220,48,"signaller",Vector2i(7,1),20,2],["Abordador das amarras",260,62,"boarder",Vector2i(5,3),19,3],["Guarda da retaguarda",220,58,"guard",Vector2i(6,4),16,3]],"obstacles":[Vector2i(3,1),Vector2i(4,5)]},
	"final_boarding":{"units":[["Contramestre da nau",500,100,"defender",Vector2i(6,3),22,3],["Piqueiro das amarras",380,80,"pikeman",Vector2i(6,6),23,3],["Bombardeiro do paiol",320,70,"bombard",Vector2i(8,0),22,3],["Socorrista contratado",290,62,"medic",Vector2i(8,6),21,3]],"challenge_units":[["Besteiro do livro",290,64,"archer",Vector2i(7,1),24,3]],"obstacles":[Vector2i(3,1),Vector2i(4,5),Vector2i(5,0)]},
	"final_esteban":{"units":[["Esteban de Alarcón",1700,135,"boss",Vector2i(7,3),25,4],["Piqueiro do capitão",380,80,"pikeman",Vector2i(6,6),23,3],["Besteiro das ordens",310,64,"archer",Vector2i(8,0),24,3]],"challenge_units":[["Bombardeiro da fuga",300,65,"bombard",Vector2i(8,7),22,3]],"obstacles":[Vector2i(3,1),Vector2i(4,5),Vector2i(5,0)]},
	"storm_escort":{"units":[["Piqueiro da escolta",360,76,"pikeman",Vector2i(6,3),23,3],["Bombardeiro de abordagem",310,65,"bombard",Vector2i(7,1),22,3],["Socorrista de bordo",280,60,"medic",Vector2i(8,5),21,3],["Duelista da amurada",420,88,"duelist",Vector2i(6,6),23,4]],"challenge_units":[["Besteiro da escolta",280,60,"archer",Vector2i(8,0),24,3]],"obstacles":[Vector2i(3,1),Vector2i(4,5),Vector2i(5,0)]},
	"storm_mate":{"units":[["Imediato de Esteban",1100,120,"boss",Vector2i(7,3),24,4],["Piqueiro da proa",380,82,"pikeman",Vector2i(6,6),23,3],["Bombardeiro do imediato",320,68,"bombard",Vector2i(8,1),22,3],["Socorrista da proa",290,62,"medic",Vector2i(8,6),21,3]],"challenge_units":[["Guarda das cartas",320,72,"defender",Vector2i(6,0),22,3]],"obstacles":[Vector2i(3,1),Vector2i(4,5),Vector2i(5,0)]},
	"coast_convoy":{"units":[["Atirador da represália",310,60,"archer",Vector2i(6,3),24,3],["Guarda da passagem",440,90,"defender",Vector2i(6,6),20,3],["Piqueiro contratado",350,70,"pikeman",Vector2i(7,1),23,4],["Besteiro do desembarque",300,60,"archer",Vector2i(8,6),24,3]],"obstacles":[Vector2i(3,1),Vector2i(4,6),Vector2i(5,0)]},
	"coast_yusuf":{"units":[["Yusuf ibn Rami",1020,110,"duelist",Vector2i(7,3),24,4],["Incendiário da represália",360,70,"rogue",Vector2i(8,1),24,4],["Capitão de Esteban",780,100,"boss",Vector2i(7,6),24,4],["Bombardeiro da torre",310,64,"bombard",Vector2i(8,7),24,3]],"obstacles":[Vector2i(3,1),Vector2i(4,6),Vector2i(5,0)]},
	"ceuta_patrol":{"units":[["Guarda do recibo",430,86,"defender",Vector2i(6,3),19,3],["Besteiro contratado",265,54,"archer",Vector2i(7,1),22,3],["Atirador do cais",270,54,"archer",Vector2i(8,6),22,3],["Piqueiro do pagamento",280,60,"pikeman",Vector2i(7,5),21,4]],"challenge_units":[["Batedor do portão",230,52,"rogue",Vector2i(8,0),22,4]],"obstacles":[Vector2i(3,1),Vector2i(3,6),Vector2i(5,2),Vector2i(5,6)]},
	"ceuta_hostages":{"units":[["Capataz das amarras",510,90,"duelist",Vector2i(6,3),22,4],["Guarda do pátio",390,86,"defender",Vector2i(6,6),18,3],["Besteiro das cordas",290,58,"archer",Vector2i(7,0),23,3],["Atiradora contratada",295,58,"archer",Vector2i(8,5),23,3],["Socorrista contratado",260,56,"medic",Vector2i(7,7),21,4]],"challenge_units":[["Guarda de reforço",250,58,"guard",Vector2i(8,1),20,3]],"obstacles":[Vector2i(3,1),Vector2i(4,5),Vector2i(5,2)]},
	"ceuta_depot":{"units":[["Incendiário do entreposto",310,64,"rogue",Vector2i(6,2),23,4],["Mestre do pagamento",800,100,"boss",Vector2i(7,6),23,4],["Bombardeiro do óleo",300,60,"bombard",Vector2i(8,0),24,3],["Guarda dos registos",420,90,"defender",Vector2i(6,5),19,3]],"challenge_units":[["Atirador do entreposto",270,54,"archer",Vector2i(8,7),23,3]],"obstacles":[Vector2i(3,1),Vector2i(3,5),Vector2i(5,6)]},
	"prologue_raid":{"units":[["Assaltante mascarado",115,42,"guard",Vector2i(6,2),11,3],["Espadachim da bandeira negra",135,48,"duelist",Vector2i(6,5),14,4]],"challenge_units":[["Gancho da bandeira negra",92,34,"rogue",Vector2i(8,3),15,4]],"obstacles":[Vector2i(3,1),Vector2i(4,4),Vector2i(5,6)]},
	"training":{"units":[["Discípulo do cais",140,54,"guard",Vector2i(5,3),10,3]],"obstacles":[Vector2i(3,2),Vector2i(3,6),Vector2i(6,5)]},
	"patrol":{"units":[["Baluarte da Névoa",200,66,"defender",Vector2i(6,2),14,2],["Arqueira da Névoa",145,40,"archer",Vector2i(6,5),16,3],["Duelista da Névoa",185,54,"duelist",Vector2i(7,4),10,4]],"challenge_units":[["Batedor da Névoa",130,38,"rogue",Vector2i(8,7),13,4]],"obstacles":[Vector2i(3,2),Vector2i(4,2),Vector2i(4,5),Vector2i(5,5)]},
	"secret":{"units":[["Vigia do penhasco",255,66,"duelist",Vector2i(6,3),16,4],["Arqueiro errante",180,44,"archer",Vector2i(6,5),11,3]],"challenge_units":[["Aprendiz do vigia",125,38,"guard",Vector2i(8,1),12,3]],"obstacles":[Vector2i(3,1),Vector2i(3,2),Vector2i(5,5),Vector2i(5,6)]},
	"boss":{"units":[["Mestre de Ferro",850,95,"boss",Vector2i(6,3),15,4]],"challenge_units":[["Porta-lâmina do Mestre",235,62,"defender",Vector2i(7,6),14,3]],"obstacles":[Vector2i(3,1),Vector2i(6,1),Vector2i(3,6),Vector2i(6,6)]},
	"cove_trial_1":{"units":[["Sentinela do Lastro",190,62,"defender",Vector2i(6,3),14,2],["Aprendiz do Lastro",105,38,"guard",Vector2i(7,5),13,3],["Flanqueador do Lastro",90,36,"rogue",Vector2i(8,6),16,4],["Arqueira da falésia",80,32,"archer",Vector2i(7,1),16,3],["Arqueiro da doca",80,32,"archer",Vector2i(8,4),15,3]],"challenge_units":[["Escudeiro do Lastro",100,38,"guard",Vector2i(8,0),12,3]],"obstacles":[Vector2i(3,2),Vector2i(5,3),Vector2i(5,6)]},
	"cove_trial_2":{"units":[["Atiradora da Névoa",130,48,"archer",Vector2i(7,1),18,3],["Guarda de linha",160,54,"defender",Vector2i(6,5),14,3],["Batedora da Névoa",110,38,"rogue",Vector2i(8,7),16,4],["Arqueiro da enseada",125,40,"archer",Vector2i(8,3),17,3],["Arqueira da maré",120,38,"archer",Vector2i(7,6),16,3],["Lanceiro da linha",100,38,"pikeman",Vector2i(6,2),13,3]],"challenge_units":[["Vigia da Névoa",100,38,"guard",Vector2i(8,0),13,3]],"obstacles":[Vector2i(3,1),Vector2i(4,3),Vector2i(5,5)]},
	"cove_trial_3":{"units":[["Duelista da Névoa",200,60,"duelist",Vector2i(6,3),17,4],["Marinheiro do Lastro",120,45,"guard",Vector2i(7,5),13,3],["Lanceiro do Lastro",100,40,"pikeman",Vector2i(8,1),15,4],["Arqueira do penhasco",100,36,"archer",Vector2i(7,0),16,3],["Arqueiro da passagem",100,36,"archer",Vector2i(8,2),15,3],["Arqueira do recife",100,36,"archer",Vector2i(7,6),16,3],["Baluarte do Lastro",130,50,"defender",Vector2i(6,6),13,2]],"challenge_units":[["Veterano do Lastro",105,42,"guard",Vector2i(8,7),13,3]],"obstacles":[Vector2i(3,2),Vector2i(4,5),Vector2i(6,5)]},
	"cove_trial":{"units":[["Grão-mestre do Lastro",580,96,"boss",Vector2i(7,3),17,4],["Arqueira de honra",95,38,"archer",Vector2i(7,0),17,3],["Arqueiro da muralha",95,38,"archer",Vector2i(8,1),16,3],["Arqueira do cabo",95,38,"archer",Vector2i(8,4),17,3],["Arqueiro da maré",95,38,"archer",Vector2i(7,6),16,3],["Arqueira do Lastro",95,38,"archer",Vector2i(8,7),17,3]],"challenge_units":[["Porta-lâmina do Lastro",110,42,"guard",Vector2i(6,7),13,3]],"obstacles":[Vector2i(3,1),Vector2i(4,5),Vector2i(6,1),Vector2i(6,6)]},
	"lisbon_pursuit":{"units":[["Mensageiro",230,52,"duelist",Vector2i(5,3),16,2],["Corta-caminho",250,68,"defender",Vector2i(6,6),15,3]],"challenge_units":[["Batedora do Tejo",145,42,"rogue",Vector2i(8,1),18,4]],"obstacles":[Vector2i(3,2),Vector2i(4,2),Vector2i(5,5),Vector2i(6,5)]},
	"lisbon_fire":{"units":[["Incendiário",245,50,"rogue",Vector2i(6,2),17,4],["Besteiro do armazém",215,45,"archer",Vector2i(7,5),19,3],["Guarda comprado",280,72,"defender",Vector2i(6,6),14,3],["Carregador subornado",155,40,"guard",Vector2i(8,7),12,3]],"challenge_units":[["Capanga do cais",140,40,"guard",Vector2i(8,0),11,2]],"obstacles":[Vector2i(3,1),Vector2i(3,4),Vector2i(5,3),Vector2i(5,6)]},
	"lisbon_avelar":{"units":[["Rui de Avelar",620,110,"archer",Vector2i(7,3),19,4],["Besteiro de Avelar",235,48,"archer",Vector2i(7,6),18,3],["Homem de armas",310,78,"defender",Vector2i(6,1),15,3],["Espadachim de Avelar",180,48,"guard",Vector2i(8,5),13,4]],"challenge_units":[["Lanceiro de Avelar",165,46,"pikeman",Vector2i(8,7),14,4]],"obstacles":[Vector2i(3,2),Vector2i(3,5),Vector2i(5,2),Vector2i(5,5)]},
	"douro_blockade":{"units":[["Capitão do bloqueio",410,78,"defender",Vector2i(6,3),16,3],["Arqueira da margem",220,46,"archer",Vector2i(7,1),20,3],["Besteiro do castelo",225,48,"archer",Vector2i(8,6),19,3],["Saqueador do batel",210,50,"rogue",Vector2i(5,5),18,4],["Arqueiro da ponte",205,44,"archer",Vector2i(8,3),18,3],["Piqueiro do cais",240,60,"pikeman",Vector2i(6,6),15,3]],"challenge_units":[["Batedora da margem",180,42,"archer",Vector2i(8,0),20,3]],"obstacles":[Vector2i(3,1),Vector2i(3,6),Vector2i(5,2),Vector2i(5,6)]},
	"saint_roman":{"units":[["Sargento de Esteban",440,82,"duelist",Vector2i(6,3),19,4],["Arqueira da colina",235,48,"archer",Vector2i(7,0),20,3],["Socorrista da capela",190,44,"medic",Vector2i(8,2),19,3],["Besteiro da rua",235,46,"archer",Vector2i(8,6),20,3],["Guarda da praça",310,74,"defender",Vector2i(6,6),15,3],["Rastreador castelhano",205,48,"rogue",Vector2i(7,5),18,4]],"challenge_units":[["Atirador de reforço",190,44,"archer",Vector2i(8,7),20,3]],"obstacles":[Vector2i(3,1),Vector2i(3,5),Vector2i(5,2),Vector2i(5,5)]},
	"stronghold":{"units":[["Catarina",850,96,"boss",Vector2i(7,3),20,4],["Arqueiro da torre",250,50,"archer",Vector2i(7,0),21,3],["Arqueira da ponte",255,50,"archer",Vector2i(8,2),21,3],["Bombardeiro da muralha",220,48,"bombard",Vector2i(8,5),20,3],["Arqueira de Catarina",245,48,"archer",Vector2i(7,7),21,3],["Veterano de Esteban",340,78,"defender",Vector2i(6,6),16,3]],"challenge_units":[["Guarda da torre",225,48,"guard",Vector2i(8,1),16,4]],"obstacles":[Vector2i(3,1),Vector2i(3,6),Vector2i(5,1),Vector2i(5,6)]},
	"vigia_sentinel":{"units":[["Sentinela do ancoradouro",355,78,"defender",Vector2i(6,3),19,3],["Besteiro do cais",245,51,"archer",Vector2i(7,0),21,3],["Arqueira da galeria",250,50,"archer",Vector2i(8,2),21,3],["Rastreador da Vigia",255,56,"rogue",Vector2i(7,6),20,4],["Guarda do arquivo",310,72,"guard",Vector2i(8,5),17,3]],"challenge_units":[["Atirador de Esteban",235,48,"archer",Vector2i(8,7),21,3]],"obstacles":[Vector2i(3,1),Vector2i(3,6),Vector2i(5,2),Vector2i(5,5)]},
	"vigia_guard":{"units":[["Guardião da Rosa",950,108,"boss",Vector2i(7,3),23,4],["Besteiro do arquivo",280,54,"archer",Vector2i(7,0),23,3],["Arqueira do espelho",285,56,"archer",Vector2i(8,2),24,3],["Atirador da galeria",275,54,"archer",Vector2i(8,5),23,3],["Bombardeiro da pólvora",240,48,"bombard",Vector2i(7,7),24,3],["Veterano castelhano",390,84,"defender",Vector2i(6,6),18,3]],"challenge_units":[["Lanceiro de Esteban",245,52,"pikeman",Vector2i(8,1),18,4]],"obstacles":[Vector2i(3,1),Vector2i(3,6),Vector2i(5,1),Vector2i(5,6)]}
}
const LEGACY_XP := [0,80,220,420,700,1100,1550,2050,2600,3300,4150,5150]
# Fixed authored growth for later chapters, never scaled to the player's level.
const ENCOUNTER_GROWTH := {
	"douro_blockade":1.15,"saint_roman":1.18,"stronghold":1.20,
	"vigia_sentinel":1.22,"vigia_guard":1.25,
	"ceuta_patrol":1.30,"ceuta_hostages":1.30,"ceuta_depot":1.35,
	"coast_convoy":1.40,"coast_yusuf":1.42,
	"storm_escort":1.48,"storm_mate":1.50,
	"final_boarding":1.55,"final_esteban":1.60
}
const XP := [0,80,220,420,700,1100,1550,2050,2450,2850,3250,3650,4100,4500,4900,5350,5800,6200,6450,6700]
const MAX_LEVEL := 20
# Saved allocation indices remain Vitalidade, Força, Espírito.
# Keep the preparation preview and the battle stats on the same progression table.
const ATTRIBUTES := [
	{"name":"Vitalidade","gains":{"hp":8,"posture":2},"defense_every":3},
	{"name":"Força","gains":{"attack":2},"break_every":2},
	{"name":"Espírito","gains":{"qi":2,"posture":1}}
]
# Only allocated Espírito grants recovery; equipment reserve does not compound it.
static func spirit_recovery(points: int) -> int:
	return clampi(int(points/4),0,3)

const STAT_DETAILS := {
	"hp":"Vida: dano que podes receber antes de cair.",
	"qi":"Alento: reserva para técnicas; não aumenta o dano.",
	"attack":"Ataque: soma ao dano das técnicas, antes do timing e da posição.",
	"defense":"Defesa: reduz o dano recebido antes dos outros modificadores.",
	"posture":"Postura: resistência à quebra da guarda; não reduz dano à vida.",
	"speed":"Iniciativa: determina a ordem; não concede turnos adicionais.",
	"movement":"Movimento: casas por turno, limitado entre 2 e 5.",
	"break_power":"Quebra: soma à pressão de postura; não aumenta dano à vida."
}
const REWARDS := {
	"refuge_trial":{"xp":180,"gold":160},"refuge_legacy":{"xp":0,"gold":0},"refuge_threat":{"xp":120,"gold":180},"refuge_training":{"xp":0,"gold":0},
	"cargo_boarding":{"xp":70,"gold":65},"cargo_signals":{"xp":90,"gold":80},"cargo_return":{"xp":100,"gold":100},"cargo_weapon":{"xp":0,"gold":0},"cargo_done":{"xp":60,"gold":120},
	"final_boarding":{"xp":200,"gold":240}, "final_book":{"xp":0,"gold":50}, "final_rhythm":{"xp":0,"gold":0}, "final_esteban":{"xp":350,"gold":300}, "final_escape":{"xp":0,"gold":0},
	"storm_escort":{"xp":200,"gold":220}, "storm_mate":{"xp":300,"gold":300}, "storm_balance":{"xp":80,"gold":50}, "storm_promise":{"xp":80,"gold":80},
	"coast_convoy":{"xp":350,"gold":200}, "coast_yusuf":{"xp":450,"gold":250}, "coast_agreement":{"xp":100,"gold":80},
	"ceuta_patrol":{"xp":280,"gold":140}, "ceuta_hostages":{"xp":360,"gold":180},
	"ceuta_depot":{"xp":450,"gold":240}, "ceuta_evidence":{"xp":100,"gold":80},
	"prologue_raid":{"xp":0,"gold":0},
	"training":{"xp":80,"gold":60}, "patrol":{"xp":160,"gold":110},
	"secret":{"xp":140,"gold":100}, "boss":{"xp":200,"gold":160},
	"parcel":{"xp":60,"gold":40}, "quest":{"xp":80,"gold":70},
	"manual":{"xp":40,"gold":0}, "chest":{"xp":40,"gold":50},
	"cove_trial_1":{"xp":25,"gold":25}, "cove_trial_2":{"xp":25,"gold":25}, "cove_trial_3":{"xp":30,"gold":30},
	"cove_trial":{"xp":110,"gold":140}, "cove_parley":{"xp":100,"gold":65}, "cove_cache":{"xp":40,"gold":35},
	"lisbon_pursuit":{"xp":210,"gold":90}, "lisbon_fire":{"xp":280,"gold":120}, "lisbon_avelar":{"xp":380,"gold":180},
	"douro_blockade":{"xp":280,"gold":120},"saint_roman":{"xp":320,"gold":145},"stronghold":{"xp":450,"gold":220},
	"vigia_sentinel":{"xp":180,"gold":150},"vigia_guard":{"xp":300,"gold":300}}

const ITEMS := {
	"order_halberd":{"name":"Alabarda da Primeira Maré","slot":"weapon","price":620,"stats":{"attack":28,"break_power":24,"speed":-2},"role":"Área","icon":"gear_douro_halberd","description":"+28 ataque · +24 quebra · −2 iniciativa. Atingir dois inimigos recupera 2 alento, uma vez por turno.","combat_effect":{"event":"multi_hit","recovery":{"qi":2},"cooldown":0}},
	"order_sword":{"name":"Espada da Porta Aberta","slot":"weapon","price":620,"stats":{"attack":34,"speed":3},"role":"Flancos","icon":"gear_estoque_regio","description":"+34 ataque · +3 iniciativa. Um golpe de flanco recupera 1 alento e dá 1 movimento, uma vez por turno.","combat_effect":{"event":"flank","recovery":{"qi":1},"movement":1,"cooldown":0}},
	"order_mantle":{"name":"Manto da Primeira Maré","slot":"outfit","price":540,"stats":{"hp":90,"defense":11,"posture":20,"speed":-2},"role":"Resistência","icon":"gear_laurel_doublet","description":"+90 vida · +11 defesa · +20 postura · −2 iniciativa. Não controla o visual do legado."},
	"order_sash":{"name":"Traje da Porta Aberta","slot":"outfit","price":540,"stats":{"hp":55,"defense":7,"qi":5,"speed":2},"role":"Mobilidade","icon":"gear_school_doublet","description":"+55 vida · +7 defesa · +5 alento · +2 iniciativa. Não controla o visual do legado."},
	"order_seal":{"name":"Selo dos Dois Caminhos","slot":"accessory","price":400,"stats":{"posture":16,"qi":3},"role":"Dupla","icon":"gear_medal","description":"+16 postura · +3 alento. Ao iniciar o turno junto do parceiro vivo (até 2 casas), recupera 6 vida.","combat_effect":{"event":"turn_start","near_ally":true,"recovery":{"hp":6},"cooldown":0}},
	"order_compass":{"name":"Bússola da Primeira Maré","slot":"accessory","price":400,"stats":{"speed":2,"break_power":8},"role":"Ruptura","icon":"gear_astrolabio_cobre","description":"+2 iniciativa · +8 quebra. Quebrar postura recupera 1 alento, uma vez por turno.","combat_effect":{"event":"break","recovery":{"qi":1},"cooldown":0}},

	"cargo_halberd":{"name":"Alabarda das amarras","slot":"weapon","price":350,"stats":{"attack":19,"break_power":8,"speed":-1},"icon":"gear_douro_halberd","role":"Reposicionamento","description":"+19 ataque · +8 quebra · -1 iniciativa. Puxar um inimigo concede 1 movimento e recupera 1 alento, uma vez por turno. Exige deslocamento real.","combat_effect":{"event":"pull","movement":1,"recovery":{"qi":1},"cooldown":0}},
	"cliff_token":{"name":"Fivela do vigia","slot":"accessory","price":95,"stats":{"speed":1,"posture":-4},"icon":"gear_seal_flank","role":"Reposicionamento","description":"+1 iniciativa · −4 postura. Flanco perfeito: +1 movimento, uma vez por turno próprio.","combat_effect":{"event":"flank_perfect","movement":1,"cooldown":0}},
	"ledger_clasp":{"name":"Fecho dos livros salvos","slot":"accessory","price":170,"stats":{"qi":2,"speed":-1},"icon":"gear_brass_clasp","role":"Recuperação","description":"+2 alento · −1 iniciativa. Respirar: +6 vida e +1 alento extra. Recarga: 1 turno próprio.","combat_effect":{"event":"breathe","recovery":{"hp":6,"qi":1},"cooldown":1}},
	"pilot_knot":{"name":"Nó dos barqueiros","slot":"accessory","price":240,"stats":{"posture":8,"attack":-3},"icon":"gear_rope_bracelet","role":"Parceria","description":"+8 postura · −3 ataque. Consumir Abertura: +1 alento e +1 movimento. Recarga: 1 turno próprio.","combat_effect":{"event":"opening_hit","recovery":{"qi":1},"movement":1,"cooldown":1}},
	"storm_tether":{"name":"Amarra da travessia","slot":"accessory","price":340,"stats":{"qi":3,"speed":-2},"icon":"gear_mafalda_knot","role":"Formação","description":"+3 alento · −2 iniciativa. Início do turno: +4 postura se o outro herói vivo estiver até 2 casas.","combat_effect":{"event":"turn_start","near_ally":true,"recovery":{"posture":4},"cooldown":0}},
	"dock_knife":{"name":"Espada curta de cordoeiro","slot":"weapon","price":65,"description":"+2 iniciativa · +4 ataque.","stats":{"speed":2,"attack":4},"role":"Iniciativa"},
	"oilskin":{"name":"Capa de oleado","slot":"outfit","price":70,"description":"+26 vida · +6 postura · +1 defesa.","stats":{"hp":26,"posture":6,"defense":1},"role":"Resistência"},
	"rope_bracelet":{"name":"Pulseira de cordame","slot":"accessory","price":55,"description":"+12 postura · -1 iniciativa.","stats":{"posture":12,"speed":-1},"role":"Guarda"},
	"practice_blade":{"name":"Alabarda de treino lastrada","slot":"weapon","price":120,"description":"+2 ataque · +10 quebra · +12 postura · -1 iniciativa.","stats":{"attack":2,"break_power":10,"posture":12,"speed":-1},"role":"Controlo"},
	"school_doublet":{"name":"Gibão de prática","slot":"outfit","price":110,"description":"+5 defesa · +16 postura · -2 iniciativa.","stats":{"defense":5,"posture":16,"speed":-2},"role":"Guarda"},
	"balanced_belt":{"name":"Cinto de contrapeso","slot":"accessory","price":95,"description":"+8 quebra · -1 alento.","stats":{"break_power":8,"qi":-1},"role":"Quebra"},
	"river_blade":{"name":"Espada da Ribeira","slot":"weapon","price":155,"description":"+14 ataque · -2 iniciativa · -3 quebra.","stats":{"attack":14,"speed":-2,"break_power":-3},"role":"Ofensiva"},
	"travelling_doublet":{"name":"Gibão de jornada","slot":"outfit","price":145,"description":"+40 vida · +4 alento · -1 iniciativa.","stats":{"hp":40,"qi":4,"speed":-1},"role":"Sustento"},
	"brass_clasp":{"name":"Fecho de latão","slot":"accessory","price":130,"description":"+4 defesa · -4 postura.","stats":{"defense":4,"posture":-4},"role":"Defesa"},
	"heal":{"name":"Infusão de ervas","slot":"item","price":18,"description":"Recupera 30% da vida máxima do alvo (65 a 110). Alcance 2, linha livre; gasta a acção.","stats":{}},
	"qi":{"name":"Tónico de alento","slot":"item","price":22,"description":"Recupera 30% do alento máximo do alvo (6 a 10). Alcance 2, linha livre; gasta a acção.","stats":{}},
	"sword":{"name":"Espada do cais","slot":"weapon","price":30,"description":"Equilíbrio: dano sem sacrificar quebra ou iniciativa.","stats":{"attack":1}},
	"halberd":{"name":"Alabarda do cais","slot":"weapon","price":30,"description":"Haste de guarda: alcança duas casas e pressiona a postura.","stats":{"break_power":1}},
	"breaker":{"name":"Alabarda de lastro","slot":"weapon","price":85,"description":"+2 ataque · +12 quebra.","stats":{"attack":2,"break_power":12}},
	"rapier":{"name":"Estoque de bruma","slot":"weapon","price":90,"description":"+7 ataque · +2 iniciativa · -2 quebra.","stats":{"attack":7,"speed":2,"break_power":-2}},
	"coat":{"name":"Traje do cais","slot":"outfit","price":25,"description":"Equilíbrio: alguma defesa, sem penalizar a iniciativa.","stats":{"defense":1}},
	"mail":{"name":"Gibão reforçado","slot":"outfit","price":80,"description":"+18 vida · +5 defesa · -1 iniciativa.","stats":{"hp":18,"defense":5,"speed":-1}},
	"silk":{"name":"Faixa de viagem","slot":"outfit","price":75,"description":"+4 alento · +2 iniciativa.","stats":{"qi":4,"speed":2}},
	"charm":{"name":"Nó de marinheiro","slot":"accessory","price":25,"description":"Firmeza: mais postura para resistir à quebra da guarda.","stats":{"posture":4}},
	"shell":{"name":"Concha do cabo","slot":"accessory","price":60,"description":"+4 alento.","stats":{"qi":4}},
	"medal":{"name":"Medalhão da armada","slot":"accessory","price":70,"description":"+24 vida.","stats":{"hp":24}},
	"boots":{"name":"Fita dos ventos","slot":"accessory","price":100,"description":"Mobilidade: mais uma casa, mas a guarda fica mais frágil.","stats":{"movement":1,"posture":-6}},
	"crescent":{"name":"Espada crescente da maré","slot":"weapon","price":105,"description":"+8 ataque · -4 quebra · +3 iniciativa.","stats":{"attack":8,"break_power":-4,"speed":3},"role":"Flancos"},
	"ironwood":{"name":"Alabarda de azinho","slot":"weapon","price":95,"description":"+4 ataque · +10 quebra · +8 postura · -2 iniciativa.","stats":{"attack":4,"break_power":10,"posture":8,"speed":-2},"role":"Quebra"},
	"vest_mariner":{"name":"Colete de mareante","slot":"outfit","price":90,"description":"+32 vida · +4 defesa · -1 iniciativa.","stats":{"hp":32,"defense":4,"speed":-1},"role":"Sobrevivência"},
	"vest_silk":{"name":"Casaco de seda azul","slot":"outfit","price":105,"description":"Ritmo: iniciativa e movimento, mas menos defesa.","stats":{"speed":2,"movement":1,"defense":-1},"role":"Iniciativa"},
	"ring_tide":{"name":"Anel de maré","slot":"accessory","price":85,"description":"+6 alento · -2 postura.","stats":{"qi":6,"posture":-2},"role":"Técnicas"},
	"seal_flank":{"name":"Selo do flanco","slot":"accessory","price":115,"description":"+6 ataque · +2 iniciativa · -5 postura.","stats":{"attack":6,"speed":2,"posture":-5},"role":"Execução"}
	,"lastro_sabre":{"name":"Alabarda do Lastro","slot":"weapon","price":185,"description":"+10 ataque · +14 quebra · -1 iniciativa.","stats":{"attack":10,"break_power":14,"speed":-1},"role":"Pressão"}
	,"river_halberd":{"name":"Alabarda da Ribeira","slot":"weapon","price":260,"description":"+8 ataque · +16 quebra · +10 postura · +3 defesa · -2 iniciativa.","stats":{"attack":8,"break_power":16,"posture":10,"defense":3,"speed":-2},"role":"Guarda"}
	,"gibao_lastro":{"name":"Gibão do Lastro","slot":"outfit","price":175,"description":"+40 vida · +6 defesa · +12 postura · -2 iniciativa.","stats":{"hp":40,"defense":6,"posture":12,"speed":-2},"role":"Guarda"}
	,"astrolabio_cobre":{"name":"Astrolábio de cobre","slot":"accessory","price":165,"description":"+5 alento · +2 iniciativa · -3 postura.","stats":{"qi":5,"speed":2,"posture":-3},"role":"Reserva"}
	,"estoque_regio":{"name":"Estoque régio","slot":"weapon","price":285,"description":"+18 ataque · +3 iniciativa · -3 quebra · -4 postura.","stats":{"attack":18,"speed":3,"break_power":-3,"posture":-4},"role":"Execução"}
	,"couraça_da_ribeira":{"name":"Couraça da Ribeira","slot":"outfit","price":270,"description":"+60 vida · +8 defesa · +16 postura · -2 iniciativa · -1 movimento.","stats":{"hp":60,"defense":8,"posture":16,"speed":-2,"movement":-1},"role":"Resistência"}
	,"selo_de_marfil":{"name":"Selo de marfim","slot":"accessory","price":250,"description":"+8 ataque · +5 alento · +20 vida · -5 postura.","stats":{"attack":8,"qi":5,"hp":20,"posture":-5},"role":"Versátil"}
	,"douro_halberd":{"name":"Alabarda do bloqueio","slot":"weapon","price":310,"description":"+16 ataque · +18 quebra · -2 iniciativa.","stats":{"attack":16,"break_power":18,"speed":-2},"role":"Pressão"}
	,"barge_doublet":{"name":"Gibão de barqueiro","slot":"outfit","price":280,"description":"+54 vida · +7 defesa · +14 postura · -1 movimento.","stats":{"hp":54,"defense":7,"posture":14,"movement":-1},"role":"Resistência"}
	,"mafalda_knot":{"name":"Nó de Mafalda","slot":"accessory","price":260,"description":"+6 alento · +32 vida · +2 iniciativa · -6 postura.","stats":{"qi":6,"hp":32,"speed":2,"posture":-6},"role":"Versátil"}
	,"madeira_rapier":{"name":"Lâmina de cedro da Madeira","slot":"weapon","price":355,"description":"+22 ataque · +3 iniciativa · -2 postura.","stats":{"attack":22,"speed":3,"posture":-2},"role":"Ritmo"}
	,"vigia_halberd":{"name":"Alabarda dos canais","slot":"weapon","price":370,"description":"+12 ataque · +24 quebra · +14 postura · -2 iniciativa.","stats":{"attack":12,"break_power":24,"posture":14,"speed":-2},"role":"Controlo"}
	,"laurel_doublet":{"name":"Gibão de loureiro","slot":"outfit","price":345,"description":"+68 vida · +9 defesa · +18 postura · -1 iniciativa · -1 movimento.","stats":{"hp":68,"defense":9,"posture":18,"speed":-1,"movement":-1},"role":"Sobrevivência"}
	,"ceuta_halberd":{"name":"Alabarda da muralha","slot":"weapon","price":480,"stats":{"attack":22,"break_power":22,"speed":-2},"role":"Ruptura","icon":"gear_douro_halberd","description":"+22 ataque · +22 quebra · -2 iniciativa."}
	,"ceuta_sabre":{"name":"Lâmina de aço de Ceuta","slot":"weapon","price":480,"stats":{"attack":28,"speed":3,"posture":-4},"role":"Execução","icon":"gear_estoque_regio","description":"+28 ataque · +3 iniciativa · -4 postura."}
	,"captain_coat":{"name":"Gibão do capitão","slot":"outfit","price":430,"stats":{"hp":76,"defense":10,"posture":16,"speed":-2},"role":"Resistência","icon":"gear_laurel_doublet","description":"+76 vida · +10 defesa · +16 postura · -2 iniciativa."}
	,"compass":{"name":"Bússola da travessia","slot":"accessory","price":390,"stats":{"attack":10,"qi":7,"posture":-6},"role":"Técnicas","icon":"gear_astrolabio_cobre","description":"+10 ataque · +7 alento · -6 postura."}
	,"douro_sword":{"name":"Espada dos barqueiros","slot":"weapon","price":305,"stats":{"attack":19,"break_power":5,"speed":-1},"icon":"gear_estoque_regio","role":"Pressão","description":"+19 ataque · +5 quebra · -1 iniciativa."}
	,"river_silk":{"name":"Casaco da corrente","slot":"outfit","price":275,"stats":{"hp":26,"qi":5,"speed":3,"posture":-6},"icon":"gear_vest_silk","role":"Iniciativa","description":"+26 vida · +5 alento · +3 iniciativa · -6 postura."}
	,"pilot_seal":{"name":"Selo do piloto","slot":"accessory","price":255,"stats":{"attack":7,"break_power":9,"qi":-2},"icon":"gear_seal_flank","role":"Quebra","description":"+7 ataque · +9 quebra · -2 alento."}
	,"laurel_charm":{"name":"Ramo de loureiro","slot":"accessory","price":320,"stats":{"qi":7,"posture":16,"speed":-1},"icon":"gear_ring_tide","role":"Técnicas","description":"+7 alento · +16 postura · -1 iniciativa."}
	,"island_sash":{"name":"Faixa dos levadeiros","slot":"outfit","price":335,"stats":{"hp":36,"qi":6,"movement":1,"defense":-2},"icon":"gear_silk","role":"Mobilidade","description":"+36 vida · +6 alento · +1 movimento · -2 defesa."}
	,"channel_weight":{"name":"Contrapeso dos canais","slot":"accessory","price":325,"stats":{"attack":5,"break_power":14,"speed":-2},"icon":"gear_balanced_belt","role":"Quebra","description":"+5 ataque · +14 quebra · -2 iniciativa."}
	,"ceuta_wrap":{"name":"Manto da sentinela","slot":"outfit","price":420,"stats":{"hp":44,"qi":8,"speed":3,"posture":-8},"icon":"gear_vest_silk","role":"Técnicas","description":"+44 vida · +8 alento · +3 iniciativa · -8 postura."}
	,"wall_badge":{"name":"Insígnia da muralha","slot":"accessory","price":380,"stats":{"hp":36,"defense":4,"posture":18,"speed":-2},"icon":"gear_medal","role":"Guarda","description":"+36 vida · +4 defesa · +18 postura · -2 iniciativa."}
	,"coast_halberd":{"name":"Alabarda da escolta","slot":"weapon","price":500,"stats":{"attack":17,"break_power":29,"posture":14,"speed":-3},"icon":"gear_vigia_halberd","role":"Controlo","description":"+17 ataque · +29 quebra · +14 postura · -3 iniciativa."}
	,"coast_sword":{"name":"Espada da caravana","slot":"weapon","price":500,"stats":{"attack":25,"break_power":12,"speed":1},"icon":"gear_river_blade","role":"Pressão","description":"+25 ataque · +12 quebra · +1 iniciativa."}
	,"coast_coat":{"name":"Casaco da estrada","slot":"outfit","price":450,"stats":{"hp":58,"defense":6,"qi":6,"movement":1,"posture":-10},"icon":"gear_travelling_doublet","role":"Mobilidade","description":"+58 vida · +6 defesa · +6 alento · +1 movimento · -10 postura."}
	,"coast_charm":{"name":"Amuleto da caravana","slot":"accessory","price":405,"stats":{"hp":42,"qi":9,"speed":-1},"icon":"gear_mafalda_knot","role":"Reserva","description":"+42 vida · +9 alento · -1 iniciativa."}
	,"storm_halberd":{"name":"Alabarda do temporal","slot":"weapon","price":520,"stats":{"attack":25,"break_power":18,"speed":1,"posture":-10},"icon":"gear_douro_halberd","role":"Iniciativa","description":"+25 ataque · +18 quebra · +1 iniciativa · -10 postura."}
	,"storm_sword":{"name":"Estoque do relâmpago","slot":"weapon","price":520,"stats":{"attack":27,"speed":5,"break_power":-5,"posture":-6},"icon":"gear_madeira_rapier","role":"Flancos","description":"+27 ataque · +5 iniciativa · -5 quebra · -6 postura."}
	,"storm_coat":{"name":"Gibão de abordagem","slot":"outfit","price":460,"stats":{"hp":64,"defense":8,"posture":28,"qi":-3,"speed":-1},"icon":"gear_gibao_lastro","role":"Guarda","description":"+64 vida · +8 defesa · +28 postura · -3 alento · -1 iniciativa."}
	,"storm_knot":{"name":"Nó do temporal","slot":"accessory","price":420,"stats":{"break_power":16,"posture":20,"speed":-2},"icon":"gear_rope_bracelet","role":"Ruptura","description":"+16 quebra · +20 postura · -2 iniciativa."}
	,"final_halberd":{"name":"Alabarda da alvorada","slot":"weapon","price":550,"stats":{"attack":28,"break_power":26,"speed":-3,"qi":-3},"icon":"gear_river_halberd","role":"Ruptura","description":"+28 ataque · +26 quebra · -3 iniciativa · -3 alento."}
	,"final_sword":{"name":"Lâmina do regresso","slot":"weapon","price":550,"stats":{"attack":32,"speed":2,"break_power":-4,"posture":-8},"icon":"gear_estoque_regio","role":"Execução","description":"+32 ataque · +2 iniciativa · -4 quebra · -8 postura."}
	,"final_coat":{"name":"Casaco da alvorada","slot":"outfit","price":480,"stats":{"hp":50,"defense":7,"qi":9,"speed":2,"posture":-6},"icon":"gear_oilskin","role":"Técnicas","description":"+50 vida · +7 defesa · +9 alento · +2 iniciativa · -6 postura."}
	,"final_seal":{"name":"Selo do regresso","slot":"accessory","price":440,"stats":{"attack":14,"break_power":8,"hp":-24,"posture":-8},"icon":"gear_selo_de_marfil","role":"Execução","description":"+14 ataque · +8 quebra · -24 vida · -8 postura."}
	,"roman_token":{"name":"Laço de São Romão","slot":"accessory","price":290,"stats":{"hp":30,"posture":20,"qi":-2},"icon":"gear_rope_bracelet","role":"Guarda","description":"+30 vida · +20 postura · -2 alento. Interceptar cobertura remove o próprio Sangramento. Recarga: 1 turno próprio.","combat_effect":{"event":"cover","cleanse":true,"cooldown":1}}
	,"vigia_lens":{"name":"Lente da Vigia","slot":"accessory","price":360,"stats":{"qi":8,"speed":3,"defense":-3},"icon":"gear_astrolabio_cobre","role":"Iniciativa","description":"+8 alento · +3 iniciativa · -3 defesa. Consumir Exposto recupera 1 alento. Recarga: 1 turno próprio.","combat_effect":{"event":"exposed_hit","recovery":{"qi":1},"cooldown":1}}
}

const LEGACY_ITEMS := ["order_halberd","order_sword","order_mantle","order_sash","order_seal","order_compass"]
const EXPLORATION_ITEMS := {"cargo_weapon":"cargo_halberd","secret":"cliff_token","lisbon_fire":"ledger_clasp","douro_blockade":"pilot_knot","stronghold":"roman_token","vigia_guard":"vigia_lens","storm_balance":"storm_tether"}

const SHOP := ["heal","qi"]
const STAT_NAMES := {"hp":"Vida","qi":"Alento","attack":"Bónus de ataque","defense":"Defesa","posture":"Postura","speed":"Iniciativa","movement":"Movimento","break_power":"Bónus de quebra"}
const HALBERDS := ["order_halberd","cargo_halberd","halberd","breaker","practice_blade","ironwood","lastro_sabre","river_halberd","douro_halberd","vigia_halberd","ceuta_halberd","coast_halberd","storm_halberd","final_halberd"]

static func weapon_family(id: String) -> String:
	if not ITEMS.has(id) or ITEMS[id].slot!="weapon": return ""
	return "alabarda" if HALBERDS.has(id) else "espada"

static func item_icon_key(id: String) -> String:
	return "item_6" if id=="heal" else ("item_7" if id=="qi" else str(ITEMS[id].get("icon","gear_"+id)))

static func consumable_restore(id: String, maximum: int) -> int:
	return clampi(int(maximum*0.30),65,110) if id=="heal" else clampi(int(maximum*0.30),6,10)

static func can_wield(hero: int, id: String) -> bool:
	return hero in [0,1] and weapon_family(id)==("alabarda" if hero==0 else "espada")

const REGIONAL_SHOP := {
	0:["dock_knife","oilskin","rope_bracelet","breaker","mail","shell"],
	1:["practice_blade","school_doublet","balanced_belt","rapier","silk","boots","crescent","ironwood","vest_mariner","lastro_sabre","gibao_lastro","astrolabio_cobre"],
	2:["river_blade","river_halberd","travelling_doublet","brass_clasp","vest_silk","ring_tide","seal_flank","estoque_regio","couraça_da_ribeira","selo_de_marfil"],
	3:["douro_halberd","barge_doublet","mafalda_knot","douro_sword","river_silk","pilot_seal"],
	5:["madeira_rapier","vigia_halberd","laurel_doublet","laurel_charm","island_sash","channel_weight"],
	8:["ceuta_halberd","ceuta_sabre","captain_coat","compass","ceuta_wrap","wall_badge"],
	9:["coast_halberd","coast_sword","coast_coat","coast_charm"],
	10:["storm_halberd","storm_sword","storm_coat","storm_knot"],
	11:["final_halberd","final_sword","final_coat","final_seal"]}

static func shop_stock(region: int) -> Array:
	var stock:Array=SHOP.duplicate()
	if region in [9,10,11]: stock.append_array(REGIONAL_SHOP[8])
	stock.append_array(REGIONAL_SHOP.get(region,[]))
	return stock

static func sold_here(id: String, region: int = -1) -> bool:
	if region>=0: return shop_stock(region).has(id)
	if SHOP.has(id): return true
	for stock in REGIONAL_SHOP.values():
		if stock.has(id): return true
	return false

static func attribute_effect(index: int) -> String:
	var attribute: Dictionary=ATTRIBUTES[index]
	var names: Dictionary={"hp":"vida","posture":"postura","attack":"ataque","break_power":"quebra","qi":"alento"}
	var effects: Array[String]=[]
	for key in attribute.gains:
		effects.append("+%d %s"%[attribute.gains[key],names[key]])
	if attribute.has("defense_every"): effects.append("+1 defesa / %d pts"%attribute.defense_every)
	if attribute.has("break_every"): effects.append("+1 quebra / %d pts"%attribute.break_every)
	return " · ".join(effects)


static func passive_def(id: String) -> Dictionary:
	return PROC_PASSIVES.get(id,PASSIVES.get(id,{}))

static func passive_exists(id: String) -> bool:
	return PASSIVES.has(id) or PROC_PASSIVES.has(id)

static func technique_rarity(id: int) -> String:
	return TECHNIQUE_RARITY.get(id,"Comum")

static func extra_skill(hero: int, id: int) -> Dictionary:
	if id==7:
		return {"name":"Tónico","cost":0,"power":0,"posture":0,"shape":"friend","range":2,"status":"","resource":"qi","restore":6,"cooldown":0,"effect":"qi","description":"Recupera 30% do alento máximo do alvo (6 a 10). Alcance 2, linha livre; gasta a acção."}
	if id==5:
		return SKILLS[5].duplicate(true)
	if id==6:
		return SKILLS[6].duplicate(true)
	if not HERO_SKILLS.has(hero) or not HERO_SKILLS[hero].has(id):
		return {}
	var definition: Dictionary=HERO_SKILLS[hero][id].duplicate(true)
	if TECHNIQUE_LEVELS.has(id):
		definition.acquisition="Inicial" if TECHNIQUE_LEVELS[id]==1 else "Nível %d da dupla"%TECHNIQUE_LEVELS[id]
		definition.description=definition.description.replace("Exclusiva Lastro. ","").replace("Exclusiva Armada. ","")
	if DISCOVERY_SOURCES.has(id): definition.acquisition=DISCOVERY_SOURCES[id]
	return definition

static func combat_effect_def(id: String) -> Dictionary:
	return ITEMS[id] if ITEMS.has(id) else passive_def(id)

