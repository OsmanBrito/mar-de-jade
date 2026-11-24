extends SceneTree
class Gallery extends Node2D:
	var art
	var icons: Array[Texture2D] = []
	func _draw():
		var font := ThemeDB.fallback_font
		draw_rect(Rect2(0,0,1440,900),Color("122c32"))
		draw_string(font,Vector2(40,48),"MAR DE JADE  /  ARMA DE FOGO",HORIZONTAL_ALIGNMENT_LEFT,-1,26,Color("ead8ac"))
		draw_string(font,Vector2(40,79),"Arcabuz de aprendiz · nove poses próprias · quatro técnicas ensinadas por Tomé",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("8db5ae"))
		var poses := ["ready","walk","walk","shoot","shoot","shoot","guard","hurt","kneel"]
		var clocks := [0.0,0.0,0.18,0.1,0.36,0.8,0.0,0.0,0.0]
		var names := ["Pronto","Passo esquerdo","Passo direito","Mira","Recuo do disparo","Recuperação","Guarda do Cano","Impacto recebido","Ajoelhado"]
		for i in 9:
			var point := Vector2(120+(i%5)*285,340+(i/5)*290)
			art.draw_actor(self,"hero",point,false,poses[i],clocks[i],"FO",false,0,false,Vector2.RIGHT,3.0)
			draw_string(font,point+Vector2(-92,35),names[i],HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("eddfbb"))
		var titles := ["Disparo de Medida","Tiro Preparado","Guarda do Cano","Tiro de Passagem"]
		var costs := ["4 alento · alcance 3","6 alento · alcance 4","7 alento · própria","7 alento · alcance 3 + passo"]
		for i in 4:
			var x := 30+i*352
			draw_rect(Rect2(x,714,334,158),Color("1c3c40"))
			draw_texture_rect(icons[i],Rect2(x+16,726,78,78),false)
			draw_string(font,Vector2(x+108,756),titles[i],HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("ead8ac"))
			draw_string(font,Vector2(x+108,786),costs[i],HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("99c6b8"))
			var effects := ["Reduz o bónus de aproximação.","+15% de potência sem movimento.","−30% no primeiro contacto frontal.","Dispara e dá um passo lateral."]
			draw_string(font,Vector2(x+17,842),effects[i],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("eddfbb"))
func _initialize(): call_deferred("run")
func run():
	root.size = Vector2i(1440,900)
	root.get_node("ChapterProgress").auto_save = false
	root.get_node("GamePreferences").persist_enabled = false
	var gallery := Gallery.new(); gallery.art = load("res://scripts/combat/portugal_actor_art.gd")
	for id in ["FO07","FO01","FO08","FO09"]: gallery.icons.append(load("res://assets/art/skills/portugal/"+id+".png"))
	root.add_child(gallery)
	for i in 6: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/arma-de-fogo-arte.png")
	gallery.free(); print("FIREARM_ART_CAPTURE_RESULT: original atlas rendered with live anchors"); quit()
