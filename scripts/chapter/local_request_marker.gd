extends Node2D
var highlighted := false
var available := true
var symbol := "…"
var caption := ""
var clock := 0.0
var outlined_host := false

## The person this marker belongs to gets a gold outline while in focus.
func _outline(node: Node,on: bool) -> void:
	var person = node.get("presentation") if node != null else null
	if person == null and node != null and "outlined" in node: person = node
	if person != null and "outlined" in person: person.outlined = on

func _exit_tree() -> void:
	if outlined_host: _outline(get_parent(),false)

func _process(delta: float) -> void:
	clock += delta
	queue_redraw()

func _draw() -> void:
	if not available: return
	var art = preload("res://scripts/ui/marker_art.gd")
	var center := Vector2(0,-112+sin(clock*2.0)*2)
	art.badge(self,center,symbol,highlighted,clock)
	if highlighted:
		art.caption(self,center+Vector2(0,-20),caption)
	# Outline the person or object this marker belongs to while it is in focus.
	if highlighted != outlined_host: _outline(get_parent(),highlighted); outlined_host = highlighted
