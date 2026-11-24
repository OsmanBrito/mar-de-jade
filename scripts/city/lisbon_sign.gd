extends Node2D
## A wayfinding object has a ground anchor and participates in actor depth sorting.
var caption := ""
var right := true
func _draw() -> void:
	draw_set_transform(Vector2(7,3),0,Vector2(1,.4))
	draw_circle(Vector2.ZERO,13,Color(.10,.13,.10,.2))
	draw_set_transform(Vector2.ZERO)
	preload("res://scripts/city/place_materials.gd").sign(self,Vector2.ZERO,caption,right)
