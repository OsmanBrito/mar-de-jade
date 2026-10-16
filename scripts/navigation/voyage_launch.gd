extends RefCounted
## Launch context never edits the character profile or the Portugal checkpoint.
static var mode := "test"
static var resume_requested := false
static var boarding_requested := false
const SCENE := "res://scenes/navigation/voyage.tscn"
static func start(tree: SceneTree, campaign: bool = false, resume: bool = false, boarding: bool = false) -> void:
	mode = "campaign" if campaign else "test"
	resume_requested = resume
	boarding_requested = boarding and not campaign
	tree.change_scene_to_file(SCENE)
static func save_path(campaign: bool = false) -> String:
	return "user://navegacao.json" if campaign else "user://navegacao-teste.json"
