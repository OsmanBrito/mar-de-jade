extends Control
@export_file("*.json") var profile_path := "user://campanha-perfil.json"
@onready var name_field: LineEdit = $Center/Card/Margin/Content/Name
@onready var confirm_button: Button = $Center/Card/Margin/Content/Confirm
@onready var error_label: Label = $Center/Card/Margin/Content/Error
var submitting := false

func _ready() -> void:
	name_field.text_changed.connect(_update_validation)
	name_field.text_submitted.connect(func(_text): confirm())
	confirm_button.pressed.connect(confirm)
	_update_validation(name_field.text)
	name_field.grab_focus()
	var navigation = Button.new()
	navigation.name = "NavigationQuickStart"
	navigation.text = "Testar navegação · Lisboa → Madeira"
	navigation.custom_minimum_size.y = 48
	confirm_button.get_parent().add_child(navigation)
	navigation.pressed.connect(func(): preload("res://scripts/navigation/voyage_launch.gd").start(get_tree()))
	var boarding := Button.new(); boarding.name = "BoardingQuickStart"
	boarding.text = "Testar abordagem · combate no convés"; boarding.custom_minimum_size.y = 42
	confirm_button.get_parent().add_child(boarding)
	boarding.pressed.connect(func(): preload("res://scripts/navigation/voyage_launch.gd").start(get_tree(),false,false,true))
	for campaign in [false,true]:
		if FileAccess.file_exists(preload("res://scripts/navigation/voyage_launch.gd").save_path(campaign)):
			var saved_campaign: bool = campaign
			var voyage_resume = Button.new()
			voyage_resume.text = "Continuar navegação da campanha" if campaign else "Continuar teste de navegação"
			voyage_resume.custom_minimum_size.y = 42
			confirm_button.get_parent().add_child(voyage_resume)
			voyage_resume.pressed.connect(func(): preload("res://scripts/navigation/voyage_launch.gd").start(get_tree(),saved_campaign,true))
	if FileAccess.file_exists(ChapterProgress.SAVE_PATH):
		var resume = Button.new()
		resume.text = "Continuar capítulo guardado"
		resume.custom_minimum_size.y = 42
		confirm_button.get_parent().add_child(resume)
		resume.pressed.connect(resume_chapter)

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
	CampaignProfile.name_entry_destination = "res://scenes/chapter_01/opening.tscn"
	get_tree().change_scene_to_file(destination)

func resume_chapter() -> void:
	if submitting: return
	var result := ChapterProgress.load_from()
	if result != OK:
		error_label.text = "Não foi possível carregar o capítulo guardado."
		return
	get_tree().change_scene_to_file(ChapterProgress.entry_scene)


