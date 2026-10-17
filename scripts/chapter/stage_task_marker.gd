extends Node2D
var props
func _process(_delta: float) -> void:
	position = props.marker; visible = props.marker_active; queue_redraw()
func _draw() -> void:
	if props==null or not props.marker_active: return
	var font := ThemeDB.fallback_font
	var message: String = GamePreferences.hint_text(props.marker_label)
	var size: int = GamePreferences.font_size(13)
	var width: float = font.get_string_size(message,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
	var height: float = font.get_height(size)+8
	draw_arc(Vector2.ZERO,21+sin(props.clock*4)*2,0,TAU,32,Color("e5c787"),2)
	draw_line(Vector2(0,-24),Vector2(0,-84),Color(0.9,0.8,0.57,0.55),1,true)
	draw_style_box(preload("res://scripts/ui/presentation.gd").panel(Color("132c30"),Color("d9bc80")),Rect2(Vector2(-width*0.5-8,-84-height),Vector2(width+16,height)))
	draw_string(font,Vector2(-width*0.5,-84-height+4+font.get_ascent(size)),message,HORIZONTAL_ALIGNMENT_LEFT,-1,size,Color("eee5cc"))
