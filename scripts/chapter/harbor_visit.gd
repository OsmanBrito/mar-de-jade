extends RefCounted
## Optional shore leave between packing and the approved captain dialogue.
const MERCHANT = preload("res://scripts/chapter/quay_merchant.gd")
const GATE := Vector2(1496,1120)
const START := Vector2(517,880)
var director
var merchant
var active := false
var gate_label: Label
var city
var entry_notice := ""
var entry_origin := Vector2.ZERO
var building_visit := false

func _init(owner) -> void:
	director = owner
	city = preload("res://scripts/chapter/lisbon_requests.gd").new(self)

func install(world) -> void:
	active = false; merchant = null; gate_label = null
	if director.map_kind not in ["cais","service"] and not world.has_meta("continuous_lisbon"): return
	city.apply_world(world)
	var stall = world.sorted_world.get_node_or_null("BancaDePeixe")
	if stall == null: return
	# Narrative rescue/meal scenes keep the market art without shop UI or a
	# second shopkeeper crossing the actors. Shore leave installs the service.
	if not building_visit and not world.has_meta("continuous_lisbon"): return
	merchant = MERCHANT.new(); merchant.name = "ComercianteDeLisboa"
	merchant.position = stall.position+Vector2(-67,8); world.sorted_world.add_child(merchant)
	for name in ["Provisoes","LisbonShopSign"]:
		var old: Node = stall.get_node_or_null(name)
		if old!=null: old.free()
	# Existing goods art is displayed on the existing stall; source PNGs stay intact.
	var goods := Node2D.new(); goods.name = "Provisoes"; goods.position = Vector2(0,-39); stall.add_child(goods)
	for i in 3:
		var icon := Sprite2D.new(); icon.texture = load("res://assets/art/items/portugal/"+["PT-C01","PT-C02","PT-C03"][i]+".png")
		icon.position = Vector2((i-1)*23,(i-1)*-5); icon.scale = Vector2.ONE*24.0/icon.texture.get_width()
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR; goods.add_child(icon)
	var sign_label := Label.new(); sign_label.name = "LisbonShopSign"; sign_label.text = "PROVISÕES · LISBOA"; sign_label.position = Vector2(-85,-146)
	sign_label.size.x = 170; sign_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; merchant.style_label(sign_label,12); stall.add_child(sign_label)

func can_begin() -> bool:
	if ChapterProgress.flags.get("injured",false) or ChapterProgress.flags.get("embarked",false): return false
	if director.scene_index == 3: return ChapterProgress.flags.get("patient_helped",false)
	if director.scene_index == 5: return ChapterProgress.flags.get("meal",false)
	return director.scene_index == 15 and ChapterProgress.flags.get("packed",false) and ChapterProgress.flags.get("recovered",false)

func before_meal() -> bool:
	return director.scene_index == 3

func before_evaluation() -> bool:
	return director.scene_index==5

func begin() -> void:
	if not can_begin(): return
	building_visit = true; director._load_map("cais"); building_visit = false
	# Characters who have left the story cannot return during this optional visit.
	for name in director.actors.keys():
		if name == "Duarte": continue
		director.actors[name].free(); director.actors.erase(name)
	director.actors["Duarte"].position = GATE
	director.actors["Duarte"].get_node("NameLabel").hide()
	# Keep the customer's standing space out of the fish seller's ambient errand.
	var fisher = director.world.sorted_world.get_node_or_null("Pescadora")
	if fisher != null:
		fisher.route = PackedVector2Array([Vector2(642,877),Vector2(662,937)])
		fisher.position = fisher.route[0]; fisher.route_index = 0; fisher.path.clear(); fisher.waiting = 1.0
	gate_label = Label.new(); gate_label.position = Vector2(-110,-122); gate_label.size.x = 220
	gate_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; merchant.style_label(gate_label,14)
	director.actors["Duarte"].add_child(gate_label)
	director.world.player.position = START; director.world.player.presentation.posture = "standing"
	director.world.player.presentation.carries_bowl = false
	active = true; ChapterProgress.flags.harbor_pause = true
	entry_origin = director.world.player.position
	entry_notice = "Serviço no cais · +40 de ouro · Podes explorar antes de seguir com Duarte." if director.service_paid_now else ""
	city.install(director.world)
	director.world.rebuild_navigation()
	resume()
	director.world.player.camera.offset = preload("res://scripts/chapter/quay_camera.gd").offset_at(START)
	director.world.player.camera.reset_smoothing()
	if ChapterProgress.auto_save: ChapterProgress.save_to()

func resume() -> void:
	if director.routes!=null and director.routes.active:
		director.routes.resume(); return
	if not active or director.paused: return
	director.phase = "exploration"; director._clear_options(); director.view.panel.hide()
	director.view.next_button.hide(); director._lock_player(false)
	director.view.caption_label.text = "Lisboa · Depois do socorro\nUma pausa no cais" if before_meal() else "Lisboa · Antes da partida\nProvisões e embarque"
	if before_evaluation(): director.view.caption_label.text = "Lisboa · Depois da refeição\nAntes da avaliação de amanhã"
	director.view.status.text = city.objective()+"  ·  J · pedidos"
	director.view.hint.text = "WASD / setas / clique · mover     E / A · interagir     J · pedidos     I · sacola     Esc · menu"
	var focus = director.get_viewport().gui_get_focus_owner()
	if focus != null: focus.release_focus()

