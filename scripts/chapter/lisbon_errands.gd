extends RefCounted
## Information and preparation requests, independent of canonical Oxx quests.
const ACCOUNT := "C01-LIS-02"
const KIT := "C01-LIS-03"
const BATEL := "C01-LIS-04"
const DEFINITIONS := {
	ACCOUNT:{"title":"A conta das entregas","summary":"A pescadora recebeu aviso de sete caixas, mas só cinco chegaram à banca. Confere os destinos antes de cobrar uma entrega duplicada.","stages":["dock","kitchen","reconcile","completed"],"objectives":{"dock":"Pergunta no pontão pelas duas caixas ou confere os recibos no armazém, na rua da oficina.","kitchen":"Confirma a entrega com a vizinha ou pelos recibos no armazém, na rua da oficina.","reconcile":"Volta à pescadora e explica como as sete caixas foram distribuídas.","completed":"Cinco caixas na banca, duas na cozinha. A conta foi acertada; recebeste 8 de ouro."}},
	KIT:{"title":"Uma sacola preparada","summary":"O trabalhador do pontão propôs conferir uma reserva pessoal de curativos e água antes da viagem.","stages":["prepare","completed"],"objectives":{"prepare":"Leva uma ligadura e uma reserva de água ao trabalhador do pontão. O comerciante junto à banca vende ambas.","completed":"Reserva conferida: ligadura e água continuam na tua sacola para a abordagem. Recebeste 3 de ouro pelo auxílio à conferência."}},
	BATEL:{"title":"A maré e a amarra","summary":"O marinheiro do pontão poente precisa ajustar a amarra do batel. Observa a água e o cabo antes de decidir.","stages":["observe","solve","completed"],"objectives":{"observe":"Examina a marca de água no poste e a amarra, no pontão poente junto ao estaleiro.","solve":"A água baixou e o cabo ficou tenso. Regula a amarra no extremo do pontão poente.","completed":"Amarra regulada, batel afastado em segurança e 6 de ouro recebidos. O marinheiro recorda a ajuda."}}
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
