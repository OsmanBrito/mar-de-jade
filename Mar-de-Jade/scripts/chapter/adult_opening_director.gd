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
	view = preload("res://scripts/chapter/dialogue_view.gd").new()
	view.caption = "Portugal · Presente · 19 anos\nA correia e o prazo"
	add_child(view)
	view.continuation_requested.connect(_continue_pressed)
	view.replay_requested.connect(func(): get_tree().reload_current_scene())
	choices = HBoxContainer.new()
	choices.add_theme_constant_override("separation",12)
	view.body.get_parent().add_child(choices)
	for id in ["assumir","desculpar"]:
		var button := Button.new()
		button.text = "Assumir o atraso" if id == "assumir" else "Dar uma desculpa"
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
		view.body.text = "A sacola está pronta. Duarte espera no pátio."
		view.next_button.show()
		view.next_button.disabled = false
		view.next_button.text = "Continuar para o pátio"
		view.replay_button.show()
		view.next_button.grab_focus()
		view.status.text = "Cena concluída"
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
	draw_rect(Rect2(sack_position-Vector2(15,25),Vector2(30,24)),Color("9b8862"))
	draw_arc(sack_position+Vector2(0,-25),12,PI,TAU,12,Color("5c4d35"),3)
	draw_line(sack_position+Vector2(-10,-16),sack_position+Vector2(10,-16),Color("c9b48a") if sack_ready else Color("5c4d35"),2)
	for offset in [Vector2(-15,30),Vector2(20,35)]:
		draw_circle($SackAtDoor.position+offset,11,Color("b8aa89"))

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
		get_tree().change_scene_to_file("res://scenes/chapter_01/chapter_flow.tscn")
	else: advance()




