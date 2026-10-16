extends RefCounted
## One source for announced moves and executed effects; no combat-state mutations.
const BOSSES := {
	"refuge_trial":{"normal":"Três ecos da Rosa","skill":"Maré da memória","power":32,"posture":28,"effect":"pressure","hint":"Maré da memória: 5 tempos e forte pressão. Sai das áreas anunciadas; pune o eco quando ficar Exposto."},
	"boss":{"normal":"Talho de ferro","skill":"Martelo da guarda","power":27,"posture":24,"effect":"pressure","hint":"Martelo: +10 pressão de postura. Guarda ou apara; castiga a exposição após o golpe de área."},
	"cove_trial":{"normal":"Palma do Lastro","skill":"Passo da ressaca","power":27,"posture":19,"effect":"push","hint":"Passo da ressaca empurra 1 casa. Guarda, cobertura ou defesa perfeita impedem o empurrão."},
	"stronghold":{"normal":"Estocada de comando","skill":"Guarda da capitã","power":30,"posture":23,"effect":"guard","hint":"Recompõe a guarda frontal após a técnica. Flanqueia ou quebra a postura."},
	"vigia_guard":{"normal":"Ponta da Rosa","skill":"Haste do espelho","power":30,"posture":30,"effect":"pressure","hint":"Haste: alcance 2 com linha livre. Técnica: +10 pressão de postura. Flanqueia ou usa obstáculos."},
	"ceuta_depot":{"normal":"Corte do cobrador","skill":"Cobrança de alento","power":31,"posture":23,"effect":"drain","hint":"Cobrança retira 2 de alento se causar dano. Guarda, cobertura ou defesa perfeita evitam a perda."},
	"coast_yusuf":{"normal":"Talho do capitão","skill":"Ordem de avanço","power":31,"posture":26,"effect":"push","hint":"Ordem de avanço empurra 1 casa. Guarda ou apara e mantém livre a retirada dos civis."},
	"storm_mate":{"normal":"Talho da amurada","skill":"Abalroamento","power":31,"posture":27,"effect":"push","hint":"Abalroamento e a vaga empurram 1 casa. Guarda ou cobertura impedem o empurrão."},
	"final_esteban":{"normal":"Fio de Alarcón","skill":"Assinatura de sangue","power":36,"posture":28,"effect":"bleed","hint":"Hemorragia por 2 turnos se ferir. Guarda, cobertura ou defesa perfeita evitam-na."}
}
const SPECIALISTS := {
	"douro_blockade":{"Besteiro do castelo":"interrupt"},
	"saint_roman":{"Besteiro da rua":"interrupt"},
	"vigia_guard":{"Atirador da galeria":"interrupt"},
	"coast_convoy":{"Atirador da represália":"interrupt"},
	"final_esteban":{"Besteiro das ordens":"interrupt"}
}
static func setup(u: Dictionary, encounter: String) -> void:
	if SPECIALISTS.get(encounter,{}).get(u.name,"")=="interrupt": u.disrupts_qi=true

static func is_yusuf(u: Dictionary) -> bool:
	return u.name=="Yusuf ibn Rami"

static func reach(u: Dictionary, encounter: String) -> int:
	return 2 if u.kind=="boss" and encounter=="vigia_guard" else 1

static func move(u: Dictionary, encounter: String, turn: int) -> Dictionary:
	if is_yusuf(u):
		return {"name":"Fio da represália","power":31,"posture":23,"bleed":true,"push_on_hit":true,"defense_beats":4} if turn%3==0 else {"name":"Corte de Yusuf","power":24,"posture":16,"defense_beats":3}
	if u.kind!="boss": return {}
	var d: Dictionary=BOSSES.get(encounter,BOSSES.boss)
	var special:=turn%4==0
	var result: Dictionary={"name":d.skill if special else d.normal,"power":d.power,"posture":d.posture,"defense_beats":4 if special else 3}
	if encounter=="refuge_trial" and special: result.defense_beats=5
	if special:
		match d.effect:
			"pressure": result.posture+=10
			"push": result.push_on_hit=true
			"guard": result.guard_after=true
			"drain": result.qi_drain=2
			"bleed": result.bleed=true
	return result

static func intent_hint(u: Dictionary, encounter: String, turn: int) -> String:
	if turn%4==0: return BOSSES.get(encounter,BOSSES.boss).hint
	if encounter=="vigia_guard": return "Ataque normal: 3 tempos; alcance 2 com linha livre. Flanqueia ou usa obstáculos."
	return "Ataque normal: 3 tempos. Apara pela frente ou prepara guarda e cobertura."

