extends "res://tests/medida_catalogue.gd"
func _initialize():
	ProjectSettings.set_setting("application/config/custom_user_dir_name","Jade-QA-Medida-Motion")
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir());call_deferred("run")
func frames(n:=2):
	for i in n: await process_frame
func run():
	Rules=load("res://scripts/combat/campaign_rules.gd");p=root.get_node("ChapterProgress");p.auto_save=false
	root.get_node("GamePreferences").persist_enabled=false;root.get_node("CampaignProfile").hero_name="Miguel"
	root.content_scale_size=Vector2i(960,540);root.size=Vector2i(960,540)
	DirAccess.make_dir_recursive_absolute("res://.qa-runtime/medida-motion")
	var index:=0
	for id in ["ES08","PU15","LA13"]:
		var c=fixture(id,1)
		if id=="PU15": c.units[2].cell=Vector2i(6,3)
		c.caption=Book.rows()[id].name;c.units[1].kind="duarte";c.units[1].name="Duarte"
		var host=load("res://scripts/combat/battle_host.gd").new();host.combat=c;root.add_child(host);host.tactical.begin();host.active=false
		host.tactical.selected_skill=Book.action(id);host.tactical.selected_cell=c.units[1].cell if id=="LA13" else c.units[2].cell
		host.tactical.queue_player(1)
		var hit:=false
		for frame in 26:
			host.tactical.clock=frame/20.0
			if not hit and host.tactical.clock>=.45: host.tactical.apply_impact();hit=true
			host.queue_redraw();await frames();await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://.qa-runtime/medida-motion/%03d.png"%index);index+=1
		host.free();await frames()
	print("MEDIDA_MOTION_CAPTURE_OK ",index);quit()
