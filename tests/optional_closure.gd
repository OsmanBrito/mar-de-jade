extends SceneTree
const Optional=preload("res://scripts/chapter/optional_arc.gd")
const House=preload("res://scripts/city/house_life.gd")
const Journal=preload("res://scripts/chapter/campaign_journal.gd")
const Errands=preload("res://scripts/chapter/lisbon_errands.gd")
var p
var game
var checks:=0
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
	checks+=1
	if not ok:failures.append(message);push_error(message)
func frames(n:int=4) -> void:
	for i in n:await process_frame
func walk(at:Vector2) -> bool:
	game.world.walk_to(at)
	for i in 2600:
		await physics_frame
		if game.world.player.position.distance_to(at)<12:return true
		if game.world.player.destination_path.is_empty():break
	return false
func read() -> void:
	for i in 30:
		if game.harbor.city.cursor>=game.harbor.city.lines.size():return
		game.harbor.city.advance();await frames(1)
func talk_house(id:String) -> String:
	check(await walk(House.rows(game.world)[id].at),"Actual approach to house service "+id)
	game.routes.interact("house:"+id);await frames()
	check(game.phase=="order_inspection","House service opens by proximity "+id)
	var text:String=game.view.body.text
	game.options_box.get_child(0).pressed.emit();await frames()
	return text
func capture(id:String) -> void:
	if DisplayServer.get_name()=="headless":return
	DirAccess.make_dir_recursive_absolute("res://.qa-runtime/optional-close/captures")
	await frames();await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.qa-runtime/optional-close/captures/"+id+".png")
