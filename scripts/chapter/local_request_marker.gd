extends Node2D
var highlighted := false
var available := true
var symbol := "…"
var caption := ""
var clock := 0.0

func _process(delta: float) -> void:
	clock += delta
	queue_redraw()

func _draw() -> void:
	if not available: return
	var center := Vector2(0,-112+sin(clock*2.0)*2)
	var color := Color("efd195") if highlighted else Color("a2caba")
	draw_circle(center,11,Color("153338"))
	draw_arc(center,11,0,TAU,24,color,1.5,true)
	var font := ThemeDB.fallback_font
	draw_string(font,center+Vector2(-5,5),symbol,HORIZONTAL_ALIGNMENT_LEFT,-1,14,color)
	if highlighted:
		var size := font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,14)
		draw_style_box(preload("res://scripts/ui/presentation.gd").panel(Color("132c30"),Color("84764e")),Rect2(Vector2(-size.x/2-9,-150),size+Vector2(18,10)))
		draw_string(font,Vector2(-size.x/2,-132),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("f1e4c3"))
