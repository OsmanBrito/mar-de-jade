extends Node
## Campaign identity, shared by chapter scenes; independent of the cais study save.
const SCHEMA_VERSION := 1
const MAX_NAME_LENGTH := 24
const SAVE_PATH := "user://campanha-perfil.json"
var hero_name := ""
var origin_response := "" # Runtime chapter choice; progress persistence is separate.
var name_entry_destination := "res://scenes/chapter_01/childhood_home.tscn"

func normalized_name(value: String) -> String:
	return " ".join(value.strip_edges().split(" ",false))

func name_error(value: String) -> String:
	var normalized = normalized_name(value)
	if normalized.is_empty():
		return "Escreve o nome do protagonista."
	if normalized.length() > MAX_NAME_LENGTH:
		return "Usa até 24 caracteres."
	for character in normalized:
		if character.unicode_at(0) < 32 or character.unicode_at(0) == 127:
			return "Usa um nome numa única linha."
	return ""

func speaker_name(identity: String) -> String:
	if identity in ["Herói", "Herói criança"] and not hero_name.is_empty():
		return hero_name
	return identity

func confirm_name(value: String, path: String = SAVE_PATH) -> Error:
	if not name_error(value).is_empty():
		return ERR_INVALID_DATA
	var normalized = normalized_name(value)
	var file = FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify({"schema_version":SCHEMA_VERSION,"hero_name":normalized},"\t"))
	file.flush()
	file.close()
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(path+".bak"):
			var remove_error = DirAccess.remove_absolute(path+".bak")
			if remove_error != OK:
				return remove_error
		var backup_error = DirAccess.rename_absolute(path,path+".bak")
		if backup_error != OK:
			return backup_error
	var error = DirAccess.rename_absolute(path+".tmp",path)
	if error != OK:
		if FileAccess.file_exists(path+".bak"):
			DirAccess.rename_absolute(path+".bak",path)
		return error
	hero_name = normalized
	origin_response = ""
	ChapterProgress.reset()
	return OK

func load_from(path: String = SAVE_PATH) -> Error:
	if not FileAccess.file_exists(path):
		return ERR_FILE_NOT_FOUND
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary or data.get("schema_version") != SCHEMA_VERSION:
		return ERR_INVALID_DATA
	if not data.get("hero_name") is String or not name_error(data["hero_name"]).is_empty():
		return ERR_INVALID_DATA
	hero_name = normalized_name(data["hero_name"])
	return OK


