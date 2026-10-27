extends "res://scripts/chapter/plaza_world.gd"
const Plan = preload("res://scripts/city/convent_plan.gd")
@export var childhood := false
var static_root: Dictionary = {}
var static_sorted: Dictionary = {}
func remember_static() -> void:
	for node in get_children(): static_root[node.get_instance_id()] = true
	for node in sorted_world.get_children(): static_sorted[node.get_instance_id()] = true
func clear_story() -> void:
	for node in sorted_world.get_children():
		if not static_sorted.has(node.get_instance_id()): node.free()
	for node in get_children():
		if not static_root.has(node.get_instance_id()): node.free()
func _ready() -> void:
	if not InputMap.has_action("move_left"):
		var bindings = load("res://scripts/main.gd").new(); bindings.configure_input(); bindings.free()
	var ground: TileMapLayer = get_node("Ground")
	for x in range(-32,33):
		for y in range(-32,33):
			if Plan.BOUNDS.has_point(ground.map_to_local(Vector2i(x,y))): ground.set_cell(Vector2i(x,y),0,Vector2i.ZERO)
	set_meta("order_convent",true)
	super._ready()
	terrain.hide()
	preload("res://scripts/city/convent_scenery.gd").install(self)
	load("res://scripts/city/house_life.gd").install(self)
	load("res://scripts/city/order_house_hub.gd").install(self)
	rebuild_navigation()
	player.presentation.identity = "hero_child" if childhood else "hero"
	player.camera_zoom = 1.12; player.camera.offset = Vector2(0,-100)
	remember_static()
func _process(delta: float) -> void:
	super._process(delta)
	if is_instance_valid(player) and player.enabled:
		var center := Plan.camera_focus(player.position)
		player.camera.offset = player.camera.offset.lerp(center-player.position,1-exp(-delta*3.5))
func is_walkable_point(p: Vector2) -> bool:
	return Plan.contains(p)
func _draw() -> void:
	if click_time>0:
		draw_set_transform(click_mark,0,Vector2(1,.5)); draw_arc(Vector2.ZERO,15,0,TAU,32,Color(.95,.85,.6,click_time/1.1),1.5); draw_set_transform(Vector2.ZERO)
