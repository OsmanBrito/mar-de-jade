extends SceneTree
const Arc=preload("res://scripts/chapter/adult_arc.gd")
const Objectives=preload("res://scripts/chapter/chapter_objectives.gd")
const Journal=preload("res://scripts/chapter/campaign_journal.gd")
var checks:=0
var failures:Array[String]=[]
var p
var game
var shots:Dictionary={}
func _initialize() -> void:call_deferred("run")
func check(ok:bool,text:String) -> void:
	checks+=1
	if not ok:failures.append(text);push_error(text)
func frames(n:int=4) -> void:
	for i in n:await process_frame
func capture(id:String) -> void:
	if DisplayServer.get_name()=="headless" or shots.has(id):return
	shots[id]=true;DirAccess.make_dir_recursive_absolute("res://.qa-runtime/adult-arc-close/captures")
	await frames();await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.qa-runtime/adult-arc-close/captures/"+id+".png")
func idle() -> void:
	for i in 1800:
		if not game.busy:return
		if is_instance_valid(game.staging) and game.staging.beat=="perception_without_healing":await capture("perception")
		await physics_frame
	check(false,"Adult scene finishes its choreography")
func task() -> void:
	for i in 50:
		await idle()
		if game.phase=="task":return
		game.advance();await frames(1)
	check(false,"Adult scene reaches a playable task")
func walk(at:Vector2) -> bool:
	for offset in [Vector2.ZERO,Vector2(-40,25),Vector2(40,25)]:
		if not game.world.point_clear(at+offset):continue
		game.world.walk_to(at+offset)
		for i in 1600:
			await physics_frame
			if game.world.player.position.distance_to(at)<68:return true
			if game.world.player.destination_path.is_empty():break
	return false
