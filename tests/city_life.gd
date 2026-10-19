extends SceneTree
const Social=preload("res://scripts/city/city_conversations.gd")
const House=preload("res://scripts/city/house_life.gd")
var checks:=0
var failures:Array[String]=[]
var game
var p
func _initialize() -> void: call_deferred("run")
func frames(n:int=3) -> void:
	for i in n: await process_frame
func check(ok:bool,text:String) -> void:
	checks+=1
	if not ok: failures.append(text);push_error(text)
func walk(at:Vector2) -> bool:
	game.world.walk_to(at)
	for i in 2200:
		await physics_frame
		if game.world.player.position.distance_to(at)<12:return true
		if game.world.player.destination_path.is_empty():break
	return false
func read() -> void:
	for i in 20:
		if game.harbor.city.cursor>=game.harbor.city.lines.size():return
		game.harbor.city.advance();await frames(1)
func run() -> void:
	Engine.time_scale=4;root.size=Vector2i(1440,900)
	p=root.get_node("ChapterProgress");p.auto_save=false;p.reset()
	for id in Social.TITLES:
		check(not Social.introduction(p,id).is_empty(),"First meeting identifies role "+id)
		check(Social.introduction(p,id).is_empty(),"Introduction does not immediately repeat "+id)
	for context in ["accident","rescue","demonstration","departure"]:
		p.flags={"cargo_freed":true} if context=="accident" else {"patient_helped":true} if context=="rescue" else {"city_leonor_demonstrated":true} if context=="demonstration" else {"packed":true}
		check(Social.event(p)==context,"Event context "+context)
		for id in Social.TITLES:
			check(Social.reply(p,id,0)==Social.REACTIONS[context][id],"Resident reacts to "+context+" "+id)
			check(Social.reply(p,id,1)!=Social.reply(p,id,2),"Work conversation varies "+id+" "+context)
	p.journey={"kind":"port_visit"}
	check(Social.event(p)=="return","Return to Lisbon takes precedence over old departure flags")
	check(Social.reply(p,"fisher",0)==Social.REACTIONS["return"].fisher,"Residents acknowledge returning from the ship")
	p.reset();p.flags={"patient_helped":true,"patient_stable":true,"cargo_freed":true,"harbor_pause":true}
	root.get_node("CampaignProfile").hero_name="Inês"
	game=load("res://scenes/chapter_01/chapter_flow.tscn").instantiate();game.start_block=3;root.add_child(game);await frames(8)
	var life=game.world.get_node("CityLife")
	check(life.walkers.size()==2,"Both public errand routes have clear endpoints")
	var origins:Dictionary={}
	for person in life.walkers:origins[person.name]=person.position
	for i in 240:await physics_frame
	for person in life.walkers:
		check(person.distance_walked>20,"Passerby actually walks "+str(person.name))
		check(person.collision_layer==0,"Passerby cannot block story or player "+str(person.name))
	for id in Social.TITLES:
		var city=game.harbor.city
		check(await walk(city.approach(id)),"Walk reaches working resident "+id)
		var actor=city.residents[id]
		var origin:Vector2=actor.position
		var request_state:Dictionary=p.local_requests.duplicate(true)
		var money:int=p.coins
		check(city.interact(id),"Physical conversation opens "+id)
		await frames();await read()
		check(city.actions.any(func(a):return a[1]=="city_life"),"Work conversation offered beside request "+id)
		city.choose("city_life");await frames()
		var first:String=game.view.body.text
		check(first==Social.REACTIONS.rescue[id],"Actual dialogue reacts to rescue "+id)
		await read();city.choose("city_life");await frames()
		check(game.view.body.text!=first,"Immediate repetition changes topic "+id)
		var paused_positions:Dictionary={}
		for person in life.walkers:paused_positions[person.name]=person.position
		for i in 35:await physics_frame
		check(life.walkers.all(func(a):return a.position==paused_positions[a.name] and not a.presentation.walking),"Talking suspends public errands "+id)
		check(actor.position==origin,"Conversation keeps service location "+id)
		check(not (actor.presentation if actor.get("presentation")!=null else actor).walking,"Resident stands to converse "+id)
		check(p.local_requests==request_state and p.coins==money,"Social talk does not accept a request or grant reward "+id)
		if DisplayServer.get_name()!="headless" and id in ["workshop","fisher"]:
			DirAccess.make_dir_recursive_absolute("res://.qa-runtime/city-life-close/captures")
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://.qa-runtime/city-life-close/captures/"+id+".png")
		city.close();await frames()
		check(game.world.player.enabled and game.phase=="roaming","Conversation resumes exploration "+id)
	var city=game.harbor.city
	for context in ["demonstration","departure"]:
		p.flags["city_leonor_demonstrated" if context=="demonstration" else "packed"]=true
		check(city.interact("keeper"),"Known resident opens after event "+context)
		await read();city.choose("city_life");await frames()
		check(game.view.body.text==Social.REACTIONS[context].keeper,"Event change gives a fresh actual reaction "+context)
		city.close();await frames()
	p.flags.erase("city_leonor_demonstrated");p.flags.erase("packed")
	life.elapsed=0;await frames()
	check(city.residents.workshop.presentation.posture=="crouched","Official resumes inspecting the axle after conversation")
	check(city.residents.neighbor.presentation.carries_bowl or city.residents.neighbor.presentation.carries_cup,"Kitchen work visibly resumes after conversation")
	var clock:float=life.elapsed
	game._lock_player(true);await frames(20)
	check(life.elapsed==clock,"Work clock pauses during locked staging")
	game._lock_player(false);await frames()
	check(life.elapsed>clock,"Work clock resumes after staging")
	check(p.save_to("user://city-life-close.json")==OK and p.load_from("user://city-life-close.json")==OK,"Introductions and journey remain valid across save/load")
	var remembered:Dictionary=p.flags.duplicate()
	game.free();await frames()
	game=load("res://scenes/chapter_01/chapter_flow.tscn").instantiate();root.add_child(game);await frames(7)
	check(p.flags==remembered,"Reload does not reset first meetings or replay conversations")
	var current_life=game.world.get_node("CityLife")
	check(current_life.walkers.size()==2,"Reload installs exactly one pair of errand actors")
	var before_flags:Dictionary=p.flags.duplicate()
	p.flags.erase("patient_helped");p.flags.erase("patient_stable");p.flags.cargo_freed=true
	var alarm:Dictionary=House.talk(game.world,p,"porter")
	check(alarm.text.contains("agitação no cais"),"Porter reacts while accident is still unresolved")
	p.flags=before_flags
	var previous_journey:Dictionary=p.journey.duplicate(true)
	p.journey={"kind":"port_visit"}
	var welcome:Dictionary=House.talk(game.world,p,"porter")
	check(welcome.text.contains("Bem-vindo de volta"),"Porter welcomes a return instead of repeating departure")
	p.journey=previous_journey
	check(Social.introduction(p,"fisher").is_empty(),"Known resident does not introduce herself after reload")
	game.free();await frames();p.reset()
	game=load("res://scenes/chapter_01/plaza.tscn").instantiate();root.add_child(game);await frames(6)
	life=game.world.get_node("CityLife")
	for node in life.PEOPLE.values():check(not game.world.sorted_world.get_node(node).visible,"Adult workplace absent from childhood "+node)
	check(life.walkers.filter(func(a):return a.visible).size()==1,"Childhood keeps forecourt life without adult cargo errand")
	var first:Dictionary=House.talk(game.world,p,"porter")
	var again:Dictionary=House.talk(game.world,p,"porter")
	check(first.text!=again.text and again.text.contains("Leonor"),"Child porter varies repeated directions without losing destination")
	var before:Dictionary=p.snapshot()
	check(before.flags.size()<100,"City memory stays within existing save schema")
	game.free();await frames()
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists("user://city-life-close.json"+suffix):DirAccess.remove_absolute("user://city-life-close.json"+suffix)
	print("CITY_LIFE_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
