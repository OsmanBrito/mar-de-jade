extends Node2D
## First approved narrative scene; dialogue continuation is not a story choice.
@export_file("*.json") var sequence_path: String = "res://data/chapter_01/opening.json"
@export_file("*.tscn") var next_scene_path: String = ""
signal scene_finished(scene_id: String)
var sequence: Dictionary
var event_index := -1
var completed := false
var busy := false
var paused := false
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
var _initial_child: Dictionary
var _initial_tome: Dictionary

func _ready() -> void:
	if CampaignProfile.hero_name.is_empty():
		get_tree().change_scene_to_file.call_deferred("res://scenes/chapter_01/name_entry.tscn")
		return
	ChapterProgress.enter_scene("res://scenes/chapter_01/opening.tscn")
	sequence = JSON.parse_string(FileAccess.get_file_as_string(sequence_path))
	room = get_node("Abrigo")
	child = room.get_node("ActorsAndProps/Child")
	tome = room.get_node("ActorsAndProps/Tome")
	_initial_child = {"position":child.position,"posture":child.posture,"carries_bowl":child.carries_bowl}
	_initial_tome = {"position":tome.position,"posture":tome.posture}
	_build_interface()
	advance()

func _build_interface() -> void:
	view = preload("res://scripts/chapter/dialogue_view.gd").new()
	add_child(view)
	speaker = view.speaker
	body = view.body
	status = view.status
	panel = view.panel
	next_button = view.next_button
	view.continuation_requested.connect(_continue_pressed)
	view.replay_requested.connect(restart)

func _continue_pressed() -> void:
	if busy or paused:
		return
	if completed:
		if not next_scene_path.is_empty():
			get_tree().change_scene_to_file(next_scene_path)
		else:
			restart()
	else:
		advance()

func restart() -> void:
	if busy or paused:
		return
	child.position = _initial_child["position"]
	child.posture = _initial_child["posture"]
	child.carries_bowl = _initial_child["carries_bowl"]
	tome.position = _initial_tome["position"]
	tome.posture = _initial_tome["posture"]
	room.get_node("ActorsAndProps/Table/Bowl").hide()
	event_index = -1
	completed = false
	next_button.text = "Continuar"
	view.replay_button.hide()
	advance()

func advance() -> void:
	if busy or completed or paused:
		return
	while event_index+1 < sequence["events"].size():
		event_index += 1
		var event: Dictionary = sequence["events"][event_index]
		match event["type"]:
			"line":
				speaker.text = CampaignProfile.speaker_name(event["speaker"])
				body.text = event["text"]
				status.text = ""
				next_button.grab_focus()
				return
			"tome_sits":
				tome.posture = "seated"
			"to_table":
				busy = true
				next_button.disabled = true
				panel.hide()
				status.text = "Tomé espera. O menino acompanha-o, levando a tigela."
				tome.posture = "standing"
				child.posture = "standing"
				var movement = room.create_tween().set_parallel(true)
				movement.tween_property(tome,"position",room.get_node("Staging/TomeAtTable").position,2.4)
				movement.tween_property(child,"position",room.get_node("Staging/ChildAtTable").position,2.4).set_delay(0.5)
				await movement.finished
				child.carries_bowl = false
				child.posture = "seated"
				tome.posture = "seated"
				room.get_node("ActorsAndProps/Table/Bowl").show()
				busy = false
				next_button.disabled = false
				panel.show()
			"end":
				completed = true
				speaker.text = "Um lugar à mesa"
				body.text = "A tigela vai à mesa. Não volta escondida para debaixo da cama."
				status.text = "Cena concluída"
				next_button.text = "Rever a cena" if next_scene_path.is_empty() else "Continuar para a praça"
				view.replay_button.visible = not next_scene_path.is_empty()
				next_button.grab_focus()
				scene_finished.emit(sequence["id"])
				return

func _unhandled_input(event: InputEvent) -> void:
	if view == null:
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START):
		if not paused:
			_status_before_pause = status.text
		paused = not paused
		get_tree().paused = paused
		status.text = "Pausa · Esc para continuar" if paused else _status_before_pause
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") and not busy and not paused:
		get_viewport().set_input_as_handled()
		_continue_pressed()