func run() -> void:
	Engine.time_scale=3;root.size=Vector2i(1440,900)
	p=root.get_node("ChapterProgress");p.auto_save=false;p.reset();root.get_node("CampaignProfile").hero_name="Miguel"
	check(Arc.notes(p).is_empty(),"No future adult events in a new campaign")
	for id in ["lever","meal","recovery_walk","blue_rope"]:
		var fake:Dictionary={"routes":null,"completed":false,"phase":"task","task_id":id,"task_step":0,"current_event":{"caption":"stale instruction"}}
		var before:String=Objectives.current(fake);fake.task_step=1
		check(before!=Objectives.current(fake) and not Objectives.current(fake).contains("stale"),"Objective follows the current physical substep "+id)
	check(Arc.task("recovery_water",0).contains("não encerra"),"Water is distinguished from recovery")
	p.flags={"duel_lost":true}
	check(Arc.notes(p).size()==1 and not str(Arc.notes(p)).contains("Dez anos"),"Defeat does not reveal the later promise or aid")
	p.flags={"green_sight":true}
	check(Arc.notes(p).size()==1 and Arc.notes(p)[0].text.contains("nem curaste"),"Perception does not claim healing or completed treatment")
	p.flags={}
	game=load("res://scenes/chapter_01/chapter_flow.tscn").instantiate();game.start_block=1;root.add_child(game);await frames(6);await task()
	check(game.task_id=="lever" and game.task_step==0,"Rescue begins with the support rather than a single automatic lift")
	var health:Dictionary=p.vitals.duplicate()
	check(await walk(game.props.marker),"Player physically approaches the lever")
	game.interact_task();await idle()
	check(game.task_step==1 and not p.flags.get("cargo_freed",false),"Support and joint lift remain two separate actions")
	check(Objectives.current(game).contains("elevação conjunta"),"Journal asks for joint lift after support")
	check(await walk(game.props.marker),"Player approaches Duarte for the joint lift")
	game.interact_task();await idle()
	check(p.flags.get("cargo_freed",false) and p.flags.get("green_sight",false),"Joint lift precedes the perceived injury")
	check(not p.flags.get("patient_stable",false) and p.vitals==health,"Perception grants no treatment flag or healing")
	check(Arc.notes(p).any(func(row):return row.id=="story:perception") and not Arc.notes(p).any(func(row):return row.id=="story:care"),"Diary separates perception from later ordinary care")
	game._load_block(2);await frames();await idle()
	check(p.flags.get("patient_stable",false) and game.actors["Trabalhador ferido"].injured,"Ordinary care stabilizes the patient without erasing the injury")
	check(game.actors["Trabalhador ferido"].has_node("OrdinaryDressing"),"Tomé visibly applies the existing cloth art")
	await capture("ordinary-care")
	game._load_block(3);await frames();game._stage("patient_departure")
	var supported:=false
	for i in 900:
		if game.actors.Familiar.visible and game.actors.Familiar.walking and game.actors["Trabalhador ferido"].walking:
			supported=true;await capture("family-support")
		if p.flags.get("patient_helped",false):break
		await physics_frame
	check(supported,"Family actually walks beside the injured worker")
	check(p.flags.get("patient_helped",false) and not game.actors.Familiar.visible and not game.actors["Trabalhador ferido"].visible,"Both leave before the social aftermath")
	game._load_block(6);await frames();await idle()
	check(game.view.caption_label.text.contains("Demonstração pública") and game.staging.audience.size()==6,"Public scene identifies its context and audience")
	for i in 20:
		if game.busy:break
		game.advance();await frames(1)
	await idle()
	check(p.flags.get("city_leonor_demonstrated",false) and Arc.notes(p).any(func(row):return row.id=="story:public"),"Watching the whole demonstration unlocks only its own diary note")
	await capture("public-aftermath")
	game._load_block(7);await frames();await idle();await frames(30)
	check(game.view.caption_label.text.contains("Avaliação reservada") and not game.world.sorted_world.has_node("PublicAudience"),"Private evaluation changes context without inheriting the public audience")
	check(game.view.portrait_id=="leonor_adult","Private dialogue uses adult Leonor identity")
	check(game.world.player.position.distance_to(Vector2(23,367))<2 and game.world.player.position.distance_to(game.world.sorted_world.get_node("Bench").position)<60,"Direct loading preserves the authored seated position instead of leaving the hero beside an empty bench")
	var covering:=0
	for prop in game.world.sorted_world.get_children():
		if prop.get_script()==preload("res://scripts/city/lisbon_prop.gd") and (prop.covers(game.world.player.global_position) or prop.covers(game.actors.Leonor.global_position)):
			covering+=1;check(prop.occlusion_alpha<.05,"Adult bench shot clears the foreground facade")
	check(covering>0,"Native adult private shot exercises facade visibility")
	await capture("private-bench")
	game._load_block(8);await frames()
	check(game.phase=="battle" and game.battle_host.note.contains("Avaliação reservada"),"Actual duel identifies the controlled evaluation")
	game.battle_host.combat.units[0].hp=0;game.battle_host.check_outcome()
	check(game.battle_host.ending.title=="LEONOR VENCEU" and game.battle_host.ending.detail.contains("recuperação"),"Defeat ending announces story continuation and care")
	for i in 600:
		if game.phase!="battle":break
		await physics_frame
	await idle()
	check(game.scene_index==9 and p.flags.get("duel_lost",false) and p.flags.get("injured",false),"Defeat hands off to the next canonical scene rather than a retry")
	check(not Arc.notes(p).any(func(row):return row.id in ["story:promise","story:help"]),"Aftermath events are not recorded before being witnessed")
	check(p.save_to("user://adult-arc.json")==OK and p.load_from("user://adult-arc.json")==OK,"Known-event diary survives existing save schema")
	game._menu("Pedidos");await frames()
	check(game.player_menu.listing.find_children("*","Button",true,false).any(func(b):return b.text=="A avaliação terminou"),"Adult diary exposes witnessed event for rereading")
	await capture("story-journal");game._menu()
	var aboard:Dictionary=p.snapshot();aboard.flags.packed=true
	check(Arc.notes(aboard).filter(func(row):return row.id=="story:mission")[0].text.contains("Falta apresentar-te"),"Preparation preserves the condition of captain acceptance")
	aboard.completed=true
	var mission:String=Arc.notes(aboard).filter(func(row):return row.id=="story:mission")[0].text
	check(mission.contains("sob Rodrigo") and mission.contains("Madeira") and mission.contains("Duas Águas"),"Departure links apprenticeship, first stop and mission")
	check(Journal.notes(aboard).any(func(row):return row.id=="story:mission"),"Aboard journal retains witnessed story context")
	check(game.blocks.all(func(block):return not block.events.any(func(event):return event.get("mode","") in ["adult_attack","adult_defense"])),"No mandatory Duarte training is reintroduced")
	game.free();await frames()
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists("user://adult-arc.json"+suffix):DirAccess.remove_absolute("user://adult-arc.json"+suffix)
	print("ADULT_ARC_CLOSURE_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
