extends CanvasLayer
## Shared presentation for staged chapter scenes.
signal continuation_requested
signal replay_requested
signal menu_requested(page: String)
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
var history: Array[Dictionary]:
	get: return ChapterProgress.dialogue_history
var last_record := ""
var hint_source := ""
var rendered_hint := ""
var status_source := ""
var rendered_status := ""
var guide
var brand: Label
var exploration_layout := false
var footer: ColorRect
var portrait_frame: PanelContainer
var portrait_image: TextureRect
var portrait_id := ""
var exploration_back: Panel
var interaction_back: Panel
var objective_label: Label
var interaction_label: Label
var exploration_objective := ""
var exploration_prompt := ""
var independent_exploration_hud := false
var exploration_actions: HBoxContainer
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
	exploration_back = Panel.new(); exploration_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	exploration_back.add_theme_stylebox_override("panel",Presentation.panel(Color(.055,.105,.10,.90),Color(.45,.49,.37,.7)))
	control.add_child(exploration_back); exploration_back.hide()
	var header = _label("MAR DE JADE",19)
	brand = header
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
	objective_label = _label("",15); objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.add_theme_color_override("font_color",Color("ded8bd")); objective_label.hide(); control.add_child(objective_label)
	interaction_back = Panel.new(); interaction_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interaction_back.add_theme_stylebox_override("panel",Presentation.panel(Color(.055,.105,.10,.94),Color("a99161")))
	control.add_child(interaction_back); interaction_back.hide()
	interaction_label = _label("",17); interaction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	interaction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; control.add_child(interaction_label); interaction_label.hide()
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
	var dialogue_row := HBoxContainer.new(); dialogue_row.add_theme_constant_override("separation",22); panel.add_child(dialogue_row)
	portrait_frame = PanelContainer.new(); portrait_frame.custom_minimum_size = Vector2(166,176)
	portrait_frame.add_theme_stylebox_override("panel",Presentation.panel(Color("102428"),Color("63776a")))
	dialogue_row.add_child(portrait_frame)
	portrait_image = TextureRect.new(); portrait_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; portrait_image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	portrait_frame.add_child(portrait_image); portrait_frame.hide()
	content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL; dialogue_row.add_child(content_scroll)
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
	var footer_shade = ColorRect.new(); footer = footer_shade
	footer_shade.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer_shade.offset_top = -42
	footer_shade.color = Color(0.035,0.075,0.08,0.78)
	footer_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	control.add_child(footer_shade)
	hint = _label("Enter / espaço / clique · continuar     Esc · pausar",14)
	hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	hint.position = Vector2(-520,-26)
	hint.size.x = 1040
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	control.add_child(hint)
	control.theme = Presentation.theme()
	exploration_actions = HBoxContainer.new()
	exploration_actions.add_theme_constant_override("separation",8)
	control.add_child(exploration_actions)
	for entry in [["Caderno","Pedidos"],["Menu","Sistema"]]:
		var action := Button.new(); action.text = entry[0]
		action.custom_minimum_size = Vector2(104,42)
		action.pressed.connect(func(): menu_requested.emit(entry[1]))
		exploration_actions.add_child(action)
	exploration_actions.hide()
	GamePreferences.changed.connect(_preferences_changed)
	_preferences_changed()
	guide = preload("res://scripts/chapter/journey_guide.gd").new(); guide.view = self; add_child(guide)

func _preferences_changed() -> void:
	if not is_instance_valid(body): return
	body.add_theme_font_size_override("font_size",GamePreferences.font_size(23))
	speaker.add_theme_font_size_override("font_size",GamePreferences.font_size(22))
	next_button.add_theme_font_size_override("font_size",GamePreferences.font_size(17))
	if hint!=null: hint.add_theme_font_size_override("font_size",GamePreferences.font_size(14))

func remember(who: String,words: String) -> void:
	if who.is_empty() or words.is_empty(): return
	last_record = who+"\n"+words
	preload("res://scripts/chapter/dialogue_log.gd").remember(ChapterProgress,who,words)

func set_exploration_prompt(objective: String,prompt: String) -> void:
	exploration_objective = objective; exploration_prompt = prompt
	# Preserve the status contract used by gameplay and accessibility checks.
	status.text = prompt if not prompt.is_empty() else objective

