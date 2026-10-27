extends Node2D
## Short depth-sorted masonry segments with real thickness on every axis.
var across := Vector2.ZERO
var height := 60.0
func _draw() -> void:
	var a := -across*.5
	var b := across*.5
	var up := Vector2(0,-height)
	var thickness := Vector2(8,-5)
	var face := PackedVector2Array([a,b,b+up,a+up])
	preload("res://scripts/city/place_materials.gd").polygon(self,face,"limewash-wall",Color("b7b29b"),170)
	draw_colored_polygon(PackedVector2Array([a+up,b+up,b+up+thickness,a+up+thickness]),Color("c9bea0"))
	draw_colored_polygon(PackedVector2Array([b,b+thickness,b+up+thickness,b+up]),Color("8a8772"))
	draw_line(a+up,b+up,Color("8d8167"),3,true)
	draw_line(a+Vector2(0,-8),b+Vector2(0,-8),Color("8b846e"),3,true)
	draw_line(a,b,Color(.20,.22,.17,.32),3,true)