func near_merchant() -> bool:
	if not active or not is_instance_valid(merchant): return false
	var point: Vector2 = director.world.player.position
	return point.distance_to(merchant.position) <= 86 and point.distance_to(merchant.approach) <= 70 and director.world.segment_clear(point,merchant.approach)

func near_gate() -> bool:
	if not active: return false
	var point: Vector2 = director.world.player.position
	return point.distance_to(GATE) <= 82 and director.world.segment_clear(point,GATE+Vector2(-45,0))

func update() -> void:
	if not is_instance_valid(merchant): return
	merchant.available = active and can_begin()
	merchant.highlighted = merchant.available and director.phase == "exploration" and not director.paused and near_merchant()
	city.update()
	if active and director.phase == "exploration" and not director.paused:
		var city_prompt: String = city.prompt()
		if not city_prompt.is_empty(): director.view.status.text = city_prompt
		elif merchant.highlighted: director.view.status.text = "E / A · negociar com o comerciante · %d de ouro" % ChapterProgress.coins
		elif near_gate(): director.view.status.text = "E / A · falar com Duarte e levar a refeição" if before_meal() else "E / A · falar com Duarte e preparar o embarque"
		elif not entry_notice.is_empty() and director.world.player.position.distance_to(entry_origin)<25: director.view.status.text = entry_notice
		else:
			entry_notice = ""
			var state: String = city.Requests.stage(ChapterProgress)
			if state.is_empty() or state=="completed":
				director.view.status.text = ("Explora as conversas do cais" if state.is_empty() else "Pedido concluído · A roda presa")+" · Duarte espera no pontão"
			else: director.view.status.text = city.objective()+"  ·  J · pedidos"
	if not active or not is_instance_valid(gate_label): return
	gate_label.text = "Duarte · "+("Refeição" if before_meal() else "Embarque")
	if director.phase == "exploration" and not director.paused and near_gate(): gate_label.text = "E / A · "+("Seguir com Duarte" if before_meal() else "Embarcar")
	if before_evaluation():
		gate_label.text = "Duarte · Regressar ao abrigo"
		if near_gate() and director.phase=="exploration": director.view.status.text = "E / A · combinar o regresso ao abrigo · avaliação amanhã"

func interact() -> void:
	if not active or not can_begin() or director.phase != "exploration" or director.paused: return
	if city.interact(): return
	if near_merchant():
		# Stop a click route at the counter; closing the store resumes at these feet.
		director.world.player.destination_path.clear(); director.world.player.velocity = Vector2.ZERO
		director.world.player.presentation.walking = false
		director._menu("Loja de Lisboa")
		director.player_menu.notice.text = "Comerciante de Lisboa · Fecha a loja para continuar a explorar o cais."
	elif near_gate(): request_boarding()

func request_boarding() -> void:
	if not active or not can_begin() or not near_gate() or director.phase != "exploration" or director.paused: return
	director.phase = "boarding"; director._lock_player(true); director._clear_options()
	director.view.panel.show(); director.view.next_button.hide(); director.options_box.show()
	director.view.speaker.text = "Duarte" if before_meal() or before_evaluation() else "Partida · Botafogo"
	director.view.body.text = "O atendimento terminou. A cozinha separou água e duas porções para quem ficou. Vamos levá-las?" if before_meal() else "Madeira para mantimentos; depois Duas Águas e a busca pela caravela. Embarcas como aprendiz sob Rodrigo. Confere a sacola antes de deixar Lisboa."
	if before_evaluation(): director.view.body.text = "Leonor marcou a avaliação para amanhã. Ainda podes tratar dos pedidos do cais; depois regressamos ao abrigo e encontramo-nos na praça pela manhã."
	director.view.status.text = "Podes voltar à oficina mais tarde." if before_meal() else "Revê os preparativos antes de deixar Lisboa."
	if not before_meal() and not before_evaluation() and not city.Requests.stage(ChapterProgress).is_empty() and city.Requests.stage(ChapterProgress)!="completed": director.view.status.text = "Ainda tens um pedido por concluir em Lisboa. Podes continuar a explorar."
	if not before_meal() and not before_evaluation():
		for state in ChapterProgress.local_requests.values():
			if state!="completed": director.view.status.text = "Ainda tens pedidos em Lisboa. Podes continuar a explorar antes de embarcar."
	if not before_meal() and not before_evaluation(): director.view.body.text += "\n\n"+preload("res://scripts/chapter/optional_arc.gd").boarding(ChapterProgress)
	if before_evaluation(): director.view.status.text = "Sem prazo para os pedidos nesta pausa. A próxima cena começa na manhã seguinte."
	director.view.remember(director.view.speaker.text,director.view.body.text)
	director.view.hint.text = "Enter / A · escolher     Esc / B · voltar"
	director.view.panel.offset_top = -350
	director._option("Continuar a explorar",resume)
	director._option("Levar a refeição" if before_meal() else "Embarcar com Duarte",confirm_boarding)
	if before_evaluation(): director.options_box.get_child(1).text = "Regressar ao abrigo · avaliação na manhã seguinte"
	director.options_box.get_child(0).grab_focus()

func confirm_boarding() -> void:
	if not active or director.phase != "boarding" or director.paused: return
	ChapterProgress.flags.erase("harbor_pause"); active = false
	director._load_block(director.scene_index+1)
