extends Node2D
## Approved shelter scene: spoken turns, visible gestures, then a covered exit.
@export_file("*.json") var sequence_path: String = "res://data/chapter_01/opening.json"
@export_file("*.tscn") var next_scene_path: String = ""
signal scene_finished(scene_id: String)
const Walk = preload("res://scripts/chapter/staged_walk.gd")
const Transition = preload("res://scripts/chapter/scene_transition.gd")
var sequence: Dictionary
var event_index := -1
var completed := false
var busy := false
var paused := false
var leaving := false
var stage := "conversation"
var _status_before_pause := ""
var speaker: Label
var body: Label
var next_button: Button
var status: Label
var panel: PanelContainer
var view: CanvasLayer
var room: Node2D
var child: Node2D
var tome: Node2D
var framing
var previous_button: Button
var turn_counter: Label
var history: Array[Dictionary] = []
var history_cursor := -1
var line_total := 0
var speaker_labels: Dictionary = {}
var step_voices: Dictionary = {}
var step_distances: Dictionary = {}
var last_positions: Dictionary = {}
var footstep_serial := 0
var _initial_child: Dictionary
var _initial_tome: Dictionary

func _ready() -> void:
	if CampaignProfile.hero_name.is_empty():
		get_tree().change_scene_to_file.call_deferred("res://scenes/chapter_01/name_entry.tscn")
		return
	# The first scene must install the controller bindings before the plaza does.
	if not InputMap.has_action("move_left"):
		var bindings = preload("res://scripts/main.gd").new(); bindings.configure_input(); bindings.free()
	ChapterProgress.enter_scene("res://scenes/chapter_01/opening.tscn")
	sequence = JSON.parse_string(FileAccess.get_file_as_string(sequence_path))
	line_total = sequence.events.filter(func(event): return event.type=="line").size()
	room = get_node("Abrigo")
	child = room.get_node("ActorsAndProps/Child"); tome = room.get_node("ActorsAndProps/Tome")
	child.facing = 3; tome.facing = 3; child.empty_bowl = true
	room.get_node("ActorsAndProps/Table/Bowl").empty_bowl = true
	_initial_child = {"position":child.position,"posture":child.posture,"carries_bowl":child.carries_bowl}
	_initial_tome = {"position":tome.position,"posture":tome.posture}
	get_node("Camera").enabled = false
	framing = preload("res://scripts/chapter/chapter_framing.gd").install(self,[child,tome],2.0)
	framing.bias = Vector2(0,23); framing.camera.position = framing.target()
	_build_interface()
	advance()
	Transition.reveal(self)

func _build_interface() -> void:
	view = preload("res://scripts/chapter/dialogue_view.gd").new(); add_child(view)
	speaker = view.speaker; body = view.body; status = view.status; panel = view.panel; next_button = view.next_button
	view.continuation_requested.connect(_continue_pressed); view.replay_requested.connect(restart)
	var controls: HBoxContainer = next_button.get_parent()
	turn_counter = Label.new(); turn_counter.name = "TurnCounter"; turn_counter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	turn_counter.add_theme_font_size_override("font_size",13); turn_counter.add_theme_color_override("font_color",Color("a6b6aa"))
	controls.add_child(turn_counter); controls.move_child(turn_counter,0)
	previous_button = Button.new(); previous_button.name = "ReadPrevious"; previous_button.text = "← Reler"
	previous_button.pressed.connect(read_previous); controls.add_child(previous_button); controls.move_child(previous_button,1)
	for actor in [child,tome]:
		var label := Label.new(); label.position = Vector2(-80,-76 if actor==tome else -61); label.size.x = 160
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.add_theme_font_size_override("font_size",10)
		label.add_theme_color_override("font_color",Color("e2b66c")); label.add_theme_color_override("font_shadow_color",Color("102c37"))
		label.add_theme_constant_override("shadow_offset_x",1); label.add_theme_constant_override("shadow_offset_y",1)
		label.z_index = 4; label.hide(); actor.add_child(label); speaker_labels[actor] = label
		var voice := AudioStreamPlayer.new(); voice.stream = preload("res://assets/audio/combat/footstep_wood.wav")
		voice.bus = GamePreferences.effects_bus
		voice.volume_db = -31 if actor==child else -28; room.add_child(voice)
		step_voices[actor] = voice; step_distances[actor] = 0.0; last_positions[actor] = actor.position

