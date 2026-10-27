extends RefCounted
## Optional city talk never advances a request or a canonical story event.
const TITLES := {"workshop":"Oficial da oficina","dock":"Trabalhador do pontão","fisher":"Pescadora","neighbor":"Vizinha","keeper":"Marinheiro do batel"}
const GREETINGS := {
	"workshop":"Cuidado com as aparas. Se precisas de alguma coisa, diz; consigo ouvir-te enquanto trabalho.",
	"dock":"Chega-te a este lado, que aqui não atrapalhamos a carga. O que te traz ao pontão?",
	"fisher":"Se vieste buscar a parte da cozinha, ainda a estou a separar. Se é para conversar, ouço-te na mesma.",
	"neighbor":"És da casa do frei Tomé, não és? Já te tenho visto a passar com o Duarte.",
	"keeper":"Pisa pelo meio das tábuas. A da ponta abana mais do que o meu batel."
}
const WORK := {
	"workshop":["O cais pede-me um carro mais leve e depois carrega-o como se fosse uma casa. Ainda hei de fazer rodas para uma casa, só para lhes mostrar.","Aprendi aqui com o meu pai. Ele dizia que uma roda direita se ouve. Uma torta também, mas nessa altura já vêm todos gritar por ti."],
	"dock":["A primeira semana passei-a a trocar destinos. Agora escrevo tudo. A memória fica muito valente até chegar o segundo barco.","Gostava de ver a Madeira. Ainda não calhou. Entretanto, conheço o cheiro de quase tudo o que vem de lá."],
	"fisher":["De manhã dizem-me que o peixe é pequeno. Ao almoço perguntam por que acabou. Amanhã trago os mesmos e voltamos à conversa.","A vizinha manda-me caldo quando sobra. Eu mando peixe. Nunca nos entendemos sobre quem deve a quem; assim é mais fácil continuar."],
	"neighbor":["O frei Tomé devolve sempre as canecas. Uma vez trouxe uma partida e pediu desculpa como se fosse uma relíquia. Disse-lhe que desse trabalho eu tratava.","Quando o caldo fica bom, ninguém pergunta quem o fez. Quando leva sal a mais, descobrem logo onde moro."],
	"keeper":["Toda a gente quer atravessar depressa. Depois, a meio, pedem-me que abrande para ver Lisboa. Aqui do pontão não lhes chega.","Estão a calafetar um casco no estaleiro. Oiço as pancadas o dia inteiro. Quando param, dou por mim à espera da seguinte."]
}
const REACTIONS := {
	"accident":{"workshop":"Ouvi a carga cair. Suspendi a saída do carro até a passagem ficar segura.","dock":"Há um homem debaixo da carga. Deixem o caminho livre para chegar ajuda.","fisher":"Afastei as caixas da passagem. Agora é preciso abrir espaço para o socorro.","neighbor":"Vou separar panos limpos. Quem vier da casa da Ordem precisa de passagem.","keeper":"O trabalho do batel pode esperar. O caminho do ferido não pode ficar ocupado."},
	"rescue":{"workshop":"Ainda bem que o Tomé chegou a tempo. Ouvi a carga cair daqui; larguei o que tinha na mão.","dock":"A família já o levou. O Tomé tratou-lhe o braço, mas aquele susto não sai tão depressa. Obrigado por teres ficado.","fisher":"Voltei à banca, mas ainda olho para o sítio onde caiu a madeira. Nunca vi tanta gente ficar tão calada.","neighbor":"Os panos do socorro já estão separados. Agora falta dar de comer a quem lá ficou; essas coisas esquecem-se sempre.","keeper":"Disseram-me que saiu com a família. Já estava à espera dessa notícia. Daqui só ouvíamos os gritos."},
	"demonstration":{"workshop":"Subi à praça a tempo de ver a Leonor desarmar o mestre. Quando voltei, estava um cliente à minha espera. Também queria saber como tinha sido.","dock":"Ouvimos a praça daqui. Se aquela gente trabalhasse no pontão, levantava-me as caixas todas só de entusiasmo.","fisher":"Tapei a banca e fui ver a Leonor. Quando dei por mim, já tinha acabado. As pessoas ao meu lado ainda estavam a comentar o primeiro golpe.","neighbor":"Fui à praça um instante. Um homem ao meu lado disse que fazia igual. Quando lhe perguntei por que não ia lá, lembrou-se de um recado.","keeper":"Toda a gente queria contar-me como a Leonor lutou. Ouvi três versões antes do almoço; numa delas, a arma do mestre quase chegava ao Tejo."},
	"recovery":{"workshop":"Já te vejo por aqui outra vez. O trabalho não foge; se o Tomé te mandou ir devagar, por uma vez faz-lhe a vontade.","dock":"Bom ver-te de pé. A carga pesada fica connosco hoje; não precisas de provar nada a uma caixa.","fisher":"Olha quem voltou. A vizinha perguntou por ti. Diz-lhe qualquer coisa quando passares, senão ainda me manda ir buscar-te.","neighbor":"Já passaste pelo Tomé? Então está bem. Senta-te um pouco se precisares; esta mesa também serve para quem não traz trabalho.","keeper":"Hoje vens pelo teu pé. Fico contente. Se vieres só ver a água, também é uma boa razão para descer ao pontão."},
	"return":{"workshop":"Já estás em terra outra vez? Ainda agora te vi a caminho do navio. Esqueceste-te de alguma coisa?","dock":"De volta à Ribeira? Se fores à Botafogo, é pelo pontão nascente. Este está a receber carga.","fisher":"Outra vez por cá? Aproveita enquanto estás em terra. A bordo não vais poder escolher a banca.","neighbor":"Voltaste à cozinha? Ainda bem que não arrumei tudo. Diz-me se te falta alguma coisa antes da viagem.","keeper":"Voltaste ao pontão poente. A Botafogo fica no outro; daqui só te levo de batel."},
	"departure":{"workshop":"Vais na Botafogo? O carro fica por minha conta. Boa viagem até à Madeira.","dock":"A Botafogo já recebe a tripulação. Confere a tua sacola antes de subires.","fisher":"Ouvi dizer que partes para a Madeira. A banca continua aqui quando voltares.","neighbor":"A cozinha já entregou as porções para a partida. Vai com cuidado e lembra-te de comer.","keeper":"A tua partida é no outro pontão. Por aqui o batel fica à espera da próxima maré."}
}
static func event(p) -> String:
	if p.journey.get("kind","")=="port_visit": return "return"
	if p.flags.get("packed",false): return "departure"
	if p.flags.get("recovered",false): return "recovery"
	if p.flags.get("city_leonor_demonstrated",false) or int(p.checkpoint)>=7: return "demonstration"
	if p.flags.get("patient_helped",false): return "rescue"
	if p.flags.get("cargo_freed",false) or p.flags.get("patient_stable",false) or int(p.checkpoint) in [1,2,3]: return "accident"
	return ""
