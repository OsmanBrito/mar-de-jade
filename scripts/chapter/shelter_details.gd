@tool
extends RefCounted
## One room treatment for the prologue, adult opening and recovery scenes.
static func install(room: Node2D) -> void:
	if room.has_node("ShelterFloor"): return
	var ground: TileMapLayer = room.get_node("Ground")
	var floor := Polygon2D.new(); floor.name = "ShelterFloor"; floor.z_index = -1
	floor.polygon = PackedVector2Array([ground.map_to_local(Vector2i.ZERO)+Vector2(0,-32),ground.map_to_local(Vector2i(7,0))+Vector2(64,0),ground.map_to_local(Vector2i(7,6))+Vector2(0,32),ground.map_to_local(Vector2i(0,6))+Vector2(-64,0)])
	floor.texture = preload("res://scripts/navigation/boarding_assets.gd").texture("regional-deck.png",true)
	var uv := PackedVector2Array()
	for point in floor.polygon: uv.append(Vector2(point.x/310.0+point.y/155.0,point.y/155.0-point.x/310.0)*floor.texture.get_size())
	floor.uv = uv; floor.color = Color("b3a58c"); floor.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	room.add_child(floor); ground.hide()
	var dressing := Node2D.new(); dressing.set_script(load("res://scripts/chapter/shelter_dressing.gd"))
	dressing.name = "TecidosELuz"; room.add_child(dressing)
	var sorted: Node2D = room.get_node("ActorsAndProps")
	var art = preload("res://scripts/chapter/furniture_art.gd")
	art.place(sorted,"cupboard",Vector2(-228,162),Vector2(103,134))
	art.place(sorted,"shelf",Vector2(224,164),Vector2(116,115))
	art.place(sorted,"washstand",Vector2(-302,221),Vector2(95,90))

static func draw_walls(canvas: Node2D,ground: TileMapLayer,room_size: Vector2i) -> void:
	var corner := ground.map_to_local(Vector2i.ZERO)+Vector2(0,-32)
	var left := ground.map_to_local(Vector2i(0,room_size.y-1))+Vector2(-64,0)
	var right := ground.map_to_local(Vector2i(room_size.x-1,0))+Vector2(64,0)
	var lift := Vector2(0,-145)
	for side in [left,right]:
		var wall := PackedVector2Array([side,corner,corner+lift,side+lift])
		canvas.draw_colored_polygon(wall,Color("aaa18c") if side==left else Color("c7bda4"))
		canvas.draw_line(side+lift,corner+lift,Color("655740"),6,true)
		canvas.draw_line(side,corner,Color("71634b"),9,true)
		# Subtle limewash grain and mortar, with local light/shade along the base.
		for row in 10:
			var height := -12.0-row*13
			for col in 23:
				var at: Vector2 = corner.lerp(side,(col+0.3+fmod(row*0.37,0.4))/24.0)+Vector2(0,height)
				canvas.draw_line(at,at+Vector2(6,-1),Color(0.34,0.29,0.21,0.045),1,true)
		for i in range(1,9):
			var at: Vector2 = corner.lerp(side,float(i)/9)
			canvas.draw_line(at,at+Vector2(0,-26),Color("9a8a6c"),2,true)
		var center: Vector2 = corner.lerp(side,0.55)+Vector2(0,-83)
		var slope: Vector2 = (side-corner).normalized()*34
		var window := PackedVector2Array([center-slope+Vector2(0,-33),center+slope+Vector2(0,-33),center+slope+Vector2(0,25),center-slope+Vector2(0,25)])
		canvas.draw_colored_polygon(window,Color("49685f"))
		var border := window.duplicate(); border.append(window[0])
		canvas.draw_polyline(border,Color("79684d"),7,true)
		canvas.draw_line(center+Vector2(0,-33),center+Vector2(0,25),Color("b3a17e"),3,true)
		canvas.draw_line(center-slope,center+slope,Color("b3a17e"),3,true)
		canvas.draw_line(center-slope+Vector2(0,29),center+slope+Vector2(0,29),Color("ded0ab"),5,true)
