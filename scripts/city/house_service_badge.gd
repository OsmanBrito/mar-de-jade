extends Node2D
func _draw() -> void:
	draw_rect(Rect2(-5,-57,10,14),Color("e1d3b0"))
	preload("res://scripts/chapter/order_house.gd").symbol(self,Vector2(0,-50),5)
