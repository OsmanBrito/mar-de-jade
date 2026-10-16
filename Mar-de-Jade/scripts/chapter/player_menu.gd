extends CanvasLayer
## A separate modal: opening a bag never replaces a dialogue or advances its event.
signal close_requested
signal save_requested
signal load_requested
signal restart_requested
const Items = preload("res://scripts/chapter/player_items.gd")
var director
var screen: Control
var content: HBoxContainer
var summary: VBoxContainer
var listing: VBoxContainer
var details: VBoxContainer
var notice: Label
var wallet: Label
var tabs: Dictionary = {}
var page := "Personagem"
var filter := "Todos"
var selected := ""
var trading := "Comprar"
var row_buttons: Dictionary = {}
var action_button: Button
var pending_sale := ""
var tab_names := ["Personagem","Inventário","Equipamento","Técnicas","Passivas","Loja de Lisboa","Sistema"]

func _ready() -> void:
	layer = 30; process_mode = Node.PROCESS_MODE_ALWAYS
	screen = Control.new(); screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(screen)
	var theme := Theme.new(); theme.default_font_size = 17
	theme.set_color("font_color","Label",Color("e8dfc8"))
	for state in ["normal","hover","pressed","focus","disabled"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color("28524f") if state in ["hover","pressed"] else Color("122f31")
		box.border_color = Color("c8b17a") if state == "focus" else Color("55756b")
		box.set_border_width_all(2 if state == "focus" else 1); box.set_corner_radius_all(4)
		box.content_margin_left = 13; box.content_margin_right = 13; box.content_margin_top = 8; box.content_margin_bottom = 8
		theme.set_stylebox(state,"Button",box)
		if state == "disabled": theme.set_color("font_disabled_color","Button",Color("85938a"))
	screen.theme = theme
	var shade := ColorRect.new(); shade.color = Color(0.015,0.035,0.04,0.88)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); screen.add_child(shade)
	var panel := PanelContainer.new(); panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 42; panel.offset_right = -42; panel.offset_top = 32; panel.offset_bottom = -32
	var box := StyleBoxFlat.new(); box.bg_color = Color("102a2e"); box.border_color = Color("b39b65")
	box.set_border_width_all(1); box.set_content_margin_all(24); box.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel",box); screen.add_child(panel)
	var column := VBoxContainer.new(); column.add_theme_constant_override("separation",15); panel.add_child(column)
	var header := HBoxContainer.new(); column.add_child(header)
	var title := label("MAR DE JADE  /  PORTUGAL",25,Color("e6cb8d")); title.size_flags_horizontal = Control.SIZE_EXPAND_FILL; header.add_child(title)
	wallet = label("",21,Color("e6cb8d")); header.add_child(wallet)
	button(header,"Retomar  ·  Esc",func(): close_requested.emit())
	var navigation := HBoxContainer.new(); navigation.add_theme_constant_override("separation",7); column.add_child(navigation)
	for name in tab_names:
		tabs[name] = button(navigation,name,switch_page.bind(name)); tabs[name].size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(HSeparator.new())
	content = HBoxContainer.new(); content.size_flags_vertical = Control.SIZE_EXPAND_FILL; content.add_theme_constant_override("separation",24); column.add_child(content)
	var scroll := ScrollContainer.new(); scroll.custom_minimum_size.x = 270; scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; content.add_child(scroll)
	summary = VBoxContainer.new(); summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL; summary.add_theme_constant_override("separation",8); scroll.add_child(summary)
	content.add_child(VSeparator.new())
	var middle := ScrollContainer.new(); middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL; middle.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; content.add_child(middle)
	listing = VBoxContainer.new(); listing.size_flags_horizontal = Control.SIZE_EXPAND_FILL; listing.add_theme_constant_override("separation",8); middle.add_child(listing)
	content.add_child(VSeparator.new())
	var right := ScrollContainer.new(); right.custom_minimum_size.x = 300; right.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; content.add_child(right)
	details = VBoxContainer.new(); details.size_flags_horizontal = Control.SIZE_EXPAND_FILL; details.add_theme_constant_override("separation",14); right.add_child(details)
	column.add_child(HSeparator.new())
	notice = label("",16,Color("e6cb8d")); notice.custom_minimum_size.y = 24; column.add_child(notice)
	column.add_child(label("Setas / comando · navegar     Enter / A · escolher     Esc / B · voltar",14,Color("a3bab0")))
	screen.hide()

