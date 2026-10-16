extends "res://scripts/combat/mar_de_ferro/tactics.gd"
## Portugal only changes encounter content and the explicitly unlearned perfect defense.
var lesson := 0
var perfect_defense_enabled := false
var safe_training := true
var caption := "Treino infantil"
var valid_hits := 0
var defense_success := false
var defense_failed := false

func start_lesson(id: int, hero_name: String) -> void:
	lesson = id
	caption = "A mão que avisa" if id == 0 else "Não fechar os olhos"
	valid_hits = 0
	defense_success = false
	defense_failed = false
	profile = {}
	encounter = "portugal_child_attack" if id == 0 else "portugal_child_defense"
	units.clear(); heroes.clear(); enemies.clear(); obstacles.clear(); order.clear()
	objective.clear(); optional_objective.clear(); exploration_notes.clear(); turn_events.clear()
	add(hero_name,100,10,100,"child",Vector2i(2,5),18,5,0)
	# The reference reserves IDs 0/1 for allies and 2+ for enemies. The second
	# slot is absent from this lesson, never a recruited or controllable companion.
	add("",0,0,0,"absent",Vector2i(-1,-1),0,0,0)
	units[1].withdrawn = true
	add("Alvo de treino" if id == 0 else "Leonor criança",1000,0,200,"target" if id == 0 else "leonor",Vector2i(5,3),12,4,1)
	units[2].face = 2
	obstacles.assign([Vector2i(3,4),Vector2i(3,3),Vector2i(3,2)])
	if id == 1:
		units[0].cell = Vector2i(4,3)
		units[0].face = 0
	potions = 0; tonics = 0; level = 0; counters = 0; perfects = 0; enemy_turns = 0
	tech_uses = [{},{}]
	order_index = -1; current_id = -1; round_no = 1
	rebuild_order()
	next_turn()

func commands(actor: int) -> Array:
	return [0] if units[actor].team == 0 else []

func skill_def(actor: int, skill: int) -> Dictionary:
	if actor == 0 and skill == 0:
		var definition: Dictionary = Catalog.HERO_SKILLS[1][0].duplicate(true)
		definition.name = "Ataque básico"
		definition.description = "Golpe curto com instrumento de treino. Alcance de uma casa; recupera 1 alento."
		definition.uses_opening = false
		return mastered(actor,skill,definition)
	if actor == 0: return {}
	return super.skill_def(actor,skill)

func availability_reason(skill: int) -> String:
	if current_id == 0 and skill != 0: return "Esta ação não está disponível no treino."
	return super.availability_reason(skill)

func perform(skill: int, aim: Vector2i, quality: int) -> Dictionary:
	var result: Dictionary = super.perform(skill,aim,quality)
	if not result.has("error") and skill == 0 and lesson == 0 and not result.hits.is_empty():
		valid_hits += 1
	return result

func uses_training_ai() -> bool: return true
func ai_plan() -> Dictionary:
	if not uses_training_ai(): return super.ai_plan()
	if lesson == 0:
		return {"kind":"recover","name":"Repor o alvo","cells":[],"targets":[],"path":[],"destination":current().cell}
	var hero: Dictionary = units[0]
	var destination: Vector2i = current().cell
	var best_path: Array[Vector2i] = []
	var best_distance := 999
	for cell in reachable(current_id).costs:
		if distance(cell,hero.cell) != 1: continue
		var path: Array[Vector2i] = path_to(current_id,cell)
		if path.size() < best_distance:
			best_distance = path.size(); destination = cell; best_path = path
	var targets_list: Array = [0] if distance(destination,hero.cell) == 1 else []
	return {"kind":"attack","name":"Golpe controlado","power":8,"posture":3,"cells":[hero.cell],"target":0,"targets":targets_list,"path":best_path,"destination":destination,"no_counter":true}

func enemy_intent(id: int) -> Dictionary:
	return {"title":"Alvo imóvel" if lesson == 0 else "Golpe controlado anunciado","detail":"Pratica alcance e orientação." if lesson == 0 else "Leonor aproxima-se e repete um golpe curto. Orienta a guarda para ela; confirma a defesa no sinal."}

func role_name(id: int) -> String:
	return "Aprendiz" if id == 0 else ("Alvo imóvel" if lesson == 0 else "Instrutora")

func objective_status() -> Dictionary:
	return {}

func outcome() -> String:
	return ""

func hurt(target: int, hp: int, posture: int) -> bool:
	# The approved childhood contract is safe and repeatable. Neither pupil nor
	# instructor can die or be incapacitated during these exercises.
	if not safe_training: return super.hurt(target,hp,posture)
	return super.hurt(target,mini(hp,maxi(0,int(units[target].hp)-1)),mini(posture,maxi(0,int(units[target].posture)-1)))

func defense_preview(actor: int, target: int, attack: Dictionary, grade: int) -> Dictionary:
	return super.defense_preview(actor,target,attack,grade if perfect_defense_enabled else mini(grade,1))

func resolve_enemy(plan: Dictionary, grades: Dictionary) -> Dictionary:
	var simple: Dictionary = grades.duplicate()
	for id in simple: simple[id] = int(simple[id]) if perfect_defense_enabled else mini(int(simple[id]),1)
	var result: Dictionary = super.resolve_enemy(plan,simple)
	if lesson == 1 and not result.has("error") and plan.get("targets",[]).has(0):
		defense_success = int(simple.get(0,0)) == 1 and flank(current_id,0) == "Frente"
		defense_failed = not defense_success
	return result




func lesson_result() -> Dictionary:
	return {"finished":valid_hits >= 2 or defense_success or defense_failed,"success":valid_hits >= 2 or defense_success}

