extends SceneTree
const Book=preload("res://scripts/chapter/order_techniques.gd")
const Visuals=preload("res://scripts/combat/medida_presentation.gd")
var checks:=0
var failures: Array[String]=[]
func _initialize():call_deferred("run")
func check(ok: bool,message: String):
	checks+=1
	if not ok: failures.append(message);push_error(message)
func run():
	root.get_node("ChapterProgress").auto_save=false
	var icons: Dictionary={}
	for row in JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_01/skill_icons.json")).skills: icons[row.id]=row.icon
	var paths: Dictionary={}
	for id in Book.rows():
		var path: String=icons[id]
		check(not paths.has(path),id+" has a dedicated icon path")
		paths[path]=true
		check(Visuals.profiles()[id].icon==path,id+" menu and battle share the same icon")
		var texture: Texture2D=load(path)
		check(texture!=null,id+" imports as a Godot texture")
		if texture==null: continue
		check(texture.get_width()<=256 and texture.get_height()<=256,id+" uses a bounded menu texture")
		check(texture.get_image().detect_alpha()!=Image.ALPHA_NONE,id+" preserves transparent background")
	print("MEDIDA_ASSETS_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
