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
var framing
var wash_stand

func objective() -> String:
	if phase=="washing":return "Leonor espera enquanto lavas a mão."
	if completed or after_dialogue=="outing_ready":
		return "Regressa com Leonor ao banco." if ChapterProgress.flags.get("hunt_completed",false) else "Vai com Leonor procurar o corço no caminho da ponte."
	return "Experimenta dois golpes no alvo com a orientação de Leonor." if lesson==0 else "Observa Leonor e mantém a guarda voltada para ela."

func _ready() -> void:
	preload("res://scripts/chapter/childhood_pacing.gd").install(self)
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
	leonor.carries_training_tool=true
	world.player.position = $AttackStart.position
	world.player.presentation.posture = "standing"
	world.player.presentation.position = Vector2.ZERO
	world.player.presentation.carries_training_tool=true
	world.player.camera.reset_smoothing()
	view = preload("res://scripts/chapter/dialogue_view.gd").new()
	view.caption = "Portugal · Infância\nA mão que avisa"
	add_child(view)
	world.player.camera.enabled=false
	framing=preload("res://scripts/chapter/chapter_framing.gd").install(self,[world.player,leonor],1.65)
	var rack:=preload("res://scenes/chapter_01/training_tools.tscn").instantiate()
	rack.position=Vector2(-215,260);world.sorted_world.add_child(rack)
	wash_stand=preload("res://scripts/chapter/childhood_training_props.gd").new()
	wash_stand.position=Vector2(-210,350);world.sorted_world.add_child(wash_stand)
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
	preload("res://scripts/chapter/childhood_menu.gd").install(self)
	preload("res://scripts/chapter/scene_transition.gd").reveal(self)
	if ChapterProgress.flags.get("child_defense_practised",false):
		if ChapterProgress.flags.get("child_forest_invited",false):_outing_ready()
		else:_prepare_outing.call_deferred()
	elif ChapterProgress.flags.get("child_attack_practised",false):
		lesson=1;view.caption_label.text="Portugal · Infância\nNão fechar os olhos";_dialogue(1,0,3,"battle")
	else:_dialogue(0,0,7,"battle")

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
		preload("res://scripts/chapter/scene_transition.gd").travel(get_tree(),"res://scenes/chapter_01/promise.tscn" if ChapterProgress.flags.get("hunt_completed",false) else "res://scenes/chapter_01/forest_hunt.tscn")
		return
	if phase != "dialogue": return
	line_index += 1
	if line_index < lines.size():
		view.speaker.text = CampaignProfile.speaker_name(str(lines[line_index]["speaker"]).replace(" [defesa correta]",""))
		view.body.text = lines[line_index]["text"]
		view.remember(view.speaker.text,view.body.text)
		if lines[line_index]["speaker"]=="Leonor criança" and view.body.text in ["Então olha antes de bater.","Olha para mim.","Vou repetir."]:
			var gesture:Tween=world.create_tween();gesture.tween_property(leonor,"tool_angle",-.5,.22);gesture.tween_property(leonor,"tool_angle",.45,.35)
		return
	match after_dialogue:
		"defense_intro":
			lesson = 1
			view.caption_label.text = "Portugal · Infância\nNão fechar os olhos"
			_dialogue(1,0,3,"battle")
		"complete":
			_prepare_outing()
		"outing_ready":
			ChapterProgress.flags.child_forest_invited=true
			if ChapterProgress.auto_save:ChapterProgress.save_to()
			_outing_ready()
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
				battle_host.select_battle_map("plaza_child")
				battle_host.begin(lesson,CampaignProfile.hero_name)

func _battle_finished(success: bool) -> void:
	if lesson == 0 and success:
		ChapterProgress.flags.child_attack_practised=true
		if ChapterProgress.auto_save:ChapterProgress.save_to()
		scene_finished.emit("C01-M01/S04")
		_dialogue(1,0,0,"defense_intro")
	elif success:
		ChapterProgress.flags.child_defense_practised=true
		if ChapterProgress.auto_save:ChapterProgress.save_to()
		_dialogue(1,7,15,"complete")
	else:
		_dialogue(1,3,7,"battle")

func _outing_ready() -> void:
	phase="complete";completed=true
	world.player.presentation.carries_training_tool=false;leonor.carries_training_tool=false
	world.player.position=Vector2(-183,350);leonor.position=Vector2(-145,335)
	world.player.presentation.facing=3;leonor.facing=1
	view.show();view.panel.show();view.next_button.show();battle_container.hide()
	view.caption_label.text="Lisboa · Infância\nO caminho da ponte"
	view.speaker.text="Leonor criança";view.body.text="O banco está livre. Anda." if ChapterProgress.flags.get("hunt_completed",false) else "Vem. A ponte fica depois dos olivais."
	view.remember(view.speaker.text,view.body.text)
	view.next_button.text="Ir com Leonor";view.replay_button.hide();view.next_button.grab_focus()
	scene_finished.emit("C01-M01/S05")

func _prepare_outing() -> void:
	if phase=="washing":return
	phase="washing";view.show();view.panel.hide();view.next_button.hide();battle_container.hide()
	view.caption_label.text="Lisboa · Infância\nDepois do treino"
	view.hint.text="Esc / Start · pausa"
	world.player.presentation.carries_training_tool=false;leonor.carries_training_tool=false
	var walk=preload("res://scripts/chapter/staged_walk.gd")
	var hers:Tween=walk.along(leonor,[Vector2(-145,335)],world,115)
	await walk.along(world.player,[Vector2(-183,350)],world,100).finished
	if hers.is_running():await hers.finished
	world.player.presentation.facing=1;world.player.presentation.posture="crouched"
	wash_stand.washing=true
	var water:=AudioStreamPlayer.new();water.stream=load("res://assets/audio/chapter/foley/water.wav");water.bus=GamePreferences.effects_bus;water.volume_db=-30;world.add_child(water)
	if DisplayServer.get_name()!="headless":water.play()
	var pause:Tween=world.create_tween();pause.tween_interval(.7);await pause.finished
	wash_stand.washing=false;water.queue_free();world.player.presentation.posture="standing"
	var invitation:Array=[["Herói criança","Já está. E agora?"],["Leonor criança","Vou até à ponte. Disseram-me que anda lá um corço branco."],["Herói criança","Vais procurar?"],["Leonor criança","Quero ver se é verdade."],["Herói criança","Vou contigo."]]
	if ChapterProgress.flags.get("hunt_completed",false):invitation=[["Herói criança","Já está."],["Leonor criança","Deixa a vara com as outras. Vamos sentar-nos um bocado."]]
	phase="dialogue";lines=[]
	view.caption_label.text="Lisboa · Infância\nUma saída com Leonor"
	for row in invitation:lines.append({"speaker":row[0],"text":row[1]})
	line_index=-1;after_dialogue="outing_ready";view.panel.show();view.next_button.show();view.next_button.text="Continuar"
	view.hint.text="Enter / espaço / A · continuar     Esc / Start · pausa";advance()

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