func label(value: String, font_size: int = 17, color := Color("e8dfc8")) -> Label:
	var node := Label.new(); node.text = value; node.add_theme_font_size_override("font_size",font_size)
	node.add_theme_color_override("font_color",color); node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node

func paragraph(parent: Control, value: String, color := Color("b4c7bd")) -> Label:
	var node := label(value,17,color); node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL; parent.add_child(node); return node

func button(parent: Control, text: String, callback: Callable) -> Button:
	var node := Button.new(); node.text = text; node.custom_minimum_size.y = 42
	node.pressed.connect(callback); parent.add_child(node); return node

func clear(parent: Node) -> void:
	for child in parent.get_children(): parent.remove_child(child); child.queue_free()

func open(initial: String = "Personagem") -> void:
	page = initial; filter = "Todos"; selected = ""; pending_sale = ""; screen.show(); refresh()
	notice.text = "O capítulo guarda no início da etapa; a mochila conserva as tuas alterações."
	tabs[page].grab_focus()

func close() -> void:
	screen.hide(); pending_sale = ""

func switch_page(value: String) -> void:
	page = value; selected = ""; filter = "Todos"; pending_sale = ""; refresh()
	tabs[page].grab_focus()

func refresh() -> void:
	clear(summary); clear(listing); clear(details); row_buttons.clear(); action_button = null
	var p = ChapterProgress
	wallet.text = "%d reais" % p.coins
	for name in tabs: tabs[name].modulate = Color("e6cb8d") if name == page else Color.WHITE
	var hero_name := label(CampaignProfile.hero_name,29,Color("e6cb8d"))
	hero_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; hero_name.tooltip_text = CampaignProfile.hero_name; summary.add_child(hero_name)
	summary.add_child(label("19 anos  ·  Aprendiz",16))
	var art := TextureRect.new(); art.custom_minimum_size = Vector2(244,160)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var atlas := AtlasTexture.new(); atlas.atlas = load("res://assets/art/combat/portugal/hero-v1.png")
	var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/combat/portugal/frames.json"))
	var rect: Array = manifest.entries.hero.frames[0]
	atlas.region = Rect2(rect[0],rect[1],rect[2],rect[3]); art.texture = atlas; summary.add_child(art)
	summary.add_child(label(Items.STYLES[p.style],22,Color("e6cb8d")))
	paragraph(summary,"Em recuperação · aguarda o tratamento de Tomé." if p.flags.get("injured",false) else "Fundamento" if p.flags.get("recovered",false) else "Antes do ensino de Tomé")
	var stats := Items.stats(p)
	for key in ["hp","qi","posture"]:
		var value := "%d / %d" % [int(p.vitals[key]),int(stats[key])]
		summary.add_child(label(Items.STAT_NAMES[key]+"    "+value,18))
		var meter := ProgressBar.new(); meter.max_value = stats[key]; meter.value = p.vitals[key]; meter.show_percentage = false; meter.custom_minimum_size.y = 7; summary.add_child(meter)
	paragraph(summary,"Potência %d   ·   Proteção %d\nVelocidade %d   ·   Movimento 5" % [stats.power,stats.defense,stats.speed])
	paragraph(summary,"Passivas  %d/4   ·   Duarte  %d/4" % [p.equipped_passives.size(),p.duarte_equipped_passives.size()])
	match page:
		"Personagem": character_page()
		"Inventário","Equipamento","Loja de Lisboa": inventory_page()
		"Técnicas","Passivas": knowledge_page()
		"Sistema": system_page()

