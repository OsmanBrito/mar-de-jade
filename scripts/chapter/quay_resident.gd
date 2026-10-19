extends CharacterBody2D
## Ambient workers follow short navigable errands and pause at their workstations.
@export var npc_id := "worker"
@export var route := PackedVector2Array()
@export var pause_seconds := 3.0
@export var rest_posture := "standing"
var presentation: Node2D
var world
var route_index := 0
var path := PackedVector2Array()
var waiting := 1.0
var distance_walked := 0.0
var stalled := 0.0
func _ready() -> void:
	world = get_parent().get_parent()
	collision_layer = 4; collision_mask = 1 | 2 | 4; motion_mode = MOTION_MODE_FLOATING
	var shape := CollisionShape2D.new(); var circle := CircleShape2D.new(); circle.radius = 9; shape.shape = circle; add_child(shape)
	presentation = preload("res://scripts/chapter/actor_proxy.gd").new(); presentation.npc_id = npc_id; add_child(presentation)
	waiting += float(get_index()%5)*0.6
func _plan() -> void:
	if route.size()<2: return
	route_index = (route_index+1)%route.size()
	var start: Vector2i = world._nearest_id(position)
	var end: Vector2i = world._nearest_id(route[route_index])
	if start.x<0 or end.x<0: waiting = 2; return
	path = world.navigation.get_point_path(start,end)
	if not path.is_empty(): path.append(route[route_index])
func _physics_process(delta: float) -> void:
	if not world.map_ready: return
	if (is_instance_valid(world.player) and not world.player.enabled) or not is_visible_in_tree():
		velocity=Vector2.ZERO;presentation.walking=false;presentation.queue_redraw();return
	presentation.walking = false
	if waiting>0:
		waiting -= delta
		presentation.posture = rest_posture
		if waiting<=0: _plan()
		return
	presentation.posture = "standing"
	while not path.is_empty() and position.distance_to(path[0])<5: path.remove_at(0)
	if path.is_empty(): waiting = pause_seconds; return
	var direction := position.direction_to(path[0])
	velocity = direction*(37.0+float(get_index()%3)*4.0)
	var before := position; move_and_slide()
	var travelled := position.distance_to(before); distance_walked += travelled
	if travelled<0.1:
		stalled += delta
		if stalled>1.5: path.clear(); waiting = 1.5; stalled = 0
	else: stalled = 0
	presentation.walking = travelled>0.05
	presentation.facing = (3 if direction.x>0 else 1) if absf(direction.x)>absf(direction.y)*1.15 else (0 if direction.y>0 else 2)
	presentation.frame_time = fposmod(presentation.frame_time+delta*5.0,3.0)
	presentation.queue_redraw()
