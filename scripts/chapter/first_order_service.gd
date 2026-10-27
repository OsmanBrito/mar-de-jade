extends RefCounted
## One authoritative campaign state; this introduction never grants repeat rewards.
const Requests = preload("res://scripts/chapter/local_request_state.gd")
const Items = preload("res://scripts/chapter/player_items.gd")
const SUPPLIES := {
	"protection":{"label":"Proteção · gibão reforçado e ligadura","items":{"PT-V01":1,"PT-C01":1},"outfit":"PT-V01","text":"Gibão: +12 vida máxima e +2 proteção. Ligadura: recupera 25 de vida quando usada; não cura ferimentos da história."},
	"endurance":{"label":"Viagem · capa e reserva de água","items":{"PT-V02":1,"PT-C03":1},"outfit":"PT-V02","text":"Capa: +8 vida máxima e +6 postura. Água: recupera 5 de alento quando usada. Aumentar máximos não recupera os recursos atuais."}
}
static func intro(styles: Dictionary) -> Array:
	return [
		{"type":"line","speaker":"Duarte","text":"Hoje ficas comigo no serviço da Ordem. Antes de descermos à Ribeira, preciso de saber com que pode contar a enfermaria."},
		{"type":"line","speaker":"Herói","text":"O que queres que veja?"},
		{"type":"line","speaker":"Duarte","text":"Panos e água limpa. Confere o que há e vem dar-me conta. Se faltar alguma coisa, tratamos disso antes de sair."},
		{"type":"line","speaker":"Tomé","text":"Primeiro vens escolher uma arma. Ensino-te o fundamento e experimentas no pátio, se quiseres. Não te mando para o cais de mãos vazias."},
		styles.duplicate(true),{"type":"order_supply"},
		{"type":"line","speaker":"Duarte","text":"Entra pela portaria e segue pelo lado nascente do claustro. Os panos estão junto das bacias. Espero-te aqui no pátio."},
		{"type":"order_check"},{"type":"order_report"},
		{"type":"line","speaker":"Duarte","text":"Muito bem. Já sabemos o que podemos levar da casa. Agora vem comigo à Ribeira; quero ouvir de quem lá trabalha o que está a fazer falta."}
	]
static func grant_supply(p,key: String) -> bool:
	if not SUPPLIES.has(key) or p.flags.get("order_kit_received",false): return false
	var row: Dictionary = SUPPLIES[key]
	for id in row.items: p.inventory[id] = mini(999,int(p.inventory.get(id,0))+int(row.items[id]))
	p.equipment.outfit = row.outfit
	p.choices.order_supply = key; p.flags.order_kit_received = true
	Items.clamp_vitals(p)
	return true
static func current(p) -> String:
	if not p.flags.get("order_intro_started",false): return ""
	if not p.flags.get("order_kit_received",false): return "Primeiro serviço da Ordem · escolhe a arma com Tomé e uma reserva de serviço com Duarte."
	if not p.flags.get("order_check_done",false): return "Primeiro serviço da Ordem · entra na casa pela portaria, segue à enfermaria no lado nascente do claustro e confere os panos junto das bacias."
	if not p.flags.get("order_reported",false): return "Primeiro serviço da Ordem · volta ao pátio exterior e apresenta a Duarte o que conferiste."
	return "Primeiro serviço da Ordem · reserva conferida e relato entregue a Duarte."
static func notes(p) -> Array:
	if not p.flags.get("order_intro_started",false): return []
	var text := current(p)
	if p.flags.get("order_reported",false): text += " A casa de Lisboa mantém acolhimento, enfermaria e apoio ao porto. Duarte acompanha o serviço; Tomé ensina e presta o atendimento. Escolheste conferir primeiro "+("a água limpa." if p.choices.get("order_service","")=="water" else "a separação dos panos.")
	return [{"id":"order:first_service","title":"Ordem de Cristo · O primeiro serviço da casa","text":text}]
