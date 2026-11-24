extends SceneTree
var count := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	count += 1
	if not ok: failures.append(message); push_error(message)
func run() -> void:
	var progress = root.get_node("ChapterProgress"); progress.auto_save = false; progress.reset()
	root.get_node("CampaignProfile").hero_name = "Inês"
	var Rules = load("res://scripts/combat/campaign_rules.gd")
	progress.equipped_passives.assign(["GE21"])
	var b = Rules.new(); b.start_encounter("school","Inês","ES"); b.end_turn(0)
	var attack: Dictionary = {"kind":"attack","power":100,"posture":10,"cells":[b.units[0].cell],"target":0,"targets":[0],"no_counter":true}
	var preview: Dictionary = b.defense_preview(2,0,attack,0)
	check(preview.damage == 95,"Stationary passive reduces first contact 5 percent")
	var hp: int = b.units[0].hp; b.resolve_enemy(attack,{0:0})
	check(hp-b.units[0].hp == preview.damage,"Passive prediction equals actual impact")
	check(b.defense_preview(2,0,attack,0).damage == 100,"Stationary protection consumed once")
	b.start_encounter("school","Inês","ES"); b.end_turn(0); b.units[0].cell = Vector2i(4,4)
	preview = b.defense_preview(2,0,attack,0)
	progress.equipped_passives.clear()
	check(preview.damage == b.defense_preview(2,0,attack,0).damage,"Involuntary position change invalidates stationary protection")
	progress.equipped_passives.assign(["GE22"])
	b.start_encounter("school","Inês","ES"); b.perform(0,b.units[2].cell,1); b.end_turn(0)
	b.resolve_enemy(b.ai_plan(),{}); b.next_turn()
	check(b.skill_def(0,1).cost == 3,"First technique after previous-turn basic discounts one energy")
	var qi: int = b.units[0].qi; b.perform(1,b.units[2].cell,1)
	check(qi-b.units[0].qi == 3 and b.skill_def(0,1).cost == 4,"Technique discount executes once")
	for style in ["LA","FO"]:
		progress.equipped_passives.assign([style+"-P11"])
		b.start_encounter("school","Inês",style)
		check(b.skill_def(0,1).power == (22 if style=="LA" else 21),style+" stationary technique power bonus")
		b.current().cell += Vector2i.LEFT
		check(b.skill_def(0,1).power == (21 if style=="LA" else 20),style+" movement removes power bonus")
	progress.equipped_passives.assign(["MC-P11"])
	b.start_encounter("school","Inês","MC"); b.perform(0,b.units[2].cell,1); b.end_turn(0)
	b.resolve_enemy(b.ai_plan(),{0:1}); b.next_turn(); b.perform(1,b.current().cell,1); b.end_turn(0)
	attack.cells = [b.units[0].cell]
	preview = b.defense_preview(2,0,attack,0); hp = b.units[0].hp; b.resolve_enemy(attack,{0:0})
	check(preview.damage == 67 and hp-b.units[0].hp == 67,"Machado preparation and passive affect actual residual")
	progress.equipped_passives.clear(); progress.passives.assign(["DU-P09"])
	b.start_encounter("duarte_support","Inês")
	check(b.skill_def(1,4).cost == 6,"Learning does not auto-equip Duarte passive")
	progress.duarte_equipped_passives.assign(["DU-P09"])
	check(b.skill_def(1,4).cost == 5,"Equipped Duarte passive discounts first interception")
	b.perform(4,b.units[0].cell,1)
	check(b.skill_def(1,4).cost == 6,"Duarte discount used once")
	b.end_turn(0); b.end_turn(0)
	hp = b.units[0].hp; var duarte_hp: int = b.units[1].hp; b.resolve_enemy(attack,{0:0})
	check(hp-b.units[0].hp == 60 and duarte_hp-b.units[1].hp == 40,"Interception preserves approved 60/40 split")
	var valid: Dictionary = progress.snapshot()
	for field in ["flags","choices","inventory","skills"]:
		var invalid = valid.duplicate(true); invalid[field] = null
		FileAccess.open("res://tests/passive-invalid.json",FileAccess.WRITE).store_string(JSON.stringify(invalid))
		check(progress.load_from("res://tests/passive-invalid.json") == ERR_INVALID_DATA and progress.snapshot() == valid,"Malformed "+field+" rejected atomically")
	print("PASSIVES_RESULT ",JSON.stringify({"checks":count,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
