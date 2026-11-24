extends SceneTree
## Lisbon exterior overview and street stations for the row-house pass.
## Usage: Godot --path . --script res://tools/capture_casario.gd -- <output_dir> [grid]
var game
func _initialize() -> void:
	ProjectSettings.set_setting("application/config/custom_user_dir_name","Mar-de-Jade-QA-Casario")
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir())
	call_deferred("run")
func frames(count: int = 12) -> void:
	for i in count: await process_frame
func shot(dir: String,label: String) -> void:
	await frames(30); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(dir.path_join(label+".png"))
func run() -> void:
	var args := OS.get_cmdline_user_args(); var dir: String = args[0]
	root.size = Vector2i(1440,900)
	var p = root.get_node("ChapterProgress"); p.auto_save = false; p.reset()
	root.get_node("GamePreferences").persist_enabled = false
	root.get_node("CampaignProfile").hero_name = "Miguel"
	p.flags = {"patient_helped":true,"harbor_pause":true}
	game = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate(); game.start_block = 3
	root.add_child(game); await frames()
	if "grid" in args:
		var grid := Node2D.new(); grid.z_index = 60
		var code := GDScript.new()
		code.source_code = "extends Node2D\nfunc _draw():\n\tvar f := ThemeDB.fallback_font\n\tfor x in range(-1400,2001,100):\n\t\tdraw_line(Vector2(x,-800),Vector2(x,1500),Color(1,1,1,0.35 if x%500 else 0.8),2)\n\t\tdraw_string(f,Vector2(x+4,-760),str(x),HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color.YELLOW)\n\tfor y in range(-800,1501,100):\n\t\tdraw_line(Vector2(-1400,y),Vector2(2000,y),Color(1,1,1,0.35 if y%500 else 0.8),2)\n\t\tdraw_string(f,Vector2(-1390,y-4),str(y),HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color.YELLOW)\n"
		code.reload(); grid.set_script(code); game.world.add_child(grid)
	var camera := Camera2D.new(); game.world.add_child(camera)
	camera.position = Vector2(300,330); camera.zoom = Vector2.ONE*0.4; camera.make_current()
	await shot(dir,"overview")
	if "grid" in args: game.free(); quit(); return
	for station in [["rua-alta",Vector2(1130,60)],["bairro",Vector2(1000,300)],["descida",Vector2(700,560)],["ribeira",Vector2(500,880)],["estaleiro",Vector2(-500,800)]]:
		camera.position = station[1]; camera.zoom = Vector2.ONE
		await shot(dir,station[0])
	game.free(); await frames(); print("CASARIO_CAPTURES_COMPLETE"); quit()
