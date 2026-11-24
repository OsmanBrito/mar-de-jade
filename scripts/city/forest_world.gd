extends "res://scripts/chapter/plaza_world.gd"
const Plan = preload("res://scripts/city/forest_plan.gd")
func _ready() -> void:
	if not InputMap.has_action("move_left"):
		var bindings = load("res://scripts/main.gd").new(); bindings.configure_input(); bindings.free()
	var ground: TileMapLayer = get_node("Ground")
	for x in range(-40,45):
		for y in range(-40,45):
			if Plan.BOUNDS.has_point(ground.map_to_local(Vector2i(x,y))): ground.set_cell(Vector2i(x,y),0,Vector2i.ZERO)
	super._ready(); terrain.hide()
	player.presentation.identity = "hero_child"; player.camera_zoom = 1.15
	preload("res://scripts/city/forest_scenery.gd").install(self)
	var ambience := preload("res://scripts/city/forest_ambience.gd").new(); ambience.world = self; add_child(ambience)
	rebuild_navigation()
func is_walkable_point(point: Vector2) -> bool: return Plan.contains(point)
func _process(delta: float) -> void:
	super._process(delta)
	if is_instance_valid(player): player.camera.offset = player.camera.offset.lerp(Vector2(80,-75),1-exp(-delta*4))
func _draw() -> void:
	if click_time>0: draw_arc(click_mark,14,0,TAU,24,Color(1,.9,.6,click_time/1.1),2,true)
