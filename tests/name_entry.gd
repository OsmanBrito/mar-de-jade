extends SceneTree
var checks := 0
var failures: Array[String] = []
var profile

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func capture(path: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)

func scene_frames() -> void:
	await process_frame
	await process_frame

func run() -> void:
	root.get_node("ChapterProgress").auto_save = false
	profile = root.get_node("CampaignProfile")
	var preferences = root.get_node("GamePreferences"); preferences.persist_enabled = false
	profile.hero_name = ""
	check(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/chapter_01/name_entry.tscn", "F5 begins with the name choice")
	check(change_scene_to_file("res://scenes/chapter_01/name_entry.tscn") == OK, "Name screen loads")
	await scene_frames()
	var entry = current_scene
	entry.profile_path = "res://tests/name-profile-fixture.json"
	check(entry.name_field.has_focus(), "Name field receives initial keyboard focus")
	check(entry.confirm_button.disabled, "Empty name cannot be confirmed")
	var settings: Button = entry.confirm_button.get_parent().get_node("GameSettings")
	settings.pressed.emit(); await scene_frames()
	var panel = entry.get_child(entry.get_child_count()-1)
	check(paused and not entry.can_process(), "Initial settings prevent input reaching the name screen")
	var timing: CheckButton = panel.column.get_node("wide_timing")
	var previous_timing: bool = preferences.options.wide_timing
	timing.button_pressed = not previous_timing
	check(preferences.options.wide_timing != previous_timing, "Initial settings update the shared combat preference")
	timing.button_pressed = previous_timing
	await capture("res://previews/revision-initial-settings.png")
	var cancel := InputEventKey.new(); cancel.keycode = KEY_ESCAPE; cancel.physical_keycode = KEY_ESCAPE; cancel.pressed = true
	root.push_input(cancel); await scene_frames()
	check(not paused and not is_instance_valid(panel) and settings.has_focus(), "Escape closes initial settings and returns focus without starting a campaign")
	entry.confirm()
	check(current_scene == entry and profile.hero_name.is_empty(), "Empty confirmation does not start the story")
	entry.name_field.text = "   "
	entry.name_field.text_changed.emit(entry.name_field.text)
	check(entry.confirm_button.disabled, "Spaces alone are rejected")
	entry.name_field.text = "A".repeat(25)
	entry.name_field.text_changed.emit(entry.name_field.text)
	check(entry.confirm_button.disabled and not entry.error_label.text.is_empty(), "Overlong name shows validation feedback")
	check(not profile.name_error("João\nMiguel").is_empty(), "Multiline profile name is rejected")
	entry.name_field.text = "João Miguel"
	entry.name_field.text_changed.emit(entry.name_field.text)
	check(not entry.confirm_button.disabled and entry.error_label.text.is_empty(), "Accents and spaces are accepted")
	await capture("res://tests/name-entry-preview.png")
	entry.name_field.text = "  João   Miguel  "
	entry.name_field.text_changed.emit(entry.name_field.text)
	entry.name_field.text_submitted.emit(entry.name_field.text)
	await scene_frames()
	check(current_scene.scene_file_path == "res://scenes/chapter_01/opening.tscn", "Enter confirms the name and starts the opening")
	check(profile.hero_name == "João Miguel", "Confirmation trims and normalizes spaces")
	check(FileAccess.file_exists("res://tests/name-profile-fixture.json"), "Confirmed name is persisted separately from the study save")
	var restored = load("res://scripts/chapter/campaign_profile.gd").new()
	check(restored.load_from("res://tests/name-profile-fixture.json") == OK and restored.hero_name == "João Miguel", "Versioned name profile round-trips")
	var old_name: String = restored.hero_name
	var invalid = FileAccess.open("res://tests/name-profile-invalid.json",FileAccess.WRITE)
	invalid.store_string('{"schema_version":999,"hero_name":"Outro"}')
	invalid.close()
	check(restored.load_from("res://tests/name-profile-invalid.json") == ERR_INVALID_DATA and restored.hero_name == old_name, "Invalid version does not replace the current name")
	check(restored.confirm_name("", "res://tests/name-profile-fixture.json") == ERR_INVALID_DATA and restored.hero_name == old_name, "Invalid rename preserves identity")
	check(profile.speaker_name("Herói") == "João Miguel" and profile.speaker_name("Tomé") == "Tomé", "Only protagonist identities are substituted")
	restored.free()
	var opening = current_scene
	check(opening.body.text == "Estão a chamar para comer.", "Name selection leaves the approved first line unchanged")
	opening.advance()
	check(opening.speaker.text == "João Miguel" and opening.body.text == "Já tenho esta.", "Selected name appears on the child's dialogue")
	await capture("res://tests/name-in-dialogue-preview.png")
	check(change_scene_to_file("res://scenes/chapter_01/plaza.tscn") == OK, "Next map loads with the chosen profile")
	await scene_frames()
	var plaza = current_scene
	plaza.advance()
	check(plaza.view.speaker.text == "João Miguel" and plaza.view.body.text == "Cabe mais uma.", "Chosen name survives the map transition")
	plaza.restart()
	plaza.advance()
	check(plaza.view.speaker.text == "João Miguel", "Scene replay preserves the chosen name")
	profile.hero_name = ""
	check(change_scene_to_file("res://scenes/chapter_01/opening.tscn") == OK, "Opening can be launched directly")
	for i in range(5):
		await process_frame
	check(current_scene.scene_file_path == "res://scenes/chapter_01/name_entry.tscn", "Direct F6 opening asks for a name if none is chosen")
	var result = {"checks":checks,"failures":failures,"rendered":DisplayServer.get_name() != "headless"}
	var file = FileAccess.open("res://tests/name-entry-report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t"))
	print("NAME_ENTRY_RESULT ",JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)

