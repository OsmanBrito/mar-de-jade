extends SceneTree
var game
var failures: Array[String] = []
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func run() -> void:
	root.get_node("CampaignProfile").hero_name = "Inês"
	var progress = root.get_node("ChapterProgress"); progress.reset(); progress.auto_save = false
	progress.flags.injured = true
	game = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate(); game.start_block = 13; root.add_child(game)
	var driver = load("res://tests/chapter_driver.gd").new()
	var selection := 0
	var styles := ["ES","LA","MC","FO","PU"]
	for i in 1500:
		if not game.busy:
			match game.phase:
				"dialogue": game.advance()
				"task": game.world.player.position = game.props.marker; game.interact_task()
				"styles": game.choose_style(styles[selection]); selection += 1
				"battle": driver.drive(game.battle_host)
				"styles_result":
					check(progress.skills.has(game.battle_host.combat.FIRST[progress.style]),"Style lesson learned "+progress.style)
					if selection < 5: game._show_styles(game.style_options)
					else: game.confirm_style()
				"block_end": break
		if game.busy: await physics_frame
		else: await process_frame
	check(progress.tested_styles.size() == 5,"All five styles can be tested in one visit")
	check(progress.passives.size() == 8,"Eight passives taught with correct owner")
	check(progress.equipped_passives.is_empty() and progress.duarte_equipped_passives.is_empty(),"Learning does not auto-equip passives")
	check(progress.style == "PU" and progress.inventory.has("PT-W05") and not progress.inventory.has("PT-W01"),"Chosen style changes initial weapon without duplicating loan weapons")
	print("CHAPTER_STYLES_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	game.queue_free(); await process_frame; await process_frame
	quit(0 if failures.is_empty() else 1)
