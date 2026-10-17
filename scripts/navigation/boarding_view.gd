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
func encounter_location() -> String:
	return "A BORDO"

func encounter_caption() -> String:
	return "Recuperar o convés"
