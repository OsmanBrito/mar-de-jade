extends Node2D
signal scene_finished(scene_id: String)
var world
var leonor
var view
var lessons: Array
var lesson := 0
var phase := "dialogue"
var lines: Array = []
var line_index := -1
var after_dialogue := "battle"
var paused := false
var completed := false
var first_feedback := false
var battle_host
var battle_layer: CanvasLayer
var battle_container: SubViewportContainer

func _ready() -> void:
	world = get_node("Praca")
	world.player.enabled = false
	world.player.set_physics_process(false)
	if CampaignProfile.hero_name.is_empty():
		CampaignProfile.name_entry_destination = "res://scenes/chapter_01/training.tscn"
		get_tree().change_scene_to_file.call_deferred("res://scenes/chapter_01/name_entry.tscn")
		return
	ChapterProgress.enter_scene("res://scenes/chapter_01/training.tscn")
	lessons = JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_01/training_contracts.json"))["lessons"]
	leonor = world.get_node("ActorsAndProps/Leonor")
	leonor.position = $Instructor.position
	world.player.position = $AttackStart.position
	world.player.presentation.posture = "standing"
	world.player.presentation.position = Vector2.ZERO
	world.player.camera.reset_smoothing()
	view = preload("res://scripts/chapter/dialogue_view.gd").new()
	view.caption = "Portugal · Infância\nA mão que avisa"
	add_child(view)
	view.continuation_requested.connect(advance)
	view.replay_requested.connect(func(): get_tree().reload_current_scene())
	battle_layer = CanvasLayer.new()
	battle_layer.layer = 10
	add_child(battle_layer)
	battle_container = SubViewportContainer.new()
	battle_container.size = Vector2(960,540)
	battle_container.stretch = true
	battle_layer.add_child(battle_container)
	preload("res://scripts/combat/battle_stage.gd").install(battle_layer,battle_container)
	var viewport := SubViewport.new()
	viewport.world_2d = World2D.new()
	viewport.size = Vector2i(960,540)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	battle_container.add_child(viewport)
	battle_host = preload("res://scripts/combat/battle_host.gd").new()
	viewport.add_child(battle_host)
	battle_host.lesson_completed.connect(_battle_finished)
	get_viewport().size_changed.connect(_resize_battle)
	_resize_battle()
	battle_container.hide()
	_dialogue(0,0,7,"battle")

func _resize_battle() -> void:
	preload("res://scripts/combat/battle_stage.gd").fit(battle_container,get_viewport_rect().size)

func _dialogue(id: int, start: int, end: int, next: String) -> void:
	phase = "dialogue"
	lines = lessons[id]["lines"].slice(start,end)
	line_index = -1
	after_dialogue = next
	battle_container.hide()
	view.show()
	view.panel.show()
	view.next_button.show()
	view.status.text = ""
	view.hint.text = "Enter / espaço · continuar     Esc · pausar"
	advance()

func advance() -> void:
	if paused: return
	if phase == "complete":
		get_tree().change_scene_to_file("res://scenes/chapter_01/promise.tscn")
		return
	if phase != "dialogue": return
	line_index += 1
	if line_index < lines.size():
		view.speaker.text = CampaignProfile.speaker_name(str(lines[line_index]["speaker"]).replace(" [defesa correta]",""))
		view.body.text = lines[line_index]["text"]
		return
	match after_dialogue:
		"defense_intro":
			lesson = 1
			view.caption_label.text = "Portugal · Infância\nNão fechar os olhos"
			_dialogue(1,0,3,"battle")
		"complete":
			phase = "complete"; completed = true
			view.speaker.text = "Treino concluído"
			view.body.text = "Ataque básico e defesa simples praticados."
			view.next_button.text = "Continuar para a promessa"
			view.replay_button.show()
			view.next_button.grab_focus()
			scene_finished.emit("C01-M01/S05")
		_:
			phase = "battle"
			view.hide()
			var focus = get_viewport().gui_get_focus_owner()
			if focus != null: focus.release_focus()
			battle_container.show()
			if after_dialogue == "resume_battle":
				battle_host.active = true
				battle_host.tactical.phase = "choose"
				battle_host.tactical.refresh_paths()
			else:
				battle_host.begin(lesson,CampaignProfile.hero_name)

func _battle_finished(success: bool) -> void:
	if lesson == 0 and success:
		scene_finished.emit("C01-M01/S04")
		_dialogue(1,0,0,"defense_intro")
	elif success:
		_dialogue(1,7,15,"complete")
	else:
		_dialogue(1,3,7,"battle")

func _process(_delta: float) -> void:
	# Preserve S04's intermediate feedback after the first actual impact and
	# its recovery animation. The battle then resumes with the action spent.
	if phase == "battle" and lesson == 0 and not first_feedback and battle_host.combat.valid_hits == 1 and battle_host.tactical.phase == "choose":
		first_feedback = true
		battle_host.active = false
		_dialogue(0,7,11,"resume_battle")

func _unhandled_input(event: InputEvent) -> void:
	if view == null or phase == "battle": return
	if event.is_action_pressed("ui_cancel") or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START):
		paused = not paused
		get_tree().paused = paused
		view.status.text = "Pausa · Esc para continuar" if paused else ""
		get_viewport().set_input_as_handled()
	elif not paused and event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		advance()




