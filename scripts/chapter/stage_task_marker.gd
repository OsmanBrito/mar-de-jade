extends Node2D
var props
func _process(_delta: float) -> void:
	position = props.marker; visible = props.marker_active; queue_redraw()
func _draw() -> void:
	if props==null or not props.marker_active: return
	var art = preload("res://scripts/ui/marker_art.gd")
	art.ground_ring(self,Vector2.ZERO,22,props.clock)
	draw_line(Vector2(0,-14),Vector2(0,-70),Color(0.9,0.8,0.57,0.45),1,true)
	art.badge(self,Vector2(0,-84),"!",true,props.clock)
	art.caption(self,Vector2(0,-102),GamePreferences.hint_text(props.marker_label),GamePreferences.font_size(13))