func character_page() -> void:
	listing.add_child(label("Preparação para a viagem",25,Color("e6cb8d")))
	paragraph(listing,"Os teus equipamentos, técnicas aprendidas e suprimentos seguem contigo.")
	listing.add_child(HSeparator.new())
	for slot in Items.SLOTS:
		var id: String = ChapterProgress.equipment.get(slot,"")
		button(listing,Items.SLOTS[slot]+"  ·  "+(Items.items()[id].name if not id.is_empty() else "Livre"),func():
			switch_page("Equipamento")
			if not id.is_empty(): select_item(id))
	button(listing,"Abrir a sacola",switch_page.bind("Inventário"))
	button(listing,"Ver técnicas e passivas",switch_page.bind("Técnicas"))
	details.add_child(label("Portugal · Capítulo 1",22,Color("e6cb8d")))
	paragraph(details,director.blocks[director.scene_index].title)
	paragraph(details,"O equipamento aumenta os atributos a partir dos treinos de Tomé. Trocar uma peça não recupera vida ou alento.")
	paragraph(details,"Tomé repõe pelo menos 8 de alento no início de cada aula de manejo.")
	paragraph(details,"O serviço no cais rende 40 reais, uma única vez.")

func shop_reason() -> String:
	if director.busy or ChapterProgress.flags.get("injured",false): return "Termina esta sequência e recupera antes de visitar a loja."
	if director.map_kind not in ["cais","service","plaza","courtyard"] or ChapterProgress.flags.get("embarked",false): return "A loja fica em Lisboa. Visita-a nas pausas no cais, na praça ou no pátio."
	if director.phase not in ["block_end","styles","styles_result","equipment","exploration"]: return "Termina esta etapa para visitar a loja numa pausa segura."
	return ""

func inventory_page() -> void:
	var shopping := page == "Loja de Lisboa"
	listing.add_child(label("Provisões de Lisboa" if shopping else page,25,Color("e6cb8d")))
	if shopping:
		var reason := shop_reason()
		if not reason.is_empty(): paragraph(listing,reason); return
		var trade_tabs := HBoxContainer.new(); listing.add_child(trade_tabs)
		for mode in ["Comprar","Vender"]: button(trade_tabs,("• " if trading == mode else "")+mode,func(): trading = mode; selected = ""; pending_sale = ""; refresh())
		paragraph(listing,"Estoque limitado · preço por unidade · venda a metade do preço",Color("a3bab0"))
	var filters := HBoxContainer.new(); listing.add_child(filters)
	for value in ["Todos","Peças","Usáveis","História"]:
		button(filters,("• " if filter == value else "")+value,func(): filter = value; selected = ""; refresh())
	var count := 0
	for id in Items.items():
		var row: Dictionary = Items.items()[id]
		var amount: int = int(ChapterProgress.shop_stock.get(id,0)) if shopping and trading == "Comprar" else int(ChapterProgress.inventory.get(id,0))
		if shopping and trading == "Comprar":
			if not row.tradeable or row.price == null: continue
		elif amount <= 0: continue
		if page == "Equipamento" and row.slot == null: continue
		if filter == "Peças" and row.slot == null: continue
		if filter == "Usáveis" and not row.has("recovery"): continue
		if filter == "História" and row.tradeable: continue
		count += 1
		var suffix := "   ×%d" % amount
		if shopping: suffix += "   ·   %d reais" % (int(row.price) if trading == "Comprar" else maxi(1,int(row.price)/2)) if row.price != null else "   ·   Protegido"
		elif ChapterProgress.equipment.values().has(id): suffix += "   ·   Equipado"
		var node := button(listing,row.name+suffix,select_item.bind(id))
		node.alignment = HORIZONTAL_ALIGNMENT_LEFT; node.icon = load(row.icon); node.expand_icon = true
		node.add_theme_constant_override("icon_max_width",46); node.custom_minimum_size.y = 66
		node.tooltip_text = row.description; row_buttons[id] = node
	if count == 0: paragraph(listing,"Não tens objetos nesta categoria.")
	if not selected.is_empty() and row_buttons.has(selected): draw_item()
	else: paragraph(details,"Escolhe um objeto para ver a descrição, a raridade e as ações.")

func select_item(id: String) -> void:
	selected = id; pending_sale = ""; clear(details); draw_item()
	details.get_parent().set_deferred("scroll_vertical",0)
	if row_buttons.has(id): row_buttons[id].grab_focus()

