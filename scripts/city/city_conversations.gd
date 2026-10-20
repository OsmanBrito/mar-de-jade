extends RefCounted
## Optional city talk never advances a request or a canonical story event.
const TITLES := {"workshop":"Oficial da oficina","dock":"Trabalhador do pontão","fisher":"Pescadora","neighbor":"Vizinha","keeper":"Marinheiro do batel"}
const GREETINGS := {
	"workshop":"Sou o oficial desta oficina. Cuido dos eixos e dos carros que levam a carga.",
	"dock":"Trabalho neste pontão. Confiro o que chega antes de mandar cada carga para o seu destino.",
	"fisher":"É nesta banca que separo o peixe da venda e o que segue para a cozinha.",
	"neighbor":"Ajudo na cozinha da Ribeira. Recebo as porções e devolvo as canecas limpas.",
	"keeper":"Fico com o batel do pontão poente. A água muda; o trabalho da amarra acompanha-a."
}
const WORK := {
	"workshop":["Antes de dar o eixo por pronto, confiro a folga e a cavilha. Um carro mal apoiado ocupa a rua inteira.","As aparas ficam deste lado da oficina. A passagem da carga tem de ficar livre."],
	"dock":["Primeiro conto as caixas; depois confiro o destino. Duas entregas diferentes podem vir no mesmo lote.","Quando o pontão aperta, espero que o outro carregador passe. Não vale ganhar um passo e derrubar a carga."],
	"fisher":["Separo o peixe à sombra e deixo livre o lado da banca por onde chegam as caixas.","A parte da cozinha sai antes da venda. No fim, confiro os dois destinos no registo."],
	"neighbor":["Agora separo as porções; depois recolho a louça. As canecas regressam por este lado.","O caldo espera junto da cozinha. A passagem entre a banca e a mesa fica livre para quem o leva."],
	"keeper":["Confiro o cabo junto do cabeço e volto a olhar para a linha de água. A maré não espera por nós.","O estaleiro fica atrás de mim; deixo o centro do pontão livre para quem traz peças."]
}
const REACTIONS := {
	"accident":{"workshop":"Ouvi a carga cair. Suspendi a saída do carro até a passagem ficar segura.","dock":"Há um homem debaixo da carga. Deixem o caminho livre para chegar ajuda.","fisher":"Afastei as caixas da passagem. Agora é preciso abrir espaço para o socorro.","neighbor":"Vou separar panos limpos. Quem vier da casa da Ordem precisa de passagem.","keeper":"O trabalho do batel pode esperar. O caminho do ferido não pode ficar ocupado."},
	"rescue":{"workshop":"Vi como seguraram a carga para o Tomé chegar ao ferido. É trabalho para braços combinados.","dock":"O Tomé tratou do homem e a família levou-o. Já podemos receber a carga por este lado.","fisher":"O ferido saiu acompanhado. Voltei a separar as caixas depois de limparem a passagem.","neighbor":"Separei os panos do socorro dos que usamos na cozinha. O ferido seguiu com a família.","keeper":"Soube que o homem saiu acompanhado. A rua ficou livre outra vez."},
	"demonstration":{"workshop":"Vi a demonstração da Leonor na praça. Recolhi as peças para ninguém tropeçar à volta.","dock":"Daqui ouvi a praça parar para ver a Leonor. Agora cada qual volta ao seu posto.","fisher":"Fui à beira da praça ver a Leonor. Deixei a banca tapada antes de subir.","neighbor":"Vi a Leonor na praça. Voltei a tempo de manter a refeição quente.","keeper":"A demonstração trouxe gente à praça. Mantive o pontão livre para os que voltavam ao cais."},
	"return":{"workshop":"Voltaste a terra? O carro já está ao serviço; por aqui continuamos a preparar a próxima carga.","dock":"Já conheces a rotina do navio. Se vais voltar a bordo, deixa livre o caminho da carga.","fisher":"Voltaste à Ribeira. A banca continua no mesmo sítio; hoje estou a separar a próxima entrega.","neighbor":"Bom ver-te de volta à cozinha da Ribeira. As canecas ainda regressam por este lado.","keeper":"Voltaste ao pontão poente. O teu navio fica no outro; este batel continua preso à sua amarra."},
	"departure":{"workshop":"Vais na Botafogo? O carro fica por minha conta. Boa viagem até à Madeira.","dock":"A Botafogo já recebe a tripulação. Confere a tua sacola antes de subires.","fisher":"Ouvi dizer que partes para a Madeira. A banca continua aqui quando voltares.","neighbor":"A cozinha já entregou as porções para a partida. Vai com cuidado e lembra-te de comer.","keeper":"A tua partida é no outro pontão. Por aqui o batel fica à espera da próxima maré."}
}
static func event(p) -> String:
	if p.journey.get("kind","")=="port_visit": return "return"
	if p.flags.get("packed",false): return "departure"
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
	return WORK[id][posmod(turn-(1 if REACTIONS.has(context) else 0),WORK[id].size())]

static func valid_topics(value: Variant) -> bool:
	if not value is Dictionary or value.size()>30: return false
	for key in value:
		if not key is String: return false
		var parts: PackedStringArray=key.split(":")
		if parts.size()!=2 or not TITLES.has(parts[0]) or parts[1] not in ["","accident","rescue","demonstration","departure","return"]: return false
		var count: Variant=value[key]
		if not (count is int or count is float) or not is_finite(float(count)) or float(count)!=int(count) or count<0 or count>3: return false
	return true
static func take_reply(p,id: String) -> String:
	if not TITLES.has(id): return ""
	var key:=id+":"+event(p)
	var turn:=int(p.city_topics.get(key,0))
	p.city_topics[key]=turn+1 if turn<3 else 2
	return reply(p,id,turn)
