@tool
extends Node2D
## A separate ground anchor keeps the support in front of the bed, not under it.
const ART = preload("res://scripts/chapter/dining_art.gd")
var cup_available := true:
	set(value): cup_available = value; queue_redraw()
func _draw() -> void:
	preload("res://scripts/chapter/contact_shadow.gd").draw_contact(self,Vector2.ZERO,Vector2(24,8))
	ART.draw(self,"stool_east",Vector2.ZERO,42)
	if cup_available: ART.draw(self,"cup",Vector2(-9,-27),10)
	ART.draw(self,"bowl",Vector2(7,-25),19)
