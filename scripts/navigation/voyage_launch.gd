extends RefCounted
## Launch context never edits the character profile or the Portugal checkpoint.
static var mode := "test"
static var resume_requested := false
static var boarding_requested := false
static var travel_path := "user://navegacao.json"
const SCENE := "res://scenes/navigation/voyage.tscn"
static func start(tree: SceneTree, campaign: bool = false, resume: bool = false, boarding: bool = false) -> void:
	mode = "campaign" if campaign else "test"
	resume_requested = resume
	boarding_requested = boarding and not campaign
	tree.change_scene_to_file(SCENE)
static func save_path(campaign: bool = false) -> String:
	return "user://navegacao.json" if campaign else "user://navegacao-teste.json"

static func matches_chapter(chapter: Dictionary, path: String = "user://navegacao.json") -> bool:
	if not FileAccess.file_exists(path): return false
	var stored: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not stored is Dictionary: return false
	var model = load("res://scripts/navigation/voyage_model.gd").new()
	if not model.restore(stored): return false
	if model.campaign_state.is_empty(): return model.hero_name==chapter.get("hero_name","") and chapter.get("completed",false) and str(chapter.get("run_id","")).length()==64
	return model.campaign_state.get("run_id","")==chapter.get("run_id","")
