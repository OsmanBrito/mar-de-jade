extends RefCounted
## Mar de Ferro's region -> independent battlefield pattern. No exploration state.
const PATH := "res://data/chapter_01/battle_maps.json"
static var profiles: Dictionary = {}
static func data() -> Dictionary:
	if profiles.is_empty(): profiles = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return profiles
static func has_map(id: String) -> bool: return data().has(id)
static func profile(id: String) -> Dictionary:
	assert(has_map(id),"Unknown battle map: "+id)
	return data()[id]
static func apply_obstacles(model,id: String) -> void:
	model.obstacles.clear()
	for pair in profile(id).obstacles:
		var cell := Vector2i(pair[0],pair[1])
		# The teaching point can spawn a ranged student in the bench row.
		if model.units.any(func(unit): return not unit.get("withdrawn",false) and unit.cell==cell): continue
		model.obstacles.append(cell)
