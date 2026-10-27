extends SceneTree
const Layout = preload("res://scripts/city/lisbon_layout.gd")
const Ground = preload("res://scripts/city/lisbon_ground.gd")
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func frames(count: int = 8) -> void:
	for i in count: await process_frame
func run() -> void:
	var p = root.get_node("ChapterProgress"); p.auto_save = false; p.reset()
	var prefs = root.get_node("GamePreferences"); prefs.persist_enabled = false
	root.get_node("CampaignProfile").hero_name = "Miguel"
	p.flags = {"patient_helped":true,"harbor_pause":true}
	var game = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate(); game.start_block = 3
	root.add_child(game); await frames()
	check(game.actors.values().all(func(actor): return not actor.visible),"The completed rescue cast clears the market before the indoor meal")
	var surfaces: Array[PackedVector2Array] = [Layout.paving_surface()]
	surfaces.append_array(Layout.streets())
	# The former western verge at (-750,650) now belongs to a residential
	# frontage and its public court. Sample the remaining verge further uphill.
	for at in [Vector2(-1050,720),Vector2(1810,830),Vector2(-790,510)]:
		check(not Ground.inside(at,surfaces) and not Layout.contains(at),"The blocked verge no longer advertises a paved route: "+str(at))
	for path in [Layout.WEST_STREET,Layout.EAST_STREET]:
		for at in path: check(Ground.inside(at,surfaces) and game.world.point_clear(at),"Public street is both drawn and traversable: "+str(at))
	var merchant = game.harbor.merchant
	game.world.player.position = merchant.approach; await frames()
	check(merchant.highlighted and merchant.name_label.visible,"Nearby merchant identifies the focused interaction")
	for size in [Vector2i(1440,900),Vector2i(960,600)]:
		root.size = size
		for scale in [1.0,1.2]:
			prefs.set_text_scale(scale); await frames(15)
			var view = game.view
			check(view.exploration_back.visible and view.interaction_back.visible,"Objective and action remain separately visible")
			check(view.objective_label.text.contains("refeição") and view.interaction_label.text.contains("comerciante"),"Approaching the shop retains the meal objective")
			var viewport := root.get_visible_rect()
			check(viewport.encloses(view.exploration_back.get_global_rect()) and viewport.encloses(view.interaction_back.get_global_rect()),"HUD fits the window and text scale")
			check(not view.exploration_back.get_global_rect().intersects(view.interaction_back.get_global_rect()),"Interaction does not overlap the objective")
			check(view.exploration_back.get_global_rect().encloses(view.objective_label.get_global_rect()),"Objective text stays within its backing")
			check(view.interaction_back.get_global_rect().encloses(view.interaction_label.get_global_rect()),"Prompt text stays within its backing")
	game.world.player.position = Vector2(-900,570); await frames()
	check(game.view.caption_label.text.contains("Rua da roda"),"Western descent names the current street")
	game.world.player.position = Vector2(-300,300); await frames(30)
	check(game.view.caption_label.text.contains("Praça"),"Returning within the same district refreshes the place name")
	check(not merchant.name_label.visible and merchant.visibility_weight<.05,"Distant merchant does not leave a floating advertisement")
	game._menu("Pedidos"); await frames()
	check(not game.view.exploration_back.is_visible_in_tree() and not game.view.interaction_back.is_visible_in_tree(),"Notebook hides exploration HUD")
	game._menu(); await frames()
	check(game.view.exploration_back.visible,"Closing the notebook restores the current objective")
	game.free(); await frames()
	print("LISBON_DIRECTION_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
