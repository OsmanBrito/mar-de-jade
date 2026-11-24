extends "res://tests/medida_catalogue.gd"
const Visuals=preload("res://scripts/combat/medida_presentation.gd")
func frames(n:=2):
	for i in n: await process_frame
func run():
	Rules=load("res://scripts/combat/campaign_rules.gd");p=root.get_node("ChapterProgress");p.auto_save=false
	check(Visuals.profiles().size()==65,"Every Medida technique has a visual profile")
	for id in Book.rows():
		var definition: Dictionary=Visuals.profiles()[id]
		check(definition.name==Book.rows()[id].name and definition.impact==.45,id+" uses the real combat impact")
		for time in [0.0,.2,.45,.75,1.1]:
			var sample: Dictionary=Visuals.sample(id,time,Book.rows()[id].style,Vector2.RIGHT)
			check(int(sample.frame)>=0 and int(sample.frame)<=8 and sample.body.is_finite() and sample.axis.is_finite() and is_finite(float(sample.tilt)),id+" stable anchored pose at "+str(time))
		var kind: String=Visuals.group(id)
		if kind in ["passage","retreat","sidestep"]:
			check(Visuals.movement_fraction(id,.45)==0 and Visuals.movement_fraction(id,1.1)==1,id+" step occurs after the actual strike")
		elif kind in ["approach","escort"]:
			check(Visuals.movement_fraction(id,.45)==1,id+" legal approach completes at contact")
		if kind in ["guard","watch"]: check(Visuals.sample(id,.45,Book.rows()[id].style,Vector2.RIGHT).frame==6,id+" holds guard instead of an attack pose")
	var points: Array=[Vector2(0,0),Vector2(1,0),Vector2(1,1)]
	check(Visuals.path_position(points,.5)==Vector2(1,0),"Visual movement follows path corners without crossing a wall")
	check(Visuals.sample("ES10",.3,"ES",Vector2.RIGHT).axis!=Visuals.sample("MC06",.3,"MC",Vector2.RIGHT).axis,"Feint and committed cleave have different gestures")
	for id in ["ES08","PU15","LA13"]:
		var c=fixture(id,1)
		if id=="PU15": c.units[2].cell=Vector2i(6,3)
		var host=load("res://scripts/combat/battle_host.gd").new();host.combat=c;root.add_child(host);host.tactical.begin();await frames()
		host.active=false;host.tactical.selected_skill=Book.action(id)
		host.tactical.selected_cell=c.units[1].cell if id=="LA13" else c.units[2].cell
		var initial: Vector2i=c.units[0].cell;var before: Dictionary=p.snapshot();var qi: int=c.units[0].qi
		host.tactical.queue_player(1);host.tactical.clock=.3
		check(c.units[0].cell==initial and c.units[0].qi==qi,id+" windup never applies gameplay early")
		host.tactical.clock=.45;host.tactical.apply_impact()
		check(not host.tactical.result.has("error") and c.units[0].qi<qi,id+" pays only at the original impact")
		var visual: Vector2=host.tactical.unit_position(0)
		check(visual==host.tactical.screen(initial) if id=="ES08" else visual==host.tactical.screen(c.units[0].cell),id+" body position matches the technique movement phase")
		host.tactical.clock=1.15
		check(host.tactical.unit_position(0)==host.tactical.screen(c.units[0].cell),id+" recovery ends at actual legal destination")
		check(p.snapshot()==before,id+" animation does not alter campaign progression")
		host.free();await frames()
	print("MEDIDA_VISUALS_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