func run() -> void:
	Engine.time_scale=4;root.size=Vector2i(1440,900)
	p=root.get_node("ChapterProgress");p.auto_save=false;p.reset()
	root.get_node("CampaignProfile").hero_name="Miguel"
	check(Optional.pending(p).is_empty() and Optional.memories(p).is_empty(),"No undiscovered requests or invented forest memories")
	for key in Optional.FOREST:
		for choice in Optional.FOREST[key]:
			p.choices={key:choice}
			check(Optional.memories(p).size()==1 and Journal.notes(p).any(func(row):return row.id=="memory:"+key),"Each chosen forest branch is readable "+key+" "+choice)
	p.choices={"hunt_bridge":"lead","hunt_departure":"signs","hunt_deer":"observe"}
	for id in ["workshop","keeper","fisher"]:
		check(Optional.recall(p,id).size()==2,"Forest memory and relevant resident response "+id)
	p.choices={"hunt_bridge":"invalid","hunt_departure":"invalid","hunt_deer":"invalid"}
	check(Optional.memories(p).is_empty() and Optional.recall(p,"keeper").is_empty(),"Unknown legacy choices do not invent memories")
	p.reset();p.flags={"house_child_done":true,"patient_helped":true,"patient_stable":true,"harbor_pause":true}
	preload("res://scripts/chapter/player_items.gd").pay_service(p)
	p.choices={"hunt_bridge":"trust","hunt_departure":"together","hunt_deer":"approach"}
	game=load("res://scenes/chapter_01/chapter_flow.tscn").instantiate();game.start_block=3;root.add_child(game);await frames(7)
	var inventory:Dictionary=p.inventory.duplicate(true);var coins:int=p.coins
	var text:=await talk_house("steward")
	check(House.review(p,false) and text.contains("não precisas levar outra caneca"),"Completed childhood unlocks an adult inspection variant")
	check(Optional.pending(p)==["A água da casa"],"Pending boarding list includes adult house request only")
	await talk_house("water")
	check(House.stage(p,false)=="carrying" and not game.world.player.presentation.carries_cup,"Adult checks the source without repeating the delivery")
	check(House.objective(p,false).contains("sem voltar ao adro"),"Diary explains completion at recipient")
	check(p.save_to("user://optional-close.json")==OK,"Adult review saves at intermediate step")
	var saved:Dictionary=p.snapshot()
	game.free();await frames();p.reset()
	check(p.load_from("user://optional-close.json")==OK and p.snapshot()==saved,"Adult variant and intermediate observation survive reload")
	game=load("res://scenes/chapter_01/chapter_flow.tscn").instantiate();root.add_child(game);await frames(7)
	var found:=false
	for exit in game.routes.exits:
		if exit.to=="convent":
			check(await walk(exit.point),"Actual doorway reaches infirmary")
			game.routes.interact("exit:convent");await frames();found=game.world.has_meta("order_convent");break
	check(found,"Adult inspection enters the real convent")
	text=await talk_house("ward")
	check(House.stage(p,false)=="done" and text.contains("não precisas repetir")==false,"Recipient completes experienced adult variant")
	check(Optional.pending(p).is_empty(),"Adult variant does not require a confirmation return")
	await talk_house("ward")
	check(p.coins==coins and p.inventory==inventory,"Review and repetition do not duplicate rewards or consume items")
	check(game.routes.state.target==4,"Optional variant preserves the meal objective")
	for exit in game.routes.exits:
		if exit.to=="square":
			check(await walk(exit.point),"Return uses actual convent doorway")
			game.routes.interact("exit:square");await frames();break
	for id in ["workshop","keeper","fisher"]:
		var city=game.harbor.city
		check(await walk(city.approach(id)) and city.interact(id),"Memory conversation requires actual proximity "+id)
		await frames();await read()
		check(city.actions.any(func(row):return row[1]=="forest_memory"),"Known choice exposes relevant recollection "+id)
		var before:Dictionary=p.local_requests.duplicate(true)
		city.choose("forest_memory");await frames()
		check(game.view.speaker.text==root.get_node("CampaignProfile").hero_name and game.view.body.text==Optional.recall(p,id)[0][1],"Protagonist recalls the selected branch "+id)
		game.harbor.city.advance();await frames()
		check(game.view.body.text==Optional.recall(p,id)[1][1],"Resident connects memory to current work "+id)
		check(p.local_requests==before and p.coins==coins,"Memory is narrative and does not solve a request "+id)
		await capture("memory-"+id)
		city.close();await frames()
	game._menu("Pedidos");await frames()
	check(game.player_menu.listing.find_children("*","Button",true,false).any(func(b):return b.text=="Confiar na passagem"),"Adult diary exposes the actual forest memory")
	await capture("journal");game._menu();await frames()
	# Legacy adult deliveries already started are kept as deliveries.
	p.flags.erase("house_adult_review");p.flags.erase("house_adult_done");p.flags.erase("house_adult_delivered");p.flags.house_adult_asked=true;p.flags.house_adult_carrying=true
	check(not House.review(p,false) and House.objective(p,false).contains("Leva a água"),"Started legacy delivery keeps its original objective")
	game.free();await frames();p.reset()
	p.flags={"recovered":true,"packed":true,"patient_helped":true,"patient_stable":true,"harbor_pause":true,"house_adult_asked":true,"house_child_asked":true}
	p.local_requests={"C01-LIS-01":"inspect","C01-LIS-02":"dock","C01-LIS-03":"prepare","C01-LIS-04":"observe"}
	game=load("res://scenes/chapter_01/chapter_flow.tscn").instantiate();game.start_block=15;root.add_child(game);await frames(7)
	var requests:Dictionary=p.local_requests.duplicate(true)
	check(Optional.pending(p).size()==5,"Departure includes all five initiated adult requests")
	check(await load("res://tests/lisbon_walk_driver.gd").new().reach(game,"cais"),"Actual walk reaches the departure quay")
	for exit in game.routes.exits:
		if exit.to=="deck":
			check(await walk(exit.point),"Actual walk reaches the gangplank")
			game.routes.interact("exit:deck");await frames();break
	check(game.phase=="boarding","Physical gangplank opens the departure review")
	check(not p.dialogue_history.is_empty() and p.dialogue_history.back().text==game.view.body.text,"Gangplank dialogue is preserved in the shared transcript")
	for name in Optional.pending(p):check(game.view.body.text.contains(name),"Departure names pending "+name)
	check(game.view.body.text.contains("quando estiveres de novo em Lisboa") and game.options_box.get_child_count()==2,"Departure communicates interruption and preserves free choice")
	check(p.local_requests==requests and House.stage(p,true)=="asked","Boarding review neither fails requests nor completes childhood history")
	await capture("boarding")
	game.options_box.get_child(0).pressed.emit();await frames()
	check(game.phase=="roaming" and game.world.player.enabled,"Declining boarding resumes free exploration")
	check(Journal.requests(p).any(func(r):return r.title.contains("Infância") and r.text.contains("Ficou por concluir")),"Unfinished childhood service is history rather than an adult objective")
	p.completed=true;p.journey={}
	check(Optional.availability(p).contains("atracado em Lisboa"),"Aboard availability names the actual return condition")
	check(Journal.requests(p).filter(func(r):return r.text.contains("Retoma este pedido em terra")).size()==5,"Shared aboard diary marks all five pending adult requests as local to Lisbon")
	p.completed=false
	p.local_requests["C01-LIS-03"]="completed"
	game.harbor.city.update()
	check(game.harbor.city.markers.dock.symbol=="!","Completed kit does not hide an active delivery investigation")
	p.local_requests["C01-LIS-02"]="completed";p.local_requests["C01-LIS-01"]="completed";p.local_requests["C01-LIS-04"]="completed";p.flags.house_adult_done=true
	game.harbor.city.update()
	for id in ["workshop","fisher","dock","keeper"]:check(game.harbor.city.markers[id].symbol=="✓","Completed request has a visible acknowledgement "+id)
	check(Optional.pending(p).is_empty(),"Completed requests leave pending list")
	game.free();await frames()
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists("user://optional-close.json"+suffix):DirAccess.remove_absolute("user://optional-close.json"+suffix)
	print("OPTIONAL_CLOSURE_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
