extends "res://scripts/combat/portugal_view.gd"
const Layout = preload("res://scripts/navigation/boarding_layout.gd")
func _init() -> void:
	arena = preload("res://scripts/navigation/boarding_arena.gd").new()
	field = preload("res://scripts/navigation/boarding_field.gd").new()
# Every fighter inherits Portugal's full combat poses, size and measured grips.
func input_event(event: InputEvent) -> void:
	super.input_event(event)
	if event is InputEventKey and event.pressed and event.physical_keycode in [KEY_UP,KEY_DOWN,KEY_LEFT,KEY_RIGHT] and phase in ["choose","move","aim","facing"]:
		cursor_cell = cursor_cell.clamp(Vector2i.ZERO,Layout.SIZE-Vector2i.ONE)
		selected_cell = cursor_cell
func draw_header() -> void:
	super.draw_header()
	host.panel(Rect2(16,12,222,61),BG,EDGE)
	host.text_at("A BORDO · RONDA %02d"%model.round_no,Vector2(30,33),10,GOLD)
	host.text_at("Recuperar o convés",Vector2(30,57),13,PAPER)
