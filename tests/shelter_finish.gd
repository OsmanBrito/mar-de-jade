extends SceneTree
var failures: Array[String] = []
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func run() -> void:
	root.get_node("ChapterProgress").auto_save = false
	root.get_node("CampaignProfile").hero_name = "Inês"
	var atlas: Texture2D = load("res://assets/art/portugal-v2/dining-v1.png")
	var image: Image = atlas.get_image()
	check(not image.is_empty(),"Dining atlas is available from the project")
	check(image.get_pixel(0,0).a == 0.0,"Atlas preserves original transparent gutters")
	var frames: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/portugal-v2/dining-frames.json"))
	check(frames.size() == 6,"Six atlas regions are described")
	var art = load("res://scripts/chapter/dining_art.gd")
	for id in ["stool_east","stool_west","bowl","cup","bread","napkin"]:
		var region: Array = frames[id]
		var rect := Rect2i(region[0],region[1],region[2],region[3])
		check(Rect2i(Vector2i.ZERO,image.get_size()).encloses(rect),id+" crop stays within the source")
		check(art.texture(id).get_size() == Vector2(rect.size),id+" uses its tight alpha region")
		check(art.texture(id) == art.texture(id),id+" texture cache is stable")
	var opening = load("res://scenes/chapter_01/opening.tscn").instantiate()
	root.add_child(opening)
	for i in 3: await process_frame
	var room: Node2D = opening.room
	check(room.material is ShaderMaterial,"Limewashed walls use their own surface finish")
	check(room.get_node("ShelterFloor").z_index < room.get_node("ActorsAndProps").z_index,"Floor stays behind the furniture and characters")
	check(not room.get_node("ActorsAndProps/Table/Bowl").visible,"Food stays hidden until the approved table action")
	check(room.get_node("ActorsAndProps/Table/Bowl").get_script() == load("res://scripts/chapter/table_setting.gd"),"Table setting uses painted crockery")
	var count := room.get_child_count()
	load("res://scripts/chapter/shelter_details.gd").install(room)
	check(room.get_child_count() == count,"Shelter dressing is installed only once")
	for id in ["Cupboard","Shelf","Washstand"]:
		var prop: Node2D = room.get_node("ActorsAndProps/"+id)
		check(prop.get_child(0).get_script() == load("res://scripts/chapter/contact_shadow.gd"),id+" has soft ground contact")
		check(prop.get_child(2) is StaticBody2D,id+" keeps a physical footprint")
	opening.free()
	for i in 2: await process_frame
	var flow = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate()
	root.add_child(flow)
	for i in 6: await process_frame
	flow._load_block(4)
	for i in 150:
		if not flow.busy: break
		await physics_frame
	var table: Node2D = flow.world.get_node("ActorsAndProps/Table")
	check(table.scale == Vector2.ONE,"Meal table uses adult furniture proportions")
	check(flow.props.z_index == 1,"Meal crockery draws above the tabletop")
	check(flow.world.player.position.x < table.position.x-65,"Hero sits at the left table edge")
	check(flow.actors["Leonor"].position.x > table.position.x+65,"Leonor sits at the opposite table edge")
	flow.interact_task()
	check(flow.props.meal_ready and not flow.props.carrying,"Serving transfers food from hands to the table")
	check(flow.world.player.presentation.posture == "seated","Hero returns to the dining seat after serving")
	check(flow.world.player.position == flow._point("object")+Vector2(-74,27),"Serving preserves the corrected seat location")
	root.get_node("ChapterProgress").flags.injured = true
	flow._load_block(13)
	for i in 150:
		if not flow.busy: break
		await physics_frame
	var bedside: Node2D = flow.world.get_node("ActorsAndProps/BedsideSupport")
	check(bedside.position.y > flow.world.get_node("ActorsAndProps/Bed").position.y,"Bedside support has its own forward ground anchor")
	check(bedside.get_child(0) is StaticBody2D,"Bedside support has a matching physical footprint")
	flow.free()
	for i in 2: await process_frame
	print("SHELTER_FINISH_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
