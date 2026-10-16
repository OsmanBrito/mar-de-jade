@tool
extends Node2D
@export var room_size := Vector2i(8,7)

func _draw() -> void:
	var ground = get_node_or_null("Ground") as TileMapLayer
	if ground == null or ground.tile_set == null:
		return
	var corner = ground.map_to_local(Vector2i.ZERO)+Vector2(0,-32)
	var left = ground.map_to_local(Vector2i(0,room_size.y-1))+Vector2(-64,0)
	var right = ground.map_to_local(Vector2i(room_size.x-1,0))+Vector2(64,0)
	var lift = Vector2(0,-125)
	draw_colored_polygon(PackedVector2Array([left,corner,corner+lift,left+lift]),Color("a79f87"))
	draw_colored_polygon(PackedVector2Array([corner,right,right+lift,corner+lift]),Color("c5baa0"))
	draw_line(left+lift,corner+lift,Color("665943"),7)
	draw_line(corner+lift,right+lift,Color("665943"),7)
	for side in [left,right]:
		for i in range(1,5):
			var point = corner.lerp(side,float(i)/5.0)
			draw_line(point,point+lift,Color("847559"),5)
