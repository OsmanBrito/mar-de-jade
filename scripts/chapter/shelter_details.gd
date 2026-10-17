@tool
extends RefCounted
## One room treatment for the prologue, adult opening and recovery scenes.
static func install(room: Node2D) -> void:
	if room.has_node("ShelterFloor"): return
	var finish := ShaderMaterial.new(); finish.shader = preload("res://assets/shaders/shelter_limewash.gdshader")
	room.material = finish
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
	draw_wall_span(canvas,corner,left,right)

static func draw_wall_span(canvas: Node2D,corner: Vector2,left: Vector2,right: Vector2,height: float = 145) -> void:
	var lift := Vector2(0,-height)
	for side in [left,right]:
		var wall := PackedVector2Array([side,corner,corner+lift,side+lift])
		canvas.draw_colored_polygon(wall,Color("a89d84") if side==left else Color("d0c1a1"))
		# A staggered stone plinth replaces the repeated vertical ticks.
		for row in 2:
			for col in 14:
				var start := clampf((float(col)-row*0.5)/13,0,1)
				var end := clampf((float(col+1)-row*0.5)/13,0,1)
				if end <= start: continue
				var a: Vector2 = corner.lerp(side,start)+Vector2(0,-row*12)
				var b: Vector2 = corner.lerp(side,end)+Vector2(0,-row*12)
				var face := PackedVector2Array([a,b,b-Vector2(0,11),a-Vector2(0,11)])
				var tint := Color("81755c").lightened(fposmod(col*0.163+row*0.27,0.14))
				canvas.draw_colored_polygon(face,tint)
				canvas.draw_line(a,b,Color(0.22,0.19,0.14,0.32),1,true)
				canvas.draw_line(b,b-Vector2(0,11),Color(0.22,0.19,0.14,0.3),1,true)
		canvas.draw_line(side-Vector2(0,25),corner-Vector2(0,25),Color("b3a080"),3,true)
		canvas.draw_line(side+lift,corner+lift,Color("655039"),7,true)
		canvas.draw_line(side+lift+Vector2(0,3),corner+lift+Vector2(0,3),Color("a28962"),1,true)
		# Local scuffs and thin plaster cracks are sparse rather than tiled.
		for i in [2,7,11]:
			var at: Vector2 = corner.lerp(side,float(i)/14)+Vector2(0,-48-fmod(i*17.0,46.0))
			canvas.draw_polyline(PackedVector2Array([at,at+Vector2(-2,9),at+Vector2(1,17),at+Vector2(-1,22)]),Color(0.32,0.26,0.17,0.17),0.7,true)
		for i in range(1,20):
			var at: Vector2 = corner.lerp(side,float(i)/21)+Vector2(0,-29-fmod(i*7.0,12.0))
			canvas.draw_line(at,at+Vector2(11,side.y/side.length()*5),Color(0.36,0.29,0.17,0.09),3,true)
		var center: Vector2 = corner.lerp(side,0.55)+Vector2(0,-83)
		var slope: Vector2 = (side-corner).normalized()*34
		var window := PackedVector2Array([center-slope+Vector2(0,-33),center+slope+Vector2(0,-33),center+slope+Vector2(0,25),center-slope+Vector2(0,25)])
		canvas.draw_colored_polygon(window,Color("253f3c"))
		var border := window.duplicate(); border.append(window[0])
		canvas.draw_polyline(border,Color("88795e"),10,true)
		canvas.draw_polyline(border,Color("b8a17b"),5,true)
		canvas.draw_line(window[0]+Vector2(3,4),window[3]+Vector2(3,-3),Color("3a3e30"),5,true)
		canvas.draw_line(window[0]+Vector2(3,4),window[1]+Vector2(-2,4),Color("3a3e30"),4,true)
		for pane in 3:
			var a: Vector2 = center-slope+Vector2(0,-24+pane*15)
			canvas.draw_line(a+Vector2(5,3),a+slope*1.8+Vector2(0,4),Color(0.62,0.72,0.60,0.12),7,true)
		canvas.draw_line(center+Vector2(0,-33),center+Vector2(0,25),Color("b3a17e"),3,true)
		canvas.draw_line(center-slope,center+slope,Color("b3a17e"),3,true)
		canvas.draw_colored_polygon(PackedVector2Array([window[3]+Vector2(-4,0),window[2]+Vector2(4,0),window[2]+Vector2(7,7),window[3]+Vector2(-1,7)]),Color("cbb994"))
		canvas.draw_line(window[3]+Vector2(-1,7),window[2]+Vector2(7,7),Color("74684f"),2,true)
	# Exposed corner posts join the two wall planes, with a subtle lit edge.
	for at in [left,corner,right]:
		canvas.draw_line(at,at+lift,Color("65533d"),7,true)
		canvas.draw_line(at+Vector2(-1,0),at+lift+Vector2(-1,0),Color("9e8864"),2,true)
