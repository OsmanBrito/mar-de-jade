extends RefCounted
## Information and preparation requests, independent of canonical Oxx quests.
const ACCOUNT := "C01-LIS-02"
const KIT := "C01-LIS-03"
const DEFINITIONS := {
	ACCOUNT:{"title":"A conta das entregas","summary":"A pescadora recebeu sete caixas, mas o pontão regista cinco. Confere os destinos antes de cobrar uma entrega duplicada.","stages":["dock","kitchen","reconcile","completed"],"objectives":{"dock":"Pergunta ao trabalhador do pontão pelas duas caixas em falta.","kitchen":"Confirma com a vizinha a entrega feita à cozinha.","reconcile":"Volta à pescadora e explica como as sete caixas foram distribuídas.","completed":"Cinco caixas na banca, duas na cozinha. A conta foi acertada; recebeste 8 de ouro."}},
	KIT:{"title":"Uma sacola preparada","summary":"O trabalhador do pontão propôs conferir uma reserva pessoal de curativos e água antes da viagem.","stages":["prepare","completed"],"objectives":{"prepare":"Leva uma ligadura e uma reserva de água ao trabalhador do pontão. O comerciante junto à banca vende ambas.","completed":"Reserva conferida: ligadura e água continuam na tua sacola para a abordagem. Recebeste 3 de ouro pelo auxílio à conferência."}}
}
static func stage(p,id: String) -> String: return p.local_requests.get(id,"")
static func advance(p,id: String,expected: String,next: String) -> bool:
	if not DEFINITIONS.has(id) or stage(p,id)!=expected or not DEFINITIONS[id].stages.has(next): return false
	p.local_requests[id] = next; return true
static func reconcile(p) -> bool:
	if not advance(p,ACCOUNT,"reconcile","completed"): return false
	p.coins = mini(1000000,p.coins+8); return true
static func ready(p) -> bool:
	return int(p.inventory.get("PT-C01",0))>0 and int(p.inventory.get("PT-C03",0))>0
static func inspect_kit(p) -> bool:
	if not ready(p) or not advance(p,KIT,"prepare","completed"): return false
	p.coins = mini(1000000,p.coins+3); return true
static func valid(states: Dictionary) -> bool:
	for id in DEFINITIONS:
		if states.has(id) and (not states[id] is String or not DEFINITIONS[id].stages.has(states[id])): return false
	return true
