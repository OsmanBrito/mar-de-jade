extends Node2D
const Session = preload("res://scripts/session.gd")
const Hud = preload("res://scripts/hud.gd")
const MAP_SCENES = {"cais":preload("res://scenes/maps/cais.tscn"),"armazem":preload("res://scenes/maps/armazem.tscn")}
const SAVE_PATH = "user://viagem.json"
var session = Session.new()
var hud
var world
var conversations: Dictionary
var transitioning: bool = false
var fade_layer: CanvasLayer
var fade: ColorRect

func _ready() -> void:
	configure_input()
	conversations = JSON.parse_string(FileAccess.get_file_as_string("res://data/conversations.json"))
	hud = Hud.new()
	add_child(hud)
	hud.choice_selected.connect(_on_choice)
	hud.menu_action.connect(_on_menu)
	session.changed.connect(_refresh)
	fade_layer = CanvasLayer.new()
	fade_layer.layer = 30
	add_child(fade_layer)
	fade = ColorRect.new()
	fade.color = Color("101e20")
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.modulate.a = 0
	fade_layer.add_child(fade)
	_mount_map("cais")
	hud.show_notice("O mundo começa onde termina o caminho conhecido.")

func configure_input() -> void:
	var keys = {"move_left":[KEY_A,KEY_LEFT],"move_right":[KEY_D,KEY_RIGHT],"move_up":[KEY_W,KEY_UP],"move_down":[KEY_S,KEY_DOWN],"interact":[KEY_E],"run":[KEY_SHIFT],"journal":[KEY_J,KEY_TAB],"pause":[KEY_ESCAPE],"quick_save":[KEY_F5],"quick_load":[KEY_F9],"fullscreen":[KEY_F11]}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action,0.22)
		for key in keys[action]:
			var event = InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action,event)
	var buttons = {"move_left":JOY_BUTTON_DPAD_LEFT,"move_right":JOY_BUTTON_DPAD_RIGHT,"move_up":JOY_BUTTON_DPAD_UP,"move_down":JOY_BUTTON_DPAD_DOWN,"interact":JOY_BUTTON_A,"run":JOY_BUTTON_X,"journal":JOY_BUTTON_Y,"pause":JOY_BUTTON_START,"zoom_out":JOY_BUTTON_LEFT_SHOULDER,"zoom_in":JOY_BUTTON_RIGHT_SHOULDER}
	for action in buttons:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var button = InputEventJoypadButton.new()
		button.button_index = buttons[action]
		InputMap.action_add_event(action,button)
	for config in [["move_left",JOY_AXIS_LEFT_X,-1.0],["move_right",JOY_AXIS_LEFT_X,1.0],["move_up",JOY_AXIS_LEFT_Y,-1.0],["move_down",JOY_AXIS_LEFT_Y,1.0]]:
		var motion = InputEventJoypadMotion.new()
		motion.axis = config[1]
		motion.axis_value = config[2]
		InputMap.action_add_event(config[0],motion)
	var accept = InputEventKey.new()
	accept.physical_keycode = KEY_E
	InputMap.action_add_event("ui_accept",accept)
	var accept_pad := InputEventJoypadButton.new()
	accept_pad.button_index = JOY_BUTTON_A
	if not InputMap.action_has_event("ui_accept",accept_pad): InputMap.action_add_event("ui_accept",accept_pad)

func _mount_map(map_id: String, entrance: String = "") -> void:
	if world != null:
		remove_child(world)
		world.queue_free()
	world = MAP_SCENES[map_id].instantiate()
	add_child(world)
	move_child(world,0)
	world.interaction_requested.connect(_on_interaction)
	if session.has_position and session.map_id == map_id and entrance.is_empty():
		world.player.position = world.safe_spawn(session.player_position)
	elif map_id == "cais" and entrance == "armazem":
		for door in world.interactions:
			if door.definition["id"] == "warehouse_door":
				world.player.position = door.position+Vector2(15,35)
	session.map_id = map_id
	if map_id == "armazem":
		session.visited_warehouse = true
	world.player.camera.reset_smoothing()
	_refresh()

