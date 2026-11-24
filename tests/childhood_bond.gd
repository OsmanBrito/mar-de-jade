extends SceneTree
const Bond=preload("res://scripts/chapter/childhood_bond.gd")
const Plan=preload("res://scripts/city/forest_plan.gd")
var checks:=0
var failures:Array[String]=[]
var p
var game
var balance:Array=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,text:String) -> void:
	checks+=1
	if not ok:failures.append(text);push_error(text)
func frames(n:int=4) -> void:
	for i in n:await process_frame
func drain() -> void:
	for i in 100:
		if game.phase!="dialogue":return
		game.advance()
func walk(at:Vector2) -> bool:
	game.world.walk_to(at)
	for i in 2600:
		await physics_frame
		if game.world.player.position.distance_to(at)<20:return true
		if game.world.player.destination_path.is_empty():break
	return false
func capture(id:String) -> void:
	if DisplayServer.get_name()=="headless":return
	DirAccess.make_dir_recursive_absolute("res://.qa-runtime/childhood-close/captures")
	await frames();await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.qa-runtime/childhood-close/captures/"+id+".png")
func mount(stage:int,at:Vector2) -> void:
	p.childhood_hunt={"stage":stage,"position":[at.x,at.y],"notes":[]}
	game=load("res://scenes/chapter_01/forest_hunt.tscn").instantiate();root.add_child(game);await frames(7);drain()
func simulate(grade:int,wait_turns:int) -> void:
	var b=preload("res://scripts/combat/forest_rules.gd").new();b.start_hunt("wolf","Miguel")
	var turns:=0;var valid:=true
	for i in 100:
		if not b.outcome().is_empty():break
		if b.current_id==0:
			if turns>=wait_turns:
				var result:Dictionary=b.perform(0,b.units[2].cell,grade)
				valid=valid and not result.has("error")
			turns+=1
		else:
			var result:Dictionary=b.resolve_enemy(b.ai_plan(),{0:grade})
			valid=valid and not result.has("error")
		b.end_turn(b.suggested_facing(b.current_id))
	balance.append({"quality":grade,"initial_waits":wait_turns,"turns":turns,"hp":b.units[0].hp,"result":b.outcome()})
	check(valid and b.outcome()=="victory" and b.units[0].hp>0,"Real wolf victory with quality "+str(grade)+" and "+str(wait_turns)+" initial waits")
	check(not b.safe_training and b.units[2].hp<=0,"Wolf is genuinely defeated without training immortality")
