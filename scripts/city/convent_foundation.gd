@tool
extends Node2D
const Plan = preload("res://scripts/city/convent_plan.gd")
const Materials = preload("res://scripts/city/place_materials.gd")
func _draw() -> void:
	# Short shadows follow the real plinth, rather than tinting the entire adro.
	for i in Plan.FRONTAGE.size()-1:
		var a: Vector2 = Plan.FRONTAGE[i]
		var b: Vector2 = Plan.FRONTAGE[i+1]
		for band in range(4,0,-1):
			var offset := Vector2(3,3)*band
			draw_colored_polygon(PackedVector2Array([a,b,b+offset,a+offset]),Color(.19,.15,.10,.035))
		Materials.polygon(self,PackedVector2Array([a,b,b+Vector2(0,5),a+Vector2(0,5)]),"limewash-wall",Color("9b8a6c"),230)
		draw_line(a+Vector2(0,5),b+Vector2(0,5),Color(.21,.17,.12,.18),2,true)
