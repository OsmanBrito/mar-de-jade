extends "res://tools/capture_combat.gd"
## Rendered campaign field states; never writes saves or fabricates overlays in images.
func capture(name: String) -> void:
	game.host.queue_redraw(); await frames(2); await RenderingServer.frame_post_draw
	var directory := "res://docs/" if name in ["caminho-v3","alcance-v3"] else "res://tests/"
	root.get_texture().get_image().save_png(directory+"combate-"+name+".png")
func run() -> void:
	root.get_node("ChapterProgress").auto_save = false
	root.get_node("CampaignProfile").hero_name = "Aprendiz"
	await mount("child_attack")
	var v = game.host.tactical
	v.select_move(); v.select_cell(Vector2i(4,3)); await capture("caminho-v3")
	v.select_cell(Vector2i(3,4)); await capture("obstaculo-v3")
	v.select_cell(Vector2i(7,4)); await capture("custo-v3")
	await mount("school","FO"); v = game.host.tactical
	v.select_skill(0); v.select_cell(game.host.combat.units[2].cell); await capture("alcance-v3")
	await mount("school","LA"); v = game.host.tactical
	# Test-only staging exposes an extra constraint in the actual lance lesson.
	game.host.combat.units[0].cell = Vector2i(4,3); v.refresh_paths()
	v.select_skill(1); v.select_cell(game.host.combat.units[2].cell); await capture("alvo-invalido-v3")
	await mount("school","MC"); v = game.host.tactical
	v.select_skill(1); await capture("preparacao-v3")
	await mount("child_defense"); v = game.host.tactical
	v.start_facing(); v.facing = 0; await capture("orientacao-v3")
	v.confirm(); v.update(1); await capture("golpe-anunciado-v3")
	game.free(); await frames(2); quit()
