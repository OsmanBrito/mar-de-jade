extends SceneTree
class Gallery extends Node2D:
	var rows: Array=[]
	var icons: Dictionary={}
	func _draw():
		draw_rect(Rect2(0,0,1280,830),Color("102a2e"))
		var font: Font=ThemeDB.fallback_font
		draw_string(font,Vector2(28,34),"MAR DE JADE · TRADIÇÃO DA MEDIDA",HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("e6cb8d"))
		draw_string(font,Vector2(28,57),"65 técnicas · ícones próprios · mesma identidade nos graus I–III",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("b4c7bd"))
		var style_names: Array=["ESPADA","LANÇA","MACHADO","DESARMADO","FOGO"]
		for row in 5:
			var y:=86.0+row*142
			draw_string(font,Vector2(18,y+43),style_names[row],HORIZONTAL_ALIGNMENT_LEFT,112,16,Color("e6cb8d"))
			draw_line(Vector2(18,y+111),Vector2(1260,y+111),Color("315356"),1)
			for column in 13:
				var entry: Dictionary=rows[row*13+column]
				var x:=137.0+column*86
				draw_texture_rect(icons[entry.id],Rect2(x,y,72,72),false)
				draw_string(font,Vector2(x,y+91),entry.id,HORIZONTAL_ALIGNMENT_CENTER,72,14,Color("e8dfc8"))
		draw_string(font,Vector2(28,812),"44 ícones novos + 21 artes próprias preservadas · geração integrada ao projeto",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("a3bab0"))
func _initialize():
	ProjectSettings.set_setting("application/config/custom_user_dir_name","Jade-QA-Icon-Gallery")
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir());call_deferred("run")
func run():
	root.get_node("ChapterProgress").auto_save=false;root.content_scale_size=Vector2i(1280,830);root.size=Vector2i(1280,830)
	var view:=Gallery.new();view.rows=JSON.parse_string(FileAccess.get_file_as_string("res://data/order_techniques.json")).techniques
	var icons: Dictionary={}
	for row in JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_01/skill_icons.json")).skills:icons[row.id]=row.icon
	for row in view.rows:view.icons[row.id]=load(icons[row.id])
	root.add_child(view)
	for i in 5:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/medida-icones.png")
	print("MEDIDA_ICON_GALLERY_OK");quit()
