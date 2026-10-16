@tool
extends Node2D

func _draw() -> void:
	preload("res://scripts/chapter/furniture_art.gd").draw(self,"bench",Vector2(0,20),Vector2(148,91))
