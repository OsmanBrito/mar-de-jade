extends SceneTree
const PATH := "user://qa-childhood-city.json"
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func frames(n: int = 3) -> void:
	for i in n: await process_frame
func run() -> void:
	var p = root.get_node("ChapterProgress"); p.auto_save = false; p.reset()
	root.get_node("CampaignProfile").hero_name = "Joana"
	var game = load("res://scenes/chapter_01/plaza.tscn").instantiate(); root.add_child(game); await frames()
	check(game.phase=="childhood_explore" and game.world.childhood,"The child explores the same city with its age-specific boundary")
	check(not game.world.is_walkable_point(Vector2(315,997)),"The child cannot enter the adult working district")
	game.world.walk_to(Vector2(-250,190))
	for i in 400:
		await physics_frame
		if game.world.player.position.distance_to(Vector2(-250,190))<15: break
	check(game.world.player.position.distance_to(Vector2(-250,190))<20,"Actual movement reaches the Order's optional discovery")
	game.roam.interact()
	check(game.phase=="childhood_note" and game.view.body.text.contains("Ordem de Cristo"),"A discovery identifies the institution before the lesson")
	var feet: Vector2 = game.world.player.position; game.advance()
	check(game.phase=="childhood_explore" and game.world.player.position==feet,"Reading returns to the same feet without starting Leonor's encounter")
	check(p.coins==0 and p.skills.is_empty() and p.passives.is_empty() and p.inventory=={"PT-Q01":1},"Childhood exploration grants no adult skills, gear or money")
	game.roam.save(); check(p.save_to(PATH)==OK,"Childhood location writes as a current Jade save")
	var expected: Dictionary = p.snapshot(); game.free(); await frames(); p.reset()
	check(p.load_from(PATH)==OK and p.snapshot()==expected,"Position and childhood objective survive save/load")
	game = load("res://scenes/chapter_01/plaza.tscn").instantiate(); root.add_child(game); await frames()
	check(game.phase=="childhood_explore" and game.world.player.position==Vector2(roundi(feet.x),roundi(feet.y)),"Reopening restores childhood exploration at the saved world coordinate")
	var before: Dictionary = p.snapshot()
	for patch in [{"entry_scene":"res://scenes/chapter_01/chapter_flow.tscn"},{"schema_version":4},{"schema_version":p.SCHEMA_VERSION+1}]:
		var invalid := before.duplicate(true); invalid.merge(patch,true)
		FileAccess.open(PATH,FileAccess.WRITE).store_string(JSON.stringify(invalid))
		check(p.load_from(PATH)==ERR_INVALID_DATA and p.snapshot()==before,"Incompatible childhood save is rejected atomically: "+str(patch))
	var invalid := before.duplicate(true); invalid.journey.position = [315,997]
	FileAccess.open(PATH,FileAccess.WRITE).store_string(JSON.stringify(invalid))
	check(p.load_from(PATH)==ERR_INVALID_DATA and p.snapshot()==before,"Forged childhood location cannot move the child onto the adult waterfront")
	game.free(); await frames()
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(PATH+suffix): DirAccess.remove_absolute(PATH+suffix)
	print("CHILDHOOD_CITY_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
