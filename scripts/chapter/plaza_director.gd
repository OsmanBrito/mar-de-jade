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
var framing
var roam

func objective() -> String:
	if phase in ["childhood_explore","childhood_note"]:return "Encontra a Leonor junto do banco. Trouxeste água para os dois."
	if not walking_stage.is_empty():return "Chega até à marca de Leonor, contornando o banco."
	if completed:return "Experimenta a vara de treino com Leonor, junto do alvo."
	return "Conversa com Leonor junto do banco."

func _ready() -> void:
	preload("res://scripts/chapter/childhood_pacing.gd").install(self)
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
	view.independent_exploration_hud=true
	view.caption = "Portugal · Infância\nO banco da praça"
	add_child(view)
	view.continuation_requested.connect(func():
		if completed:
			preload("res://scripts/chapter/scene_transition.gd").travel(get_tree(),"res://scenes/chapter_01/training.tscn")
		else:
			advance())
	view.replay_requested.connect(restart)
	framing = preload("res://scripts/chapter/chapter_framing.gd").install(self,[world.player,leonor],1.65)
	_set_staged(true)
	world.player.presentation.posture = "seated"
	world.player.z_index = 1 # Seated body overlaps the bench's front edge.
	world.player.presentation.position.y = 0
	world.player.camera.reset_smoothing()
	roam = preload("res://scripts/chapter/childhood_roam.gd").new(self)
	roam.begin()
	preload("res://scripts/chapter/childhood_menu.gd").install(self)
	preload("res://scripts/chapter/scene_transition.gd").reveal(self)

func _set_staged(staged: bool) -> void:
	if staged:
		world.player.presentation.facing = 3 if leonor.position.x>world.player.position.x else 1
		leonor.facing = 1 if leonor.position.x>world.player.position.x else 3
	if framing != null:
		framing.activate(staged)
		world.player.camera.enabled = not staged
		if not staged: world.player.camera.make_current()
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
	if phase=="childhood_note": roam.resume(); return
	if phase=="childhood_explore": return
	if busy or paused or completed or not walking_stage.is_empty():
		return
	var events: Array = data["segments"][segment]
	while event_index+1 < events.size():
		event_index += 1
		var event: Dictionary = events[event_index]
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
			view.speaker.text = "Leonor criança"
			view.body.text = "Anda. Pega na vara que deixei junto do banco."
			view.remember(view.speaker.text,view.body.text)
			view.status.text = ""
			view.next_button.text = "Treinar com Leonor"
			view.replay_button.hide()
			view.next_button.grab_focus()
			scene_finished.emit("C01-M01/S03")

func _stage(action: String) -> void:
	match action:
		"share_bench":
			var seat:Vector2=world.get_node("Staging/ChildInSun").position
			var walk=preload("res://scripts/chapter/staged_walk.gd")
			var hers:Tween=walk.along(leonor,[world.get_node("Staging/LeonorSeat").position],world,100)
			await walk.along(world.player,[Vector2(world.player.position.x,400),Vector2(seat.x,400),seat],world,110).finished
			if hers.is_running():await hers.finished
			world.player.presentation.posture="seated"
			leonor.posture = "seated"
		"cups":
			world.get_node("ActorsAndProps/Bench/Cups").show()
		"stand":
			leonor.posture = "standing"
			await preload("res://scripts/chapter/staged_walk.gd").along(leonor,[Vector2(170,400),world.get_node("Staging/LeonorStanding").position],world,130).finished
		"first_positions":
			world.player.z_index = 0 # Restore normal depth sorting for exploration.
			world.player.presentation.posture = "standing"
			world.player.presentation.position = Vector2.ZERO
			var walk=preload("res://scripts/chapter/staged_walk.gd")
			var hers:Tween=walk.along(leonor,[Vector2(220,400),world.get_node("Staging/LeonorFirst").position],world,160)
			await walk.along(world.player,[Vector2(23,400),Vector2(-150,400),world.get_node("Staging/FirstStart").position],world,160).finished
			if hers.is_running():await hers.finished
			world.player.camera.reset_smoothing()
		"second_positions":
			await preload("res://scripts/chapter/staged_walk.gd").along(leonor,[Vector2(285,280),Vector2(-165,280),world.get_node("Staging/LeonorSecond").position],world,200).finished

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
	if phase=="childhood_explore" and roam!=null: roam.update(); return
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
	world.player.z_index = 1
	world.player.presentation.position.y = 0
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
		if phase in ["childhood_explore","childhood_note"]: roam.save()
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
	if phase in ["childhood_explore","childhood_note"]:
		if phase=="childhood_note":
			if event.is_action_pressed("ui_accept"): roam.resume(); get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("interact"):
			roam.interact(); get_viewport().set_input_as_handled(); return
		if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
			roam.click(world.get_global_transform_with_canvas().affine_inverse()*event.position); get_viewport().set_input_as_handled()
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




