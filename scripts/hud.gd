extends CanvasLayer
signal choice_selected(action: String)
signal menu_action(action: String)
var root: Control
var modal_kind: String = ""
var title: Label
var objective: Label
var prompt: Label
var footer: Label
var notice: Label
var notice_time: float = 0.0
var dialogue_panel: PanelContainer
var dialogue_title: Label
var dialogue_body: Label
var choices: VBoxContainer
var pause_panel: PanelContainer
var journal_panel: PanelContainer
var journal_body: Label
var gamepad: bool = false
var serif: SystemFont
var state

func _ready() -> void:
	layer = 10
	serif = SystemFont.new()
	serif.font_names = PackedStringArray(["Georgia","Times New Roman"])
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = _theme()
	add_child(root)
	var shade = ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	shade.offset_bottom = 115
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader = Shader.new()
	shader.code = "shader_type canvas_item; void fragment(){COLOR=vec4(0.025,0.075,0.08,pow(1.0-UV.y,1.4)*0.82);}"
	var material = ShaderMaterial.new()
	material.shader = shader
	shade.material = material
	root.add_child(shade)
	_build_header()
	_build_objective()
	_build_footer()
	_build_dialogue()
	_build_pause()
	_build_journal()
	notice = _label("",16,Color("dfc78f"))
	notice.add_theme_color_override("font_outline_color",Color(0.025,0.065,0.065,0.9))
	notice.add_theme_constant_override("outline_size",5)
	notice.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	notice.position = Vector2(-400,-126)
	notice.size = Vector2(800,32)
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(notice)

func _theme() -> Theme:
	var theme = Theme.new()
	theme.default_font_size = 18
	theme.set_color("font_color","Label",Color("e6dfcc"))
	for pair in [["normal","1c3538"],["hover","2e4b4a"],["pressed","3b5650"],["focus","2a4745"]]:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(pair[1])
		style.border_color = Color("8b805e")
		style.set_border_width_all(1)
		style.set_corner_radius_all(3)
		style.content_margin_left = 18
		style.content_margin_right = 18
		style.content_margin_top = 11
		style.content_margin_bottom = 11
		if pair[0] == "focus":
			style.border_color = Color("e5c787")
			style.set_border_width_all(2)
		theme.set_stylebox(pair[0],"Button",style)
	theme.set_color("font_color","Button",Color("e7e0cd"))
	theme.set_color("font_hover_color","Button",Color("fff3cf"))
	theme.set_color("font_focus_color","Button",Color("fff3cf"))
	return theme

func _label(text: String, size: int = 18, color: Color = Color("e6dfcc")) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _panel() -> PanelContainer:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.065,0.12,0.13,0.95)
	style.border_color = Color(0.64,0.57,0.38,0.65)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 25
	style.content_margin_right = 25
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel",style)
	return panel

func _build_header() -> void:
	var brand = _label("MAR DE JADE",29,Color("eee5cc"))
	brand.add_theme_font_override("font",serif)
	brand.position = Vector2(38,25)
	root.add_child(brand)
	var chapter = _label("O MUNDO ALÉM DO CAIS",11,Color("b8b598"))
	chapter.position = Vector2(40,65)
	root.add_child(chapter)
	var location = VBoxContainer.new()
	location.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	location.position = Vector2(-200,24)
	location.size = Vector2(400,70)
	location.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(location)
	var region = _label("LISBOA   /   TEJO",12,Color("d2bf8b"))
	region.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	location.add_child(region)
	title = _label("Cais do Tejo",28)
	title.add_theme_font_override("font",serif)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	location.add_child(title)
	var actions = HBoxContainer.new()
	actions.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	actions.position = Vector2(-296,33)
	actions.add_theme_constant_override("separation",10)
	root.add_child(actions)
	for item in [["Diário","journal"],["Menu","pause"]]:
		var button = Button.new()
		button.text = item[0]
		var action = item[1]
		button.pressed.connect(func(): menu_action.emit(action))
		actions.add_child(button)

func _build_objective() -> void:
	var card = _panel()
	card.position = Vector2(38,125)
	card.custom_minimum_size = Vector2(260,0)
	card.size = Vector2(260,0)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(card)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation",8)
	card.add_child(box)
	var heading = _label("UM PORTO À VISTA",12,Color("cdbb88"))
	box.add_child(heading)
	objective = _label("",16)
	objective.custom_minimum_size.x = 210
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(objective)

func _build_footer() -> void:
	prompt = _label("",18,Color("f3e5bc"))
	prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	prompt.position = Vector2(-420,-91)
	prompt.size = Vector2(840,36)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(prompt)
	footer = _label("",13,Color("c5c6b0"))
	footer.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	footer.position = Vector2(-610,-42)
	footer.size = Vector2(1220,25)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(footer)
	_update_footer()

