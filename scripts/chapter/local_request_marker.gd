extends Node2D
## Nearby interactions remain quiet; the focused one owns the readable cue.
var highlighted := false
var available := true
var symbol := "…"
var caption := ""
var clock := 0.0
var world: Node2D
var visibility_weight := 0.0
func _ready() -> void:
	var parent := get_parent()
	while parent!=null:
		if parent.has_method("is_walkable_point"): world = parent; break
		parent = parent.get_parent()
func _process(delta: float) -> void:
	clock += delta
	var target := 1.0
	if is_instance_valid(world) and is_instance_valid(world.player):
		var distance: float = global_position.distance_to(world.player.global_position)
		target = 1.0-smoothstep(170,400 if symbol=="!" else 280,distance)
	if highlighted: target = 1.0
	visibility_weight = lerpf(visibility_weight,target,1-exp(-delta*12))
	modulate.a = visibility_weight
	queue_redraw()
func _draw() -> void:
	if not available or visibility_weight<.015: return
	var center := Vector2(0,-92)
	var color := Color("efd195") if highlighted else Color("b7c3aa")
	var radius := 12.0 if highlighted else 7.0
	draw_circle(center+Vector2(1,2),radius+1,Color(0,.03,.025,.45))
	draw_circle(center,radius,Color("203a38"))
	draw_arc(center,radius,0,TAU,28,color,1.5,true)
	var font := ThemeDB.fallback_font
	var text := symbol if highlighted or symbol in ["!","?"] else "·"
	var text_size := 15 if highlighted else 11
	var width := font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,text_size).x
	draw_string(font,center+Vector2(-width/2,5 if highlighted else 4),text,HORIZONTAL_ALIGNMENT_LEFT,-1,text_size,color)
	if highlighted:
		draw_set_transform(Vector2(0,-25),0,Vector2(1,.45))
		draw_arc(Vector2.ZERO,19,0,TAU,32,Color(.94,.82,.57,.7),1.5,true)
		draw_set_transform(Vector2.ZERO)
