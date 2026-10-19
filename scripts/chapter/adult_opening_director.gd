extends Node2D
signal scene_finished(scene_id: String)
var data: Dictionary
var view
var hero
var segment := "common"
var line_index := -1
var phase := "dialogue"
var busy := false
var paused := false
var completed := false
var sack_position := Vector2.ZERO
var sack_ready := false
var choices: HBoxContainer

func _ready() -> void:
	if CampaignProfile.hero_name.is_empty():
		CampaignProfile.name_entry_destination = "res://scenes/chapter_01/adult_opening.tscn"
		get_tree().change_scene_to_file.call_deferred("res://scenes/chapter_01/name_entry.tscn")
		return
	ChapterProgress.enter_scene("res://scenes/chapter_01/adult_opening.tscn")
	get_node("Abrigo/Ground").z_index = -1
	data = JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_01/adult_opening.json"))
	hero = $Abrigo/ActorsAndProps/Child
	$Abrigo/ActorsAndProps/Tome.seat_support = true
	hero.facing = 3
	$Abrigo/ActorsAndProps/Tome.facing = 1
	$Abrigo/ActorsAndProps/Duarte.facing = 3
	get_node("Camera").enabled = false
	preload("res://scripts/chapter/chapter_framing.gd").install(self,[hero,$Abrigo/ActorsAndProps/Tome,$Abrigo/ActorsAndProps/Duarte],1.45)
	view = preload("res://scripts/chapter/dialogue_view.gd").new()
	view.caption = "Lisboa · Casa da Ordem de Cristo · 19 anos\nA correia e o prazo"
	add_child(view)
	view.continuation_requested.connect(_continue_pressed)
	view.replay_requested.connect(func(): get_tree().reload_current_scene())
	choices = HBoxContainer.new()
	choices.add_theme_constant_override("separation",12)
	view.body.get_parent().add_child(choices)
	for id in ["assumir","desculpar"]:
		var button := Button.new()
		button.text = "“"+data.segments[id][0].text+"”"
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size.y = 42
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(choose.bind(id))
		choices.add_child(button)
	choices.hide()
	sack_position = $SackOnTable.position
	advance()

func advance() -> void:
	if paused or busy or completed or phase != "dialogue": return
	line_index += 1
	var lines: Array = data.segments[segment]
	if line_index < lines.size():
		if segment == "common" and line_index == 8:
			busy = true
			view.next_button.disabled = true
			var tween = $Abrigo.create_tween()
			tween.tween_property(hero,"position",$HeroBySack.position,0.5)
			await tween.finished
			busy = false
			view.next_button.disabled = false
			sack_ready = true
			queue_redraw()
		view.speaker.text = CampaignProfile.speaker_name(lines[line_index].speaker)
		view.body.text = lines[line_index].text
		view.remember(view.speaker.text,view.body.text)
		view.next_button.grab_focus()
		return
	if segment == "common":
		phase = "choice"
		view.speaker.text = CampaignProfile.hero_name
		view.body.text = "A entrega está atrasada."
		view.next_button.hide()
		choices.show()
		choices.get_child(0).grab_focus()
	else:
		busy = true
		view.next_button.disabled = true
		var tween = $Abrigo.create_tween().set_parallel(true)
		tween.tween_property(hero,"position",$HeroAtDoor.position,0.8)
		tween.tween_property(self,"sack_position",$SackAtDoor.position,0.8)
		await tween.finished
		busy = false
		completed = true
		phase = "complete"
		view.speaker.text = "A correia e o prazo"
		view.body.text = "A sacola está pronta. Termina a entrega no cais e regressa ao pátio de Duarte."
		view.next_button.show()
		view.next_button.disabled = false
		view.next_button.text = "Sair para Lisboa"
		view.replay_button.hide()
		view.next_button.grab_focus()
		view.status.text = ""
		scene_finished.emit(data.id)

func choose(id: String) -> void:
	if paused or phase != "choice" or id not in ["assumir","desculpar"]: return
	CampaignProfile.origin_response = id
	segment = id
	line_index = -1
	phase = "dialogue"
	choices.hide()
	view.next_button.show()
	advance()

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if view == null: return
	preload("res://scripts/chapter/story_prop_art.gd").draw_item(self,"PT-Q01",sack_position,43)
	for offset in [Vector2(-15,30),Vector2(20,35)]:
		preload("res://scripts/chapter/story_prop_art.gd").draw_item(self,"PT-T01",$SackAtDoor.position+offset,28)

func _unhandled_input(event: InputEvent) -> void:
	if view == null: return
	if event.is_action_pressed("ui_cancel") or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START):
		paused = not paused
		get_tree().paused = paused
		view.status.text = "Pausa · Esc para continuar" if paused else ""
		get_viewport().set_input_as_handled()
	elif not paused and event.is_action_pressed("ui_accept") and phase in ["dialogue","complete"]:
		get_viewport().set_input_as_handled()
		_continue_pressed()


func _continue_pressed() -> void:
	if busy or paused: return
	if completed:
		ChapterProgress.choices.origin_response = CampaignProfile.origin_response
		if sack_ready and not ChapterProgress.flags.get("delivery_finished",false): ChapterProgress.flags.delivery_pending = true
		get_tree().change_scene_to_file("res://scenes/chapter_01/chapter_flow.tscn")
	else: advance()




