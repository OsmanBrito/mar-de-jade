extends RefCounted
## Local NPC conversations and one complete request, using the campaign save.
const Requests = preload("res://scripts/chapter/local_request_state.gd")
const Items = preload("res://scripts/chapter/player_items.gd")
const Marker = preload("res://scripts/chapter/local_request_marker.gd")
const Errands = preload("res://scripts/chapter/lisbon_errands.gd")
const CART_HOME := Vector2(-115,811)
const CART_FIXED := Vector2(-185,799)
var visit_ref: WeakRef
var harbor:
	get: return visit_ref.get_ref()
var director
var world
var residents: Dictionary = {}
var markers: Dictionary = {}
var cart: Node2D
var lines: Array = []
var cursor := -1
var actions: Array = []
var conversation := ""
var feedback := ""

func _init(visit) -> void:
	visit_ref = weakref(visit)
	director = visit.director

func apply_world(map) -> void:
	var vehicle = map.sorted_world.get_node_or_null("CarroDaOficina")
	if vehicle == null: return
	var fixed: bool = Requests.stage(ChapterProgress) in ["return","completed"]
	vehicle.position = CART_FIXED if fixed else CART_HOME
	# Tilt the illustrated body, leaving its ground footprint stable.
	for child in vehicle.get_children():
		if child is Sprite2D: child.rotation = 0.0 if fixed else -0.075
	var stall = map.sorted_world.get_node_or_null("BancaDePeixe")
	if stall!=null and Errands.stage(ChapterProgress,Errands.ACCOUNT)=="completed" and not stall.has_node("DeliveryRecord"):
		var record := Node2D.new(); record.name = "DeliveryRecord"; record.position = Vector2(22,-40)
		record.set_script(preload("res://scripts/chapter/delivery_record.gd")); stall.add_child(record)

func install(map) -> void:
	for previous in markers.values():
		if is_instance_valid(previous): previous.queue_free()
	world = map; residents.clear(); markers.clear()
	cart = world.sorted_world.get_node("CarroDaOficina")
	apply_world(world)
	var specs := {
		"workshop":["OficialDaOficina","Oficial da oficina",Vector2(-35,756)],
		"dock":["TrabalhadorDoPontao","Trabalhador do pontão",Vector2(760,930)],
		"fisher":["Pescadora","Pescadora",Vector2(642,937)],
		"neighbor":["Vizinha","Vizinha",Vector2(315,955)]
	}
	for id in specs:
		var spec: Array = specs[id]
		var resident = world.sorted_world.get_node(spec[0])
		resident.set_physics_process(false); resident.path.clear(); resident.velocity = Vector2.ZERO
		resident.position = spec[2]; resident.presentation.walking = false; resident.presentation.facing = 0
		residents[id] = resident
		_add_marker(id,resident,spec[1])
	_add_marker("cart",cart,"Carro da oficina")
	update()

func _add_marker(id: String, node: Node2D, caption: String) -> void:
	var mark := Marker.new(); mark.caption = caption
	if id == "cart": mark.position.y = 52
	node.add_child(mark); markers[id] = mark

func approach(id: String) -> Vector2:
	var node = cart if id == "cart" else residents.get(id)
	if not is_instance_valid(node): return Vector2.INF
	var offset := Vector2(0,42)
	if id=="cart": offset = Vector2(-32,34)
	elif id=="workshop": offset = Vector2(-42,35)
	elif id=="fisher": offset = Vector2(-42,0)
	return node.position+offset

func near(id: String) -> bool:
	if not is_instance_valid(world) or not harbor.active: return false
	var target := approach(id)
	return world.player.position.distance_to(target)<62 and world.segment_clear(world.player.position,target)

func focus() -> String:
	var result := ""; var best := 62.0
	for id in markers:
		if not is_instance_valid(markers[id]) or not markers[id].available or not near(id): continue
		var distance: float = world.player.position.distance_to(approach(id))
		if distance<best: best = distance; result = id
	return result

func update() -> void:
	if not harbor.active or not is_instance_valid(world): return
	var selected := focus() if director.phase in ["exploration","roaming"] and not director.paused else ""
	for id in markers:
		if not is_instance_valid(markers[id]): continue
		markers[id].highlighted = id==selected
		markers[id].symbol = "?" if id=="workshop" and Requests.stage(ChapterProgress)=="" else ("!" if id=="workshop" and Requests.stage(ChapterProgress)=="return" else "…")
		if id=="fisher": markers[id].symbol = "?" if Errands.stage(ChapterProgress,Errands.ACCOUNT)=="" else "!" if Errands.stage(ChapterProgress,Errands.ACCOUNT)=="reconcile" else "…"
		if id=="neighbor" and Errands.stage(ChapterProgress,Errands.ACCOUNT)=="kitchen": markers[id].symbol = "!"
		if id=="dock":
			if Errands.stage(ChapterProgress,Errands.ACCOUNT)=="dock" or Errands.stage(ChapterProgress,Errands.KIT)=="prepare": markers[id].symbol = "!"
			elif ChapterProgress.flags.get("recovered",false) and Errands.stage(ChapterProgress,Errands.KIT)=="": markers[id].symbol = "?"
		if id=="cart": markers[id].symbol = "⌕"; markers[id].available = Requests.stage(ChapterProgress) not in ["return","completed"]

