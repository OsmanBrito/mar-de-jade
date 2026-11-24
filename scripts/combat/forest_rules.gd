extends "res://scripts/combat/portugal_rules.gd"
const LEONOR_SKILLS := [0,12,16,17,18,19,24,26]
func start_hunt(kind: String,hero_name: String) -> void:
	super.start_lesson(0,hero_name)
	safe_training = false; perfect_defense_enabled = false
	encounter = "portugal_child_"+kind
	caption = "Sozinho na clareira · O lobo" if kind=="wolf" else "Leonor · A força que não conhecias"
	obstacles.clear(); units[0].cell = Vector2i(4,3); units[2].cell = Vector2i(5 if kind=="wolf" else 6,3)
	units[0].hp = 110; units[0].max_hp = 110; units[0].defense = 4; units[0].attack = 4
	units[2].name = "Lobo" if kind=="wolf" else "Urso"; units[2].kind = kind
	units[2].hp = 76 if kind=="wolf" else 1800; units[2].max_hp = units[2].hp
	units[2].posture = 180 if kind=="wolf" else 1600; units[2].max_posture = units[2].posture
	units[2].speed = 12; units[2].movement = 5; units[2].moves = 5; units[2].defense = 0 if kind=="wolf" else 35
	if kind=="bear":
		units[0].name = "Leonor criança"; units[0].kind = "leonor"
		units[0].hp = 12000; units[0].max_hp = 12000; units[0].qi = 120; units[0].max_qi = 120
		units[0].posture = 9000; units[0].max_posture = 9000; units[0].defense = 900; units[0].attack = 900
		units[0].speed = 99; units[0].movement = 8; units[0].moves = 8
	order_index = -1; rebuild_order(); next_turn()
func commands(actor: int) -> Array:
	return LEONOR_SKILLS if actor==0 and encounter.ends_with("bear") else [0,5] if actor==0 else []
func skill_def(actor: int,skill: int) -> Dictionary:
	if actor>=2: return super.skill_def(actor,skill)
	if encounter.ends_with("wolf"):
		if skill==5: return mastered(actor,skill,Catalog.extra_skill(actor,skill).duplicate(true))
		var basic: Dictionary = Catalog.HERO_SKILLS[1][0].duplicate(true)
		basic.name = "Golpe firme"; basic.description = "Mantém a distância e golpeia quando o lobo se aproxima. O treino de Leonor ajuda a orientar a guarda."
		return mastered(actor,0,basic)
	var definition: Dictionary = Catalog.HERO_SKILLS[1][skill].duplicate(true)
	definition.requires_partner = false; definition.cooldown = 0
	definition.cover_after = false; definition.duarte_cover_after = false
	if int(definition.get("power",0))>0: definition.power = int(definition.power)*45
	definition.posture = 2200; definition.cost = 0
	definition.range = maxi(2,int(definition.range))
	definition.description = "Domínio de Leonor · "+("Um golpe supremo, com a força que ela nunca tinha mostrado ao herói." if definition.get("ultimate",false) else "Uma técnica lendária que Leonor já domina por completo.")+" Escolhe o urso e confirma o golpe."
	return mastered(actor,skill,definition)
func availability_reason(skill: int) -> String:
	if not commands(current_id).has(skill): return "Esta ação não está disponível."
	if current().acted: return "A ação deste turno já foi usada."
	return ""
func uses_training_ai() -> bool: return false
func role_name(id: int) -> String:
	return "Leonor · Domínio extraordinário" if id==0 and encounter.ends_with("bear") else "Aprendiz" if id==0 else "Animal do bosque"
func ai_plan() -> Dictionary:
	var plan: Dictionary = super.ai_plan()
	if plan.kind=="attack":
		plan.name = "Investida do lobo" if encounter.ends_with("wolf") else "Pancada do urso"
		plan.power = 19 if encounter.ends_with("wolf") else 180
	return plan
func enemy_intent(_id: int) -> Dictionary:
	return {"title":"Investida do lobo","detail":"Orienta a guarda para ele e responde no sinal."} if encounter.ends_with("wolf") else {"title":"Urso · Força esmagadora","detail":"Contra o herói seria um perigo extremo. Agora controlas Leonor: escolhe uma técnica lendária ou suprema."}
func outcome() -> String:
	if units[0].hp<=0: return "defeat"
	return "victory" if units[2].hp<=0 else ""
func lesson_result() -> Dictionary:
	var result := outcome()
	return {"finished":not result.is_empty(),"success":result=="victory"}
