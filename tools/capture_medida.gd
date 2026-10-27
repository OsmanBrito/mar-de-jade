extends SceneTree
const Book=preload("res://scripts/chapter/order_techniques.gd")
var host
func _initialize():
	ProjectSettings.set_setting("application/config/custom_user_dir_name","Jade-QA-Medida")
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir()); call_deferred("run")
func frames(n:=4):
	for i in n: await process_frame
func run():
	DirAccess.make_dir_recursive_absolute("res://.qa-runtime/medida")
	root.content_scale_size=Vector2i(960,540); root.size=Vector2i(1440,810)
	var p=root.get_node("ChapterProgress"); p.auto_save=false; p.reset(); root.get_node("CampaignProfile").hero_name="Miguel"
	root.get_node("GamePreferences").persist_enabled=false
	host=load("res://scripts/combat/battle_host.gd").new(); host.combat=load("res://scripts/combat/campaign_rules.gd").new(); root.add_child(host); await frames()
	var ids: Array=Book.rows().keys().filter(func(id): return not Book.LEGACY.has(id)) if "--all-medida" in OS.get_cmdline_user_args() else ["ES57","PU56","FO57","LA13","MC14"]
	for id in ids:
		p.reset(); p.auto_save=false; p.style=Book.rows()[id].style; p.learn(Book.FIRST[p.style]); p.learn(id)
		p.development.members.hero.active_skills=[id]; p.development.members.hero.practice[id]=20
		host.combat.start_encounter("practice","Miguel",p.style); host.combat.obstacles.clear(); host.combat.current_id=0
		host.combat.units[0].cell=Vector2i(4,3); host.combat.units[0].qi=100;host.combat.units[0].max_qi=100; host.combat.units[0].acted=false
		if id=="FO57": host.combat.low_cover.assign([Vector2i(7,3),Vector2i(6,4)])
		host.combat.units[2].cell=Vector2i(6,3) if id in ["LA12","LA15"] else Vector2i(5,3)
		host.combat.units[1].hp=100;host.combat.units[1].max_hp=100;host.combat.units[1].withdrawn=false;host.combat.units[1].cell=Vector2i(4,4)
		host.tactical.begin();host.active=false;host.tactical.select_skill(Book.action(id))
		host.tactical.selected_cell=host.combat.units[0].cell if host.combat.skill_def(0,Book.action(id)).shape=="self" else host.combat.units[1].cell if id in ["LA13","PU13"] else host.combat.units[2].cell
		host.tactical.cursor_cell=host.tactical.selected_cell;host.tactical.confirmation=true;host.tactical.keys_cursor=true
		host.queue_redraw(); await frames(); await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.qa-runtime/medida/"+id+".png")
		host.tactical.queue_player(1); host.tactical.clock=.58; host.tactical.apply_impact(); host.queue_redraw()
		await frames(); await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.qa-runtime/medida/"+id+"-impacto.png")
		assert(not host.tactical.result.has("error"),id+" animation resolves legal action")
	print("MEDIDA_CAPTURE_OK ",ids.size()); host.active=false;host.free();await frames();quit()