func draw_item() -> void:
	action_button = null
	var row: Dictionary = Items.items()[selected]
	var color := Color(row.rarity_color)
	var icon := TextureRect.new(); icon.texture = load(row.icon); icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; icon.custom_minimum_size = Vector2(270,170); details.add_child(icon)
	paragraph(details,row.name,Color("e6cb8d")).add_theme_font_size_override("font_size",24)
	paragraph(details,"Nv. %d · %s" % [row.rarity_level,row.rarity_name],color)
	paragraph(details,row.description)
	if not row.tradeable: paragraph(details,"História / serviço · protegido",Color("e6cb8d"))
	if row.slot != null:
		paragraph(details,Items.SLOTS[row.slot]+"  ·  "+Items.describe_stats(row.stats))
		if row.has("style") and not ChapterProgress.tested_styles.has(row.style): paragraph(details,"Para equipar: experimenta "+Items.STYLES[row.style]+" com Tomé.")
		var current: String = ChapterProgress.equipment.get(row.slot,"")
		paragraph(details,"Equipado: "+(Items.items()[current].name if not current.is_empty() else "Livre"))
		var delta: Dictionary = row.stats.duplicate()
		if not current.is_empty():
			for key in Items.items()[current].stats: delta[key] = int(delta.get(key,0))-int(Items.items()[current].stats[key])
		details.add_child(label("Se trocares:",16))
		var differences := false
		for key in delta:
			if int(delta[key]) == 0: continue
			differences = true
			paragraph(details,"%s %+d" % [Items.STAT_NAMES.get(key,key),int(delta[key])],Color("8cd7b7") if delta[key] > 0 else Color("e4a598"))
		if not differences: paragraph(details,"Sem alteração de atributos.")
	var p = ChapterProgress
	if page == "Loja de Lisboa":
		var reason := Items.buy_reason(p,selected) if trading == "Comprar" else Items.sell_reason(p,selected)
		var price: int = int(row.price) if trading == "Comprar" else maxi(1,int(row.price)/2) if row.price != null else 0
		var verb := trading+" 1 · %d reais" % price
		action_button = button(details,verb,trade_selected)
		action_button.disabled = not reason.is_empty()
		if not reason.is_empty(): paragraph(details,reason)
	elif row.slot != null:
		var equipped: bool = p.equipment.values().has(selected)
		var reason := Items.equip_reason(p,selected)
		if equipped and row.slot == "weapon" and not p.tested_styles.has("PU"): reason = "Experimenta desarmado com Tomé antes de retirar a arma."
		action_button = button(details,"Retirar" if equipped else "Equipar",func():
			var message := Items.unequip(p,row.slot) if equipped else Items.equip(p,selected)
			refresh(); notice.text = message
			if row_buttons.has(selected): row_buttons[selected].grab_focus())
		action_button.disabled = not reason.is_empty()
		if not reason.is_empty(): paragraph(details,reason)
	elif row.has("recovery"):
		var reason := Items.use_reason(p,selected)
		action_button = button(details,"Usar 1 unidade",func():
			var message := Items.use(p,selected); refresh(); notice.text = message
			if row_buttons.has(selected): row_buttons[selected].grab_focus()
			else: tabs[page].grab_focus())
		action_button.disabled = not reason.is_empty()
		if not reason.is_empty(): paragraph(details,reason)
	# The primary action stays above long descriptions and comparison rows.
	if action_button != null: details.move_child(action_button,3)

func trade_selected() -> void:
	# Explicit review for selling a possession; buying already shows cost and stock.
	if trading == "Vender" and pending_sale != selected:
		pending_sale = selected; action_button.text = "Confirmar venda de 1 unidade"; return
	var message := Items.buy(ChapterProgress,selected) if trading == "Comprar" else Items.sell(ChapterProgress,selected)
	pending_sale = ""; refresh(); notice.text = message
	if row_buttons.has(selected): row_buttons[selected].grab_focus()
	else: tabs[page].grab_focus()

