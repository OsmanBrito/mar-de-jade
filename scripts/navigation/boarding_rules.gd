extends "res://scripts/combat/campaign_rules.gd"
## Real combat with the campaign's grid, timing, movement and companion.
const Layout = preload("res://scripts/navigation/boarding_layout.gd")
func inside(cell: Vector2i) -> bool:
	return cell.x>=0 and cell.y>=0 and cell.x<Layout.SIZE.x and cell.y<Layout.SIZE.y
func start_encounter(_kind: String, hero_name: String, chosen_style: String = "ES") -> void:
	if progress_override.is_empty(): progress_override = preload("res://scripts/navigation/boarding_loadout.gd").practice(chosen_style)
	super.start_encounter("boarding",hero_name,chosen_style)
	encounter = "atlantic_boarding"; caption = "Abordagem · recuperar o convés"
	lesson = 1; safe_training = false
	units[0].cell = Vector2i(2,2); units[1].cell = Vector2i(2,3)
	units[2].name = "Corsário"; units[2].kind = "raider"; units[2].cell = Vector2i(6,1)
	units[2].hp = 65; units[2].max_hp = 65; units[2].posture = 45; units[2].max_posture = 45
	obstacles.assign([Vector2i(4,0),Vector2i(4,1)])
	add("Vigia corsário",50,0,40,"raider",Vector2i(7,3),10,3,1)
	for unit in units: unit.home = unit.cell; unit.turn_origin = unit.cell
	order_index = -1; rebuild_order(); next_turn()
func uses_training_ai() -> bool: return false
func lesson_result() -> Dictionary:
	var result := outcome()
	return {"finished":not result.is_empty(),"success":result=="victory"}
func outcome() -> String:
	if living(0).is_empty(): return "defeat"
	if living(1).is_empty(): return "victory"
	return ""
func enemy_intent(_id: int) -> Dictionary:
	return {"title":"Recuperar o convés","detail":"Protagonista e Duarte. Movimento, uma ação principal e orientação. A defesa acontece no timing."}
func role_name(id: int) -> String:
	return "Aprendiz" if id==0 else ("Companheiro" if id==1 else "Corsário")
