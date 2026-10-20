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
	for area in Ferro.BUILDINGS:
		var a:=Layout.point(Vector2(area.position.x,area.end.y))
		var b:=Layout.point(area.end)
		for n in range(3,0,-1):
			draw_colored_polygon(PackedVector2Array([a,b,b+Vector2(7,n*4),a+Vector2(7,n*4)]),Color(.20,.17,.12,.028))
	for row in [[Vector2(-690,1000),"Estaleiro"],[Vector2(330,850),"Cordoaria"],[Vector2(745,970),"Mercado"],[Vector2(1015,830),"Armazém"],[Vector2(1455,1040),"Oficina"]]:
		Materials.sign(self,row[0],row[1])
	# Small private/service plaques read as notices, not new door handles.
	for id in ["house_west","house_centre","warehouse","workshop"]:
		var at: Vector2=preload("res://scripts/city/lisbon_access.gd").ROWS[id].at
		draw_rect(Rect2(at+Vector2(-15,-33),Vector2(30,12)),Color("67543b"))
		draw_line(at+Vector2(-12,-30),at+Vector2(11,-30),Color("d8c398"),1.2,true)
