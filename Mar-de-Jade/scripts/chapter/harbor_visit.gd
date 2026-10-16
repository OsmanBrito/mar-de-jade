extends RefCounted
## Optional shore leave between packing and the approved captain dialogue.
const MERCHANT = preload("res://scripts/chapter/quay_merchant.gd")
const GATE := Vector2(947,1014.5)
const START := Vector2(517,880)
var director
var merchant
var active := false
var gate_label: Label

func _init(owner) -> void:
	director = owner

func install(world) -> void:
	active = false; merchant = null; gate_label = null
	if director.map_kind not in ["cais","service"]: return
	var stall = world.sorted_world.get_node_or_null("BancaDePeixe")
	if stall == null: return
	merchant = MERCHANT.new(); merchant.name = "ComercianteDeLisboa"
	merchant.position = stall.position+Vector2(-67,8); world.sorted_world.add_child(merchant)
	# Existing goods art is displayed on the existing stall; source PNGs stay intact.
	var goods := Node2D.new(); goods.name = "Provisoes"; goods.position = Vector2(0,-39); stall.add_child(goods)
	for i in 3:
		var icon := Sprite2D.new(); icon.texture = load("res://assets/art/items/portugal/"+["PT-C01","PT-C02","PT-C03"][i]+".png")
		icon.position = Vector2((i-1)*23,(i-1)*-5); icon.scale = Vector2.ONE*24.0/icon.texture.get_width()
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR; goods.add_child(icon)
	var sign_label := Label.new(); sign_label.text = "PROVISÕES · LISBOA"; sign_label.position = Vector2(-85,-146)
	sign_label.size.x = 170; sign_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; merchant.style_label(sign_label,12); stall.add_child(sign_label)

func can_begin() -> bool:
	return director.scene_index == 15 and ChapterProgress.flags.get("packed",false) and ChapterProgress.flags.get("recovered",false) and not ChapterProgress.flags.get("injured",false) and not ChapterProgress.flags.get("embarked",false)

func begin() -> void:
	if not can_begin(): return
	director._load_map("cais")
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
	director.world.rebuild_navigation()
	resume()
	director.world.player.camera.offset = preload("res://scripts/chapter/quay_camera.gd").offset_at(START)
	director.world.player.camera.reset_smoothing()
	if ChapterProgress.auto_save: ChapterProgress.save_to()

func resume() -> void:
	if not active or director.paused: return
	director.phase = "exploration"; director._clear_options(); director.view.panel.hide()
	director.view.next_button.hide(); director._lock_player(false)
	director.view.caption_label.text = "Lisboa · Antes da partida\nProvisões e embarque"
	director.view.status.text = "Visita a banca de provisões. Procura Duarte no pontão quando quiseres embarcar."
	director.view.hint.text = "WASD / setas / clique · mover     E / A · interagir     I · sacola     Esc · menu"
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
	if active and director.phase == "exploration" and not director.paused:
		if merchant.highlighted: director.view.status.text = "E / A · negociar com o comerciante · %d reais" % ChapterProgress.coins
		elif near_gate(): director.view.status.text = "E / A · falar com Duarte e preparar o embarque"
		else: director.view.status.text = "Visita a banca de provisões. Procura Duarte no pontão quando quiseres embarcar."
	if not active or not is_instance_valid(gate_label): return
	gate_label.text = "Duarte · E / A · embarcar" if director.phase == "exploration" and not director.paused and near_gate() else "Duarte · Embarque"

func interact() -> void:
	if not active or not can_begin() or director.phase != "exploration" or director.paused: return
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
	director.view.speaker.text = "Partida · Botafogo"
	director.view.body.text = "Embarcar e deixar Lisboa? Confere a sacola antes de partir."
	director.view.status.text = "Revê os preparativos antes de deixar Lisboa."
	director.view.hint.text = "Enter / A · escolher     Esc / B · voltar"
	director.view.panel.offset_top = -350
	director._option("Continuar a explorar",resume)
	director._option("Embarcar com Duarte",confirm_boarding)
	director.options_box.get_child(0).grab_focus()

func confirm_boarding() -> void:
	if not active or director.phase != "boarding" or director.paused: return
	ChapterProgress.flags.erase("harbor_pause"); active = false
	director._load_block(16)
