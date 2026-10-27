extends SceneTree
var actors: Array=[]
func _initialize():
	ProjectSettings.set_setting("application/config/custom_user_dir_name","Mar-de-Jade-QA-costumes-"+str(Time.get_ticks_usec()))
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir())
	call_deferred("run")
func label(text: String,at: Vector2,size: int,color := Color("e6d8b2")):
	var item:=Label.new();item.text=text;item.position=at;item.add_theme_font_size_override("font_size",size);item.add_theme_color_override("font_color",color);root.add_child(item)
func run():
	root.size=Vector2i(1440,900)
	root.get_node("ChapterProgress").auto_save=false
	root.get_node("GamePreferences").persist_enabled=false
	var backdrop:=ColorRect.new();backdrop.color=Color("172e2c");backdrop.size=Vector2(1440,900);root.add_child(backdrop)
	label("MAR DE JADE · TRAJES DA CASA DA ORDEM",Vector2(65,65),32)
	label("Galeria de arte · sprites usados pelos NPCs no jogo",Vector2(65,115),21,Color("a4b9aa"))
	var titles: Array=["Irmão escrivão","Irmão instrutor","Servidor da casa","Cozinheira"]
	var subtitles: Array=["Hábito, escapulário e livro","Tabardo, malha e espada de treino","Túnica verde e avental de serviço","Coifa, vestido e avental"]
	for i in 4:
		var role: String=["brother","instructor","server","cook"][i]
		var at:=Vector2(220+i*335,570)
		var actor=load("res://scripts/chapter/actor_proxy.gd").new();actor.npc_id="order_"+role;actor.scale=Vector2.ONE*3.2;actor.position=at;root.add_child(actor);actors.append(actor)
		label(titles[i],Vector2(90+i*335,625),25)
		label(subtitles[i],Vector2(65+i*335,675),17,Color("a4b9aa"))
	label("Quatro direções · poses de repouso e caminhada · arte própria da Ordem e dos servidores",Vector2(65,815),20)
	for n in 12:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/ordem-trajes-personagens.png")
	# Every runtime facing and walking index is rendered, including northward work routes.
	for facing in 4:
		for frame in 4:
			for actor in actors:actor.facing=facing;actor.walking=frame>0;actor.frame_time=frame-1;actor.queue_redraw()
			for n in 2:await process_frame
	print("ORDER_COSTUMES_CAPTURE_OK: four costumes and all 64 runtime poses rendered")
	quit()
