extends SceneTree
const Items = preload("res://scripts/chapter/player_items.gd")
const Loadout = preload("res://scripts/navigation/boarding_loadout.gd")
const PATH := "user://qa-ferro-integration.json"
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func fixture(data: Dictionary) -> void:
	FileAccess.open(PATH,FileAccess.WRITE).store_string(JSON.stringify(data))
func run() -> void:
	var p = root.get_node("ChapterProgress")
	p.auto_save = false; p.reset()
	root.get_node("CampaignProfile").hero_name = "Joana"
	check(p.inventory == {"PT-Q01":1} and p.coins == 0 and p.skills.is_empty(),"Import grants no starting gear, currency or techniques")
	var imported := 0
	for id in Items.items():
		if not id.begins_with("FERRO:"): continue
		imported += 1
		var row: Dictionary = Items.items()[id]
		check(row.source_id == id.trim_prefix("FERRO:") and not row.has("combat_effect") and ResourceLoader.exists(row.icon),"Imported item has provenance, local art and supported effects: "+id)
	check(imported == 8 and not Items.items().has("FERRO:order_seal"),"Only the audited batch enters the campaign catalog")
	Items.pay_service(p); Items.buy(p,"FERRO:coat")
	check(p.coins == 15 and p.inventory.get("FERRO:coat") == 1 and p.shop_stock["FERRO:coat"] == 0,"Imported purchase uses the same service payment and limited stock")
	check(not Items.equip_reason(p,"FERRO:coat").is_empty(),"Imported armor respects narrative recovery")
	p.flags.recovered = true; Items.equip(p,"FERRO:coat")
	check(Items.stats(p).defense == 1 and p.vitals.hp == 100,"Source armor executes its actual bonus without healing")
	var before: Dictionary = p.snapshot()
	Items.buy(p,"FERRO:coat"); Items.sell(p,"FERRO:coat")
	check(p.snapshot() == before,"Exhausted purchases and sale of equipped last copy are atomic")
	p.coins = 200; Items.buy(p,"FERRO:dock_knife")
	check(not Items.equip_reason(p,"FERRO:dock_knife").is_empty(),"Imported sword requires learned weapon family")
	p.tested_styles.assign(["ES","PU"]); Items.equip(p,"FERRO:dock_knife")
	check(p.style == "ES" and Items.stats(p).power == 26 and Items.stats(p).speed == 20,"Adapted sword uses Jade's ES family and source stats")
	var battle = load("res://scripts/combat/campaign_rules.gd").new()
	battle.start_encounter("school","Joana",p.style)
	check(battle.units[0].defense == 1 and battle.units[0].speed == 20 and battle.skill_def(0,0).power == 26,"Imported equipment reaches the live land combat")
	var carried := Loadout.capture(p.snapshot())
	check(not carried.is_empty() and carried.equipment == p.equipment,"Existing boarding adapter accepts the same equipment IDs")
	var boarding = load("res://scripts/navigation/boarding_rules.gd").new()
	boarding.progress_override = carried; boarding.start_encounter("boarding","Joana",p.style)
	check(boarding.units[0].defense == 1 and boarding.units[0].speed == 20 and boarding.skill_def(0,0).power == 26,"Boarding executes the same imported bonuses")
	var sea = load("res://scripts/navigation/voyage_model.gd").new()
	sea.hero_name = "Joana"; sea.style = p.style; sea.boarding_profile = carried
	check(sea.save_to(PATH+".voyage") == OK,"Maritime save accepts the imported carried equipment")
	var resumed = load("res://scripts/navigation/voyage_model.gd").new()
	var load_error: int = resumed.load_from(PATH+".voyage")
	check(load_error == OK and resumed.boarding_profile.equipment == carried.equipment and int(resumed.boarding_profile.inventory.get("FERRO:dock_knife",0)) == 1 and Items.stats(resumed.boarding_profile) == Items.stats(carried) and int(resumed.boarding_profile.vitals.hp) == 100,"Maritime load preserves imported gear, quantity, health and executed bonuses")
	check(p.save_to(PATH) == OK,"Current Jade campaign writes")
	before = p.snapshot(); p.reset()
	check(p.load_from(PATH) == OK and p.snapshot() == before,"Imported equipment, stock, wallet and inventory survive save/load")
	for version in [1,2,3]:
		p.reset()
		var old: Dictionary = p.snapshot(); old.schema_version = version; old.erase("campaign_id")
		for id in Items.items():
			if id.begins_with("FERRO:"): old.shop_stock.erase(id)
		old.shop_stock["PT-C03"] = 0; old.coins = 17
		if version == 1:
			for key in ["coins","equipment","shop_stock","payments","vitals"]: old.erase(key)
		fixture(old)
		check(p.load_from(PATH) == OK and p.shop_stock.get("FERRO:coat") == 1 and p.inventory == {"PT-Q01":1},"Legacy v%d migrates only shop availability"%version)
		if version > 1: check(p.shop_stock["PT-C03"] == 0 and p.coins == 17,"Legacy migration preserves spent stock and money")
		p.shop_stock["FERRO:coat"] = 0
		check(p.save_to(PATH) == OK and p.load_from(PATH) == OK and p.shop_stock["FERRO:coat"] == 0,"Upgraded save never replenishes imported stock")
	for version in [4,5]:
		var old: Dictionary = p.snapshot(); old.schema_version = version
		old.shop_stock["FERRO:coat"] = 0; old.coins = 17
		fixture(old)
		check(p.load_from(PATH) == OK and p.shop_stock["FERRO:coat"] == 0 and p.coins == 17,"Upgrading v%d preserves exhausted imported stock and money"%version)
	before = p.snapshot()
	for patch in [{"campaign_id":"mare_de_ferro"},{"campaign_id":null},{"schema_version":99},{"inventory":{"FERRO:unknown":1}},{"equipment":{"outfit":"FERRO:coat"}},{"shop_stock":{"FERRO:coat":-1}}]:
		var invalid := before.duplicate(true); invalid.merge(patch,true); fixture(invalid)
		check(p.load_from(PATH) == ERR_INVALID_DATA and p.snapshot() == before,"Malformed/foreign save rejected before mutation: "+str(patch.keys()))
	# Exercise the real menu so catalog additions cannot break item details or trade.
	p.reset(); p.flags.recovered = true; p.coins = 200; p.resume_requested = false
	var game = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate()
	game.start_block = 14; root.add_child(game)
	for i in 3: await process_frame
	game.phase = "block_end"; game._menu("Loja de Lisboa")
	check(game.player_menu.row_buttons.has("FERRO:oilskin"),"Real Lisbon shop lists adapted gear")
	game.player_menu.select_item("FERRO:oilskin")
	game.player_menu.action_button.pressed.emit()
	check(p.inventory.get("FERRO:oilskin") == 1 and p.coins == 130,"Real shop button purchases through the shared economy")
	game._menu(); game.queue_free()
	for i in 3: await process_frame
	for suffix in ["",".bak",".tmp",".voyage",".voyage.bak",".voyage.tmp"]:
		if FileAccess.file_exists(PATH+suffix): DirAccess.remove_absolute(PATH+suffix)
	print("FERRO_INTEGRATION_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
