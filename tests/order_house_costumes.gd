extends SceneTree
const Art=preload("res://scripts/npcs/lisbon_npc_library.gd")
var checks := 0
var failures: Array[String]=[]
func _initialize():call_deferred("run")
func check(ok: bool,message: String):
	checks+=1
	if not ok:failures.append(message);push_error(message)
func run():
	root.get_node("ChapterProgress").auto_save=false
	root.get_node("GamePreferences").persist_enabled=false
	for role in ["brother","instructor","server","cook","grandmaster"]:
		var id: String="order_"+role
		check(Art.data().has(id),"Dedicated costume exists: "+id)
		if not Art.data().has(id):continue
		var entry: Dictionary=Art.data()[id]
		var image=Image.load_from_file(entry.source)
		check(not image.is_empty() and image.detect_alpha()!=Image.ALPHA_NONE,"Atlas has real transparency: "+id)
		check(entry.frames.size()==16 and entry.pivots.size()==16,"Four facings and four poses indexed: "+id)
		for i in 16:
			var f: Array=entry.frames[i]
			var rect:=Rect2i(f[0],f[1],f[2],f[3])
			check(Rect2i(Vector2i.ZERO,image.get_size()).encloses(rect),"Frame within image: %s/%d"%[id,i])
			check(not image.get_region(rect).is_invisible(),"Frame contains artwork: %s/%d"%[id,i])
		for direction in 4:
			var first: Array=entry.frames[direction*4+1]
			var last: Array=entry.frames[direction*4+3]
			var a=image.get_region(Rect2i(first[0],first[1],first[2],first[3])).get_data()
			var b=image.get_region(Rect2i(last[0],last[1],last[2],last[3])).get_data()
			check(a!=b,"Walking strides have distinct artwork: %s/%d"%[id,direction])
	var map=load("res://scenes/maps/convento_ordem.tscn").instantiate();root.add_child(map)
	for i in 4:await process_frame
	var order_count := 0
	for actor in map.sorted_world.get_children():
		if actor.get("npc_id")!=null and str(actor.npc_id).begins_with("order_"):order_count+=1
	check(order_count==11,"All eleven adult Order-house staff and leaders use dedicated sprites")
	var hub=map.get_node("OrderHouseHub")
	check(hub.workers.size()==3 and hub.workers.all(func(job):return str(job.actor.npc_id).begins_with("order_")),"Three work routines retain the new costumes")
	map.free()
	print("ORDER_HOUSE_COSTUMES_RESULT ",JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
