@tool
extends Node2D
## Code-native original layout furniture. Collision remains an editable scene child.
@export_enum("bed", "table", "stool") var furniture: String = "bed"

func _draw() -> void:
	if furniture == "stool":
		preload("res://scripts/chapter/contact_shadow.gd").draw_contact(self,Vector2.ZERO,Vector2(15,5))
		preload("res://scripts/chapter/dining_art.gd").draw(self,"stool_west",Vector2.ZERO,38)
		return
	var size := Vector2(178,144) if furniture == "bed" else Vector2(134,94)
	var foot := Vector2(0,28) if furniture == "bed" else Vector2(0,6)
	preload("res://scripts/chapter/contact_shadow.gd").draw_contact(self,Vector2(0,-6),Vector2(size.x*0.46,18 if furniture == "bed" else 13))
	preload("res://scripts/chapter/furniture_art.gd").draw(self,furniture,foot,size)
