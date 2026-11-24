extends RefCounted
## A click is a request to approach, never permission to interact through a wall.
var pending: Dictionary = {}
func cancel() -> void: pending.clear()
func begin(world,point: Vector2,targets: Array) -> void:
	cancel()
	var best := 62.0
	for row in targets:
		var distance: float = point.distance_to(row.at+Vector2(0,-30))
		if distance<best and world.point_clear(row.point):
			best = distance; pending = {"id":row.id,"point":row.point,"world":world.get_instance_id()}
	if pending.is_empty(): world.walk_to(point); return
	world.walk_to(pending.point)
func poll(world) -> String:
	if pending.is_empty(): return ""
	if pending.world!=world.get_instance_id() or Input.get_vector("move_left","move_right","move_up","move_down").length()>.1:
		cancel(); return ""
	if world.player.position.distance_to(pending.point)<48 and world.segment_clear(world.player.position,pending.point):
		var result: String = pending.id; cancel(); return result
	if world.player.destination_path.is_empty(): cancel()
	return ""
