extends SceneTree
const Access = preload("res://scripts/city/lisbon_access.gd")
const Layout = preload("res://scripts/city/lisbon_layout.gd")
const Portraits = preload("res://scripts/chapter/dialogue_portraits.gd")
const Animals = preload("res://scripts/city/forest_animal.gd")
var checks:=0
var failures: Array[String]=[]
var game
class Preview:
	extends Node2D
	var portraits:=false
	func _draw():
		draw_rect(Rect2(0,0,1440,900),Color("172c2c"))
		var font:=ThemeDB.fallback_font
		if portraits:
			var ids:=["hero_adult","hero_child","duarte","leonor_adult","leonor_child","tome_adult","tome_young","rodrigo","beatriz","master","worker","dock_woman","injured_worker","attendant","observer","family","shelter_child","combatant"]
			for i in ids.size():
				var at:=Vector2(30+(i%6)*235,20+(i/6)*290)
				draw_rect(Rect2(at,Vector2(160,192)),Color("102428"))
				draw_texture_rect(Portraits.portrait(ids[i]),Rect2(at+Vector2(7,8),Vector2(146,176)),false)
				draw_string(font,at+Vector2(0,216),ids[i],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("e4d3ae"))
		else:
			for row in 3:
				var id: String=["wolf","bear","deer"][row]
				for col in 6:
					var at:=Vector2(130+col*225,210+row*320)
					var pose: String=["ready","walk","walk","attack","attack","kneel"][col]
					var time: float=[0,.02,.20,.10,.45,0][col]
					if id=="deer": pose=["ready","ready","inspect","walk","walk","run"][col];time=[0,5,0,.02,.20,.45][col]
					Animals.paint(self,id,at,([62,102,80][row])*2,true,pose,time)
					draw_string(font,at+Vector2(-60,30),id+" · "+pose,HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("e4d3ae"))
func _initialize(): call_deferred("run")
func check(ok: bool,message: String):
	checks+=1
	if not ok: failures.append(message);push_error(message)
func frames(n: int=5):
	for i in n: await process_frame
func capture(name: String):
	if DisplayServer.get_name()=="headless":return
	DirAccess.make_dir_recursive_absolute("res://.qa-runtime/map-art-close/captures")
	await frames(12);await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.qa-runtime/map-art-close/captures/"+name+".png")
func walk(at: Vector2) -> bool:
	game.world.walk_to(at)
	for i in 2600:
		await physics_frame
		if game.world.player.position.distance_to(at)<15:return true
		if game.world.player.destination_path.is_empty():break
	return false
