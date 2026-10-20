extends SceneTree
var Rules
var checks := 0
var failures: Array[String] = []
var game
func _initialize(): call_deferred("run")
func check(ok: bool,message: String):
	checks += 1
	if not ok: failures.append(message); push_error(message)
func fresh():
	var b = Rules.new(); b.start_encounter("practice","Miguel","FO")
	b.current_id = 0; b.obstacles.clear(); b.units[0].cell = Vector2i(3,3); b.units[0].turn_origin = Vector2i(3,3)
	b.units[0].face = 0; b.units[0].qi = 40; b.units[0].hp = 100; b.units[0].defense = 0
	b.units[2].cell = Vector2i(5,3); b.units[3].cell = Vector2i(7,6); b.units[4].cell = Vector2i(7,5)
	return b
func frames(n := 3):
	for i in n: await process_frame
func run():
	Rules = load("res://scripts/combat/campaign_rules.gd")
	var p = root.get_node("ChapterProgress"); p.auto_save = false; p.reset()
	root.get_node("GamePreferences").persist_enabled = false
	root.get_node("CampaignProfile").hero_name = "Miguel"
	var b = fresh()
	check(b.commands(0)==[0,1,2,3,8],"Firearm exposes basic and all four canonical techniques")
	for action in Rules.Firearm.IDS:
		var d: Dictionary = b.skill_def(0,action)
		check(d.content_id==Rules.Firearm.IDS[action] and not d.name.begins_with("Exercício"),"Canonical identity: "+d.content_id)
		p.learn(d.content_id)
	check(p.skills.size()==4,"All four techniques can be learned and saved")
	var legacy: Dictionary = p.snapshot(); legacy.skills = ["FO07"]; legacy.schema_version = 12; legacy.erase("development")
	var restored = load("res://scripts/chapter/chapter_progress.gd").new()
	check(restored.restore(legacy)==OK and Rules.Firearm.LEARNED.all(func(id): return restored.skills.has(id)),"Existing chapter saves inherit the completed four-technique lesson")
	check(legacy.skills==["FO07"],"Upgrading a loaded chapter does not mutate its input snapshot")
	restored.free()
	var ocean = load("res://scripts/navigation/voyage_model.gd").new()
	ocean.hero_name = "Miguel"; ocean.style = "FO"; ocean.boarding_profile = preload("res://scripts/navigation/boarding_loadout.gd").practice("FO")
	ocean.boarding_profile.skills = ["FO07","DU01","DP01"]
	var old_voyage: Dictionary = ocean.snapshot()
	check(ocean.restore(old_voyage) and Rules.Firearm.LEARNED.all(func(id): return ocean.boarding_profile.skills.has(id)),"Existing voyage saves upgrade the completed lesson after validation")
	var carried = preload("res://scripts/navigation/boarding_loadout.gd").practice("FO")
	carried.skills = p.skills.duplicate()
	var ship = load("res://scripts/navigation/boarding_rules.gd").new(); ship.progress_override = carried; ship.start_encounter("boarding","Miguel","FO")
	check(ship.commands(0)==[0,1,2,3,8,-1],"Learned firearm techniques reach real boarding with the bag")
	carried.skills = ["FO07"]
	ship = load("res://scripts/navigation/boarding_rules.gd").new(); ship.progress_override = carried; ship.start_encounter("boarding","Miguel","FO")
	check(ship.commands(0)==[0,1,-1],"An older loadout cannot silently execute unlearned techniques")
	for action in [0,1,2,3]:
		for grade in [0,1,2]:
			b = fresh()
			var aim: Vector2i = b.units[2].cell
			var before: int = b.units[2].hp; var qi: int = b.units[0].qi
			var d: Dictionary = b.skill_def(0,action); var preview: Dictionary = b.predict(0,2,action,grade,aim)
			var r: Dictionary = b.perform(action,aim,grade)
			check(not r.has("error") and before-b.units[2].hp==preview.damage,"Damage preview equals execution: %d / %d"%[action,grade])
			check(b.units[0].qi>=qi if action==0 else b.units[0].qi==qi-d.cost+(1 if grade==2 else 0),"One payment and the universal Perfect recovery: %d / %d"%[action,grade])
			check(b.units[0].acted and not b.available(action),"One principal action: %d / %d"%[action,grade])
			if action==3: check(b.units[0].cell==r.firearm_landing and b.distance(r.firearm_origin,r.firearm_landing)==1,"Passage moves exactly one legal side step after damage")
	b = fresh(); var prepared: int = b.skill_def(0,2).power
	b.move_to(Vector2i(3,4))
	check(b.skill_def(0,2).power<prepared and b.valid_attack(2,b.units[2].cell),"Moving removes the prepared bonus without disabling the shot")
	b.move_to(Vector2i(3,3))
	check(b.skill_def(0,2).power<prepared,"Returning to the starting cell cannot restore the stationary bonus")
	for action in [0,1,2,3]:
		b = fresh(); b.obstacles.append(Vector2i(4,3))
		var before: int = b.units[0].qi
		check(not b.valid_attack(action,b.units[2].cell) and b.perform(action,b.units[2].cell,2).has("error") and b.units[0].qi==before,"Wall blocks shot without payment: "+str(action))
		b = fresh(); b.units[3].cell = Vector2i(4,3)
		check(not b.valid_attack(action,b.units[2].cell),"The first unit blocks a shot through it: "+str(action))
	b = fresh(); b.units[2].cell = Vector2i(5,4)
	check(not b.valid_attack(1,b.units[2].cell),"Measure requires a grid line")
	b = fresh(); b.obstacles.assign([Vector2i(3,2),Vector2i(3,4)])
	check(not b.valid_attack(3,b.units[2].cell) and b.units[0].cell==Vector2i(3,3),"Passage unavailable when both lateral destinations are blocked")
	b.obstacles.erase(Vector2i(3,4))
	check(b.valid_attack(3,b.units[2].cell),"One legal lateral destination is sufficient")
	for grade in [0,1,2]:
		b = fresh(); b.perform(1,b.units[2].cell,grade)
		check(b.approach_weakened==(grade>0),"Measure approach effect requires Good or Perfect")
		b.current_id = 2
		var approach := {"kind":"attack","power":40,"posture":10,"approach_bonus":8,"targets":[0],"cells":[b.units[0].cell],"name":"Aproximação"}
		var mitigated: int = b.defense_preview(2,0,approach,0).damage
		b.approach_weakened = false
		var plain: int = b.defense_preview(2,0,approach,0).damage
		check(mitigated==plain-4 if grade>0 else mitigated==plain,"Measure halves only the approach bonus")
	for kind in ["attack","heavy","ranged"]:
		for face in [0,1,2]:
			b = fresh(); b.units[0].face = face; b.units[2].cell = Vector2i(4,3)
			var r: Dictionary = b.perform(8,b.units[0].cell,1)
			check(not r.has("error") and b.firearm_guard and not b.units[0].guard and r.hits.is_empty(),"Cannon guard has no free shot or universal guard")
			b.current_id = 2
			var attack := {"kind":kind,"power":40,"posture":10,"targets":[0],"cells":[b.units[0].cell],"name":"Contacto"}
			var protected: int = b.defense_preview(2,0,attack,0).damage
			b.firearm_guard = false
			var plain: int = b.defense_preview(2,0,attack,0).damage
			var eligible: bool = kind!="ranged" and face==0
			check(protected==roundi(plain*0.7) if eligible else protected==plain,"Guard protects frontal contact only: %s / %d"%[kind,face])
			b.firearm_guard = true; b.resolve_enemy(attack,{0:0})
			check(b.firearm_guard!=eligible,"Only the first eligible contact consumes cannon guard")
	b = fresh(); b.perform(8,b.units[0].cell,1)
	for i in b.order.size()+1:
		b.next_turn()
		if b.current_id==0: break
	check(not b.firearm_guard,"Cannon guard expires at the next own turn")
	p.equipped_passives.assign(["GE22"])
	for action in [1,2,3,8]:
		b = fresh(); b.mode = "school"; b.previous_action = 0; b.previous_action_turn = b.current().turns-1
		check(b.skill_def(0,action).cost==Rules.Firearm.COSTS[action]-1,"The first technique discount supports every firearm technique")
		b.perform(action,b.units[0].cell if action==8 else b.units[2].cell,1)
		b.units[0].acted = false; b.units[0].qi = 40
		check(b.technique_evaluated and b.skill_def(0,1).cost==4,"A different first technique cannot leave a second passive discount available")
	p.equipped_passives.clear()
	p.flags.recovered = true; p.style = "FO"
	game = load("res://scenes/art/firearm_study.tscn").instantiate(); root.add_child(game); await frames()
	game.host.set_process(false)
	var v = game.host.tactical
	v.select_move(); v.select_cell(Vector2i(4,4)); v.confirm(); v.update(1)
	check(game.host.combat.firearm_moved,"Confirmed movement removes the stationary bonus")
	v.undo_move()
	check(not game.host.combat.firearm_moved,"Undoing a planned movement restores stationary eligibility")
	for action in [1,2,3,8]:
		var pad := InputEventJoypadButton.new(); pad.pressed = true; pad.button_index = JOY_BUTTON_Y
		game.host._unhandled_input(pad)
		check(v.selected_skill==action,"Controller cycles every firearm technique: "+str(action))
		check(v.icon_texture(0,action).resource_path.ends_with(Rules.Firearm.IDS[action]+".png"),"Technique uses its own existing icon: "+str(action))
	v.cancel(); v.select_skill(3); v.select_cell(game.host.combat.units[2].cell)
	game.host.queue_redraw(); await frames()
	check(v.field_state.has("firearm_landing"),"Aim preview reveals the lateral landing")
	v.confirm(); v.commit_timing(2); v.update(0.451)
	check(v.result.has("firearm_origin") and game.host.combat.units[0].cell!=v.result.firearm_origin and v.unit_position(0).distance_to(v.screen(v.result.firearm_origin))<5,"Shot is displayed at its original cell before the lateral step")
	v.update(0.65); game.host.queue_redraw(); await frames()
	check(v.weapon_tips.has(0) and v.weapon_tips[0].is_finite(),"Illustrated muzzle remains anchored while moving")
	v.update(0.6)
	check(v.unit_position(0).is_equal_approx(v.screen(game.host.combat.units[0].cell)),"Recovery ends on the actual landing cell")
	game.free(); await frames()
	print("FIREARM_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
