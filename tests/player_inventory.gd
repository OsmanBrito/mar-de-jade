extends SceneTree
const Items = preload("res://scripts/chapter/player_items.gd")
var failures: Array[String] = []
var checks := 0
var game
var p
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func frames(n: int = 2) -> void:
	for i in n: await process_frame
func fixture(data: Dictionary) -> void:
	FileAccess.open("res://tests/player-state.json",FileAccess.WRITE).store_string(JSON.stringify(data))
func press_key(code: int) -> void:
	var event := InputEventKey.new(); event.physical_keycode = code; event.keycode = code; event.pressed = true; root.push_input(event)
	await frames(); event.pressed = false; root.push_input(event); await frames()
func press_pad(code: int) -> void:
	var event := InputEventJoypadButton.new(); event.button_index = code; event.pressed = true; root.push_input(event)
	await frames(); event.pressed = false; root.push_input(event); await frames()
func run() -> void:
	p = root.get_node("ChapterProgress"); p.auto_save = false; p.reset()
	root.get_node("CampaignProfile").hero_name = "Joana"
	check(Items.items().size() == 18 and p.coins == 0 and p.inventory == {"PT-Q01":1},"New campaign has only its story bag and no free gear")
	Items.pay_service(p); Items.pay_service(p)
	check(p.coins == 40 and p.payments.size() == 1,"Cais service payment cannot be farmed")
	Items.buy(p,"PT-V01")
	check(p.coins == 16 and p.inventory["PT-V01"] == 1 and p.shop_stock["PT-V01"] == 1,"Purchase transfers currency, quantity and stock")
	var before: Dictionary = p.snapshot()
	Items.buy(p,"PT-W04")
	check(p.snapshot() == before,"Unaffordable purchase is atomic")
	check(not Items.equip_reason(p,"PT-V01").is_empty(),"Gear cannot bypass Tomé's recovery")
	p.flags.recovered = true
	Items.equip(p,"PT-V01")
	check(p.equipment.outfit == "PT-V01" and Items.stats(p).hp == 112 and Items.stats(p).defense == 2,"Outfit bonuses aggregate")
	check(p.vitals.hp == 100,"Equipping extra maximum HP does not heal")
	check(not Items.sell_reason(p,"PT-V01").is_empty(),"Last equipped copy cannot be sold")
	Items.unequip(p,"outfit"); Items.sell(p,"PT-V01")
	check(p.coins == 28 and p.shop_stock["PT-V01"] == 2 and p.inventory["PT-V01"] == 0,"Sale returns half price and replenishes stock")
	before = p.snapshot(); Items.sell(p,"PT-Q01"); Items.buy(p,"PT-Q02"); Items.sell(p,"PT-T01")
	check(p.snapshot() == before,"Story objects and service tools cannot be traded")
	p.coins = 200
	Items.buy(p,"PT-W02")
	check(not Items.equip_reason(p,"PT-W02").is_empty(),"Buying an unfamiliar weapon does not teach a style")
	p.tested_styles.assign(["ES","LA","PU"]); Items.equip(p,"PT-W02")
	check(p.style == "LA" and p.equipment.weapon == "PT-W02","Known weapon changes active maneuver")
	Items.unequip(p,"weapon")
	check(p.style == "PU" and not p.equipment.has("weapon"),"Unarmed works without mandatory wraps")
	Items.buy(p,"PT-C01"); p.vitals.hp = 60; Items.use(p,"PT-C01")
	check(p.vitals.hp == 85 and p.inventory["PT-C01"] == 0,"Bandages restore real out-of-combat HP")
	Items.buy(p,"PT-C03"); p.vitals.qi = 18; Items.use(p,"PT-C03")
	check(p.vitals.qi == 20 and p.inventory["PT-C03"] == 0,"Water clamps to maximum energy")
	Items.buy(p,"PT-C03"); before = p.snapshot(); Items.use(p,"PT-C03")
	check(p.snapshot() == before,"Full resources never waste a supply")
	p.flags.injured = true; before = p.snapshot(); Items.use(p,"PT-C03")
	check(p.snapshot() == before,"Supplies never remove narrative injury")
	p.flags.injured = false; p.vitals.qi = 8
	Items.buy(p,"PT-V01"); Items.equip(p,"PT-V01"); Items.equip(p,"PT-W02")
	var rules = load("res://scripts/combat/campaign_rules.gd").new(); rules.start_encounter("school","Joana","LA")
	check(rules.units[0].max_hp == 112 and rules.units[0].hp == 85 and rules.units[0].defense == 2,"Live battle reads equipped stats and current health")
	check(rules.skill_def(0,0).power == 22,"Weapon bonus reaches actual basic attack")
	check(rules.skill_def(0,1).power == 20,"Weapon bonus reaches actual technique")
	var attack: Dictionary = {"kind":"attack","power":30,"posture":5,"cells":[rules.units[0].cell],"target":0,"targets":[0],"no_counter":true}
	var damage: int = rules.defense_preview(2,0,attack,0).damage
	var life: int = rules.units[0].hp; rules.end_turn(0); rules.resolve_enemy(attack,{0:0})
	check(life-int(rules.units[0].hp) == damage,"Equipped protection prediction matches actual HP loss")
	rules.start_encounter("school","Joana","FO")
	check(rules.skill_def(0,0).power == 20,"Borrowed style trial cannot use another weapon bonus")
	rules.start_encounter("duel","Joana","LA")
	check(rules.units[0].hp == 90 and rules.units[2].hp == 4000,"Early scripted narrative encounter retains its real power gap")
	p.checkpoint = 14; p.entry_scene = "res://scenes/chapter_01/chapter_flow.tscn"
	before = p.snapshot(); check(p.save_to("res://tests/player-state.json") == OK,"Economy save writes atomically")
	p.reset(); check(p.load_from("res://tests/player-state.json") == OK and p.snapshot() == before,"Coins, equipment, stock and vitals round-trip")
	for patch in [{"coins":-1},{"coins":1.5},{"equipment":{"feet":"PT-W02"}},{"equipment":{"weapon":"PT-W04"}},{"shop_stock":{"PT-Q01":2}},{"vitals":{"hp":-1,"qi":2,"posture":2}},{"vitals":{"hp":900,"qi":2,"posture":2}},{"payments":["cais_service","cais_service"]}]:
		var invalid := before.duplicate(true); invalid.merge(patch,true); fixture(invalid)
		check(p.load_from("res://tests/player-state.json") == ERR_INVALID_DATA and p.snapshot() == before,"Invalid economy rejected without mutation: "+str(patch.keys()))
	var legacy := before.duplicate(true); legacy.schema_version = 1; legacy.flags.clear_passage = true
	for key in ["coins","equipment","shop_stock","payments","vitals"]: legacy.erase(key)
	fixture(legacy); check(p.load_from("res://tests/player-state.json") == OK and p.coins == 40 and p.equipment.weapon == "PT-W02","Old save migrates currency, stock and selected weapon")
	check(p.save_to("res://tests/player-state.json") == OK and p.load_from("res://tests/player-state.json") == OK and p.coins == 40,"Migrated payment never repeats")
	# Mount the real chapter, preserving its dialogue while the modal owns input.
	p.resume_requested = false
	game = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate(); game.start_block = 14; root.add_child(game); await frames(3)
	game.phase = "block_end"
	var old_event: int = game.event_index; var old_text: String = game.view.body.text
	game._menu(); await frames()
	check(paused and game.menu_open and game.player_menu.screen.visible,"Esc opens a separately paused player modal")
	for tab in game.player_menu.tab_names:
		game.player_menu.tabs[tab].emit_signal("pressed"); await frames()
		check(game.player_menu.page == tab,"Menu tab works: "+tab)
	game.player_menu.switch_page("Loja de Lisboa"); await frames()
	check(game.player_menu.shop_reason().is_empty() and game.player_menu.row_buttons.has("PT-C03"),"Store reachable during safe courtyard pause")
	game.player_menu.row_buttons["PT-C03"].emit_signal("pressed"); await frames()
	var coins_before: int = p.coins; game.player_menu.action_button.grab_focus(); await press_key(KEY_ENTER)
	check(p.coins == coins_before-3,"Keyboard activation of real shop button completes purchase")
	game.player_menu.action_button.grab_focus(); await press_pad(JOY_BUTTON_A)
	check(p.coins == coins_before-6,"Controller A completes purchase once")
	game.player_menu.trading = "Vender"; game.player_menu.refresh(); game.player_menu.select_item("PT-C03")
	coins_before = p.coins; game.player_menu.action_button.emit_signal("pressed")
	check(p.coins == coins_before,"Sale first asks for review")
	game.player_menu.action_button.emit_signal("pressed"); await frames()
	check(p.coins == coins_before+1,"Sale confirmation transfers exactly one item")
	game.player_menu.switch_page("Inventário"); game.player_menu.select_item("PT-V01"); await frames()
	check(game.player_menu.action_button != null,"Inventory exposes gear action with details")
	game.player_menu.tabs["Inventário"].grab_focus(); await press_pad(JOY_BUTTON_DPAD_RIGHT)
	check(root.gui_get_focus_owner() == game.player_menu.tabs["Equipamento"],"Controller directional navigation changes focused tab")
	await press_pad(JOY_BUTTON_A); check(game.player_menu.page == "Equipamento","Controller A opens focused tab")
	var cancel := InputEventAction.new(); cancel.action = "ui_cancel"; cancel.pressed = true; root.push_input(cancel); await frames()
	check(not paused and not game.menu_open and game.event_index == old_event and game.view.body.text == old_text,"Closing modal restores exact dialogue and never advances")
	game._menu("Loja de Lisboa"); game.map_kind = "deck"; game.player_menu.refresh()
	check(not game.player_menu.shop_reason().is_empty() and game.player_menu.row_buttons.is_empty(),"Store unavailable aboard ship")
	game._menu()
	# Replaying optional preparation must not duplicate free narrative supplies.
	game.phase = "task"; game.task_id = "pack"; game.task_step = 0; game.props.marker = game.world.player.position
	p.flags.pack = true; p.inventory["PT-C02"] = 0; p.inventory["PT-C03"] = 0
	game.interact_task(); check(p.inventory["PT-C02"] == 0 and p.inventory["PT-C03"] == 0,"Packing replay cannot regenerate sold or consumed supplies")
	game.phase = "styles_result"; p.flags.initial_weapon_received = true; p.style = "PU"; p.inventory["PT-W05"] = 0
	game.confirm_style(); check(p.inventory["PT-W05"] == 0 and not p.equipment.has("weapon"),"Repeating final choice never regenerates free gear; unarmed remains valid")
	game.queue_free(); await frames(3)
	for path in ["res://tests/player-state.json","res://tests/player-state.json.bak"]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	print("PLAYER_INVENTORY_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