func knowledge_page() -> void:
	var passive := page == "Passivas"
	listing.add_child(label("Passivas · quatro vagas por pessoa" if passive else "Técnicas aprendidas",24,Color("e6cb8d")))
	var rows: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_01/"+("passives.json" if passive else "skill_icons.json")))["passives" if passive else "skills"]
	var owned: Array = ChapterProgress.passives if passive else ChapterProgress.skills
	var count := 0
	for row in rows:
		if not owned.has(row.id): continue
		count += 1
		var equipped: Array = ChapterProgress.duarte_equipped_passives if row.id.begins_with("DU") else ChapterProgress.equipped_passives
		var node := button(listing,("✓ " if passive and equipped.has(row.id) else "")+row.name+(" · Duarte" if row.id.begins_with("DU") else ""),show_knowledge.bind(row,passive))
		node.icon = load(row.icon); node.expand_icon = true; node.add_theme_constant_override("icon_max_width",46); node.custom_minimum_size.y = 62
	if count == 0: paragraph(listing,"Tomé ainda não ensinou estas práticas.")
	paragraph(details,"Escolhe uma prática para consultar os detalhes.")

func show_knowledge(row: Dictionary, passive: bool) -> void:
	clear(details); paragraph(details,row.name,Color("e6cb8d")).add_theme_font_size_override("font_size",24)
	paragraph(details,"Nv. %d · %s" % [row.rarity_level,row.rarity_name],Color(row.rarity_color))
	if not passive:
		paragraph(details,"Aprendida · "+("Duarte" if row.id.begins_with("DU") else CampaignProfile.hero_name))
		if row.id in ["ES07","LA07","MC08","FO07","PU07"]:
			var style: String = row.id.substr(0,2)
			var rules = preload("res://scripts/combat/campaign_rules.gd").new()
			rules.start_encounter("school",CampaignProfile.hero_name,style)
			var definition: Dictionary = rules.skill_def(0,1)
			paragraph(details,"%s · %d alento\nPotência %d · Alcance %d" % [Items.STYLES[style],definition.cost,definition.power,definition.range])
			paragraph(details,definition.description)
			if ChapterProgress.style != style: paragraph(details,"Equipa o manejo de "+Items.STYLES[style]+" para preparar esta técnica.")
		elif row.id == "DP01": paragraph(details,"Reage no sinal do golpe inimigo. Bom/Perfeito dependem do timing e da orientação da guarda.")
		elif row.id == "DU01": paragraph(details,"6 alento · alcance 1. Duarte prepara uma interceptação: 60% do residual para o aliado e 40% para si.")
		elif row.id == "DU02": paragraph(details,"Prática de Duarte registada. Neste capítulo, o exercício de apoio disponibiliza o básico e Guarda Companheira.")
		paragraph(details,"A linha de ações do combate mostra as técnicas disponíveis em cada exercício.")
		return
	paragraph(details,row.effect); paragraph(details,row.limit)
	var equipped: Array = ChapterProgress.duarte_equipped_passives if row.owner == "duarte" else ChapterProgress.equipped_passives
	var active := equipped.has(row.id)
	var node := button(details,"Retirar passiva" if active else "Equipar passiva",func():
		if equipped.has(row.id): equipped.erase(row.id)
		elif equipped.size() < 4: equipped.append(row.id)
		var message := Items.persist(ChapterProgress,"Passivas atualizadas.")
		refresh(); show_knowledge(row,true); notice.text = message; tabs[page].grab_focus())
	node.disabled = (not active and equipped.size() >= 4) or not ChapterProgress.flags.get("recovered",false)
	details.move_child(node,2)
	if not active and equipped.size() >= 4: paragraph(details,"Retira uma passiva antes de equipar outra.")

func system_page() -> void:
	listing.add_child(label("Capítulo e progresso",25,Color("e6cb8d")))
	paragraph(listing,"Carregar regressa ao início da etapa guardada, com os teus itens e moedas. Recomeçar repete a etapa atual.")
	button(listing,"Guardar capítulo",func(): save_requested.emit())
	button(listing,"Carregar último save",func():
		clear(details); paragraph(details,"Regressar ao início da etapa guardada?")
		button(details,"Confirmar carregamento",func(): load_requested.emit()))
	button(listing,"Recomeçar esta etapa",func():
		clear(details); paragraph(details,"Repetir a etapa atual? Os teus objetos e moedas serão conservados.")
		button(details,"Confirmar reinício",func(): restart_requested.emit()))

func _input(event: InputEvent) -> void:
	if not screen.visible: return
	if event.is_action_pressed("ui_cancel") or (event is InputEventJoypadButton and event.pressed and event.button_index in [JOY_BUTTON_B,JOY_BUTTON_START]):
		get_viewport().set_input_as_handled(); close_requested.emit()
