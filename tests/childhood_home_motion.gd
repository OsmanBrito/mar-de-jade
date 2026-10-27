extends SceneTree
var failures:Array[String]=[]
var checks:=0
var game

func _initialize() -> void:call_deferred("run")
func check(value:bool,message:String) -> void:
	checks+=1
	if not value:failures.append(message);push_error(message)
func frames(n:int=3) -> void:
	for i in n:await process_frame
func boot_bottom(image:Image,left:bool) -> int:
	var bottom:=-1
	for y in range(65,96):
		# Exclude the centre seam where an overlapping boot crosses the body axis.
		for x in range(24,44) if left else range(52,72):
			if image.get_pixel(x,y).a>.5:bottom=maxi(bottom,y)
	return bottom
func run() -> void:
	root.get_node("ChapterProgress").auto_save=false
	root.get_node("ChapterProgress").reset()
	root.get_node("CampaignProfile").hero_name="Miguel"
	change_scene_to_file("res://scenes/chapter_01/childhood_home.tscn")
	await frames(8);game=current_scene
	for i in 3:game.advance()
	# Inspect real exported triangles, not just the builder's intended heights.
	var foundation_top:=-INF
	var paving_top:=-INF
	var building:Node3D=game.world.get_child(0)
	for node in building.find_children("*","MeshInstance3D",true,false):
		for surface in node.mesh.get_surface_count():
			var arrays:Array=node.mesh.surface_get_arrays(surface)
			var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
			for i in range(0,indices.size(),3):
				var a:Vector3=node.to_global(vertices[indices[i]])
				var b:Vector3=node.to_global(vertices[indices[i+1]])
				var c:Vector3=node.to_global(vertices[indices[i+2]])
				if absf(a.y-b.y)>.0001 or absf(a.y-c.y)>.0001:continue
				var area:float=(b-a).cross(c-a).length()*.5
				if area>200:foundation_top=maxf(foundation_top,a.y)
				elif area>.12 and area<.16 and a.y<.01:paving_top=maxf(paving_top,a.y)
	check(is_finite(foundation_top) and is_finite(paving_top),"Export contains both the foundation and actual paving faces")
	check(paving_top-foundation_top>=.08,"Foundation cannot compete with paving in the depth buffer")
	# Inspect the actual boot silhouettes, not only changing animation metadata.
	for facing in [0,2]:
		var lift:Array[int]=[]
		for phase in 8:
			game.world.set_frame(game.world.sprites.hero_child,facing,phase+1)
			var image:Image=game.world.sprites.hero_child.texture.get_image()
			if game.world.sprites.hero_child.flip_h:image.flip_x()
			lift.append(boot_bottom(image,true)-boot_bottom(image,false))
		check(lift.min()<=-8 and lift.max()>=8,"Both boots visibly lift on alternating halves of vertical stride: "+str(facing)+" "+str(lift))
		check(is_equal_approx(game.world.sprites.hero_child.pixel_size,1.15/96.0),"All vertical poses retain a shared scale")
	var start:=Vector3(-7.2,0,9)
	game.world.player.position=start;game.world.stop()
	check(game.world.walk_to(Vector2(-7.2,6.5)),"Straight walk is accepted")
	var idle_ticks:=0;var samples:=0;var last:Vector3=game.world.player.position
	var seen:Dictionary={}
	for i in 200:
		await physics_frame
		var now:Vector3=game.world.player.position
		var distance:float=Vector2(now.x-last.x,now.z-last.z).length()
		if i>1 and game.world.point().distance_to(Vector2(-7.2,6.5))>.2:
			if distance<.001:idle_ticks+=1
			samples+=1;seen[int(game.world.sprites.hero_child.get_meta("frame"))]=true
		last=now
		if game.world.destination_path.is_empty():break
	check(samples>15,"Walk samples cover a full stride")
	check(idle_ticks==0,"Click walking never idles at intermediate navigation points")
	check(seen.size()==8,"Continuous upward walking advances all eight stride phases")
	check(game.world.point().distance_to(Vector2(-7.2,6.5))<.1,"Walk finishes at the requested destination")
	check(absf(game.world.player.position.y-game.world.floor_height(game.world.point()))<.0001,"Feet rest on the raised wooden floor rather than intersecting it")
	game.world.stop();await frames(5)
	check(game.world.last_facing==2 and int(game.world.sprites.hero_child.get_meta("frame"))==8,"Stopping retains the walking direction and uses its idle pose")
	check(game.world.walk_to(Vector2(-7.2,9)),"Downward return walk is accepted")
	var down_seen:Dictionary={}
	for i in 200:
		await physics_frame
		if game.world.last_facing==0:down_seen[int(game.world.sprites.hero_child.get_meta("frame"))]=true
		if game.world.destination_path.is_empty():break
	check(down_seen.has_all([100,101,102,103,104,105,106,107]),"Downward walking also visits all eight phases")
	game.world.stop()
	var stopped:Vector3=game.world.player.position;await frames(10)
	check(game.world.player.position.distance_to(stopped)<.0001,"Idle character remains stationary")
	game.world.player.position=Vector3(-8.4,0,3.3);game.world.stop();await frames(2)
	check(game.world.player_visual.global_position.distance_to(game.world.player.global_position)<.001,"Resuming or repositioning never leaves an interpolated ghost behind")
	print("CHILDHOOD_HOME_MOTION_RESULT ",JSON.stringify({"checks":checks,"failures":failures,"idle_ticks":idle_ticks,"samples":samples,"poses":seen.keys(),"foundation_top":foundation_top,"paving_top":paving_top}))
	quit(0 if failures.is_empty() else 1)
