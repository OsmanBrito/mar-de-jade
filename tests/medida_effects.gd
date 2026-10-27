extends "res://tests/medida_catalogue.gd"
func enemy_plan(c,power:=40) -> Dictionary:
	return {"kind":"attack","power":power,"posture":8,"targets":[0],"cells":[c.units[0].cell],"path":[],"destination":c.units[2].cell,"name":"Contacto"}
func run():
	Rules=load("res://scripts/combat/campaign_rules.gd"); p=root.get_node("ChapterProgress"); p.auto_save=false; root.get_node("CampaignProfile").hero_name="Miguel"
	for id in ["PU08","MC13","ES57","MC57"]:
		for grade in [1,2,3]:
			var c=fixture(id,grade); var command: int=Book.action(id)
			var plan: Dictionary=enemy_plan(c); var original: int=c.defense_preview(2,0,plan,0).damage
			var qi: int=c.units[0].qi; c.perform(command,c.units[0].cell,1)
			var preview: Dictionary=c.defense_preview(2,0,plan,0)
			check(preview.damage<original,id+" grade "+str(grade)+" reduces real eligible physical hit")
			check(c.units[0].qi<qi,id+" preparation never restores energy")
			c.current_id=2; c.units[2].acted=false
			var hp: int=c.units[0].hp; var result: Dictionary=c.resolve_enemy(plan,{0:0})
			check(not result.has("error") and hp-c.units[0].hp==preview.damage,id+" guard prediction matches execution")
			check(c.battle_practice.get("hero",{}).has(id),id+" actual guard contact awards skill practice")
			check(c.medida_state.has("guard_0")== (id in ["ES57","MC57"]),id+" consumes exactly one occurrence")
			c.current_id=0; c.units[0].turns+=1; c.Medida.turn(c)
			check(not c.medida_state.has("guard_0"),id+" expires at next own turn")
	var c=fixture("ES13",1); c.perform(Book.action("ES13"),c.units[0].cell,1)
	check(c.push_destination(2,0,1)==c.units[0].cell,"Firm position prevents physical push")
	var ranged: Dictionary=enemy_plan(c); ranged.kind="ranged"
	check(c.defense_preview(2,0,ranged,0).get("medida_guard","")=="guard_0","Medida Guardada protects distant attack")
	check(not c.defense_preview(2,0,enemy_plan(c),0).has("medida_guard"),"Medida Guardada does not protect contact")
	c=fixture("MC10",1); c.units[2].guard=true; c.perform(Book.action("MC10"),c.units[2].cell,0)
	check(not c.units[2].get("order_disarmed",false),"Failed timing cannot disarm")
	c=fixture("MC10",1); c.units[2].guard=true; c.perform(Book.action("MC10"),c.units[2].cell,1)
	check(c.units[2].get("order_disarmed",false),"Cunha disarms physical guard on good hit")
	c=fixture("PU11",1); c.units[2].kind="boss"; c.perform(Book.action("PU11"),c.units[2].cell,1)
	check(not c.units[2].get("order_disarmed",false) and c.units[2].get("order_weapon_weakened",false),"Boss suffers reduced power instead of losing action")
	c=fixture("PU11",1); c.units[2].order_disarm_immune_until=c.units[2].turns+2; c.perform(Book.action("PU11"),c.units[2].cell,1)
	check(not c.units[2].get("order_disarmed",false),"Temporary immunity prevents repeated strong control")
	c=fixture("ES08",1); c.units[0].moves=0; var before: Dictionary=c.units[0].duplicate(true)
	check(c.perform(Book.action("ES08"),c.units[2].cell,1).has("error") and c.units[0]==before,"Side step cannot bypass movement budget")
	c=fixture("LA13",1); var ally_action: bool=c.units[1].acted; var moves: int=c.units[0].moves
	c.perform(Book.action("LA13"),c.units[1].cell,1)
	check(c.units[1].acted==ally_action and c.units[0].moves==moves-1,"Escort spends own movement without giving ally an action")
	check(c.medida_state.has("guard_1"),"Escort protects the escorted ally")
	for id in ["LA01","LA11","LA57","FO11"]:
		c=fixture(id,1); c.units[2].cell=Vector2i(7,3); c.units[2].turn_origin=c.units[2].cell
		c.perform(Book.action(id),c.units[0].cell,1); c.current_id=2
		if id=="LA11": c.units[2].turn_origin=Vector2i(6,4)
		var hp: int=c.units[2].hp
		var plan: Dictionary={"path":[Vector2i(6,3),Vector2i(5,3)],"destination":Vector2i(5,3)}
		var hits: Array=c.Medida.before_enemy(c,plan)
		check(not hits.is_empty() and c.units[2].hp<hp,id+" watches real voluntary movement")
		hp=c.units[2].hp; c.Medida.before_enemy(c,plan)
		check(c.units[2].hp==hp,id+" cannot hit the same enemy twice")
		check(c.Medida.before_enemy(c,{"path":[],"destination":Vector2i(5,3)}).is_empty(),id+" does not trigger on teleport or empty movement")
	c=fixture("FO57",1); c.units[2].cell=Vector2i(7,3); c.units[2].turn_origin=c.units[2].cell
	c.perform(Book.action("FO57"),c.units[0].cell,1); c.current_id=2
	var first: Array=c.Medida.before_enemy(c,{"path":[Vector2i(8,3)],"destination":Vector2i(8,3)})
	check(first.size()==1,"Mira watches a marked exit from real low cover")
	c.units[3].hp=500; c.units[3].cell=Vector2i(7,3); c.units[3].turn_origin=c.units[3].cell; c.current_id=3
	check(c.Medida.before_enemy(c,{"path":[Vector2i(8,3)],"destination":Vector2i(8,3)}).is_empty(),"A second enemy at the same exit cannot consume the other marked shot")
	c.units[3].cell=Vector2i(6,4); c.units[3].turn_origin=c.units[3].cell
	var second: Array=c.Medida.before_enemy(c,{"path":[Vector2i(7,4)],"destination":Vector2i(7,4)})
	check(second.size()==1 and second[0].damage<first[0].damage,"Distinct second exit uses half-power shot")
	c=fixture("ES12",1); c.units[3].hp=100; c.units[3].cell=Vector2i(4,2)
	check(c.area(0,Book.action("ES12"),c.units[2].cell).has(c.units[3].cell),"Corner cut includes second adjacent perpendicular target")
	c.units[3].cell=Vector2i(3,3)
	check(not c.area(0,Book.action("ES12"),c.units[2].cell).has(c.units[3].cell),"Corner cut excludes opposite side")
	for id in ["MC12","LA14"]:
		c=fixture(id,1); c.units[3].hp=500; c.units[3].cell=Vector2i(6,3)
		var action: int=Book.action(id); var aim: Vector2i=c.units[2].cell
		check(c.area(0,action,aim).has(c.units[3].cell),id+" includes the second aligned enemy behind the first")
		var before_hp: int=c.units[3].hp; var preview: Dictionary=c.predict(0,3,action,1,aim)
		c.perform(action,aim,1)
		check(before_hp-c.units[3].hp==preview.damage,id+" second target receives predicted impact")
	c=fixture("PU56",1); c.units[2].defense=30; c.medida_state.focus="armor"
	var armor: int=c.predict(0,2,Book.action("PU56"),1).damage; c.medida_state.focus="anchor"
	check(armor>c.predict(0,2,Book.action("PU56"),1).damage,"Focus changes armor penetration before confirmation")
	c.perform(Book.action("PU56"),c.units[2].cell,1)
	check(c.units[0].get("medida_anchor",0)==1 and not c.units[2].has("medida_weaken"),"Selected focus applies one benefit only")
	c=fixture("MC11",1); c.perform(Book.action("MC11"),c.units[2].cell,1); c.current_id=2; c.units[2].cell=Vector2i(7,3);c.units[2].turn_origin=c.units[2].cell
	var shortened: Dictionary=c._medida_plan({"kind":"attack","path":[Vector2i(6,3),Vector2i(5,3)],"destination":Vector2i(5,3),"targets":[0],"cells":[c.units[0].cell]})
	check(shortened.path.size()==1 and shortened.destination==Vector2i(6,3) and shortened.targets.is_empty(),"Contrapeso removes one advance step and cannot attack from outside contact")
	# Save every learned ID and mastery grade without losing the active six.
	p.reset(); p.auto_save=false; p.flags.order_audience_done=true; p.flags.order_trial_done=true
	for id in Book.rows(): p.learn(id); p.flags["order_manual_"+id]=true
	for id in p.skills: Dev.member(p).practice[id]=20
	var snapshot: Dictionary=p.snapshot(); check(p.save_to("user://medida-full.json")==OK,"Complete repertoire saves to disk")
	p.reset(); check(p.load_from("user://medida-full.json")==OK and p.skills.size()==65,"Complete repertoire loads all 65 unique skills")
	check(p.development.members.hero.active_skills.size()==6,"Save/load respects six active slots")
	print("MEDIDA_EFFECTS_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
