extends CanvasLayer
## One pause/journal for childhood scenes; it never advances the narrative cursor.
const Plan = preload("res://scripts/city/convent_plan.gd")
const Forest = preload("res://scripts/city/forest_plan.gd")
const House = preload("res://scripts/city/house_life.gd")
var host
var screen: Control
var sheet: PanelContainer
var column: VBoxContainer
var opened := false
var settings_open := false
var previous_pause := false
var previous_focus: WeakRef
var page := "pause"
var message := ""
var pending_binding := ""
var progress:
	get: return get_node("/root/ChapterProgress")

static func install(director) -> Node:
	var menu := new(); menu.name = "ChildhoodMenu"; menu.host = director; director.add_child(menu); return menu

func _ready() -> void:
	layer = 35; process_mode = Node.PROCESS_MODE_ALWAYS
	if not InputMap.has_action("journal"):
		var bindings = preload("res://scripts/main.gd").new(); bindings.configure_input(); bindings.free()
	screen = Control.new(); screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(screen)
	screen.theme = preload("res://scripts/ui/presentation.gd").theme()
	var shade := ColorRect.new(); shade.color = Color(.02,.04,.04,.93); shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); screen.add_child(shade)
	sheet = PanelContainer.new(); sheet.add_theme_stylebox_override("panel",preload("res://scripts/ui/presentation.gd").panel()); screen.add_child(sheet)
	var scroll := ScrollContainer.new(); scroll.follow_focus = true; scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; sheet.add_child(scroll)
	column = VBoxContainer.new(); column.size_flags_horizontal = Control.SIZE_EXPAND_FILL; column.add_theme_constant_override("separation",12); scroll.add_child(column)
	screen.hide()

func battle_active() -> bool:
	return host.get("phase")=="battle"

func open(which: String = "pause") -> void:
	if battle_active(): return
	if not opened:
		previous_pause = get_tree().paused
		var focus = get_viewport().gui_get_focus_owner()
		previous_focus = weakref(focus) if focus!=null else null
		opened = true; host.paused = true; get_tree().paused = true
	page = which; screen.show(); refresh()

func close() -> void:
	if not opened: return
	opened = false; pending_binding = ""; screen.hide()
	host.paused = false; get_tree().paused = previous_pause
	var focus = previous_focus.get_ref() if previous_focus!=null else null
	if is_instance_valid(focus) and focus.is_visible_in_tree(): focus.grab_focus()
	else: get_viewport().gui_release_focus()

func text(value: String, title: bool = false) -> void:
	var label := Label.new(); label.text = value; label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",GamePreferences.font_size(24 if title else 18)); column.add_child(label)
	if page in ["journal","history"]:
		label.focus_mode = Control.FOCUS_ALL
		label.focus_entered.connect(func(): label.modulate = Color("e6cb8d"))
		label.focus_exited.connect(func(): label.modulate = Color.WHITE)

func button(value: String, action: Callable) -> Button:
	var item := Button.new(); item.text = value; item.custom_minimum_size.y = 42; item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.add_theme_font_size_override("font_size",GamePreferences.font_size(18)); item.pressed.connect(action); column.add_child(item); return item

func refresh() -> void:
	for child in column.get_children(): column.remove_child(child); child.queue_free()
	text("Infância · Caderno" if page=="journal" else "Infância · Pausa",true)
	if not message.is_empty(): text(message)
	if page=="journal": journal()
	elif page=="history":
		text("Conversas · últimas 200 falas guardadas com a campanha",true)
		for row in progress.dialogue_history:
			text(row.speaker+" · "+row.text)
		if progress.dialogue_history.is_empty(): text("Ainda não há falas registradas.")
	var back := button("Retomar",close)
	button("Pausa e opções" if page=="journal" else "Caderno · objetivo, pedidos e descobertas",func(): page = "pause" if page=="journal" else "journal"; message = ""; refresh())
	button("Conversas",func(): page = "history"; message = ""; refresh())
	button("Guardar progresso",save_game)
	button("Som, leitura e combate",settings)
	if page=="pause":
		for action in ["interact","journal","quick_save"]:
			var caption: String = {"interact":"Interagir","journal":"Caderno","quick_save":"Guardar"}[action]
			button(caption+" · "+OS.get_keycode_string(GamePreferences.bindings[action]),func(): pending_binding = action; message = "Prime a nova tecla. Esc/B cancela."; refresh())
	text("Guardar conserva o percurso livre. Falas e combates retomam o início da etapa.")
	if page in ["journal","history"]: column.get_child(0).grab_focus()
	else: back.grab_focus()

