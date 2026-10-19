extends "res://scripts/combat/campaign_rules.gd"
## Real combat with the campaign's grid, timing, movement and companion.
const Layout = preload("res://scripts/navigation/boarding_layout.gd")
func inside(cell: Vector2i) -> bool:
	return cell.x>=0 and cell.y>=0 and cell.x<Layout.SIZE.x and cell.y<Layout.SIZE.y
func start_encounter(_kind: String, hero_name: String, chosen_style: String = "ES") -> void:
	if progress_override.is_empty(): progress_override = preload("res://scripts/navigation/boarding_loadout.gd").practice(chosen_style)
	super.start_encounter("boarding",hero_name,chosen_style)
	# The reference profile describes its own campaign, not our carried kit.
	profile = {}
	potions = int(progress_override.inventory.get("PT-C01",0)); tonics = int(progress_override.inventory.get("PT-C03",0))
	encounter = "atlantic_boarding"; caption = "Abordagem · recuperar o convés"
	lesson = 1; safe_training = false
	units[0].cell = Vector2i(2,2); units[1].cell = Vector2i(2,3)
	var companion: Dictionary = progress_override.get("companion_vitals",{}).get("duarte",{})
	for key in companion: units[1][key] = int(companion[key])
	units[2].name = "Corsário"; units[2].kind = "raider"; units[2].cell = Vector2i(6,1)
	units[2].hp = 65; units[2].max_hp = 65; units[2].posture = 45; units[2].max_posture = 45
	obstacles.assign([Vector2i(4,0),Vector2i(4,1)])
	add("Vigia corsário",50,0,40,"raider",Vector2i(7,3),10,3,1)
	for unit in units: unit.home = unit.cell; unit.turn_origin = unit.cell
	order_index = -1; rebuild_order(); next_turn()
func uses_training_ai() -> bool: return false
func commands(actor: int) -> Array:
	var actions: Array = super.commands(actor)
	if actor<2: actions.append(-1)
	return actions
func skill_def(actor: int,skill: int) -> Dictionary:
	if skill in [6,7]:
		var definition: Dictionary = Catalog.HERO_SKILLS[1][0].duplicate(true)
		definition.name = "Ligadura" if skill==6 else "Água e fôlego"
		definition.description = "Usa uma ligadura da tua sacola." if skill==6 else "Usa uma reserva de água da tua sacola."
		definition.cost = 0; definition.shape = "friend"; definition.range = 1; definition.resource = "hp" if skill==6 else "qi"
		definition.effect = "heal" if skill==6 else "qi"; definition.power = 0
		return definition
	return super.skill_def(actor,skill)
func availability_reason(skill: int) -> String:
	if skill in [6,7]:
		if current().team!=0 or current().acted: return "Aguarda uma ação disponível."
		return "Não há este suprimento na tua sacola." if (potions if skill==6 else tonics)<=0 else ""
	return super.availability_reason(skill)
func support_preview(actor: int,skill: int,aim: Vector2i) -> Dictionary:
	var result: Dictionary = super.support_preview(actor,skill,aim)
	if skill in [6,7] and result.target>=0:
		result.capacity = 25 if skill==6 else 5
		result.amount = mini(result.capacity,maxi(0,int(units[result.target]["max_"+result.resource])-int(units[result.target][result.resource])))
		result.waste = result.capacity-result.amount
		# Keep the generic UI resource fields consistent with Jade's fixed doses.
		result[result.resource] = result.amount
	return result
func perform(skill: int,aim: Vector2i,quality: int) -> Dictionary:
	var result: Dictionary = super.perform(skill,aim,quality)
	if skill in [6,7] and not result.has("error"):
		var id := "PT-C01" if skill==6 else "PT-C03"
		progress_override.inventory[id] = maxi(0,int(progress_override.inventory.get(id,0))-1)
		if progress_override.inventory[id]==0: progress_override.inventory.erase(id)
	return result
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
