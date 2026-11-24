extends RefCounted
## Introductory command aliases and full Medida catalogue presentation. Command IDs are not catalogue IDs.
const ACTION := 100
const IDS := {"ES":"ES09","LA":"LA09","MC":"MC09","PU":"PU09","FO":"FO10"}
static var NAMES: Dictionary = all_names()
const INTRO_NAMES := {"ES09":"Guarda Cruzada","LA09":"Ponta e Calcanhar","MC09":"Talho de Passagem","PU09":"Passo de Lado","FO10":"Disparo de Guarda Baixa"}
static var COSTS: Dictionary = all_costs()
const INTRO_COSTS := {"ES09":7,"LA09":7,"MC09":8,"PU09":7,"FO10":9}
static var TEXT: Dictionary = all_text()
const INTRO_TEXT := {
	"ES09":"Protege a frente e o lado direito: reduz em 30% o primeiro golpe físico elegível até ao próximo turno. Sem dano ou recuperação de alento.",
	"LA09":"Ataca a até duas casas e dá um passo lateral após o golpe. Destino livre obrigatório; o ataque usa a posição inicial.",
	"MC09":"Ataca em contacto e dá um passo lateral depois. O primeiro golpe vindo da antiga frente causa +10% residual até ao próximo turno.",
	"PU09":"Move uma casa livre com o orçamento de movimento e protege em 20% o primeiro golpe físico da antiga frente. Sem ataque, teleporte ou alento recuperado.",
	"FO10":"Dispara a até três casas. Bom/Perfeito desarma um inimigo comum de arma física: a próxima ação dele recompõe a pega. Chefe: próximo ataque físico -10%. Não afeta animais ou projeções de cultivo."
}
static func definition(style: String,base: Dictionary) -> Dictionary:
	var id: String=IDS[style]
	var d: Dictionary=base.duplicate(true)
	d.content_id=id;d.name=NAMES[id];d.description=TEXT[id];d.cost=COSTS[id];d.uses_opening=false
	d.shape="single";d.range=2 if style=="LA" else 3 if style=="FO" else 1
	d.power={"ES":0,"LA":17,"MC":27,"PU":0,"FO":18}[style]
	d.posture=20 if style=="MC" else 16;d.effect="ranged" if style=="FO" else "cut"
	if style=="ES":d.shape="self";d.range=0;d.effect="brace"
	if style=="PU":d.shape="leap";d.effect="brace";d.description+=" A aterragem precisa de trajeto livre."
	return d
static func eligible_weapon(u: Dictionary) -> bool:
	return u.team==1 and bool(u.get("physical_weapon",true)) and u.kind in ["sailor","guard","pirate","boarder","defender","archer","pikeman","duelist","boss","raider","tome","leonor","captain","enemy","fighter"]
static func physical_attack(attack: Dictionary) -> bool:
	return bool(attack.get("physical",attack.get("kind","") in ["attack","ranged","heavy","contact"])) and int(attack.get("power",0))>0

static func all_names() -> Dictionary:
	var result: Dictionary=INTRO_NAMES.duplicate()
	for id in preload("res://scripts/chapter/order_techniques.gd").rows(): result[id]=preload("res://scripts/chapter/order_techniques.gd").rows()[id].name
	return result
static func all_costs() -> Dictionary:
	var result: Dictionary={}
	for id in preload("res://scripts/chapter/order_techniques.gd").rows(): result[id]=preload("res://scripts/chapter/order_techniques.gd").rows()[id].cost
	return result
static func all_text() -> Dictionary:
	var result: Dictionary=INTRO_TEXT.duplicate()
	for id in preload("res://scripts/chapter/order_techniques.gd").rows():
		if result.has(id): continue
		var r: Dictionary=preload("res://scripts/chapter/order_techniques.gd").rows()[id]
		result[id]=r.effect+" "+r.limit
	return result
