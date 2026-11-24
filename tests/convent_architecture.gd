extends SceneTree
const Plan = preload("res://scripts/city/convent_plan.gd")
const SAVE := "user://qa-convent-architecture.json"
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func frames(n: int = 3) -> void:
	for i in n: await process_frame
func run() -> void:
	var progress = root.get_node("ChapterProgress"); progress.auto_save = false; progress.reset()
	root.get_node("CampaignProfile").hero_name = "Miguel"
	progress.flags.delivery_pending = true
	progress.journey = {"kind":"delivery","target":0,"event":0,"stage":"","area":"convent","position":[0,-125]}
	var legacy: Dictionary = progress.snapshot(); legacy.schema_version = 6
	FileAccess.open(SAVE,FileAccess.WRITE).store_string(JSON.stringify(legacy))
	check(progress.load_from(SAVE)==OK,"A v6 convent save migrates through the real loader")
	check(progress.journey.position==[-240,-125],"The saved chapel position moves with the west church")
	check(progress.flags.delivery_pending and progress.coins==0,"Migration preserves the pending campaign and economy")
	var current: Dictionary = progress.snapshot()
	check(progress.save_to(SAVE)==OK and progress.load_from(SAVE)==OK,"The revised plan saves and reloads")
	check(progress.snapshot()==current,"A second load never translates the chapel twice")
	legacy.journey.position = [810,485]
	FileAccess.open(SAVE,FileAccess.WRITE).store_string(JSON.stringify(legacy))
	check(progress.load_from(SAVE)==OK and progress.journey.position==[810,485],"Saved infirmary positions stay in the same room")
	legacy.journey.position = [0,480]
	FileAccess.open(SAVE,FileAccess.WRITE).store_string(JSON.stringify(legacy))
	var before: Dictionary = progress.snapshot()
	check(progress.load_from(SAVE)==ERR_INVALID_DATA and progress.snapshot()==before,"Migration still rejects the planted garden atomically")
	var child_save: Dictionary = legacy.duplicate(true)
	child_save.entry_scene = "res://scenes/chapter_01/plaza.tscn"
	child_save.journey = {"kind":"childhood","target":0,"event":-1,"stage":"","area":"convent","position":[0,-125]}
	FileAccess.open(SAVE,FileAccess.WRITE).store_string(JSON.stringify(child_save))
	check(progress.load_from(SAVE)==OK and progress.journey.position==[-240,-125],"A childhood v6 chapel save migrates without becoming an adult journey")
	FileAccess.open(SAVE,FileAccess.WRITE).store_string(JSON.stringify(before))
	check(progress.load_from(SAVE)==OK,"The adult fixture restores after the childhood migration check")
	var game = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate()
	root.add_child(game); await frames()
	game.routes.load_area("convent",Plan.SPAWN); game.routes.resume(); await frames()
	check(game.world.segment_clear(Plan.CHAPEL_ENTRY+Vector2(0,40),Plan.CHAPEL_ENTRY-Vector2(0,40)),"The western chapel threshold has continuous physical clearance")
	check(not game.world.segment_clear(Vector2(0,230),Vector2(0,120)),"The former central opening is closed masonry")
	check(game.world.point_clear(Plan.NOTES.chapel.point),"The chapel discovery shares its new altar axis")
	for row in Plan.ARCADE_ROWS:
		for x in Plan.PIER_CENTERS:
			check(not game.world.point_clear(Vector2(x,row-10)),"The shared gallery pier blocks passage: "+str(Vector2(x,row)))
		for x in [-215,0,215]:
			check(game.world.segment_clear(Vector2(x,row-45),Vector2(x,row+35)),"The gallery opening clears the actual player radius: "+str(Vector2(x,row)))
	check(Plan.CHAPEL.get_center().x<Plan.CLOISTER.get_center().x and Plan.INFIRMARY.get_center().x>Plan.CLOISTER.get_center().x,"The interior retains the exterior west-church/east-infirmary organization")
	game.free(); await frames()
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(SAVE+suffix): DirAccess.remove_absolute(SAVE+suffix)
	print("CONVENT_ARCHITECTURE_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
