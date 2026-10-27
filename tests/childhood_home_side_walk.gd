extends SceneTree
var checks:=0
var failures:Array[String]=[]
var game
func _initialize() -> void:call_deferred("run")
func check(value:bool,message:String) -> void:
	checks+=1
	if not value:failures.append(message);push_error(message)
func frames(n:int=4) -> void:
	for i in n:await process_frame
func boot_span(image:Image) -> int:
	var left:=96;var right:=-1
	for y in range(74,96):
		for x in 96:
			if image.get_pixel(x,y).a>.5:left=mini(left,x);right=maxi(right,x)
	return right-left+1
func head_center(image:Image) -> float:
	var sum:=0.0;var count:=0
	for y in 24:
		for x in 96:
			if image.get_pixel(x,y).a>.5:sum+=x;count+=1
	return sum/maxi(1,count)
func run() -> void:
	var p=root.get_node("ChapterProgress");p.auto_save=false;p.reset();p.flags.home_welcome=true;p.flags.home_meal=true;p.flags.home_bowl=true
	root.get_node("CampaignProfile").hero_name="Miguel"
	change_scene_to_file("res://scenes/chapter_01/childhood_home.tscn");await frames(8);game=current_scene
	for facing in [1,3]:
		var spans:Array[int]=[];var heads:Array[float]=[];var boots:Dictionary={}
		for phase in 8:
			game.world.set_frame(game.world.sprites.hero_child,facing,phase+1)
			var image:Image=game.world.sprites.hero_child.texture.get_image()
			if game.world.sprites.hero_child.flip_h:image.flip_x()
			spans.append(boot_span(image));heads.append(head_center(image))
			boots[image.get_region(Rect2i(0,68,96,28)).get_data().hex_encode().hash()]=true
			check(game.world.sprites.hero_child.flip_h==(facing==1),"Every phase faces the direction of travel: "+str(facing)+"/"+str(phase))
		check(spans.max()-spans.min()>=16,"Boot silhouettes visibly change between contact and bent-knee passing: "+str(facing)+" "+str(spans))
		check(boots.size()>=6,"Lateral cycle contains distinct leg poses rather than repeated idle artwork")
		check(heads.max()-heads.min()<1.5,"Head stays anchored horizontally while legs and arms swing")
		check(is_equal_approx(game.world.sprites.hero_child.pixel_size,1.15/96.0),"Side and vertical walking share the same character scale")
	game.world.player.position=Vector3(-4.5,0,3.25);game.world.stop()
	for target in [Vector2(4.5,3.25),Vector2(-4.5,3.25)]:
		var facing:=3 if target.x>0 else 1
		check(game.world.walk_to(target),"Horizontal walking route is clear")
		var seen:Dictionary={};var idle:=0;var previous:Vector2=game.world.point()
		for i in 400:
			await physics_frame
			var now:Vector2=game.world.point()
			if i>1 and now.distance_to(target)>.2:
				if now.distance_to(previous)<.001:idle+=1
				seen[int(game.world.sprites.hero_child.get_meta("frame"))]=true
			previous=now
			if game.world.destination_path.is_empty():break
		check(game.world.point().distance_to(target)<.1,"Side walk arrives at its destination")
		check(seen.size()==8,"Real horizontal movement visits all eight phases")
		check(idle==0,"Horizontal click walking never pauses between waypoints")
		game.world.stop();await frames()
		check(game.world.last_facing==facing and int(game.world.sprites.hero_child.get_meta("frame"))==facing*4,"Stopping returns to the correct side idle")
	print("CHILDHOOD_HOME_SIDE_WALK_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
