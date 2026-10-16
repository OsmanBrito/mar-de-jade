extends Node2D
## Original spatial prototype. All geometry, footprints and routes share one authored plan.
var plan: Dictionary
var player
var sorted_world: Node2D
var blockers: Array[PackedVector2Array] = []
var navigation := AStarGrid2D.new()
var status: Label
var route_visible := true
const STEP := 16.0

static func project(point: Vector2) -> Vector2:
	return Vector2(point.x-point.y,(point.x+point.y)*0.5)
static func unproject(point: Vector2) -> Vector2:
	return Vector2(point.x*0.5+point.y,point.y-point.x*0.5)
static func rectangle(values: Array) -> Rect2:
	return Rect2(values[0],values[1],values[2],values[3])
static func polygon(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([project(rect.position),project(Vector2(rect.end.x,rect.position.y)),project(rect.end),project(Vector2(rect.position.x,rect.end.y))])

func _ready() -> void:
	plan = JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_01/quay_layout_plan.json"))
	var bindings = preload("res://scripts/main.gd").new(); bindings.configure_input(); bindings.free()
	sorted_world = Node2D.new(); sorted_world.y_sort_enabled = true; sorted_world.z_index = 2; add_child(sorted_world)
	for building in plan.buildings: _volume(building.name,rectangle(building.rect),building.height,Color(building.color))
	for box in plan.cargo: _volume("Carga",rectangle(box),24,Color("9d8057"))
	_build_navigation()
	player = preload("res://scenes/chapter_01/child_player.tscn").instantiate()
	player.world = self; player.position = project(Vector2(plan.spawn[0],plan.spawn[1])); sorted_world.add_child(player)
	player.presentation.identity = "hero"; player.camera.enabled = false
	player.z_index = 1 # Planning view keeps the scale figure legible beside the simple volumes.
	var camera := Camera2D.new(); camera.position = Vector2(290,400); camera.zoom = Vector2.ONE*0.83; add_child(camera)
	_interface(); queue_redraw()
	for marker in plan.markers:
		var label := Label.new(); label.text = marker.name
		label.position = project(Vector2(marker.point[0],marker.point[1]))+Vector2(12,-26)
		label.z_index = 5; label.add_theme_font_size_override("font_size",15)
		label.add_theme_color_override("font_color",Color("f4e8c9")); label.add_theme_color_override("font_shadow_color",Color("233b40"))
		label.add_theme_constant_override("shadow_offset_x",1); label.add_theme_constant_override("shadow_offset_y",1); add_child(label)

func _volume(label: String,footprint: Rect2,height: float,color: Color) -> void:
	var volume := Node2D.new(); volume.position = project(footprint.end)
	var points := polygon(footprint); var local := PackedVector2Array()
	for point in points: local.append(point-volume.position)
	var top := PackedVector2Array(); var lift := Vector2(0,-height)
	for point in local: top.append(point+lift)
	for spec in [[PackedVector2Array([local[1],local[2],top[2],top[1]]),color.darkened(0.27)],[PackedVector2Array([local[2],local[3],top[3],top[2]]),color.darkened(0.12)],[top,color.lightened(0.18)]]:
		var face := Polygon2D.new(); face.polygon = spec[0]; face.color = spec[1]; volume.add_child(face)
	var body := StaticBody2D.new(); body.collision_mask = 0; volume.add_child(body)
	var collision := CollisionPolygon2D.new(); collision.polygon = local; body.add_child(collision)
	sorted_world.add_child(volume); blockers.append(points)
	var title := Label.new(); title.text = label; title.position = top[0].lerp(top[2],0.5)+Vector2(-110,-12)
	title.size.x = 220; title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size",17); title.add_theme_color_override("font_color",Color("283736")); volume.add_child(title)

func is_walkable_point(point: Vector2) -> bool:
	var local := unproject(point)
	for area in [Rect2(0,0,900,600),rectangle(plan.pier),rectangle(plan.gangway)]:
		if area.has_point(local): return true
	return false

func point_clear(point: Vector2) -> bool:
	for offset in [Vector2.ZERO,Vector2.LEFT*14,Vector2.RIGHT*14,Vector2.UP*14,Vector2.DOWN*14]:
		if not is_walkable_point(point+offset): return false
	for shape in blockers:
		if Geometry2D.is_point_in_polygon(point,shape): return false
		for i in shape.size():
			if point.distance_to(Geometry2D.get_closest_point_to_segment(point,shape[i],shape[(i+1)%shape.size()]))<14: return false
	return true

func _build_navigation() -> void:
	navigation.region = Rect2i(0,0,72,40); navigation.cell_size = Vector2.ONE*STEP
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES; navigation.update()
	for y in navigation.region.size.y:
		for x in navigation.region.size.x: navigation.set_point_solid(Vector2i(x,y),not point_clear(project(Vector2(x,y)*STEP)))

func nearest(point: Vector2) -> Vector2i:
	var base := Vector2i((unproject(point)/STEP).round())
	var best := Vector2i(-1,-1); var distance := INF
	for y in range(-3,4):
		for x in range(-3,4):
			var id := base+Vector2i(x,y)
			if not navigation.region.has_point(id) or navigation.is_point_solid(id): continue
			var d := point.distance_to(project(Vector2(id)*STEP))
			if d<distance: distance = d; best = id
	return best

func route(start: Vector2,end: Vector2) -> PackedVector2Array:
	var a := nearest(start); var b := nearest(end); var result := PackedVector2Array()
	if a.x<0 or b.x<0: return result
	for point in navigation.get_point_path(a,b): result.append(project(point))
	return result

func walk_to(point: Vector2) -> void:
	if point_clear(point): player.follow_path(route(player.position,point))

func _draw() -> void:
	if plan.is_empty(): return
	draw_rect(Rect2(-4000,-2000,8000,5000),Color("234b53"))
	draw_colored_polygon(polygon(Rect2(-900,-900,1800,1500)),Color("7b817b"))
	draw_colored_polygon(polygon(rectangle(plan.street)),Color("c1b79f"))
	draw_colored_polygon(polygon(rectangle(plan.service)),Color("9b9e87"))
	draw_colored_polygon(polygon(rectangle(plan.quay)),Color("aca996"))
	for area in [plan.pier,plan.gangway]: draw_colored_polygon(polygon(rectangle(area)),Color("9c886c"))
	var shore_a := project(Vector2(900,-900)); var shore_b := project(Vector2(900,600))
	draw_line(shore_a,shore_b,Color("d7ccb2"),8)
	var boat := rectangle(plan.boat)
	var hull := PackedVector2Array([project(boat.position+Vector2(0,boat.size.y*0.5)),project(boat.position+Vector2(45,0)),project(Vector2(boat.end.x-30,boat.position.y)),project(Vector2(boat.end.x+20,boat.get_center().y)),project(boat.end-Vector2(30,0)),project(Vector2(boat.position.x+45,boat.end.y))])
	draw_colored_polygon(hull,Color("657b83")); draw_polyline(hull+PackedVector2Array([hull[0]]),Color("c1c8bd"),3)
	for marker in plan.markers:
		var at := project(Vector2(marker.point[0],marker.point[1]))
		draw_circle(at,6,Color("f0d99e"))
	if route_visible:
		var line := PackedVector2Array([project(Vector2(20,280)),project(Vector2(570,280)),project(Vector2(870,280)),project(Vector2(1090,280))])
		draw_polyline(line,Color(0.95,0.83,0.55,0.65),3)

func _interface() -> void:
	var layer := CanvasLayer.new(); add_child(layer)
	var title := Label.new(); title.text = "MAR DE JADE · PLANTA DO CAIS\nEstudo de espaço e circulação"; title.position = Vector2(26,22); title.add_theme_font_size_override("font_size",22); layer.add_child(title)
	status = Label.new(); status.text = "WASD / setas ou clique · caminhar     Tab · mostrar/ocultar percurso principal"; status.position = Vector2(26,845); layer.add_child(status)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT: walk_to(get_global_mouse_position())
	elif event is InputEventKey and event.pressed and event.keycode==KEY_TAB: route_visible = not route_visible; queue_redraw()