func _process(_delta: float) -> void:
	if hint!=null:
		if hint.text!=rendered_hint: hint_source = hint.text
		rendered_hint = GamePreferences.hint_text(hint_source); hint.text = rendered_hint
	if panel == null: return
	if status.text!=rendered_status: status_source = status.text
	rendered_status = GamePreferences.hint_text(status_source); status.text = rendered_status
	var window_size := get_viewport().get_visible_rect().size
	var hint_width := minf(1040,window_size.x-48)
	hint.offset_left = -hint_width/2; hint.offset_right = hint_width/2
	var footer_height := maxf(42,hint.get_minimum_size().y+18)
	footer.offset_top = -footer_height; hint.offset_top = -footer_height+9; hint.offset_bottom = -9
	var exploring := not panel.visible and not next_button.visible
	exploration_actions.visible = exploring and not menu_requested.get_connections().is_empty()
	if exploration_actions.visible:
		for action in exploration_actions.get_children(): action.add_theme_font_size_override("font_size",GamePreferences.font_size(16))
		exploration_actions.size = exploration_actions.get_combined_minimum_size()
		exploration_actions.position = Vector2(window_size.x-exploration_actions.size.x-24,24)
	if exploring!=exploration_layout:
		exploration_layout = exploring; brand.visible = not exploring
		caption_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT if exploring else Control.PRESET_CENTER_TOP)
		caption_label.offset_left = 28 if exploring else -270
		caption_label.offset_right = 728 if exploring else 270
		caption_label.offset_top = 22 if exploring else 24
		caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if exploring else HORIZONTAL_ALIGNMENT_CENTER
		status.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT if exploring else Control.PRESET_CENTER_TOP)
		status.offset_left = 28 if exploring else -400
		status.offset_right = 568 if exploring else 400
		status.offset_top = 53 if exploring else 78
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if exploring else HORIZONTAL_ALIGNMENT_CENTER
		status.max_lines_visible = 3 if exploring else -1
	if exploring:
		caption_label.offset_right = minf(728,window_size.x-28)
		status.offset_right = minf(568,window_size.x-28)
	else:
		var status_half := minf(400,(window_size.x-56)*.5)
		status.offset_left = -status_half; status.offset_right = status_half
	var city_hud: bool = exploring and not exploration_objective.is_empty() and (guide.enabled or independent_exploration_hud)
	exploration_back.visible = city_hud; objective_label.visible = city_hud
	status.visible = not city_hud
	interaction_back.visible = city_hud and not exploration_prompt.is_empty()
	interaction_label.visible = interaction_back.visible
	if city_hud:
		var hud_width := minf(450,window_size.x-48)
		caption_label.offset_left = 40; caption_label.offset_top = 29; caption_label.offset_right = hud_width+8
		caption_label.add_theme_font_size_override("font_size",GamePreferences.font_size(17))
		caption_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		objective_label.text = GamePreferences.hint_text(exploration_objective)
		objective_label.add_theme_font_size_override("font_size",GamePreferences.font_size(15))
		objective_label.position = Vector2(40,caption_label.offset_top+caption_label.get_minimum_size().y+10)
		objective_label.size = Vector2(hud_width-32,0)
		exploration_back.position = Vector2(24,18)
		exploration_back.size = Vector2(hud_width,objective_label.position.y+objective_label.get_minimum_size().y-2)
		var prompt_width := minf(660,window_size.x-80)
		interaction_label.text = GamePreferences.hint_text(exploration_prompt)
		interaction_label.add_theme_font_size_override("font_size",GamePreferences.font_size(17))
		interaction_label.size = Vector2(prompt_width-32,0)
		var prompt_height := interaction_label.get_minimum_size().y+24
		interaction_back.position = Vector2((window_size.x-prompt_width)*.5,window_size.y-footer_height-prompt_height-20)
		interaction_back.size = Vector2(prompt_width,prompt_height)
		interaction_label.position = interaction_back.position+Vector2(16,12)
	else:
		caption_label.add_theme_font_size_override("font_size",19)
		caption_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	if not panel.is_visible_in_tree(): return
	var portraits = preload("res://scripts/chapter/dialogue_portraits.gd")
	var young := caption_label.text.contains("Infância")
	var identity: String = portraits.identity(speaker.text,young,CampaignProfile.hero_name)
	if identity!=portrait_id:
		portrait_id = identity; portrait_image.texture = portraits.portrait(identity)
	portrait_frame.visible = portrait_image.texture!=null
	if body.text!=last_body_text:
		last_body_text = body.text
		content_scroll.scroll_vertical = 0
	var viewport_size := get_viewport().get_visible_rect().size
	var width := minf(1000,viewport_size.x-64)
	panel.offset_left = -width*0.5
	panel.offset_right = width*0.5
	var content_height := maxf(content_box.get_combined_minimum_size().y,176 if portrait_frame.visible else 0)
	var height := clampf(content_height+38,170,maxf(170,viewport_size.y-190))
	var bottom := maxf(54,footer_height+12)
	panel.offset_bottom = -bottom
	panel.offset_top = -bottom-height
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
