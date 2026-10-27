extends Control
@export_file("*.json") var profile_path := "user://campanha-perfil.json"
@onready var name_field: LineEdit = $Center/Card/Margin/Content/Name
@onready var confirm_button: Button = $Center/Card/Margin/Content/Confirm
@onready var error_label: Label = $Center/Card/Margin/Content/Error
var submitting := false

func _ready() -> void:
	theme = preload("res://scripts/ui/presentation.gd").theme()
	name_field.text_changed.connect(_update_validation)
	name_field.text_submitted.connect(func(_text): confirm())
	confirm_button.pressed.connect(confirm)
	_update_validation(name_field.text)
	name_field.grab_focus()
	var settings := Button.new(); settings.name = "GameSettings"; settings.text = "Som, leitura e combate"; settings.custom_minimum_size.y = 42
	confirm_button.get_parent().add_child(settings)
	settings.pressed.connect(func():
		var panel := preload("res://scripts/ui/preferences_panel.gd").new(); add_child(panel)
		panel.closed.connect(func(): settings.grab_focus()))
	# A entrada de nome é o início da campanha. Os atalhos de navegação e
	# abordagem pertencem ao kit interno de QA e não aparecem no produto.
	var voyage = preload("res://scripts/navigation/voyage_launch.gd")
	if FileAccess.file_exists(voyage.save_path(true)):
		var voyage_resume = Button.new()
		voyage_resume.text = "Continuar viagem guardada"
		voyage_resume.custom_minimum_size.y = 42
		confirm_button.get_parent().add_child(voyage_resume)
		voyage_resume.pressed.connect(func(): voyage.start(get_tree(),true,true))
		var voyage_note := Label.new(); voyage_note.text = "Retoma o último ponto seguro da viagem Lisboa → Madeira."
		voyage_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; confirm_button.get_parent().add_child(voyage_note)
	if FileAccess.file_exists(ChapterProgress.SAVE_PATH):
		var chapter_snapshot: Variant = JSON.parse_string(FileAccess.get_file_as_string(ChapterProgress.SAVE_PATH))
		if chapter_snapshot is Dictionary and chapter_snapshot.get("completed",false) and voyage.matches_chapter(chapter_snapshot): return
		var resume = Button.new()
		resume.text = "Continuar capítulo guardado"
		resume.custom_minimum_size.y = 42
		confirm_button.get_parent().add_child(resume)
		resume.pressed.connect(resume_chapter)
		var saved: Variant = JSON.parse_string(FileAccess.get_file_as_string(ChapterProgress.SAVE_PATH))
		var saved_title := "Portugal"
		if saved is Dictionary and saved.get("entry_scene") is String and saved.get("checkpoint") is float and saved.checkpoint>=0 and saved.checkpoint<17:
			var scenes: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_01/chapter_flow.json")).scenes
			saved_title = scenes[int(saved.checkpoint)].title if saved.get("entry_scene","").ends_with("chapter_flow.tscn") else "Infância · Portugal"
		var chapter_note := Label.new(); chapter_note.text = saved_title+"\nRetoma o início da etapa; conversas e combates em andamento serão repetidos."
		if saved is Dictionary and saved.get("journey") is Dictionary and not saved.journey.is_empty():
			chapter_note.text = "Lisboa · Caminho em andamento\nRetoma o local e o compromisso guardados; segue até à pessoa ou ao destino indicado."
		chapter_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; confirm_button.get_parent().add_child(chapter_note)

func _update_validation(value: String) -> void:
	var error = CampaignProfile.name_error(value)
	confirm_button.disabled = submitting or not error.is_empty()
	error_label.text = "" if value.is_empty() else error

func confirm() -> void:
	if submitting:
		return
	var error = CampaignProfile.name_error(name_field.text)
	if not error.is_empty():
		error_label.text = error
		return
	submitting = true
	confirm_button.disabled = true
	var result = CampaignProfile.confirm_name(name_field.text,profile_path)
	if result != OK:
		submitting = false
		error_label.text = "Não foi possível guardar o nome. Tenta novamente."
		confirm_button.disabled = false
		return
	name_field.text = CampaignProfile.hero_name
	var destination = CampaignProfile.name_entry_destination
	CampaignProfile.name_entry_destination = "res://scenes/chapter_01/childhood_home.tscn"
	get_tree().change_scene_to_file(destination)

func resume_chapter() -> void:
	if submitting: return
	var result := ChapterProgress.load_from()
	if result != OK:
		error_label.text = "Não foi possível carregar o capítulo guardado."
		return
	var launch = preload("res://scripts/navigation/voyage_launch.gd")
	if ChapterProgress.completed and launch.matches_chapter(ChapterProgress.snapshot()):
		launch.start(get_tree(),true,true)
	else: get_tree().change_scene_to_file(ChapterProgress.entry_scene)


