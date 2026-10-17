extends SceneTree
var RULES
var count := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	count += 1
	if not ok: failures.append(message); push_error(message)
func run() -> void:
	RULES = load("res://scripts/combat/campaign_rules.gd")
	root.get_node("CampaignProfile").hero_name = "Inês"
	root.get_node("ChapterProgress").auto_save = false
	for style in ["ES","LA","MC","FO","PU"]:
		var b = RULES.new()
		b.start_encounter("style_test","Inês",style)
		check(b.valid_attack(0,b.units[2].cell),style+" basic has legal target")
		var hp: int = b.units[2].hp
		b.perform(0,b.units[2].cell,1)
		check(b.units[2].hp < hp and b.lesson_result().finished,style+" basic applies damage and ends trial")
		b.start_encounter("school","Inês",style)
		b.perform(0,b.units[2].cell,1)
		b.end_turn(0)
		b.resolve_enemy(b.ai_plan(),{0:1}); b.next_turn()
		var aim: Vector2i = b.current().cell if style == "MC" else b.units[2].cell
		check(b.valid_attack(1,aim),style+" learned technique has legal target")
		var result: Dictionary = b.perform(1,aim,1)
		check(not result.has("error") and b.correct_sequence,style+" completes basic to technique sequence")
		if style == "MC":
			check(not b.lesson_result().finished,"Machado preparation waits for actual contact")
			b.end_turn(0); b.resolve_enemy(b.ai_plan(),{0:1})
		check(b.lesson_result().finished,style+" school trial completes")
		check(not b.available(5),style+" cannot use removed defense action")
	var b = RULES.new(); b.start_encounter("perfect_defense","Inês")
	b.end_turn(0); var plan: Dictionary = b.ai_plan()
	var hp: int = b.units[0].hp
	b.resolve_enemy(plan,{0:2})
	check(b.units[0].hp == hp and b.defense_success,"Perfect defense blocks full damage with Tomé")
	b.start_encounter("duel","Inês")
	check(not b.perfect_defense_enabled,"Perfect defense not granted before defeat in new campaign")
	var actions := 0
	for i in 12:
		if b.lesson_result().finished: break
		if b.current().team == 0:
			b.perform(0,b.units[2].cell,2); actions += 1; b.end_turn(0)
		else:
			b.resolve_enemy(b.ai_plan(),{0:1}); b.next_turn()
	check(b.units[0].hp == 0 and actions > 0 and b.units[2].hp > 0,"Power gap gives real playable defeat, not round script")
	b.start_encounter("school","Inês","FO"); b.end_turn(0)
	b.current_id = 2
	plan = {"power":40,"posture":3,"approach_bonus":8,"kind":"attack","path":[Vector2i(4,3)]}
	var expected_attack := plan.duplicate(true); expected_attack.power = 36
	var expected_damage: int = b.defense_preview(b.current_id,0,expected_attack,0).damage
	b.approach_weakened = true; b.weakened_target = 2
	check(b.defense_preview(b.current_id,0,plan,0).damage==expected_damage,"Disparo de Medida halves only the explicit approach bonus")
	plan.erase("approach_bonus"); b.approach_weakened = false
	expected_damage = b.defense_preview(b.current_id,0,plan,0).damage
	b.approach_weakened = true
	check(b.defense_preview(b.current_id,0,plan,0).damage==expected_damage,"Walking without an approach bonus does not reduce the entire attack")
	b.start_encounter("practice","Inês","FO"); b.current_id = 0; b.obstacles.clear()
	b.perform(1,b.units[2].cell,1)
	check(b.weakened_target==2,"The weakening belongs to the enemy actually hit")
	plan.approach_bonus = 8; b.approach_weakened = false
	expected_damage = b.defense_preview(4,0,plan,0).damage
	b.approach_weakened = true
	check(b.defense_preview(4,0,plan,0).damage==expected_damage,"Hitting the dummy does not weaken the instructor's unrelated approach")
	print("CHAPTER_RULES_RESULT ",JSON.stringify({"checks":count,"failures":failures}))
	quit(0 if failures.is_empty() else 1)

