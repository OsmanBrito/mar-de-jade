extends Node2D
## Screen-edge direction to the next reachable place, never a replacement for walking.
var world_ref: WeakRef
var target := Vector2.ZERO
var enabled := false
var view
func track(world: Node2D,point: Vector2) -> void:
	world_ref = weakref(world); target = point; enabled = true
func _process(_delta: float) -> void: queue_redraw()
func _draw() -> void:
	if not enabled or view==null or not view.root.is_visible_in_tree() or view.panel.visible: return
	var world = world_ref.get_ref() if world_ref!=null else null
	if world==null: return
	var size := get_viewport_rect().size
	var point: Vector2 = world.get_global_transform_with_canvas()*target
	var top := 135.0
	if view.exploration_back.visible: top = maxf(top,view.exploration_back.get_rect().end.y+24)
	var safe := Rect2(Vector2(65,top),size-Vector2(130,top+100))
	if safe.has_point(point): return
	var center := safe.get_center()
	var direction := (point-center).normalized()
	var half := safe.size*.5
	var length := minf(half.x/maxf(.001,absf(direction.x)),half.y/maxf(.001,absf(direction.y)))
	var at := center+direction*length
	draw_circle(at,15,Color(.05,.12,.12,.9))
	var normal := direction.orthogonal()
	draw_colored_polygon(PackedVector2Array([at+direction*9,at-direction*5+normal*5,at-direction*5-normal*5]),Color("e4c68a"))