func _process(_delta: float) -> void:
	if paused: return
	# Maré de Ferro also triggers footsteps by travelled distance, never a timer.
	for actor in step_voices:
		var distance: float = actor.position.distance_to(last_positions[actor])
		last_positions[actor] = actor.position
		if not actor.walking: step_distances[actor] = 0.0; continue
		step_distances[actor] += distance
		if step_distances[actor]>=26:
			step_distances[actor] = fmod(step_distances[actor],26)
			footstep_serial += 1
			if DisplayServer.get_name()!="headless": step_voices[actor].play()

func _continue_pressed() -> void:
	if busy or paused or leaving: return
	if history_cursor<history.size()-1:
		history_cursor += 1; _show_turn(); return
	if completed:
		if next_scene_path.is_empty(): restart()
		else:
			leaving = true; next_button.disabled = true; previous_button.disabled = true
			Transition.travel(get_tree(),next_scene_path)
	else: advance()

func read_previous() -> void:
	if busy or paused or leaving or history_cursor<=0: return
	history_cursor -= 1; _show_turn()

func _show_turn() -> void:
	var turn: Dictionary = history[history_cursor]
	speaker.text = CampaignProfile.speaker_name(turn.speaker); body.text = turn.text
	speaker.visible = not turn.get("narration",false)
	body.add_theme_color_override("font_color",Color("a6b6aa") if turn.get("narration",false) else Color("eee5cc"))
	turn_counter.visible = not turn.get("narration",false)
	turn_counter.text = "Fala %02d / %02d"%[history_cursor+1,line_total]
	previous_button.visible = history_cursor>0
	next_button.text = "Continuar"
	if history_cursor==history.size()-1:
		if completed: next_button.text = "Continuar para a praça" if not next_scene_path.is_empty() else "Rever a cena"
		elif history_cursor==line_total-1: next_button.text = "Acompanhar Tomé"
	view.hint.text = "Enter / espaço / A · continuar     ← / Reler · fala anterior     Esc · pausar"
	for actor in speaker_labels:
		var label: Label = speaker_labels[actor]
		label.text = speaker.text
		label.visible = not turn.get("narration",false) and ((actor==tome and turn.speaker=="Tomé") or (actor==child and turn.speaker=="Herói criança"))
	status.text = ""
	next_button.grab_focus()

func restart() -> void:
	if busy or paused or leaving: return
	child.position = _initial_child.position; child.posture = _initial_child.posture; child.carries_bowl = _initial_child.carries_bowl
	tome.position = _initial_tome.position; tome.posture = _initial_tome.posture
	for actor in [child,tome]:
		actor.facing = 3; actor.seat_support = false; actor.seat_lift = 0.0; actor.z_index = 0; actor.walking = false; actor.frame_time = 0
	room.get_node("ActorsAndProps/Table/Bowl").hide()
	event_index = -1; completed = false; stage = "conversation"; history.clear(); history_cursor = -1
	view.replay_button.hide(); advance()

func advance() -> void:
	if busy or completed or paused or leaving: return
	while event_index+1<sequence.events.size():
		event_index += 1
		var event: Dictionary = sequence.events[event_index]
		match event.type:
			"line":
				history.append(event); history_cursor = history.size()-1; _show_turn(); return
			"tome_sits":
				_begin_gesture("sitting")
				await _wait(0.18)
				tome.position = room.get_node("Staging/TomeAtSeat").position; tome.posture = "seated"; tome.facing = 1
				await _wait(0.42)
				_end_gesture()
			"to_table":
				await _to_table()
			"end":
				completed = true; stage = "complete"
				history.append({"speaker":"Um lugar à mesa","text":"A tigela vai à mesa. Não volta escondida para debaixo da cama.","narration":true})
				history_cursor = history.size()-1; _show_turn()
				scene_finished.emit(sequence.id); return

