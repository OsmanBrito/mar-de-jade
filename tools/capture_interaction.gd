extends SceneTree
## Capture the harbor interval with a resident in focus (markers and outline).
## Usage: Godot --path . --script res://tools/capture_interaction.gd -- <output_dir>
var game
func _initialize() -> void: call_deferred("run")
func frames(n: int = 5) -> void:
	for i in n: await process_frame
func run() -> void:
	var dir: String = OS.get_cmdline_user_args()[0]
	root.size = Vector2i(1440,900)
	var p = root.get_node("ChapterProgress"); p.auto_save = false; p.reset()
	root.get_node("CampaignProfile").hero_name = "Miguel"
	p.flags = {"recovered":true,"packed":true,"pack":true,"harbor_pause":true,"leonor_departed":true,"patient_helped":true}
	game = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate(); game.start_block = 15; root.add_child(game); await frames(8)
	var city = game.harbor.city
	game.routes.begin("block",16)
	game.routes.load_area("cais",Vector2(642,980))
	game.routes.install()
	await frames(4)
	game.world.player.position = city.approach("fisher")
	game.world.player.camera.reset_smoothing()
	for i in 30: await physics_frame
	await frames(10); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(dir.path_join("interaction-fisher.png"))
	var fisher = city.residents["fisher"]
	print("PROBE highlighted=",city.markers["fisher"].highlighted," ",fisher.get_class())
	for c in fisher.get_children(): print("PROBE child ",c.name," ",c.get_class()," mat=",c.material if c is CanvasItem else "-")
	game.free(); await frames(); quit()
