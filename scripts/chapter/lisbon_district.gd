extends RefCounted
## Original local activities: observe and act at the pier, or verify a receipt.
const Errands = preload("res://scripts/chapter/lisbon_errands.gd")
const TARGETS := {
	"keeper":{"node":"MarinheiroDoBatel","title":"Marinheiro do batel","at":Vector2(-430,1040),"approach":Vector2(-465,1055)},
	"tide":{"node":"MarcaDaMare","title":"Marca de água no poste","at":Vector2(-535,1140),"approach":Vector2(-493,1140)},
	"mooring":{"node":"AmarraDoBatel","title":"Amarra do batel","at":Vector2(-491,1200),"approach":Vector2(-485,1185)},
	"manifest":{"node":"RegistoDoArmazem","title":"Registo das entregas","at":Vector2(1700,610),"approach":Vector2(1645,650)}
}
const NOTES := {
	"lisbon_tide_read":{"title":"A marca da maré","text":"O poste tem uma faixa húmida acima da água atual. Quando a água baixa, o batel desce com ela; a amarra precisa acompanhar esse movimento."},
	"lisbon_rope_read":{"title":"O cabo do batel","text":"O cabo está esticado entre o pontão e o batel. O desgaste junto ao cabeço mostra onde a tensão se concentra. Uma amarra segura conserva folga para a maré."},
	"lisbon_manifest_read":{"title":"Dois destinos na mesma entrega","text":"O registo do armazém confirma sete caixas descarregadas: cinco para a banca da pescadora e duas recebidas pela cozinha. Há confirmação de receção junto dos dois destinos."}
}
static func install(world) -> void:
	if world.sorted_world.has_node("MarinheiroDoBatel"): return
	var actor := preload("res://scripts/chapter/actor_proxy.gd").new(); actor.name = TARGETS.keeper.node
	actor.npc_id = "worker"; actor.position = TARGETS.keeper.at; actor.visible = not world.childhood
	world.sorted_world.add_child(actor)
	preload("res://scripts/city/lisbon_scenery.gd").body(actor,PackedVector2Array([Vector2(-9,-5),Vector2(9,-5),Vector2(9,7),Vector2(-9,7)]))
	for id in ["tide","mooring","manifest"]:
		var node: Node2D
		if id=="manifest": node = preload("res://scripts/chapter/furniture_art.gd").place(world.sorted_world,"table",TARGETS[id].at,Vector2(76,58))
		else: node = Node2D.new(); world.sorted_world.add_child(node)
		node.name = TARGETS[id].node; node.position = TARGETS[id].at
		var detail := Node2D.new(); detail.set_script(load("res://scripts/city/district_details.gd")); detail.kind = id; node.add_child(detail)
	if not Engine.is_editor_hint(): apply_world(world,world.get_node("/root/ChapterProgress"))

static func apply_world(world,p) -> void:
	if not world.has_meta("continuous_lisbon"): return
	var done := Errands.stage(p,Errands.BATEL)=="completed"
	var boat = world.sorted_world.get_node_or_null("Batel")
	if boat!=null: boat.position = preload("res://scripts/city/lisbon_layout.gd").point(Vector2(173,761))+Vector2(-105,55) if done else preload("res://scripts/city/lisbon_layout.gd").point(Vector2(173,761))
	var mooring = world.sorted_world.get_node_or_null(TARGETS.mooring.node)
	if mooring!=null:
		mooring.get_child(0).released = done; mooring.get_child(0).queue_redraw()

static func observed(p) -> bool:
	return p.flags.get("lisbon_tide_read",false) and p.flags.get("lisbon_rope_read",false)