func transition_to(map_id: String) -> void:
	if transitioning or not MAP_SCENES.has(map_id):
		return
	transitioning = true
	hud.close_modal()
	world.player.enabled = false
	var origin = session.map_id
	var tween = create_tween()
	tween.tween_property(fade,"modulate:a",1.0,0.22)
	await tween.finished
	session.has_position = false
	_mount_map(map_id,origin)
	tween = create_tween()
	tween.tween_property(fade,"modulate:a",0.0,0.3)
	await tween.finished
	transitioning = false

func _process(_delta: float) -> void:
	if world == null:
		return
	var text = str(world.closest.definition.get("title","")) if world.closest != null else ""
	hud.set_context(text)

func _physics_process(_delta: float) -> void:
	if world != null:
		world.player.enabled = hud.modal_kind.is_empty() and not transitioning

func _unhandled_input(event: InputEvent) -> void:
	if world == null or transitioning:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		if hud.modal_kind.is_empty():
			hud.show_pause()
		else:
			hud.close_modal()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("fullscreen"):
		_on_menu("fullscreen")
	elif event.is_action_pressed("quick_save"):
		_save()
	elif event.is_action_pressed("quick_load"):
		_load()
	elif event.is_action_pressed("journal"):
		if hud.modal_kind == "journal":
			hud.close_modal()
		else:
			hud.show_journal()
	elif hud.modal_kind.is_empty():
		if event.is_action_pressed("interact"):
			world.interact()
		elif event.is_action_pressed("zoom_in"):
			world.player.set_zoom(0.1)
		elif event.is_action_pressed("zoom_out"):
			world.player.set_zoom(-0.1)
		elif event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				world.walk_to(world.get_global_mouse_position())
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
				world.player.set_zoom(0.07)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				world.player.set_zoom(-0.07)

func _on_interaction(definition: Dictionary) -> void:
	match definition["kind"]:
		"door":
			transition_to(definition["destination"])
		"npc":
			hud.show_dialogue(conversations[session.dialogue_id()])
		"ledger":
			hud.show_dialogue(conversations["manifest"])
		"observe":
			hud.show_dialogue(conversations["river"])

func _on_choice(action: String) -> void:
	session.apply_action(action)
	if action == "accept_errand":
		hud.show_notice("Caderno atualizado · Um porto à vista")
	elif action == "read_manifest":
		hud.show_notice("Registo consultado")
	elif action == "finish_errand":
		hud.show_notice("Um porto à vista · concluído")

func _refresh() -> void:
	if hud != null:
		hud.refresh(session,str(world.spec["title"]) if world != null else "")

func _on_menu(action: String) -> void:
	match action:
		"pause": hud.show_pause()
		"resume": hud.close_modal()
		"journal":
			if hud.modal_kind == "journal": hud.close_modal()
			else: hud.show_journal()
		"save": _save()
		"load": _load()
		"fullscreen":
			var fullscreen = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN)
		"quit": get_tree().quit()

func _save() -> void:
	session.map_id = world.map_id
	session.player_position = world.player.position
	session.has_position = true
	var result = session.save_to(SAVE_PATH)
	hud.show_notice("Viagem guardada." if result == OK else "Não foi possível guardar. O ficheiro anterior foi preservado.")

func _load() -> void:
	var result = session.load_from(SAVE_PATH)
	if result == OK:
		hud.close_modal()
		_mount_map(session.map_id)
		hud.show_notice("Viagem recuperada.")
	else:
		hud.show_notice("Ainda não há uma viagem guardada." if result == ERR_FILE_NOT_FOUND else "O ficheiro não pôde ser carregado. A viagem atual foi preservada.")

