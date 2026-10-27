extends Node2D
## A small wash stand beside the practice rack, using the existing story atlas.
var washing:=false
var clock:=0.0
func _process(delta:float) -> void:
	if washing:clock+=delta;queue_redraw()
func _draw() -> void:
	var art=preload("res://scripts/chapter/dining_art.gd")
	art.draw(self,"stool_west",Vector2.ZERO,40)
	art.draw(self,"bowl",Vector2(0,-31),36)
	draw_set_transform(Vector2(0,-44),0,Vector2(1,.35))
	draw_circle(Vector2.ZERO,10,Color("719a9b"))
	if washing:draw_arc(Vector2.ZERO,4+fmod(clock*8,6),0,TAU,18,Color("b6d6cb"),1)
	draw_set_transform(Vector2.ZERO)
	art.draw(self,"napkin",Vector2(-28,-24),25)