func journal() -> void:
	text(GamePreferences.hint_text("Setas / direcional · percorrer     Esc / B · retomar"))
	var hunt: bool = host.scene_file_path.ends_with("forest_hunt.tscn")
	if hunt:
		var stage: int = mini(8,int(host.state.stage))
		text("Objetivo · "+Forest.LABELS[stage])
		text(preload("res://scripts/chapter/childhood_bond.gd").hint(stage))
	else:
		var objective := "Explora a casa da Ordem. Leonor espera junto do banco na praça."
		if not host.scene_file_path.ends_with("plaza.tscn"): objective = {"opening.tscn":"Conversa com Tomé no acolhimento.","training.tscn":"Aprende os fundamentos com Leonor.","promise.tscn":"Partilha a promessa com Leonor."}.get(host.scene_file_path.get_file(),objective)
		text("Objetivo · "+objective)
	if not House.stage(progress,true).is_empty(): text("A água da casa · "+House.objective(progress,true))
	text("Lugares conhecidos",true)
	var found := false
	for id in Plan.NOTES:
		if Plan.observed(progress,id): text(Plan.NOTES[id].title+"\n"+Plan.NOTES[id].text); found = true
	for id in progress.childhood_hunt.get("notes",[]):
		text(Forest.DISCOVERIES[id].title+"\n"+Forest.DISCOVERIES[id].text); found = true
	if not found: text("As descobertas que observares ficam aqui para reler.")

func save_game() -> void:
	var was_auto: bool = progress.auto_save
	progress.auto_save = false
	if host.has_method("save"): host.save()
	elif host.get("roam")!=null and host.get("phase") in ["childhood_explore","childhood_note"]: host.roam.save()
	progress.auto_save = was_auto
	var result: Error = progress.save_to() if was_auto else OK
	message = "Progresso guardado." if result==OK else progress.last_error
	refresh()

func settings() -> void:
	settings_open = true
	var options := preload("res://scripts/ui/preferences_panel.gd").new(); add_child(options)
	options.closed.connect(func(): settings_open = false; refresh())

func _process(_delta: float) -> void:
	if not opened: return
	var viewport := get_viewport().get_visible_rect().size
	sheet.size = Vector2(minf(760,viewport.x-48),minf(column.get_combined_minimum_size().y+40,viewport.y-48))
	sheet.position = (viewport-sheet.size)*.5

func _input(event: InputEvent) -> void:
	if settings_open or battle_active(): return
	if opened and not pending_binding.is_empty():
		if event.is_action_pressed("ui_cancel") or (event is InputEventJoypadButton and event.pressed and event.button_index==JOY_BUTTON_B): pending_binding = ""; message = "Alteração cancelada."; refresh()
		elif event is InputEventKey and event.pressed and not event.echo:
			message = GamePreferences.bind_key(pending_binding,event.physical_keycode); pending_binding = ""; refresh()
		get_viewport().set_input_as_handled(); return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel") or (opened and event is InputEventJoypadButton and event.pressed and event.button_index==JOY_BUTTON_B):
		if opened: close()
		else: open()
		get_viewport().set_input_as_handled(); return
	if event.is_action_pressed("journal"):
		if opened and page=="journal": close()
		else: open("journal")
		get_viewport().set_input_as_handled(); return
	if event.is_action_pressed("quick_save"):
		if not opened: open()
		save_game(); get_viewport().set_input_as_handled()

func _unhandled_input(_event: InputEvent) -> void:
	if opened: get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	if opened: get_tree().paused = previous_pause