func prompt() -> String:
	var id := focus()
	if id.is_empty(): return ""
	return "E / A · "+("examinar o carro" if id=="cart" else "falar com "+markers[id].caption)

func objective() -> String:
	return Requests.objective(ChapterProgress)

func interact() -> bool:
	var id := focus()
	if id.is_empty(): return false
	conversation = id
	match id:
		"workshop": _workshop()
		"cart": _cart()
		"dock":
			if Requests.stage(ChapterProgress)=="parts": _say("part",[["Receber a cavilha","take_part"],["Ainda não","close"]])
			elif Requests.stage(ChapterProgress)=="fit": _message("Trabalhador do pontão","A cavilha já está contigo. O oficial segura o carro enquanto a encaixas.")
			else: _dock_topics()
		"fisher": _fisher()
		"neighbor": _neighbor()
	return true

func _fisher() -> void:
	match Errands.stage(ChapterProgress,Errands.ACCOUNT):
		"": _message("Pescadora","A passagem abriu depois do socorro; já consigo levar o peixe. Mas recebi aviso de sete caixas e só cinco chegaram à banca. Antes de cobrar outra entrega, podes conferir no pontão onde ficaram as duas?",[["Conferir o destino das duas caixas","account_accept"],["Agora não","close"]])
		"dock": _message("Pescadora","Pergunta no pontão pelo registo das sete caixas. Não quero cobrar uma entrega que alguém já fez.")
		"kitchen": _message("Pescadora","Duas seguiram para a cozinha? A vizinha ajuda a organizar as porções; confirma com ela antes de fecharmos a conta.")
		"reconcile": _message("Pescadora","Então, como ficaram as sete caixas?",[["Cinco na banca; duas entregues à cozinha","account_reconcile"],["Faltam duas: pedir outra entrega","account_wrong"],["Conferir mais tarde","close"]])
		"completed": _message("Pescadora","A conta ficou certa. Já separei a parte da cozinha no registo; ninguém vai pagar duas vezes pela mesma entrega.")

func _neighbor() -> void:
	if Errands.stage(ChapterProgress,Errands.ACCOUNT)=="kitchen":
		_message("Vizinha","Chegaram duas caixas à cozinha antes do socorro. Fiquei com a conferência: duas aqui, cinco na banca. A pescadora pode fechar a conta.",[["Anotar a entrega e voltar à pescadora","account_kitchen"],["Voltar depois","close"]])
	elif Errands.stage(ChapterProgress,Errands.ACCOUNT)=="completed": _message("Vizinha","A cozinha recebeu a parte certa, e o pontão deixou de procurar caixas que já tinham chegado. Obrigada por conferir antes de acusar alguém.")
	else: _say("neighbor_done" if Requests.stage(ChapterProgress) in ["return","completed"] else "neighbor")

func _dock_topics() -> void:
	var options: Array = []
	if Errands.stage(ChapterProgress,Errands.ACCOUNT)=="dock": options.append(["Conferir as sete caixas da pescadora","account_dock"])
	if ChapterProgress.flags.get("recovered",false):
		var state: String = Errands.stage(ChapterProgress,Errands.KIT)
		if state=="": options.append(["Conferir a reserva para a viagem","kit_accept"])
		elif state=="prepare": options.append(["Mostrar a ligadura e a água da sacola","kit_finish"])
		else: options.append(["Rever o uso dos suprimentos a bordo","kit_advice"])
	options.append(["Conversar sobre o trabalho do pontão","dock_work"]); options.append(["Voltar à rua","close"])
	_message("Trabalhador do pontão","As peças pequenas ficam comigo. Também guardo a conta das entregas; diz o que precisas de conferir.",options)

func _workshop() -> void:
	match Requests.stage(ChapterProgress):
		"": _say("offer",[["Examinar o carro e ajudar","accept"],["Agora não","close"]])
		"inspect": _message("Oficial da oficina","A roda ficou junto à porta. Olha para o aro e para a ponta do eixo antes de puxares.")
		"parts": _message("Oficial da oficina","Pergunta ao trabalhador do pontão pela cavilha. Está junto à carga, na margem do rio.")
		"fit": _message("Oficial da oficina","Tens a peça? Vamos ao carro. Eu trato do apoio; tu alinhas a roda.")
		"return": _say("reward",[["Receber pelo trabalho","claim"],["Volto já","close"]])
		"completed": _say("thanks")