func _begin_gesture(id: String) -> void:
	stage = id; busy = true; next_button.disabled = true; previous_button.disabled = true; panel.hide(); status.text = ""
	view.hint.text = "Esc · pausar"
	for label in speaker_labels.values(): label.hide()

func _end_gesture() -> void:
	stage = "conversation"; busy = false; next_button.disabled = false; previous_button.disabled = false; panel.show()

func _wait(seconds: float) -> void:
	var beat := room.create_tween(); beat.tween_interval(seconds); await beat.finished

func _to_table() -> void:
	_begin_gesture("rising")
	await _wait(0.25)
	tome.posture = "standing"; await _wait(0.28)
	child.posture = "standing"; await _wait(0.22)
	stage = "walking"
	var route: Node = room.get_node("Staging")
	var tome_points: Array[Vector2] = [route.get_node("TomeFrontLeft").position,route.get_node("TomeFrontRight").position,route.get_node("TomeAtTable").position]
	var child_points: Array[Vector2] = [route.get_node("ChildApproach").position,route.get_node("ChildAtTable").position]
	var tome_walk := Walk.along(tome,tome_points,room,74)
	var child_walk := Walk.along(child,child_points,room,57,0.55)
	while tome_walk.is_running() or child_walk.is_running(): await get_tree().process_frame
	child.facing = 3; tome.facing = 1
	stage = "placing_bowl"; await _wait(0.25)
	var bowl := Sprite2D.new(); bowl.texture = load("res://assets/art/items/portugal/PT-Q02.png"); bowl.z_index = 8
	room.add_child(bowl)
	var bowl_ratio := float(bowl.texture.get_height())/bowl.texture.get_width()
	bowl.position = child.position+Vector2(6,-58*0.33-19*bowl_ratio*0.5); bowl.scale = Vector2.ONE*19.0/bowl.texture.get_width()
	child.carries_bowl = false
	var place := room.create_tween().set_parallel(true)
	place.tween_property(bowl,"position",room.get_node("ActorsAndProps/Table/Bowl").global_position-room.global_position-Vector2(0,25*bowl_ratio*0.5),0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	place.tween_property(bowl,"scale",Vector2.ONE*25.0/bowl.texture.get_width(),0.5)
	await place.finished
	room.get_node("ActorsAndProps/Table/Bowl").show(); bowl.queue_free()
	child.posture = "seated"; tome.posture = "seated"
	child.seat_support = true; tome.seat_support = true; child.seat_lift = 14.0
	child.z_index = 1; tome.z_index = 1; child.queue_redraw(); tome.queue_redraw()
	await _wait(0.6)
	_end_gesture()

func _input(event: InputEvent) -> void:
	# Handle both edges before the focused Button: otherwise key-down advances
	# here and the Button's key-up activation advances the next spoken turn too.
	if event.is_action("ui_accept"):
		get_viewport().set_input_as_handled()
		if event.is_action_pressed("ui_accept"): _continue_pressed()
		return
	if event is InputEventKey and event.pressed and event.keycode==KEY_LEFT:
		if not event.echo: read_previous()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if view==null or leaving: return
	if event.is_action_pressed("ui_cancel") or (event is InputEventJoypadButton and event.pressed and event.button_index==JOY_BUTTON_START):
		if not paused: _status_before_pause = status.text
		paused = not paused; get_tree().paused = paused
		for voice in step_voices.values(): voice.stream_paused = paused
		status.text = "Pausa · Esc para continuar" if paused else _status_before_pause
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") and not busy and not paused:
		get_viewport().set_input_as_handled(); _continue_pressed()