func _build_dialogue() -> void:
	dialogue_panel = _panel()
	dialogue_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	dialogue_panel.position = Vector2(-465,-385)
	dialogue_panel.size = Vector2(930,340)
	root.add_child(dialogue_panel)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation",15)
	dialogue_panel.add_child(box)
	dialogue_title = _label("",25,Color("e5c787"))
	dialogue_title.add_theme_font_override("font",serif)
	box.add_child(dialogue_title)
	dialogue_body = _label("",19)
	dialogue_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_body.custom_minimum_size = Vector2(870,122)
	box.add_child(dialogue_body)
	choices = VBoxContainer.new()
	choices.add_theme_constant_override("separation",8)
	box.add_child(choices)
	dialogue_panel.hide()

func _build_pause() -> void:
	pause_panel = _panel()
	pause_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	pause_panel.position = Vector2(-200,-205)
	pause_panel.custom_minimum_size = Vector2(400,400)
	root.add_child(pause_panel)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation",12)
	pause_panel.add_child(box)
	var heading = _label("Mar de Jade",32,Color("e5d7af"))
	heading.add_theme_font_override("font",serif)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(heading)
	for item in [["Continuar","resume"],["Guardar viagem","save"],["Carregar viagem","load"],["Alternar ecrã inteiro","fullscreen"],["Sair","quit"]]:
		var button = Button.new()
		button.text = item[0]
		var action = item[1]
		button.pressed.connect(func(): menu_action.emit(action))
		box.add_child(button)
	pause_panel.hide()

func _build_journal() -> void:
	journal_panel = _panel()
	journal_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	journal_panel.position = Vector2(-310,-225)
	journal_panel.custom_minimum_size = Vector2(620,400)
	root.add_child(journal_panel)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation",18)
	journal_panel.add_child(box)
	var heading = _label("Caderno de viagem",30,Color("e5c787"))
	heading.add_theme_font_override("font",serif)
	box.add_child(heading)
	journal_body = _label("",19)
	journal_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	journal_body.custom_minimum_size = Vector2(560,200)
	box.add_child(journal_body)
	var close = Button.new()
	close.text = "Continuar a explorar"
	close.pressed.connect(close_modal)
	box.add_child(close)
	journal_panel.hide()

func refresh(session, map_title: String = "") -> void:
	state = session
	objective.text = session.objective()
	if not map_title.is_empty():
		title.text = map_title
	var a = "✓" if session.phase != "arrival" else "◇"
	var b = "✓" if session.known_manifest else "◇"
	var c = "✓" if session.phase == "complete" else "◇"
	journal_body.text = "UM PORTO À VISTA\n\n%s Falar com o escrivão.\n%s Consultar o registo no armazém.\n%s Voltar ao cais.\n\n%s" % [a,b,c,session.objective()]

func set_context(text: String) -> void:
	prompt.text = ("A   ·   " if gamepad else "E   ·   ") + text if not text.is_empty() and modal_kind.is_empty() else ""

func show_dialogue(data: Dictionary) -> void:
	close_modal()
	modal_kind = "dialogue"
	dialogue_title.text = data["speaker"]
	dialogue_body.text = data["text"]
	for child in choices.get_children():
		choices.remove_child(child)
		child.queue_free()
	for choice in data["choices"]:
		var button = Button.new()
		button.text = choice["text"]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var action = str(choice["action"])
		button.pressed.connect(func(): close_modal(); choice_selected.emit(action))
		choices.add_child(button)
	dialogue_panel.show()
	choices.get_child(0).grab_focus()

func show_pause() -> void:
	close_modal()
	modal_kind = "pause"
	pause_panel.show()
	pause_panel.get_child(0).get_child(1).grab_focus()

func show_journal() -> void:
	close_modal()
	modal_kind = "journal"
	journal_panel.show()
	journal_panel.get_child(0).get_child(2).grab_focus()

func close_modal() -> void:
	modal_kind = ""
	dialogue_panel.hide()
	pause_panel.hide()
	journal_panel.hide()
	var focused = root.get_viewport().gui_get_focus_owner()
	if focused != null:
		focused.release_focus()

func show_notice(text: String) -> void:
	notice.text = text
	notice_time = 3.5

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if event is InputEventJoypadMotion and absf(event.axis_value) < 0.3:
			return
		gamepad = true
	elif event is InputEventKey or event is InputEventMouseButton:
		gamepad = false
	_update_footer()

func _update_footer() -> void:
	if footer != null:
		footer.text = "Analógico / direcional · mover     A · interagir     X · correr     Y · diário     LB / RB · zoom     Start · menu" if gamepad else "WASD / setas · mover     Clique · caminhar     E · interagir     Shift · correr     Roda · zoom     J · diário     F5 / F9 · guardar / carregar     Esc · menu"

func _process(delta: float) -> void:
	notice_time = maxf(0,notice_time-delta)
	notice.modulate.a = clampf(notice_time,0,1)
	notice.visible = modal_kind.is_empty()
