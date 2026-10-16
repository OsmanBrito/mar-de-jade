extends "res://scripts/combat/portugal_view.gd"
const Layout = preload("res://scripts/navigation/boarding_layout.gd")
const BoardingArt = preload("res://scripts/navigation/boarding_actor_art.gd")
func _init() -> void:
	arena = preload("res://scripts/navigation/boarding_arena.gd").new()
	field = preload("res://scripts/navigation/boarding_field.gd").new()
func draw() -> void:
	arena.focus.clear()
	for unit in model.units:
		if unit.hp>0: arena.focus.append(unit_position(unit.id))
	super.draw()
func draw_combat_actor(unit: Dictionary,point: Vector2,direction: Vector2,pose: String,time: float,style: String,reaction: float) -> Vector2:
	if unit.team==0: return super.draw_combat_actor(unit,point,direction,pose,time,style,reaction)
	return BoardingArt.draw_actor(host,"rogue" if unit.id==2 else "guard",point,direction.x<0,pose,time,reaction,host.progress.data.options.reduced_fx)
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