static func dialog(p,id: String) -> Dictionary:
	var state: String = Errands.stage(p,Errands.BATEL)
	var text := ""; var options: Array = [["Voltar à rua","close"]]
	match id:
		"keeper":
			if state.is_empty():
				text = "A maré está a mudar e este batel já puxa pelo cabeço. Podes ver a marca no poste e examinar o cabo? Fico deste lado a segurar a embarcação. Depois ajustamos a amarra ali mesmo, sem andar a buscar ferramentas."
				options = [["Observar a água e o cabo","district_accept"],["Agora não","close"]]
			elif state=="completed": text = "O batel já pode afastar-se sem puxar pelo pontão. Obrigado por olhar para a água antes de mexer no cabo. O estaleiro fica mesmo ali; a rua poente leva-te de volta à casa da Ordem."
			else: text = Errands.DEFINITIONS[Errands.BATEL].objectives[state]+" Eu mantenho o batel firme enquanto conferes."
		"tide":
			p.flags.lisbon_tide_read = true; text = NOTES.lisbon_tide_read.text
		"mooring":
			p.flags.lisbon_rope_read = true
			text = "A amarra foi regulada para uma linha de água mais alta. Agora segue direita e tensa até ao batel; o marinheiro mantém a embarcação firme."
			if state=="completed": text = "O cabo ficou com uma curva de folga. O batel acompanha a água e já não prende o bordo ao pontão."
			elif not state.is_empty() and observed(p):
				text += " Que ajuste fazes?"
				options = [["Dar folga ao cabo e prendê-lo de novo","district_finish"],["Encurtar ainda mais a amarra","district_tighten"],["Cortar o cabo","district_cut"],["Observar melhor antes de mexer","close"]]
			elif state=="observe": text += " Falta comparar com a marca de água no poste."
		"manifest":
			p.flags.lisbon_manifest_read = true
			text = NOTES.lisbon_manifest_read.text+" Não há caixas em falta; o total foi repartido."
			if Errands.stage(p,Errands.ACCOUNT) in ["dock","kitchen"]:
				options = [["Conferir os dois recibos e explicar à pescadora","district_receipt"],["Voltar mais tarde","close"]]
		_: return {}
	if state=="observe" and observed(p): p.local_requests[Errands.BATEL] = "solve"
	return {"speaker":TARGETS[id].title,"text":text,"options":options}

static func choose(p,id: String,action: String) -> Dictionary:
	var state: String = Errands.stage(p,Errands.BATEL)
	match action:
		"district_accept":
			if id!="keeper" or not state.is_empty(): return {}
			p.local_requests[Errands.BATEL] = "solve" if observed(p) else "observe"
			return {"speaker":"Marinheiro do batel","text":"Olha para a marca de água e para o trecho tenso. A decisão é ali, junto à amarra; não precisas voltar aqui para a confirmar.","notice":"Pedido iniciado · A maré e a amarra"}
		"district_finish":
			if id!="mooring" or state!="solve" or not observed(p): return {}
			p.local_requests[Errands.BATEL] = "completed"; p.coins = mini(1000000,p.coins+6)
			return {"speaker":"Marinheiro do batel","text":"Isso. Seguro o bordo enquanto deixas folga; agora prende outra vez. O cabo acompanha o batel sem o suspender. Aqui tens seis de ouro pela ajuda.","notice":"Amarra regulada · batel livre · +6 de ouro"}
		"district_tighten","district_cut":
			if id!="mooring" or state!="solve": return {}
			return {"speaker":"Herói","text":"A água está mais baixa. Encurtar o cabo prende ainda mais o batel; cortá-lo deixa-o à deriva. É preciso conservar a amarra e dar-lhe folga.","notice":"O cabo não foi alterado. Podes examinar e tentar novamente."}
		"district_receipt":
			if id!="manifest" or not p.flags.get("lisbon_manifest_read",false) or Errands.stage(p,Errands.ACCOUNT) not in ["dock","kitchen"]: return {}
			p.local_requests[Errands.ACCOUNT] = "reconcile"
			return {"speaker":"Herói","text":"Os dois destinos confirmaram a receção: cinco e duas. Posso explicar à pescadora com base nos recibos, sem fazer de novo o percurso entre os moradores.","notice":"Dois recibos conferidos · explicar a conta à pescadora"}
	return {}
