extends RefCounted
## Every exterior door is either a real route or a readable closed workplace.
const ROWS := {
	"church":{"at":Vector2(-970,105),"title":"Capela · acesso pelo claustro","speaker":"Portas da casa da Ordem","text":"A porta lateral da igreja está fechada. A visita à capela faz-se pelas arcadas do adro e pelo corredor norte do claustro."},
	"house_west":{"at":Vector2(-20,835),"title":"Moradia · entrada privada","speaker":"Porta da moradia","text":"Esta é uma casa particular. A porta permanece fechada; o caminho público contorna a fachada e continua para o estaleiro e o pontão poente."},
	"house_centre":{"at":Vector2(125,680),"title":"Moradia · entrada privada","speaker":"Porta da moradia","text":"A casa pertence aos moradores da Ribeira. Não há passagem por dentro: a descida pública fica pelo lado nascente da fachada."},
	"warehouse":{"at":Vector2(895,752),"title":"Armazém · serviço no exterior","speaker":"Porta do armazém","text":"O vão serve a entrada de carga. O atendimento é feito na rua: a conferência dos recibos fica na passagem a nascente, junto à rua da oficina. O interior não está aberto à visita."},
	"workshop":{"at":Vector2(1290,856),"title":"Oficina · falar com o oficial","speaker":"Porta da oficina","text":"A porta serve o trabalho da oficina. O oficial atende junto do carro, no terreiro em frente; ferramentas e peças ficam reservadas aos trabalhadores."},
	"gate_west":{"at":Vector2(-840,330),"title":"Cancela · caminho do estaleiro","speaker":"Limite do adro","text":"Para lá da cancela fica o trabalho do cais. As crianças da casa ficam pelo adro e pelo convento nesta saída; Leonor espera junto do banco."},
	"gate_east":{"at":Vector2(600,310),"title":"Cancela · caminho da oficina","speaker":"Limite do adro","text":"Carros e cargas atravessam a rua da oficina. Para as crianças, a cancela permanece fechada. O claustro e a praça continuam acessíveis."},
	"gate_centre":{"at":Vector2(385,580),"title":"Cancela · descida à Ribeira","speaker":"Limite do adro","text":"A descida leva aos carregadores e aos pontões. As crianças só descem acompanhadas; hoje o caminho segue pelo adro, pela casa da Ordem e pelo banco de Leonor."}
}
static func rows(young: bool) -> Dictionary:
	var result := {}
	for id in ROWS:
		if id.begins_with("gate_")!=young and id!="church": continue
		result[id]=ROWS[id]
	return result
static func observe(p,id: String) -> void:
	if ROWS.has(id): p.flags["lisbon_access_"+id]=true
static func observed(p,id: String) -> bool: return p.flags.get("lisbon_access_"+id,false)
