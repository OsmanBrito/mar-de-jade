extends Node2D
const Dining = preload("res://scripts/chapter/dining_art.gd")
var care := false
var delivered := false
func _draw() -> void:
	Dining.draw(self,"napkin",Vector2(6,-43),30)
	if not care: Dining.draw(self,"bread",Vector2(-13,-47),24)
	if delivered: Dining.draw(self,"cup",Vector2(20,-52),12)
