extends CanvasLayer
## Shared presentation for staged chapter scenes.
signal continuation_requested
signal replay_requested
var caption := "Portugal · Infância\nUm lugar à mesa"
var speaker: Label
var body: Label
var status: Label
var caption_label: Label
var hint: Label
var panel: PanelContainer
var next_button: Button
var replay_button: Button

func _ready() -> void:
	var control = Control.new()
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(control)
	var shade = ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	shade.offset_bottom = 120
	shade.color = Color(0.035,0.075,0.08,0.78)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	control.add_child(shade)
	var header = _label("MAR DE JADE",28)
	header.position = Vector2(34,22)
	control.add_child(header)
	caption_label = _label(caption,23)
	caption_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	caption_label.position = Vector2(-270,24)
	caption_label.size.x = 540
	caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	control.add_child(caption_label)
	status = _label("",15)
	status.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	status.position = Vector2(-400,88)
	status.size.x = 800
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	control.add_child(status)
	panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	panel.position = Vector2(-435,-236)
	panel.size = Vector2(870,200)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.065,0.12,0.13,0.96)
	style.border_color = Color("8b805e")
	style.set_border_width_all(1)
	style.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel",style)
	control.add_child(panel)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation",12)
	panel.add_child(box)
	speaker = _label("",22)
	speaker.add_theme_color_override("font_color",Color("e5c787"))
	box.add_child(speaker)
	body = _label("",23)
	body.custom_minimum_size = Vector2(830,48)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(body)
	var buttons = HBoxContainer.new()
	box.add_child(buttons)
	next_button = Button.new()
	next_button.text = "Continuar"
	next_button.custom_minimum_size.y = 40
	next_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next_button.pressed.connect(func(): continuation_requested.emit())
	buttons.add_child(next_button)
	replay_button = Button.new()
	replay_button.text = "Rever a cena"
	replay_button.pressed.connect(func(): replay_requested.emit())
	buttons.add_child(replay_button)
	replay_button.hide()
	var footer_shade = ColorRect.new()
	footer_shade.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer_shade.offset_top = -42
	footer_shade.color = Color(0.035,0.075,0.08,0.78)
	footer_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	control.add_child(footer_shade)
	hint = _label("Enter / espaço / clique · continuar     Esc · pausar",14)
	hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	hint.position = Vector2(-520,-26)
	hint.size.x = 1040
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	control.add_child(hint)

func _label(value: String, font_size: int) -> Label:
	var label = Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",Color("eee5cc"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