static func introduction(p,id: String) -> String:
	if not TITLES.has(id) or p.flags.get("city_met_"+id,false): return ""
	p.flags["city_met_"+id]=true
	return GREETINGS[id]
static func reply(p,id: String,turn: int) -> String:
	if not WORK.has(id): return ""
	var context := event(p)
	if turn==0 and REACTIONS.has(context): return REACTIONS[context][id]
	var offset := 1 if REACTIONS.has(context) else 0
	var result := consequence(p,id)
	if not result.is_empty():
		if turn==offset: return result
		offset += 1
	return WORK[id][posmod(turn-offset,WORK[id].size())]

static func consequence(p,id: String) -> String:
	# Only completed local work becomes a memory; being in a later story
	# checkpoint does not imply that the player helped these residents.
	match id:
		"workshop":
			if p.local_requests.get("C01-LIS-01","")=="completed": return "A tua cavilha aguentou mais uma carga. E a de reserva continua na caixa; não precisas de perguntar outra vez."
		"fisher":
			if p.local_requests.get("C01-LIS-02","")=="completed": return "Hoje escrevi os dois destinos logo à chegada. Cinco para mim, duas para a cozinha. Não volto a mandar-te atrás de caixas que já entregaram."
		"neighbor":
			if p.local_requests.get("C01-LIS-02","")=="completed": return "A pescadora já me trouxe a conta certa. Ficámos as duas descansadas, graças à tua volta pelo cais."
		"dock":
			if p.local_requests.get("C01-LIS-03","")=="completed": return "Já vimos a tua sacola. Agora guarda-a onde a encontres depressa; no primeiro embarque eu pus a minha debaixo de três sacos."
		"keeper":
			if p.local_requests.get("C01-LIS-04","")=="completed": return "Olha para ele agora. Desce com a água, sem puxar pelo pontão. A amarra ficou bem; poupaste-me uma noite a vir cá espreitar."
	return ""

static func valid_topics(value: Variant) -> bool:
	if not value is Dictionary or value.size()>35: return false
	for key in value:
		if not key is String: return false
		var parts: PackedStringArray=key.split(":")
		if parts.size()!=2 or not TITLES.has(parts[0]) or parts[1] not in ["","accident","rescue","demonstration","recovery","departure","return"]: return false
		var count: Variant=value[key]
		if not (count is int or count is float) or not is_finite(float(count)) or float(count)!=int(count) or count<0 or count>3: return false
	return true
static func take_reply(p,id: String) -> String:
	if not TITLES.has(id): return ""
	var key:=id+":"+event(p)
	var turn:=int(p.city_topics.get(key,0))
	p.city_topics[key]=turn+1 if turn<3 else 2
	return reply(p,id,turn)
