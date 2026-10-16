extends RefCounted
## Persistent domain state for the exploration study. No Node references in saves.
signal changed
const SCHEMA_VERSION = 1
const MAPS = ["cais", "armazem"]
const PHASES = ["arrival", "warehouse", "return", "complete"]
var map_id: String = "cais"
var player_position: Vector2 = Vector2.ZERO
var has_position: bool = false
var phase: String = "arrival"
var visited_warehouse: bool = false
var known_manifest: bool = false
var last_choice: String = ""

func apply_action(action: String) -> void:
	last_choice = action
	match action:
		"accept_errand":
			if phase == "arrival":
				phase = "return" if known_manifest else "warehouse"
		"read_manifest":
			known_manifest = true
			if phase == "warehouse":
				phase = "return"
		"finish_errand":
			if phase == "return":
				phase = "complete"
	changed.emit()

func dialogue_id() -> String:
	return {"arrival":"clerk_first", "warehouse":"clerk_waiting", "return":"clerk_return", "complete":"clerk_done"}[phase]

func objective() -> String:
	return {"arrival":"Fala com o escrivão do cais.", "warehouse":"Procura o registo no armazém da porta azul.", "return":"Volta ao escrivão do cais.", "complete":"O cais já te é um pouco mais familiar."}[phase]

func snapshot() -> Dictionary:
	return {"schema_version":SCHEMA_VERSION, "map_id":map_id, "position":[player_position.x,player_position.y], "has_position":has_position, "phase":phase, "visited_warehouse":visited_warehouse, "known_manifest":known_manifest, "last_choice":last_choice}

func restore(data: Dictionary) -> Error:
	# Validate the whole record before mutating live state.
	if data.get("schema_version") != SCHEMA_VERSION or not data.get("map_id") in MAPS or not data.get("phase") in PHASES:
		return ERR_INVALID_DATA
	var pos = data.get("position")
	if not pos is Array or pos.size() != 2:
		return ERR_INVALID_DATA
	for coordinate in pos:
		if not (coordinate is float or coordinate is int) or not is_finite(float(coordinate)) or absf(float(coordinate)) > 100000.0:
			return ERR_INVALID_DATA
	for flag in ["has_position", "visited_warehouse", "known_manifest"]:
		if not data.get(flag) is bool:
			return ERR_INVALID_DATA
	if not data.get("last_choice", "") is String:
		return ERR_INVALID_DATA
	if data["phase"] in ["return", "complete"] and not data["known_manifest"]:
		return ERR_INVALID_DATA
	map_id = data["map_id"]
	phase = data["phase"]
	player_position = Vector2(float(pos[0]),float(pos[1]))
	has_position = data["has_position"]
	visited_warehouse = data["visited_warehouse"]
	known_manifest = data["known_manifest"]
	last_choice = data.get("last_choice", "")
	changed.emit()
	return OK

func save_to(path: String) -> Error:
	var temporary = path + ".tmp"
	var file = FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(snapshot(), "\t"))
	file.flush()
	file.close()
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(path + ".bak"):
			var remove_error = DirAccess.remove_absolute(path + ".bak")
			if remove_error != OK:
				return remove_error
		var backup_error = DirAccess.rename_absolute(path, path + ".bak")
		if backup_error != OK:
			return backup_error
	var error = DirAccess.rename_absolute(temporary, path)
	if error != OK and FileAccess.file_exists(path + ".bak"):
		DirAccess.rename_absolute(path + ".bak", path)
	return error

func load_from(path: String) -> Error:
	if not FileAccess.file_exists(path):
		return ERR_FILE_NOT_FOUND
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		return ERR_PARSE_ERROR
	return restore(parsed)