func run() -> void:
	Engine.time_scale=3;root.size=Vector2i(1440,900)
	p=root.get_node("ChapterProgress");p.auto_save=false;p.reset();root.get_node("CampaignProfile").hero_name="Miguel"
	for grade in [0,1,2]:simulate(grade,0)
	simulate(0,2)
	var timing=preload("res://scripts/chapter/childhood_pacing.gd").new()
	timing.sample("opening.tscn",10,false);timing.sample("plaza.tscn",25,false);timing.sample("plaza.tscn",40,true);timing.sample("forest_hunt.tscn",15,false)
	check(timing.report().total_seconds==50,"Pacing report counts reading and exploration but excludes pause")
	timing.sample("training.tscn",5,false);timing.sample("promise.tscn",5,false)
	timing.sample("adult_opening.tscn",5,false);timing.sample("forest_hunt.tscn",10,false)
	check(timing.report().complete_childhood and timing.report().total_seconds==60,"Adult transition closes timing without counting adulthood")
	var partial=preload("res://scripts/chapter/childhood_pacing.gd").new();partial.sample("forest_hunt.tscn",10,false);partial.sample("adult_opening.tscn",1,false)
	check(partial.report().reached_adulthood and not partial.report().complete_childhood and partial.report().missing_scenes.size()==4,"A resumed partial session cannot claim a full childhood measurement");partial.free()
	check(not timing.report().human_reading_validated,"Automated report does not claim a human pacing approval");timing.free()
	check(not root.has_node("ChildhoodPacing"),"Ordinary games do not enable a local timing log")
	for stage in 9:check(not Bond.hint(stage).is_empty(),"Clue or context for forest stage "+str(stage))
	check(Bond.promise(p).is_empty(),"Legacy promise does not invent a forest adventure")
	p.choices={"hunt_departure":"together"}
	var personal:Dictionary={"coins":p.coins,"skills":p.skills.duplicate(),"inventory":p.inventory.duplicate(true),"vitals":p.vitals.duplicate()}
	await mount(4,Vector2(1994,935))
	check(game.view.body.text.contains("Depois do treino")==false,"Reload uses current context instead of repeating the outing invitation")
	check(await walk(Plan.GOALS[4]),"Walk reaches the parting among the roots")
	game.interact();check(game.lines.any(func(row):return str(row[1]).contains("Dissemos que íamos juntos")),"Parting acknowledges the selected agreement")
	var before:Vector2=game.leonor.position
	drain()
	check(game.phase=="separating" and not game.world.player.enabled,"Departure gets its own visible stage")
	for i in 10:await physics_frame
	check(game.leonor.visible and game.leonor.position.distance_to(before)>8,"Leonor actually walks away before disappearing")
	await capture("parting")
	for i in 300:
		if game.phase!="separating":break
		await physics_frame
	check(game.state.stage==5 and not game.leonor.visible and game.world.player.enabled,"Control resumes alone after the short separation")
	check(p.save_to("user://bond-test.json")==OK and p.load_from("user://bond-test.json")==OK,"Separation checkpoint remains valid")
	check(await walk(Plan.GOALS[5]),"Hero walks to wolf encounter")
	game.interact();drain()
	check(game.phase=="battle" and game.battle_host.combat.commands(0)==[0,5],"Solo wolf encounter only offers the child's actions")
	check(game.battle_host.note.contains("Controlas Miguel") and game.battle_host.note.contains("Respirar"),"Wolf presentation identifies controller and recovery")
	var turns_before:Dictionary=p.choices.duplicate()
	game.choose("deer","approach")
	check(p.choices==turns_before,"Combat cannot be bypassed by a stale choice callback")
	game.free();await frames()
	p.flags.hunt_wolf=true;p.flags.hunt_bear=true;p.choices.hunt_departure="signs";p.choices.hunt_deer="observe"
	await mount(8,Vector2(2344,388))
	check(game.world.has_node("ForestGround") and game.return_marker.visible,"Return remains an exploration stage with companion invitation")
	check(game.near(game.leonor.position),"Companion appears on reachable ground within talking distance")
	game._process(.01)
	check(game.view.guide.target==Vector2(1460,730),"Return guide leads to bridge before pointing across the river")
	game.interact("return");drain()
	check(game.phase=="choice" and game.choices.get_child_count()==2,"Return offers accompanied travel and continued exploration")
	game.choose("return","explore")
	check(game.phase=="explore" and game.state.stage==8 and game.world.player.position.x>2000,"Choosing exploration preserves the full return walk")
	var original:Vector2=game.world.player.position
	game.interact("return");drain();await capture("return-choice");game.choose("return","home")
	check(game.world.player.position==Plan.SPAWN and game.view.body.text.contains("a pedra e o ramo"),"Accompanied return recalls the route and chosen signs")
	check(game.world.point_clear(game.world.player.position) and game.world.point_clear(game.leonor.position),"Accompanied return lands both children on valid terrain")
	check(game.state.stage==8 and p.save_to("user://bond-test.json")==OK,"Return dialogue can save before completion")
	var adult_before:Dictionary={"coins":p.coins,"skills":p.skills.duplicate(),"inventory":p.inventory.duplicate(true),"vitals":p.vitals.duplicate()}
	check(adult_before==personal,"Travel and Leonor preview do not change adult rewards or resources")
	drain()
	check(game.completed and p.flags.get("hunt_completed",false) and p.flags.get("hunt_return_assisted",false),"Accompanied return reaches the same canonical ending")
	check(Bond.promise(p).size()==3 and str(Bond.promise(p)).contains("lobo"),"Promise acknowledges personal victory and the bear contrast")
	game.free();await frames()
	game=load("res://scenes/chapter_01/promise.tscn").instantiate();root.add_child(game);await frames(7)
	check(game.view.body.text.contains("De volta à praça"),"Real promise opens with forest continuity")
	check(game.sequence.events.any(func(row):return row.get("text","")=="Gostava de ficar contigo."),"Approved promise remains intact after the new transition")
	await frames(35)
	var covering:=0
	for prop in game.world.sorted_world.get_children():
		if prop.get_script()==preload("res://scripts/city/lisbon_prop.gd") and (prop.covers(game.world.player.global_position) or prop.covers(game.leonor.global_position)):
			covering+=1;check(prop.occlusion_alpha<.05,"Foreground facade clears both speakers in the intimate shot")
	check(covering>0,"Native promise composition actually exercises foreground occlusion")
	await capture("promise")
	game.free();await frames()
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists("user://bond-test.json"+suffix):DirAccess.remove_absolute("user://bond-test.json"+suffix)
	print("CHILDHOOD_BOND_RESULT ",JSON.stringify({"checks":checks,"failures":failures,"wolf_balance":balance}))
	quit(0 if failures.is_empty() else 1)