func run():
	root.size=Vector2i(1440,900);Engine.time_scale=3
	var p=root.get_node("ChapterProgress");p.auto_save=false;p.reset()
	root.get_node("CampaignProfile").hero_name="Miguel"
	p.flags={"recovered":true,"patient_helped":true,"packed":true}
	game=load("res://scenes/chapter_01/chapter_flow.tscn").instantiate();game.start_block=3;root.add_child(game);await frames()
	game.routes.begin("block",4)
	game.routes.interact("discovery:site:warehouse")
	check(not Access.observed(p,"warehouse"),"Reading a service door requires physical proximity")
	for id in Access.rows(false):
		var at: Vector2=Access.ROWS[id].at
		check(game.world.point_clear(at),"The real approach to "+id+" is clear")
		check(await walk(at),"Real walking reaches the "+id+" door")
		game.routes.interact("discovery:site:"+id)
		check(game.phase=="order_inspection" and Access.observed(p,id),"The "+id+" door explains its actual access")
		check(root.get_camera_2d()==game.world.player.camera,"Reading the "+id+" door keeps the exploration camera")
		await capture("access-"+id)
		game.routes.resume()
	await capture("workshop-access")
	check(game.routes.goal_area=="convent" and game.events.size()>0,"Door notices do not advance the story")
	var camera: Camera2D=game.world.player.camera
	for resolution in [Vector2i(1024,768),Vector2i(1280,800),Vector2i(1920,1080)]:
		root.size=resolution;await frames()
		for at in [Vector2(-900,700),Vector2(1660,700),Vector2(-485,1185),Vector2(1496,1105)]:
			game.world.player.position=at;camera.reset_smoothing();camera.force_update_scroll();await frames()
			var screen: Vector2=game.world.get_global_transform_with_canvas()*at
			check(root.get_visible_rect().grow(-24).has_point(screen),"The character stays framed at "+str(at)+" in "+str(resolution))
			await capture("edge-"+str(resolution.x)+"-"+str(int(at.x))+"-"+str(int(at.y)))
	root.size=Vector2i(1440,900)
	check(camera.limit_left==int(Layout.VIEW_BOUNDS.position.x) and camera.limit_right==int(Layout.VIEW_BOUNDS.end.x),"Camera limits use the authored district envelope")
	var prop=game.world.sorted_world.get_node("Ferro_house_limestone")
	check(prop.size.x>0 and prop.pixels!=null,"The facade retains its original image and bounds")
	var opaque:=Vector2.ZERO
	for y in range(10,90,10):
		for x in range(10,90,10):
			var candidate: Vector2=prop.global_position+prop.rect.position+prop.rect.size*Vector2(x,y)/100+Vector2(0,45)
			if prop.covers(candidate):opaque=candidate;break
		if opaque!=Vector2.ZERO:break
	game.world.player.position=opaque
	prop.occlusion_alpha=1;prop._process(.016)
	check(prop.occlusion_alpha>.38 and prop.occlusion_alpha<1,"Occlusion fades gradually instead of snapping")
	var clear_corner:=Vector2.ZERO
	for y in range(10,80,10):
		for x in range(10,90,10):
			var candidate: Vector2=prop.global_position+prop.rect.position+prop.rect.size*Vector2(x,y)/100+Vector2(0,45)
			if not prop.covers(candidate):clear_corner=candidate;break
		if clear_corner!=Vector2.ZERO:break
	game.world.player.position=clear_corner;prop.occlusion_alpha=1;prop._process(.016)
	check(clear_corner!=Vector2.ZERO and prop.occlusion_alpha==1,"Transparent artwork corners do not fade the entire building")
	game.world.player.position=Vector2(650,1030);prop._process(1)
	check(prop.occlusion_alpha>.99,"A facade becomes opaque again after passing")
	game.free();await frames()
	p.reset()
	var child=load("res://scenes/chapter_01/plaza.tscn").instantiate();root.add_child(child);await frames()
	for id in Access.rows(true):
		var at: Vector2=Access.ROWS[id].at
		check(child.world.point_clear(at),"The childhood "+id+" notice is reachable")
		child.world.player.position=at;child.roam.interact("site:"+id)
		check(child.phase=="childhood_note" and child.view.body.text==Access.ROWS[id].text,"The childhood boundary has a readable reason")
		child.roam.resume()
	game=child
	check(await walk(preload("res://scripts/city/convent_plan.gd").PORTARIA),"A child can physically reach the functional portaria")
	child.roam.interact("portaria");await frames()
	check(child.roam.inside() and preload("res://scripts/city/convent_plan.gd").DORMITORY.has_point(child.world.player.position),"The childhood portaria opens the dormitory instead of a dead facade")
	var portaria_save: Dictionary=p.snapshot()
	check(p.restore(portaria_save,false)==OK,"The childhood portaria visit produces a valid campaign snapshot")
	child.free();await frames();p.restore(portaria_save)
	child=load("res://scenes/chapter_01/plaza.tscn").instantiate();root.add_child(child);await frames()
	check(child.roam.inside() and preload("res://scripts/city/convent_plan.gd").DORMITORY.has_point(child.world.player.position),"Reload preserves the portaria's interior landing")
	child.roam.leave();await frames()
	check(child.world.player.position.distance_to(Vector2(-690,145))<2,"Leaving returns the child beside the same portaria")
	check(not child.world.is_walkable_point(Vector2(-900,700)) and not child.world.is_walkable_point(Vector2(1660,700)),"Childhood remains inside the original district")
	child.free();await frames()
	for speaker in ["Miguel","Leonor","Tomé","Duarte","Rodrigo","Beatriz","Mestre","Pescadora","Comerciante","Marinheiro do batel","Oficial da oficina","Ajudante da enfermaria"]:
		var id: String=Portraits.identity(speaker,false,"Miguel");var texture=Portraits.portrait(id)
		check(texture!=null and absf(float(texture.get_width())/texture.get_height()-Portraits.ASPECT)<.015,"A consistent bust portrait exists for "+speaker)
	check(Portraits.portrait(Portraits.identity("Narrador",false,"Miguel"))==null,"Narration does not invent a human portrait")
	for id in Animals.data():
		var row: Dictionary=Animals.data()[id]
		check(row.frames.size()==6 and row.reference_height>0,"The "+id+" atlas contains six anchored poses")
		for frame in row.frames:check(frame[2]>0 and frame[3]>0,"The "+id+" pose has a valid crop")
		if id!="deer":
			check(Animals.frame_for(id,"attack",.10)==3 and Animals.frame_for(id,"attack",.45)==4 and Animals.frame_for(id,"kneel",0)==5,"Windup, impact and defeat use distinct "+id+" art")
		else:check(Animals.frame_for(id,"walk",.02)!=Animals.frame_for(id,"walk",.20),"The deer walks with alternate authored strides")
	if DisplayServer.get_name()!="headless":
		var preview=Preview.new();root.add_child(preview);await capture("animal-poses")
		preview.portraits=true;preview.queue_redraw();await capture("portrait-standard")
		preview.free();await frames()
	print("MAP_ART_CLOSURE_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