func _cart() -> void:
	match Requests.stage(ChapterProgress):
		"": _message("Carro da oficina","Uma roda está inclinada. O oficial da oficina tenta manter a carga apoiada. É melhor falar com ele antes de mexer.")
		"inspect": _say("inspect",[["Falta a peça que trava a roda no eixo","diagnose"],["Puxar a corda solta","wrong_rope"],["Continuar a examinar depois","close"]])
		"parts": _message("Carro da oficina","A ranhura do eixo está vazia. Precisas de uma cavilha antes de mover a roda.")
		"fit": _message("Carro da oficina","A roda precisa de ficar alinhada enquanto a cavilha entra. A carga ainda pesa sobre este lado.",[["Pedir ao oficial que apoie o carro","repair"],["Tentar levantar e encaixar sozinho","wrong_lift"],["Voltar à rua","close"]])

func _say(key: String, options: Array = []) -> void:
	_open(Requests.data().dialogue[key],options)

func _message(speaker: String,text: String,options: Array = []) -> void:
	_open([[speaker,text]],options)

func _open(turns: Array, options: Array = []) -> void:
	lines = turns.duplicate(true); cursor = -1; actions = options if not options.is_empty() else [["Voltar à rua","close"]]
	director.phase = "local_dialogue"; director._lock_player(true)
	director.world.player.presentation.posture = "standing"
	director.view.show(); director.view.panel.show(); director._clear_options()
	advance()

func advance() -> void:
	if director.paused or director.busy or director.phase!="local_dialogue": return
	if cursor>=lines.size(): return
	cursor += 1; director._clear_options()
	director.view.status.text = feedback if not feedback.is_empty() else (Requests.definition().title+" · "+objective() if not Requests.stage(ChapterProgress).is_empty() else "Lisboa · Conversas do cais")
	director.view.hint.text = "Enter / espaço / A · continuar     Esc / B · voltar à rua     J · pedidos"
	if cursor<lines.size():
		director.view.speaker.text = CampaignProfile.speaker_name(lines[cursor][0])
		director.view.body.text = lines[cursor][1]
		director.view.remember(director.view.speaker.text,director.view.body.text)
		director.view.next_button.show(); director.view.next_button.grab_focus()
		return
	cursor = lines.size()
	director.view.next_button.hide(); director.options_box.show()
	for option in actions: director._option(option[0],choose.bind(option[1]))
	director.options_box.get_child(0).grab_focus()

