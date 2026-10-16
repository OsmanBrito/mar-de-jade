extends Node2D
signal scene_finished(scene_id: String)
const VIEW = preload("res://scripts/chapter/dialogue_view.gd")
@export_file("*.json") var sequence_path := "res://data/chapter_01/plaza.json"
var world
var leonor: Node2D
var view: CanvasLayer
var data: Dictionary
var phase := "bank"
var segment := "bank"
var event_index := -1
var walking_stage := ""
var busy := false
var paused := false
var completed := false
var blocked_hint_seen := false
var _status_before_pause := ""

func _ready() -> void:
	get_node("Praca").player.set_physics_process(false)
	if CampaignProfile.hero_name.is_empty():
		get_tree().change_scene_to_file.call_deferred("res://scenes/chapter_01/name_entry.tscn")
		return
	ChapterProgress.enter_scene("res://scenes/chapter_01/plaza.tscn")
	if not InputMap.has_action("move_left"):
		var bindings = preload("res://scripts/main.gd").new()
		bindings.configure_input()
		bindings.free()
	data = JSON.parse_string(FileAccess.get_file_as_string(sequence_path))
	world = get_node("Praca")
	leonor = world.get_node("ActorsAndProps/Leonor")
	view = VIEW.new()
	view.caption = "Portugal · Infância\nO banco da praça"
	add_child(view)
	view.continuation_requested.connect(func():
		if completed:
			get_tree().change_scene_to_file("res://scenes/chapter_01/training.tscn")
		else:
			advance())
	view.replay_requested.connect(restart)
	_set_staged(true)
	world.player.presentation.posture = "seated"
	world.player.presentation.position.y = -45
	world.player.camera.reset_smoothing()
	advance()

func _set_staged(staged: bool) -> void:
	world.player.enabled = not staged
	world.player.set_physics_process(not staged)
	world.player.destination_path.clear()
	world.player.velocity = Vector2.ZERO
	world.player.presentation.walking = false
	for shape in world.player.get_children():
		if shape is CollisionShape2D:
			shape.set_deferred("disabled",staged)

func _start_segment(id: String) -> void:
	segment = id
	event_index = -1
	_set_staged(true)
	view.panel.show()
	view.hint.text = "Enter / espaço / clique · continuar     Esc · pausar"
	advance()

func advance() -> void:
	if busy or paused or completed or not walking_stage.is_empty():
		return
	var events: Array = data["segments"][segment]
	while event_index+1 < events.size():
		event_index += 1
		var event: Dictionary = events[event_index]
		if event["type"] == "line":
			view.speaker.text = CampaignProfile.speaker_name(event["speaker"])
			view.body.text = event["text"]
			view.status.text = ""
			view.next_button.grab_focus()
			return
		busy = true
		view.next_button.disabled = true
		await _stage(event["type"])
		busy = false
		view.next_button.disabled = false
	match segment:
		"bank":
			phase = "instruction"
			view.caption_label.text = "Portugal · Infância\nO espaço entre os dois"
			_start_segment("instruction")
		"instruction", "blocked":
			_begin_walk("first")
		"arrival":
			_start_segment("repeat")
		"repeat":
			_begin_walk("second")
		"finish":
			completed = true
			phase = "complete"
			_set_staged(true)
			view.speaker.text = "O espaço entre os dois"
			view.body.text = "O primeiro exercício de movimentação está concluído."
			view.status.text = "Duas passagens concluídas"
			view.next_button.text = "Continuar para o treino"
			view.replay_button.show()
			view.next_button.grab_focus()
			scene_finished.emit("C01-M01/S03")

func _stage(action: String) -> void:
	match action:
		"share_bench":
			var tween = world.create_tween().set_parallel(true)
			tween.tween_property(world.player,"position",world.get_node("Staging/ChildInSun").position,0.5)
			tween.tween_property(leonor,"position",world.get_node("Staging/LeonorSeat").position,0.5)
			await tween.finished
			leonor.posture = "seated"
		"cups":
			world.get_node("ActorsAndProps/Bench/Cups").show()
		"stand":
			leonor.posture = "standing"
			leonor.position = world.get_node("Staging/LeonorStanding").position
		"first_positions":
			world.player.presentation.posture = "standing"
			world.player.presentation.position = Vector2.ZERO
			world.player.position = world.get_node("Staging/FirstStart").position
			leonor.position = world.get_node("Staging/LeonorFirst").position
			world.player.camera.reset_smoothing()
		"second_positions":
			var tween = world.create_tween()
			tween.tween_property(leonor,"position",world.get_node("Staging/LeonorSecond").position,0.8)
			await tween.finished

func _begin_walk(id: String) -> void:
	walking_stage = id
	phase = id
	world.rebuild_navigation()
	_set_staged(false)
	world.player.presentation.posture = "standing"
	world.player.presentation.position = Vector2.ZERO
	var target = _target()
	target.active = true
	view.panel.hide()
	var focused = get_viewport().gui_get_focus_owner()
	if focused != null:
		focused.release_focus()
	view.status.text = "Chega à marca contornando o banco." if id == "first" else "Repete o percurso a partir deste lado."
	view.hint.text = "WASD / setas / clique · mover     Shift · correr     Roda · zoom     Esc · pausar"

func _target():
	return world.get_node("Staging/FirstTarget" if walking_stage == "first" else "Staging/SecondTarget")

func _physics_process(_delta: float) -> void:
	if paused or busy or walking_stage.is_empty():
		return
	var target = _target()
	if world.player.position.distance_to(target.position) <= target.reach_radius:
		var finished_stage = walking_stage
		target.active = false
		walking_stage = ""
		phase = "arrival" if finished_stage == "first" else "finish"
		_start_segment(phase)
	elif walking_stage == "first" and not blocked_hint_seen and world.player.get_slide_collision_count() > 0:
		for i in world.player.get_slide_collision_count():
			var collider = world.player.get_slide_collision(i).get_collider()
			if collider is Node and collider.get_parent().name == &"Bench":
				blocked_hint_seen = true
				world.get_node("Staging/FirstTarget").active = false
				walking_stage = ""
				_start_segment("blocked")
				return

func restart() -> void:
	if busy or paused:
		return
	completed = false
	blocked_hint_seen = false
	walking_stage = ""
	phase = "bank"
	world.get_node("Staging/FirstTarget").active = false
	world.get_node("Staging/SecondTarget").active = false
	world.get_node("ActorsAndProps/Bench/Cups").hide()
	world.player.position = world.get_node("Spawn").position
	world.player.presentation.posture = "seated"
	world.player.presentation.position.y = -45
	leonor.position = world.get_node("Staging/LeonorArrival").position
	leonor.posture = "standing"
	world.player.camera.reset_smoothing()
	view.caption_label.text = "Portugal · Infância\nO banco da praça"
	view.next_button.show()
	view.next_button.text = "Continuar"
	view.replay_button.hide()
	_start_segment("bank")

func _unhandled_input(event: InputEvent) -> void:
	if view == null:
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START):
		if not paused:
			_status_before_pause = view.status.text
		paused = not paused
		# Only the director/UI keep processing; the world and its tweens pause.
		get_tree().paused = paused
		view.status.text = "Pausa · Esc para continuar" if paused else _status_before_pause
		get_viewport().set_input_as_handled()
		return
	if paused or busy:
		return
	if walking_stage.is_empty():
		if event.is_action_pressed("ui_accept"):
			advance()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("zoom_in"):
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




