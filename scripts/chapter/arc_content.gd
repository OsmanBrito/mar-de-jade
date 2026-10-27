extends RefCounted
## Executable campaign content. Acquisition still requires the catalogue cultivation and story milestones.
static var cached: Dictionary = {}
static func data() -> Dictionary:
	if cached.is_empty(): cached = JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_01/content_scope.json"))
	return cached
static func executable(id: String,kind: String = "skill") -> bool:
	var rows: Dictionary = data().get("skills" if kind=="skill" else "passives",{})
	return rows.has(id) and rows[id].status=="implemented"
static func owner(id: String,kind: String = "skill") -> String:
	return str(data().get("skills" if kind=="skill" else "passives",{}).get(id,{}).get("owner",""))