func choose(action: String) -> void:
	if director.paused or director.busy or director.phase!="local_dialogue" or cursor<lines.size(): return
	var offered := false
	for option in actions:
		if option[1]==action: offered = true
	if not offered: return
	if action=="close": close(); return
	# Every result is checked again at commitment, not merely when a button appears.
	match action:
		"account_accept":
			if not near("fisher") or not Errands.advance(ChapterProgress,Errands.ACCOUNT,"","dock"): return
			_save("Pedido iniciado · A conta das entregas"); _message("Pescadora","O pontão é junto à carga. Pergunta pelos destinos, não apenas pela quantidade.")
		"account_dock":
			if not near("dock") or not Errands.advance(ChapterProgress,Errands.ACCOUNT,"dock","kitchen"): return
			_save("Registo conferido · duas caixas seguiram para a cozinha")
			_message("Trabalhador do pontão","Sete descarregadas: cinco para a banca, duas para a cozinha do cais. A vizinha recebeu as duas; confirma com ela, para não depender só da minha conta.")
		"account_kitchen":
			if not near("neighbor") or not Errands.advance(ChapterProgress,Errands.ACCOUNT,"kitchen","reconcile"): return
			_save("Entrega confirmada · volta à pescadora"); _message("Herói","A conta tem dois destinos. Vou explicar antes de pedirem outra carga.")
		"account_wrong": _message("Pescadora","Se a cozinha recebeu duas e a banca cinco, já temos as sete. Pedir mais duas duplicaria a entrega. Vamos acertar o registo.",[["Acertar a conta: cinco e duas","account_reconcile"],["Voltar à rua","close"]])
		"account_reconcile":
			if not near("fisher") or not Errands.reconcile(ChapterProgress): return
			_save("Pedido concluído · A conta das entregas · +8 de ouro")
			apply_world(world)
			_message("Pescadora","Cinco aqui e duas na cozinha. Vou separar os destinos no registo. Oito de ouro pela conferência; poupou-nos uma cobrança errada.")
		"kit_accept":
			if not near("dock") or not ChapterProgress.flags.get("recovered",false) or not Errands.advance(ChapterProgress,Errands.KIT,"","prepare"): return
			_save("Pedido iniciado · Uma sacola preparada")
			_message("Trabalhador do pontão","Confere uma ligadura e uma reserva de água na tua sacola. O fundo do navio paga casco e provisões de bordo; essa reserva é tua. O comerciante junto à banca tem ambas.")
		"kit_finish":
			if not near("dock"): return
			if not Errands.ready(ChapterProgress): _message("Trabalhador do pontão","Ainda falta uma ligadura ou uma reserva de água. A ração alimenta, mas não substitui esse curativo. Não precisas concluir esta conferência para embarcar."); return
			if not Errands.inspect_kit(ChapterProgress): return
			_save("Pedido concluído · reserva conferida · +3 de ouro")
			_message("Trabalhador do pontão","Ambas prontas. Ficam contigo: a ligadura recupera 25 de vida e a água 5 de alento quando usadas numa abordagem. Gastam a ação e saem da sacola; os recursos restantes seguem para o próximo encontro. Três de ouro pela ajuda à conferência.")
		"kit_advice": _message("Trabalhador do pontão","A reserva já foi conferida. Guarda a ligadura para quando houver ferimento e a água para falta de alento. Na abordagem, abre a Bolsa; não precisas gastar nada agora.")
		"dock_work": _say("worker")
		"accept":
			if conversation!="workshop" or not near("workshop") or not Requests.transition(ChapterProgress,"","inspect"): return
			_save("Pedido iniciado · A roda presa")
			_message("Oficial da oficina","Obrigado. O carro está aqui ao lado. Vê primeiro o que o prende.")
		"diagnose":
			if not near("cart") or not Requests.transition(ChapterProgress,"inspect","parts"): return
			_save("Descobriste a causa · falta a cavilha")
			_say("diagnosed")
		"wrong_rope":
			_message("Herói","A corda está solta. Puxá-la não prende a roda ao eixo. Preciso de olhar para a ranhura vazia.",[["Voltar a examinar a roda","inspect_again"],["Voltar à rua","close"]])
		"inspect_again": _cart()
		"take_part":
			if not near("dock") or not Requests.take_part(ChapterProgress): return
			_save("Recebeste uma cavilha de eixo · guardada na sacola")
			_message("Trabalhador do pontão","Leva-a à oficina. E deixa o oficial segurar a carga.")
		"wrong_lift": _message("Herói","Se largar o apoio para encaixar a peça, a carga cai sobre a roda outra vez. Preciso dos braços do oficial.",[["Combinar o reparo com o oficial","repair"],["Voltar à rua","close"]])
		"repair":
			if not near("cart") or Requests.stage(ChapterProgress)!="fit": return
			_say("repair",[["Alinhar a roda com o carro apoiado","finish_repair"],["Parar por agora","close"]])
		"finish_repair":
			if not near("cart") or not Requests.repair(ChapterProgress): return
			_save("Carro reparado · fala com o oficial para concluir")
			await _animate_repair()
			_message("Oficial da oficina","Ficou firme. Vou levar o carro para o lado da oficina. Depois vem falar comigo.")
		"claim":
			if not near("workshop") or not Requests.claim(ChapterProgress): return
			_save("Pedido concluído · +12 de ouro · +1 ração")
			_message("Oficial da oficina","Aqui tens. O carro voltou ao trabalho; eu já não preciso de ocupar a rua com a carga parada.")

func _animate_repair() -> void:
	director.busy = true; director._clear_options(); director.view.panel.hide()
	var actor = residents.workshop
	var workstation: Vector2 = actor.position
	actor.presentation.walking = true; actor.presentation.facing = 3
	var tween = director.create_tween()
	tween.tween_property(actor,"position",CART_HOME+Vector2(42,15),0.65)
	await tween.finished
	actor.presentation.walking = false; actor.presentation.posture = "crouched"
	world.player.presentation.posture = "crouched"
	await director.get_tree().create_timer(0.65,false).timeout
	actor.presentation.posture = "standing"; world.player.presentation.posture = "standing"
	for child in cart.get_children():
		if child is Sprite2D: child.rotation = 0
	tween = director.create_tween().set_parallel(true)
	actor.presentation.walking = true
	tween.tween_property(cart,"position",CART_FIXED,1.0)
	tween.tween_property(actor,"position",CART_FIXED+Vector2(42,15),1.0)
	await tween.finished
	tween = director.create_tween()
	actor.presentation.facing = 1
	tween.tween_property(actor,"position",workstation,0.65)
	await tween.finished
	actor.presentation.walking = false
	world.rebuild_navigation(); director.busy = false

func _save(message: String) -> void:
	feedback = Items.persist(ChapterProgress,message)

func close() -> void:
	if director.busy: return
	feedback = ""; lines.clear(); actions.clear(); cursor = -1
	harbor.resume()
