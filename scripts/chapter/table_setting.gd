@tool
extends Node2D
const ART = preload("res://scripts/chapter/dining_art.gd")
var empty_bowl := false
func _draw() -> void:
	ART.draw(self,"napkin",Vector2(-5,-8),27)
	ART.draw(self,"bread",Vector2(10,-18),27)
	ART.draw(self,"cup",Vector2(33,-6),13)
	if empty_bowl: preload("res://scripts/chapter/story_prop_art.gd").draw_item(self,"PT-Q02",Vector2.ZERO,25)
	else: ART.draw(self,"bowl",Vector2.ZERO,25)
