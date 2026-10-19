extends CanvasLayer
signal closed
var sheet: PanelContainer
var column: VBoxContainer
var previously_paused := false
var pending_binding := ""
var feedback := ""
var previous_focus: WeakRef
var preferences:
	get: return get_node("/root/GamePreferences")
func _ready() -> void:
	layer = 40; process_mode = Node.PROCESS_MODE_ALWAYS
	var focused := get_viewport().gui_get_focus_owner()
	previous_focus = weakref(focused) if focused!=null else null
	previously_paused = get_tree().paused; get_tree().paused = true
	var root := Control.new(); root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(root)
	root.theme = preload("res://scripts/ui/presentation.gd").theme()
	var shade := ColorRect.new(); shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); shade.color = Color(0.02,0.04,0.04,0.92); root.add_child(shade)
	sheet = PanelContainer.new(); sheet.add_theme_stylebox_override("panel",preload("res://scripts/ui/presentation.gd").panel()); root.add_child(sheet)
	var scroll := ScrollContainer.new(); scroll.follow_focus = true; scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; sheet.add_child(scroll)
	column = VBoxContainer.new(); column.size_flags_horizontal = Control.SIZE_EXPAND_FILL; column.add_theme_constant_override("separation",12); scroll.add_child(column)
	refresh()
func text(value: String) -> Label:
	var label := Label.new(); label.text = value; label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",preferences.font_size(18)); column.add_child(label); return label
func refresh() -> void:
	for child in column.get_children(): column.remove_child(child); child.queue_free()
	text("Som, leitura e combate").add_theme_font_size_override("font_size",preferences.font_size(26))
	for key in ["music","ambience","effects"]:
		var caption: String = {"music":"Música","ambience":"Ambiente","effects":"Efeitos e avisos"}[key]
		var label := text(caption+" · %d%%"%roundi(preferences.levels[key]*100))
		var slider := HSlider.new(); slider.min_value = 0; slider.max_value = 100; slider.step = 5; slider.value = preferences.levels[key]*100; slider.custom_minimum_size.y = 30; column.add_child(slider)
		slider.value_changed.connect(func(value): preferences.set_level(key,value/100.0); label.text = caption+" · %d%%"%roundi(value))
	var mute := CheckButton.new(); mute.name = "MusicMuted"; mute.text = "Silenciar música"; mute.button_pressed = preferences.music_muted; column.add_child(mute)
	mute.add_theme_font_size_override("font_size",preferences.font_size(18))
	mute.toggled.connect(func(value): preferences.set_music_muted(value))
	for key in ["wide_timing","reduced_fx","fast_combat"]:
		var toggle := CheckButton.new(); toggle.name = key; toggle.text = {"wide_timing":"Janela de timing ampliada","reduced_fx":"Reduzir efeitos e movimento","fast_combat":"Animações de combate rápidas"}[key]
		toggle.add_theme_font_size_override("font_size",preferences.font_size(18))
		toggle.button_pressed = preferences.options[key]; column.add_child(toggle)
		toggle.toggled.connect(func(value): preferences.set_option(key,value))
	var scale_button := Button.new(); scale_button.text = "Texto · %d%%"%roundi(preferences.text_scale*100); scale_button.custom_minimum_size.y = 42; column.add_child(scale_button)
	scale_button.pressed.connect(func(): preferences.set_text_scale(1.0 if preferences.text_scale>=1.19 else preferences.text_scale+0.1); refresh())
	text("As opções seguem contigo da infância à viagem. Start/Esc pausa; B/Esc volta. Remapear não altera os botões do controle.")
	if not feedback.is_empty(): text(feedback)
	for action in preferences.bindings:
		var caption: String = {"move_left":"Andar à esquerda","move_right":"Andar à direita","move_up":"Andar para cima","move_down":"Andar para baixo","interact":"Interagir","combat_move":"Combate · mover","combat_end":"Combate · fim do turno","combat_timing":"Combate · timing","combat_exit":"Sair de treino","journal":"Caderno","quick_save":"Guardar"}[action]
		var binding := Button.new(); binding.name = "Binding_"+action
		binding.text = caption+" · "+OS.get_keycode_string(preferences.bindings[action]); binding.custom_minimum_size.y = 42
		binding.add_theme_font_size_override("font_size",preferences.font_size(18)); column.add_child(binding)
		binding.pressed.connect(func(): pending_binding = action; feedback = "Prime a nova tecla para "+caption+". Esc/B cancela."; refresh())
	var restore := Button.new(); restore.text = "Restaurar teclas"; restore.custom_minimum_size.y = 42; column.add_child(restore)
	restore.pressed.connect(func(): preferences.bindings = preferences.DEFAULT_BINDINGS.duplicate(); preferences.apply_bindings(); preferences.commit(); feedback = "Teclas restauradas."; refresh())
	var back := Button.new(); back.text = "Voltar"; back.custom_minimum_size.y = 42; column.add_child(back)
	back.pressed.connect(close); back.grab_focus()
func _process(_delta: float) -> void:
	var viewport := get_viewport().get_visible_rect().size
	var size := Vector2(minf(720,viewport.x-48),minf(column.get_combined_minimum_size().y+40,viewport.y-48))
	sheet.position = (viewport-size)*0.5; sheet.size = size
func _input(event: InputEvent) -> void:
	if not pending_binding.is_empty():
		if event.is_action_pressed("ui_cancel") or (event is InputEventJoypadButton and event.pressed and event.button_index==JOY_BUTTON_B):
			pending_binding = ""; feedback = "Alteração cancelada."; refresh()
		elif event is InputEventKey and event.pressed and not event.echo:
			feedback = preferences.bind_key(pending_binding,event.physical_keycode); pending_binding = ""; refresh()
		get_viewport().set_input_as_handled(); return
	if event.is_action_pressed("ui_cancel") or (event is InputEventJoypadButton and event.pressed and event.button_index in [JOY_BUTTON_B,JOY_BUTTON_START]):
		get_viewport().set_input_as_handled(); close()
func close() -> void:
	get_tree().paused = previously_paused
	closed.emit(); queue_free()
	var focused = previous_focus.get_ref() if previous_focus!=null else null
	if is_instance_valid(focused) and focused.is_visible_in_tree(): focused.grab_focus()
func _exit_tree() -> void:
	get_tree().paused = previously_paused
