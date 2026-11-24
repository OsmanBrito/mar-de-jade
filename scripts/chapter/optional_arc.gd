extends RefCounted
## The first arc has four quay requests and the house service in two ages.
const FOREST := {
	"hunt_departure":{"together":{"title":"A promessa de seguir juntos","text":"Combinaste com Leonor que seguiriam juntos e avisariam antes de se separar."},"signs":{"title":"Sinais no caminho","text":"Combinaste com Leonor deixar uma pedra virada e um ramo como sinais para encontrar o caminho de volta."}},
	"hunt_bridge":{"lead":{"title":"Testar a passagem","text":"Escolheste testar a ponte primeiro, enquanto Leonor segurava a outra ponta."},"trust":{"title":"Confiar na passagem","text":"Escolheste seguir os passos de Leonor na ponte e atravessar pelo trajeto que ela indicou."}},
	"hunt_deer":{"observe":{"title":"Observar o corço","text":"Escolheste observar o corço sem o assustar; ele atravessou a luz e seguiu entre as árvores."},"approach":{"title":"Aproximar-se do corço","text":"Escolheste aproximar-te do corço com Leonor; o animal afastou-se."}}
}
static func memories(p) -> Array:
	var rows:Array=[]
	for key in FOREST:
		var value:String=p.choices.get(key,"")
		if FOREST[key].has(value):
			var row:Dictionary=FOREST[key][value].duplicate()
			row.id="memory:"+key;rows.append(row)
	return rows
static func recall(p,id:String) -> Array:
	var choice:String=p.choices.get("hunt_bridge","")
	if id=="workshop" and choice in ["lead","trust"]:
		return [["Herói","Quando era criança, "+("testei a ponte enquanto a Leonor segurava a outra ponta." if choice=="lead" else "segui os passos da Leonor numa ponte estreita.")],["Oficial da oficina","Aqui também combinamos os movimentos antes de mexer na carga. Quem segura o apoio precisa saber quando o outro vai encaixar a peça."]]
	choice=p.choices.get("hunt_departure","")
	if id=="keeper" and choice in ["together","signs"]:
		return [["Herói","Na floresta, combinei com a Leonor que "+("ninguém se afastaria sem avisar." if choice=="together" else "deixaríamos sinais para encontrar o caminho de volta.")],["Marinheiro do batel","No pontão fazemos o mesmo com a voz e com o cabo: combinamos o que vai acontecer antes de soltar a amarra."]]
	choice=p.choices.get("hunt_deer","")
	if id=="fisher" and choice in ["observe","approach"]:
		return [["Herói","Lembro-me de um corço que encontrámos: "+("ficámos quietos e pudemos vê-lo passar." if choice=="observe" else "tentámos chegar mais perto e ele afastou-se.")],["Pescadora","Às vezes vale esperar e olhar antes de agir. "+("Foi por isso que conferimos os destinos das caixas antes de cobrar outra entrega." if preload("res://scripts/chapter/lisbon_errands.gd").stage(p,"C01-LIS-02")=="completed" else "É por isso que quero conferir os destinos das caixas antes de cobrar outra entrega.")]]
	return []
static func pending(p) -> Array[String]:
	var titles:Array[String]=[]
	if preload("res://scripts/chapter/order_campaign.gd").cargo_stage(p) not in ["","done"]:titles.append("A carga da Ordem")
	if preload("res://scripts/city/order_house_hub.gd").meal_stage(p) in ["asked","prepared"]:titles.append("A mesa de quem fica")
	var house=preload("res://scripts/city/house_life.gd")
	if house.stage(p,false) not in ["","done"]:titles.append("A água da casa")
	var cart=preload("res://scripts/chapter/local_request_state.gd")
	if cart.stage(p) not in ["","completed"]:titles.append(cart.definition().title)
	var errands=preload("res://scripts/chapter/lisbon_errands.gd")
	for id in errands.DEFINITIONS:
		if errands.stage(p,id) not in ["","completed"]:titles.append(errands.DEFINITIONS[id].title)
	return titles
static func boarding(p) -> String:
	var titles:=pending(p)
	var text:="Estes pedidos são opcionais. Depois de partir, só poderás continuá-los quando estiveres de novo em Lisboa; o progresso fica guardado."
	if not titles.is_empty():text="Por concluir: "+", ".join(titles)+".\n\n"+text
	return text
static func availability(p) -> String:
	if p.completed and p.journey.get("kind","")!="port_visit":return "Os pedidos de Lisboa aguardam o teu regresso a terra, atracado em Lisboa. O progresso fica guardado."
	if p.flags.get("injured",false):return "Os pedidos podem esperar pela tua recuperação. Não há prazo durante esta pausa."
	if not p.flags.get("patient_helped",false):return "A casa da Ordem tem uma ajuda opcional. Os pedidos da Ribeira abrem depois do socorro."
	return "Explora os postos da Ribeira: oficina, banca de peixe, trabalhador do pontão e marinheiro do pontão poente. A reserva pessoal é conferida depois da recuperação. Os pedidos são opcionais e não têm prazo enquanto exploras Lisboa."
