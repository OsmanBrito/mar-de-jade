extends Node2D
## The merchant's provisions on the market stall, drawn with the painted dining set.
const Dining = preload("res://scripts/chapter/dining_art.gd")
const Shadows = preload("res://scripts/chapter/contact_shadow.gd")
## [art, foot on the stall top, width]; back items first so the front overlaps them.
const LAYOUT := [["napkin",Vector2(-30,-2),30.0],["bread",Vector2(-4,-6),30.0],["napkin",Vector2(-20,6),26.0],
	["bread",Vector2(14,2),26.0],["cup",Vector2(32,0),13.0],["cup",Vector2(40,6),13.0]]
func _draw() -> void:
	for item in LAYOUT:
		Shadows.draw_contact(self,item[1]+Vector2(0,-1),Vector2(item[2]*0.5,item[2]*0.16))
		Dining.draw(self,item[0],item[1],item[2])
