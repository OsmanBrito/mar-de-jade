extends Node2D
## Purposeful wear in work areas, never a second paving grid or collision layer.
const Materials = preload("res://scripts/city/place_materials.gd")
const Ferro = preload("res://scripts/city/ferro_lisbon.gd")
const Layout = preload("res://scripts/city/lisbon_layout.gd")
func patch(at: Vector2,radius: Vector2,color: Color) -> void:
	for ring in range(5,0,-1):
		draw_set_transform(at,0,radius*(.6+float(ring)*.08))
		draw_circle(Vector2.ZERO,1,Color(color.r,color.g,color.b,color.a/5))
	draw_set_transform(Vector2.ZERO)
func _draw() -> void:
	# Wood chips at the shipyard, fibres by the ropewalk, damp stone at the market.
	patch(Vector2(-430,920),Vector2(155,52),Color(.46,.32,.16,.23))
	patch(Vector2(120,825),Vector2(130,38),Color(.53,.44,.27,.17))
	patch(Vector2(590,1000),Vector2(135,40),Color(.19,.31,.28,.23))
	patch(Vector2(1335,925),Vector2(120,44),Color(.55,.39,.20,.19))
	# Each descent has a different ground use, leaving the central walking strip clear.
	for at in [Vector2(-900,510),Vector2(-900,730)]:patch(at,Vector2(34,95),Color(.41,.34,.22,.19))
	for at in [Vector2(1660,550),Vector2(1660,770)]:patch(at,Vector2(32,90),Color(.52,.46,.32,.14))
	var rng:=RandomNumberGenerator.new();rng.seed=231019
	for area in [Vector2(-430,920),Vector2(1335,925)]:
		for n in 26:
			var at: Vector2=area+Vector2(rng.randf_range(-105,105),rng.randf_range(-24,24))
			draw_line(at,at+Vector2(rng.randf_range(3,9),rng.randf_range(-2,2)),Color(.65,.46,.24,.48),1.2,true)
	for x in [772,793]:
		draw_line(Vector2(x,785),Vector2(x+56,966),Color(.32,.29,.23,.12),3,true)
	for i in Ferro.BUILDINGS.size():
		var area: Rect2 = Ferro.BUILDINGS[i]
		var base := Layout.point(Vector2(area.get_center().x,area.end.y))
		var building := get_parent().get_node("ActorsAndProps/Ferro_"+Ferro.BUILDING_KEYS[i])
		var width: float = building.size.x
		# The same low front / receding side as the source architecture. This
		# continuous contact and cast shadow replaces the tiny oval under a house.
		var a := base+Vector2(-width*.43,-width*.13)
		var b := base+Vector2(width*.28,-5)
		var c := base+Vector2(width*.48,-width*.22)
		for band in range(5,0,-1):
			var shift := Vector2(5,3)*band
			draw_colored_polygon(PackedVector2Array([a,b,c,c+shift,b+shift,a+shift]),Color(.15,.17,.13,.035))
		draw_polyline(PackedVector2Array([a,b,c]),Color(.16,.17,.13,.23),4,true)
	# Quayside traffic leaves a narrow worn strip, leaving the civic square calm.
	for x in range(-480,1510,64):
		patch(Vector2(x,1045+sin(x*.015)*8),Vector2(42,14),Color(.68,.64,.51,.12))
