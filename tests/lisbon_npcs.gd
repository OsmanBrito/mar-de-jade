extends SceneTree
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func frames(n: int) -> void:
	for i in n: await process_frame
func run() -> void:
	var lib = preload("res://scripts/npcs/lisbon_npc_library.gd")
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_01/lisbon_npcs.json"))
	check(catalog.entries.size()==16,"Sixteen visual versions cover the chapter cast")
	var people := {}; var total := 0
	for entry in catalog.entries:
		people[entry.person_id] = true
		var info: Dictionary = lib.data()[entry.id]
		var valid: bool = FileAccess.file_exists(entry.source) and FileAccess.file_exists("res://scenes/npcs/lisbon/"+entry.id+".tscn")
		valid = valid and info.frames.size()==entry.expected_rows*4
		for rect in info.frames:
			valid = valid and rect[0]>=0 and rect[1]>=0 and rect[0]+rect[2]<=info.source_size[0] and rect[1]+rect[3]<=info.source_size[1]
		check(valid,"Complete source, reusable scene and uncropped frames: "+entry.id)
		total += info.frames.size()
	check(people.size()==14 and total==280,"Fourteen identities, 280 described frames")
	check(lib.resolve("leonor")=="leonor_child" and lib.resolve("tome")=="tome_adult","Legacy identities retain the correct period")
	check(lib.data().leonor_child.height<lib.data().leonor_adult.height,"Child Leonor has child scale")
	var game = load("res://scenes/art/lisbon_cast_gallery.tscn").instantiate(); root.add_child(game)
	await frames(12)
	check(game.actors.size()==16,"All visual versions instantiate in the gallery")
	if DisplayServer.get_name()!="headless": root.get_texture().get_image().save_png("res://docs/lisbon-cast-in-game.png")
	for facing in 4:
		game.facing = facing; game.walking = true; await frames(3)
		check(game.actors.all(func(actor): return actor.facing==facing and actor.walking),"Direction and locomotion reach every NPC")
	game.walking = false; game.facing = 0; game.posture = "seated"; game._update_hint(); await frames(4)
	if DisplayServer.get_name()!="headless": root.get_texture().get_image().save_png("res://docs/lisbon-cast-poses.png")
	game.free(); await frames(2)
	var room = load("res://scenes/maps/abrigo_infancia.tscn").instantiate()
	check(room.get_node("ActorsAndProps/Tome").npc_id=="tome_young","Prologue uses younger Tomé")
	room.free()
	var adult = load("res://scenes/chapter_01/adult_opening.tscn").instantiate()
	check(adult.get_node("Abrigo/ActorsAndProps/Tome").npc_id=="tome_adult","Adult opening uses sixty-year-old Tomé")
	adult.free()
	print("LISBON_NPCS_RESULT "+JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