static func supply(d) -> void:
	var p = d.get_node("/root/ChapterProgress")
	d.phase = "order_supply"; d._lock_player(true); d._clear_options(); d.options_box.show(); d.view.panel.show(); d.view.next_button.hide()
	d.view.speaker.text = "Duarte · Reserva da Ordem"
	d.view.body.text = "A casa cede uma reserva para o serviço, uma única vez. Escolhe pelo uso que pretendes dar-lhe. O traje escolhido é equipado; as provisões ficam na sacola.\n\n"
	if not p.flags.get("order_kit_received",false):
		for key in SUPPLIES:
			d.view.body.text += SUPPLIES[key].label+"\n"+SUPPLIES[key].text+"\n\n"
			d._option(SUPPLIES[key].label,func():
				if d.paused: return
				if grant_supply(p,key): supply(d))
	else:
		d.view.body.text += "Reserva recebida: "+SUPPLIES[p.choices.get("order_supply","protection")].label+".\n\nConfere as técnicas preparadas e os itens antes de sair. Não precisas consumir nada agora."
		d._option("Preparar técnicas · seis vagas ativas",func(): d._menu("Evolução"))
		d._option("Conferir equipamento e sacola",func(): d._menu("Equipamento"))
		d._option("Pronto · ir à enfermaria",func():
			if d.paused: return
			p.flags.order_prepared = true
			d.phase = "dialogue"; d._clear_options(); d.advance())
	d.options_box.get_child(0).grab_focus()
static func inspect(d) -> void:
	d.phase = "order_inspection"; d._lock_player(true); d._clear_options(); d.options_box.show(); d.view.panel.show(); d.view.next_button.hide()
	d.view.speaker.text = "Ajudante da enfermaria · Reserva de serviço"
	d.view.body.text = "Os panos usados voltaram da manhã; a água limpa está na bacia coberta. Antes de levar material ao cais, verifica ambos e explica o que deve ficar separado. Por onde começas?"
	d._option("Começar pela água limpa; depois conferir os panos",func(): finish_check(d,"water"))
	d._option("Começar pelos panos; depois conferir a água",func(): finish_check(d,"linen"))
	d.options_box.get_child(0).grab_focus()
static func finish_check(d,key: String) -> void:
	var p = d.get_node("/root/ChapterProgress")
	if d.paused or d.phase!="order_inspection" or not d.routes.active or d.routes.state.kind!="order_check" or not d.routes.near(d.routes.goal): return
	p.flags.order_check_done = true; p.choices.order_service = key
	p.flags.convent_read_water = true; p.flags.convent_read_linen = true
	# The new main service fulfils the adult house review; do not offer the same chore twice.
	p.flags.house_adult_review = true; p.flags.house_adult_done = true
	p.flags["convent_read_"+key] = true
	d.routes.arrive_order()
static func help_offer(d) -> void:
	var p = d.get_node("/root/ChapterProgress")
	d.phase = "order_offer"; d._lock_player(true); d._clear_options(); d.options_box.show(); d.view.panel.show(); d.view.next_button.hide()
	d.view.speaker.text = "Duarte · Um pedido da casa na Ribeira"
	d.view.body.text = "O oficial da oficina pediu-me uma mão com o carro. É o que traz material à casa; ficou com uma roda presa. Queres ir comigo ver o que se passa?\n\nPodemos ajudar agora ou ir buscar a refeição. O pedido continua disponível para depois."
	d._option("Ajudar na oficina · acompanhar o pedido",func():
		if d.paused: return
		p.flags.order_help_offered = true
		p.flags.order_help_guided = true
		d.routes.begin("order_help",3))
	d._option("Mais tarde · continuar a missão com Duarte",func():
		if d.paused: return
		p.flags.order_help_offered = true
		d.phase = "dialogue"; d._clear_options(); d.advance())
	d.options_box.get_child(0).grab_focus()
static func help_target(d) -> Dictionary:
	var p = d.get_node("/root/ChapterProgress")
	var id: String = {"":"workshop","inspect":"cart","parts":"dock","fit":"cart","return":"workshop"}.get(Requests.stage(p),"")
	if id.is_empty(): return {"id":"duarte","at":d.routes.goal}
	return {"id":id,"at":d.harbor.city.approach(id)}
static func help_objective(p) -> String:
	var stage := Requests.stage(p)
	if stage=="": return "Pedido acompanhado · A roda presa: fala com o oficial da oficina, à porta da oficina na Ribeira. E / A inicia a conversa."
	if stage=="completed": return "Pedido concluído · regressa a Duarte junto à passagem para o pátio e conta o resultado."
	return "Pedido acompanhado · A roda presa: "+Requests.objective(p)+" · J: rever o pedido."
