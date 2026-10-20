extends SceneTree
class Preview extends Node2D:
	var time := 0.0
	var Art = preload("res://scripts/combat/portugal_actor_art.gd")
	var Feel = preload("res://scripts/combat/portugal_motion.gd")
	func _draw():
		draw_rect(Rect2(0,0,1200,360),Color("142c32"))
		var actions := [0,1,2,3,8]
		var names := ["Básico","Disparo de Medida","Tiro Preparado","Tiro de Passagem","Guarda do Cano"]
		for i in actions.size():
			var action: int = actions[i]
			var x := 120.0+i*240
			draw_string(ThemeDB.fallback_font,Vector2(x-108,38),names[i],HORIZONTAL_ALIGNMENT_CENTER,216,18,Color("e6cb8d"))
			draw_line(Vector2(x-105,300),Vector2(x+105,300),Color("365858"),1)
			var point := Vector2(x,290)+Feel.firearm_offset(action,time,Vector2.RIGHT,false)*2.6
			var pose: String = Feel.firearm_pose(action)
			var pose_time := time
			if action==3:
				point += Vector2(-36,0)*smoothstep(0.76,1.12,time)
				if time>=0.76: pose = "walk"; pose_time = time-0.76
			var muzzle: Vector2 = Art.draw_actor(self,"hero",point,false,pose,pose_time,"FO",false,0,false,Vector2.RIGHT,2.6)
			if action!=8 and time>=Feel.RELEASE and time<Feel.RELEASE+0.08:
				draw_circle(muzzle,8*(1-(time-Feel.RELEASE)/0.08),Color("ffd58a"))
		draw_string(ThemeDB.fallback_font,Vector2(24,337),"Preparação → disparo → recuperação · mesmo instante de liberação",HORIZONTAL_ALIGNMENT_CENTER,1152,16,Color("adc3bf"))
var preview
func _initialize():
	ProjectSettings.set_setting("application/config/custom_user_dir_name","Mar-de-Jade-QA-firearm-animation-"+str(Time.get_ticks_usec()))
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir())
	call_deferred("run")
func run():
	root.content_scale_size = Vector2i(1200,360)
	root.size = Vector2i(1200,360)
	root.get_node("ChapterProgress").auto_save = false
	root.get_node("GamePreferences").persist_enabled = false
	DirAccess.make_dir_recursive_absolute("res://.qa-runtime/firearm-animation")
	preview = Preview.new(); root.add_child(preview)
	for frame in 36:
		preview.time = frame/24.0
		preview.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.qa-runtime/firearm-animation/%03d.png"%frame)
	print("FIREARM_ANIMATION_CAPTURE_OK: 36 frames, five techniques")
	quit()
