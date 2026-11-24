extends SceneTree
const Layout = preload("res://scripts/city/lisbon_layout.gd")
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func frames(n: int = 3) -> void:
	for i in n: await process_frame
func run() -> void:
	root.get_node("ChapterProgress").auto_save = false
	root.get_node("CampaignProfile").hero_name = "Joana"
	var world = load("res://scenes/maps/praca_infancia.tscn").instantiate()
	world.childhood = false; root.add_child(world); await frames()
	check(world.has_meta("continuous_lisbon"),"The default exterior uses the continuous city")
	check(not world.point_clear(Layout.point(Vector2(565,490))),"Source barrel footprints remain physical obstacles")
	for name in ["Ferro_house_limestone","Ferro_house_teal","Ferro_warehouse","Ferro_workshop","Estaleiro","BancaDePeixe","CarroDaOficina"]:
		check(world.sorted_world.has_node(name),"Source district retains its own building or workplace: "+name)
	var start: Vector2i = world._nearest_id(Vector2(-300,160))
	for name in {"cozinha":Vector2(315,997),"socorro":Vector2(492,927),"oficina":Layout.WORKSHOP+Vector2(-42,35),"pontao":Layout.BOAT_ENTRY,"mercado":Vector2(650,1030)}:
		var point: Vector2 = {"cozinha":Vector2(315,997),"socorro":Vector2(492,927),"oficina":Layout.WORKSHOP+Vector2(-42,35),"pontao":Layout.BOAT_ENTRY,"mercado":Vector2(650,1030)}[name]
		var goal: Vector2i = world._nearest_id(point)
		check(world.point_clear(point),"Destination has physical clearance: "+name)
		check(start.x>=0 and goal.x>=0 and not world.navigation.get_point_path(start,goal).is_empty(),"One navigation graph connects convent to "+name)
	world.childhood = true; world.rebuild_navigation()
	check(world.point_clear(Vector2(80,400)) and not world.is_walkable_point(Vector2(315,997)),"Childhood retains the same square and restricts the working waterfront")
	world.free(); await frames()
	print("LISBON_CITY_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
