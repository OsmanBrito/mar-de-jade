@tool
extends "res://scripts/chapter/plaza_world.gd"
## Persistent exterior shared by the square, courtyard, services and working quay.
const Layout = preload("res://scripts/city/lisbon_layout.gd")
@export var childhood := true
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
	if not Engine.is_editor_hint() and not InputMap.has_action("move_left"):
		var input = load("res://scripts/main.gd").new(); input.configure_input(); input.free()
	map_id = "lisboa_continua"
	set_meta("continuous_lisbon",true)
	super._ready()
	for x in range(-32,39):
		for y in range(-38,39):
			var p := terrain.map_to_local(Vector2i(x,y))
			if Layout.BOUNDS.has_point(p): terrain.set_cell(Vector2i(x,y),0,Vector2i.ZERO)
	_refresh_ground(); terrain.hide()
	preload("res://scripts/city/lisbon_scenery.gd").install(self)
	rebuild_navigation()
	preload("res://scripts/city/city_life.gd").install(self)
	if is_instance_valid(player):
		player.camera_zoom = 1.0; player.camera.offset = Vector2(0,-100)
		player.camera.limit_left = int(Layout.VIEW_BOUNDS.position.x); player.camera.limit_top = int(Layout.VIEW_BOUNDS.position.y)
		player.camera.limit_right = int(Layout.VIEW_BOUNDS.end.x); player.camera.limit_bottom = int(Layout.VIEW_BOUNDS.end.y)
func is_walkable_point(p: Vector2) -> bool:
	return Layout.contains(p,childhood)
func _draw() -> void:
	if click_time>0:
		draw_set_transform(click_mark,0,Vector2(1,.5)); draw_arc(Vector2.ZERO,15,0,TAU,32,Color(.95,.85,.6,click_time/1.1),1.5); draw_set_transform(Vector2.ZERO)
func _process(delta: float) -> void:
	super._process(delta)
	if is_instance_valid(player) and player.enabled:
		var street_bias := lerpf(-160,-95,smoothstep(220,600,player.position.y))
		var west := 1-smoothstep(-850,-500,player.position.x)
		var forecourt_bias := lerpf(-210,street_bias,smoothstep(180,400,player.position.y))
		var target := Vector2(west*180,lerpf(lerpf(street_bias,forecourt_bias,west),35,smoothstep(1050,1210,player.position.y)))
		player.camera.offset = player.camera.offset.lerp(target,1-exp(-delta*4))
