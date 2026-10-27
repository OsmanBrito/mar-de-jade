extends SceneTree
## Art invariants on the instantiated exterior, including inherited transforms.
const Prop = preload("res://scripts/city/lisbon_prop.gd")
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func run() -> void:
	root.get_node("ChapterProgress").auto_save = false
	root.get_node("ChapterProgress").reset()
	root.get_node("GamePreferences").persist_enabled = false
	var world = load("res://scenes/maps/praca_infancia.tscn").instantiate()
	world.childhood = false; root.add_child(world)
	for i in 4: await process_frame
	check(world.sorted_world.y_sort_enabled,"Characters, buildings and props share Y sorting")
	var props := 0; var walls := 0
	for item in world.sorted_world.find_children("*","Node2D",true,false):
		if item is Prop:
			props += 1
			var native: Vector2 = item.texture.get_size()
			var drawn: Vector2 = item.size*item.global_scale.abs()
			check(absf(drawn.x/drawn.y-native.x/native.y)<.002,"Artwork retains native aspect through parent transforms: "+str(item.name))
			check(item.rect.end.y==0,"Illustrated prop sorts at its ground base: "+str(item.name))
			if str(item.name).begins_with("MuroIlustrado"):
				walls += 1
				var layout = preload("res://scripts/city/lisbon_layout.gd")
				var ferro = preload("res://scripts/city/ferro_lisbon.gd")
				var at: Vector2 = layout.source_point(item.position)
				for wall in ferro.COURTYARD_WALLS:
					if at.x>=wall.position.x and at.x<=wall.end.x:
						check(absf(at.y-ferro.wall_base_y(wall,at.x))*layout.SCALE<8,"Visible wall base agrees with navigation within collision thickness: "+str(item.name))
	check(props>40 and walls>8,"The audit inspected the populated exterior and sliced source walls")
	for pier in [world.get_node("FerroRibeira/Pontao0"),world.get_node("FerroRibeira/Pontao1"),world.get_node("FerroRibeira/Shoreline")]:
		check(absf(pier.global_scale.x-pier.global_scale.y)<.0001,"Waterfront artwork has uniform inherited scale: "+str(pier.name))
	for key in ["house_limestone","house_teal","warehouse","workshop"]:
		var building = world.sorted_world.get_node("Ferro_"+key)
		check(not world.point_clear(building.position-Vector2(0,20)),"Visible architectural base remains solid: "+key)
	for at in [Vector2(-770,65),Vector2(238,140),Vector2(-20,835),Vector2(125,680),Vector2(895,752),Vector2(1290,856)]:
		check(world.point_clear(at),"Existing door approaches retain character clearance: "+str(at))
	world.free()
	print("LISBON_ENVIRONMENT_ART_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
