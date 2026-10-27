extends Node2D
## S06 connects the childhood promise to the approved adult opening.
signal scene_finished(scene_id: String)
@export_file("*.json") var sequence_path := "res://data/chapter_01/promise.json"
var world
var child: Node2D
var leonor: Node2D
var view: CanvasLayer
var sequence: Dictionary
var event_index := -1
var busy := false
var paused := false
var completed := false
var _status_before_pause := ""
var framing: Node

func _ready() -> void:
	preload("res://scripts/chapter/childhood_pacing.gd").install(self)
	world = get_node("Praca")
	world.player.enabled = false
	world.player.set_physics_process(false)
	if CampaignProfile.hero_name.is_empty():
		CampaignProfile.name_entry_destination = "res://scenes/chapter_01/promise.tscn"
		get_tree().change_scene_to_file.call_deferred("res://scenes/chapter_01/name_entry.tscn")
		return
	ChapterProgress.enter_scene("res://scenes/chapter_01/promise.tscn")
	child = world.player.presentation
	leonor = world.get_node("ActorsAndProps/Leonor")
	sequence = JSON.parse_string(FileAccess.get_file_as_string(sequence_path))
	sequence.events=preload("res://scripts/chapter/childhood_bond.gd").promise(ChapterProgress)+sequence.events
	world.player.enabled = false
	world.player.set_physics_process(false)
	world.player.destination_path.clear()
	for shape in world.player.get_children():
		if shape is CollisionShape2D:
			shape.set_deferred("disabled",true)
	view = preload("res://scripts/chapter/dialogue_view.gd").new()
	view.caption = "Portugal · Infância\nA primeira promessa"
	add_child(view)
	view.continuation_requested.connect(_continue_pressed)
	view.replay_requested.connect(restart)
	world.player.camera.enabled = false
	framing = preload("res://scripts/chapter/chapter_framing.gd").install(self,[world.player,leonor],1.65)
	restart()
	preload("res://scripts/chapter/childhood_menu.gd").install(self)

func restart() -> void:
	if busy or paused:
		return
	completed = false
	event_index = -1
	world.player.position = world.get_node("Staging/ChildInSun").position
	world.player.velocity = Vector2.ZERO
	child.posture = "seated"
	world.player.z_index = 1 # The seat is behind the seated body, not in front of it.
	child.position = Vector2.ZERO
	child.carries_cup = true
	child.cup_lift = 0.0
	child.walking = false
	child.facing = 3
	leonor.position = world.get_node("Staging/LeonorSeat").position
	leonor.posture = "seated"
	leonor.carries_cup = false
	leonor.carries_training_tool = false
	leonor.cup_lift = 0.0
	leonor.walking = false
	leonor.facing = 1
	framing.subjects = [world.player,leonor]
	world.set_meta("intimate_scene_people",framing.subjects)
	framing.camera.global_position = framing.target()
	world.get_node("ActorsAndProps/Bench/Cups").hide()
	world.get_node("ActorsAndProps/ReservedTools").hide()
	world.get_node("ActorsAndProps/ReturnTools").show()
	world.get_node("ActorsAndProps/ReturnTools").count = 3
	world.player.camera.reset_smoothing()
	view.next_button.show()
	view.next_button.text = "Continuar"
	view.replay_button.hide()
	view.hint.text = "Enter / espaço / clique · continuar     Esc · pausar"
	advance()

func _continue_pressed() -> void:
	if busy or paused: return
	if completed:
		preload("res://scripts/chapter/scene_transition.gd").travel(get_tree(),"res://scenes/chapter_01/adult_opening.tscn")
	else:
		advance()

func advance() -> void:
	if busy or paused or completed:
		return
	while event_index+1 < sequence["events"].size():
		event_index += 1
		var event: Dictionary = sequence["events"][event_index]
		if event["type"] == "line":
			view.speaker.text = CampaignProfile.speaker_name(event["speaker"])
			view.body.text = event["text"]
			view.remember(view.speaker.text,view.body.text)
			view.status.text = ""
			view.next_button.grab_focus()
			return
		busy = true
		view.next_button.disabled = true
		await _stage(event["type"])
		busy = false
		view.next_button.disabled = false
	completed = true
	view.panel.show()
	view.speaker.text = "A primeira promessa"
	view.body.text = "O instrumento dele ficou junto do dela, para amanhã."
	view.status.text = ""
	view.next_button.show()
	view.next_button.text = "Continuar para o presente"
	view.replay_button.hide()
	view.next_button.grab_focus()
	scene_finished.emit(sequence["id"])

func _stage(action: String) -> void:
	match action:
		"give_water":
			child.carries_cup = false
			leonor.carries_cup = true
		"put_cup_down":
			var cup = world.create_tween().bind_node(leonor)
			cup.tween_property(leonor,"cup_lift",-5.0,0.3)
			await cup.finished
			leonor.carries_cup = false
			leonor.cup_lift = 0.0
			world.get_node("ActorsAndProps/Bench/Cups").show()
		"reserve_tools":
			view.panel.hide()
			leonor.posture = "standing"
			var tween = preload("res://scripts/chapter/staged_walk.gd").along(leonor,[Vector2(130,383),Vector2(180,354)],world,58.0)
			await tween.finished
			leonor.facing = 2
			leonor.posture = "crouched"
			await _beat(0.4)
			world.get_node("ActorsAndProps/ReturnTools").count = 1
			leonor.posture = "standing"
			leonor.carries_training_tool = true
			await preload("res://scripts/chapter/staged_walk.gd").along(leonor,[Vector2(146,378)],world,52.0).finished
			leonor.posture = "crouched"
			await _beat(0.35)
			leonor.carries_training_tool = false
			world.get_node("ActorsAndProps/ReservedTools").show()
			await _beat(0.35)
			leonor.posture = "standing"
			leonor.facing = 1
			view.panel.show()
		"leave":
			view.panel.hide()
			view.status.text = ""
			# Keep the farewell with the child and tomorrow's instruments.
			framing.subjects = [world.player,world.get_node("ActorsAndProps/ReservedTools")]
			world.set_meta("intimate_scene_people",framing.subjects)
			await _beat(0.45)
			var tween = preload("res://scripts/chapter/staged_walk.gd").along(leonor,[Vector2(208,382),Vector2(285,330),world.get_node("Staging/LeonorExit").position],world,65.0)
			await tween.finished
			await _beat(0.8)

func _beat(seconds: float) -> void:
	# World-bound intervals respect the same pause as walking and props.
	await world.create_tween().tween_interval(seconds).finished

func _unhandled_input(event: InputEvent) -> void:
	if view == null:
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START):
		if not paused:
			_status_before_pause = view.status.text
		paused = not paused
		get_tree().paused = paused
		view.status.text = "Pausa · Esc para continuar" if paused else _status_before_pause
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_continue_pressed()
