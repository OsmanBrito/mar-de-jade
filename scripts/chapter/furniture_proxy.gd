@tool
extends Node2D
## Code-native original layout furniture. Collision remains an editable scene child.
@export_enum("bed", "table") var furniture: String = "bed"

func _draw() -> void:
	var size := Vector2(178,144) if furniture == "bed" else Vector2(134,94)
	var foot := Vector2(0,28) if furniture == "bed" else Vector2(0,6)
	preload("res://scripts/chapter/furniture_art.gd").draw(self,furniture,foot,size)
