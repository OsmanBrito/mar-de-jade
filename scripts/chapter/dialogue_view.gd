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
var root: Control
var content_scroll: ScrollContainer
var content_box: VBoxContainer
var last_body_text := ""
var history: Array[Dictionary] = []
var last_record := ""
var hint_source := ""
var rendered_hint := ""
const Presentation = preload("res://scripts/ui/presentation.gd")

func _ready() -> void:
	var control = Control.new()
	root = control
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(control)
	var shade = ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	shade.offset_bottom = 108
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(0.025,0.06,0.06,0.85),Color(0.025,0.06,0.06,0)])
	var texture := GradientTexture2D.new(); texture.gradient = gradient; texture.fill_from = Vector2.ZERO; texture.fill_to = Vector2(0,1)
	var material := ShaderMaterial.new()
	var shader := Shader.new(); shader.code = "shader_type canvas_item; uniform sampler2D fade; void fragment(){COLOR=texture(fade,UV);}"
	material.shader = shader; material.set_shader_parameter("fade",texture); shade.material = material
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	control.add_child(shade)
	var header = _label("MAR DE JADE",19)
	header.position = Vector2(34,22)
	control.add_child(header)
	caption_label = _label(caption,19)
	caption_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	caption_label.position = Vector2(-270,24)
	caption_label.size.x = 540
	caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	control.add_child(caption_label)
	status = _label("",15)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_color_override("font_outline_color",Color("102b2e"))
	status.add_theme_constant_override("outline_size",4)
	status.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	status.position = Vector2(-400,78)
	status.size.x = 800
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	control.add_child(status)
	panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	panel.position = Vector2(-480,-210)
	panel.size = Vector2(960,156)
	var style = Presentation.panel(Color("132c30"),Presentation.GOLD)
	style.content_margin_left = 26
	style.content_margin_right = 26
	style.content_margin_top = 20
	style.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel",style)
	control.add_child(panel)
	content_scroll = ScrollContainer.new()
	content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_scroll.follow_focus = true
	panel.add_child(content_scroll)
	var box = VBoxContainer.new()
	content_box = box
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation",12)
	content_scroll.add_child(box)
	speaker = _label("",22)
	speaker.add_theme_color_override("font_color",Color("e5c787"))
	box.add_child(speaker)
	body = _label("",23)
	body.custom_minimum_size = Vector2(0,38)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(body)
	var buttons = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	box.add_child(buttons)
	next_button = Button.new()
	next_button.text = "Continuar"
	next_button.custom_minimum_size = Vector2(142,40)
	next_button.size_flags_horizontal = Control.SIZE_SHRINK_END
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
	control.theme = Presentation.theme()
	GamePreferences.changed.connect(_preferences_changed)
	_preferences_changed()

func _preferences_changed() -> void:
	if not is_instance_valid(body): return
	body.add_theme_font_size_override("font_size",GamePreferences.font_size(23))
	speaker.add_theme_font_size_override("font_size",GamePreferences.font_size(22))
	next_button.add_theme_font_size_override("font_size",GamePreferences.font_size(17))

func remember(who: String,words: String) -> void:
	if who.is_empty() or words.is_empty() or last_record==who+"\n"+words: return
	last_record = who+"\n"+words
	history.append({"speaker":who,"text":words})
	if history.size()>100: history.pop_front()

func _process(_delta: float) -> void:
	if hint!=null:
		if hint.text!=rendered_hint: hint_source = hint.text
		rendered_hint = GamePreferences.hint_text(hint_source); hint.text = rendered_hint
	if panel == null or not panel.is_visible_in_tree(): return
	if body.text!=last_body_text:
		last_body_text = body.text
		content_scroll.scroll_vertical = 0
	var viewport_size := get_viewport().get_visible_rect().size
	var width := minf(1000,viewport_size.x-64)
	panel.offset_left = -width*0.5
	panel.offset_right = width*0.5
	var height := clampf(content_box.get_combined_minimum_size().y+38,170,maxf(170,viewport_size.y-190))
	panel.offset_bottom = -54
	panel.offset_top = -54-height
	# Resizing always follows content, including choices and passive equipment.
	# Scrollbars handle the exceptional long menu without pushing text offscreen.
	caption_label.offset_left = -minf(300,viewport_size.x*0.25)
	caption_label.offset_right = minf(300,viewport_size.x*0.25)

func _label(value: String, font_size: int) -> Label:
	var label = Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",Color("eee5cc"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
