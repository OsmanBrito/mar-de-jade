extends Control
func _draw() -> void:
	preload("res://scripts/combat/portugal_actor_art.gd").draw_actor(self,"hero",Vector2(size.x*0.5,size.y-6),false,"ready",0,"PU",true,0,true,Vector2.RIGHT,2.25)
