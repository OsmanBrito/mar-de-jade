extends SceneTree
const Model = preload("res://scripts/navigation/voyage_model.gd")
const Launch = preload("res://scripts/navigation/voyage_launch.gd")
const SAVE := "user://qa-continuity-voyage.json"
var checks := 0
var failures: Array[String] = []
var game
func _initialize() -> void: call_deferred("run")
func frames(n: int = 4) -> void:
	for i in n: await process_frame
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func prepare() -> void:
	var p = root.get_node("ChapterProgress"); p.auto_save = false; p.reset()
	root.get_node("CampaignProfile").hero_name = "Miguel"
	p.flags = {"recovered":true,"perfect_defense":true,"embarked":true,"house_child_done":true}
	p.coins = 73; p.inventory["PT-C01"] = 2; p.inventory["PT-C03"] = 2
	p.inventory["PT-V02"] = 1; p.passives.assign(["GE21","DU-P09"])
	p.inventory["PT-W04"] = 1
	p.skills.assign(["ES07","FO07","DP01"]); p.tested_styles.assign(["ES","FO"])
	p.vitals = {"hp":80,"qi":8,"posture":90}; p.choices.origin_response = "assumir"
	p.completed = true; p.checkpoint = 16; p.entry_scene = "res://scenes/chapter_01/chapter_flow.tscn"
func mount(resume: bool = false) -> void:
	Launch.mode = "campaign"; Launch.resume_requested = false
	game = load("res://scenes/navigation/voyage.tscn").instantiate(); game.auto_save = false; root.add_child(game); await frames(); game.set_process(false); game.clear_overlay()
	game.save_path = SAVE
	if resume:
		check(game.model.load_from(SAVE)==OK,"Stored voyage validates before restoration")
		game._prepare_boarding_profile()
func capture(id: String) -> void:
	if DisplayServer.get_name()=="headless": return
	DirAccess.make_dir_recursive_absolute("res://.qa-runtime/continuity-preview")
	await frames(8); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.qa-runtime/continuity-preview/"+id+".png")
func run() -> void:
	Engine.time_scale = 3
	prepare()
	var p = root.get_node("ChapterProgress")
	var departure: Dictionary = p.snapshot()
	await mount()
	check(game.model.campaign_state==departure and p.snapshot()==departure,"Departure keeps the whole campaign without rewriting it")
	check(game.model.coins==180 and game.model.campaign_state.coins==73,"Crew fund and personal wallet remain separate")
	game.current_enemy = game.model.place("patrol"); game.begin_boarding()
	var b = game.battle_host.combat
	b.current_id = 0; b.units[0].hp = 60; b.units[0].qi = 2; b.units[0].posture = 44
	b.units[1].hp = 64; b.units[1].qi = 3; b.units[1].posture = 51
	var used: Dictionary = b.perform(6,b.units[0].cell,1)
	check(not used.has("error") and b.units[0].hp==85,"Actual boarding bandage applies its recovery")
	game._boarding_completed(true)
	check(p.inventory["PT-C01"]==1 and p.vitals.hp==85 and p.vitals.qi==2 and p.vitals.posture==44,"Victory updates the same live personal inventory and resources as land")
	check(p.companion_vitals.duarte=={"hp":64,"qi":3,"posture":51},"Duarte keeps his own health, energy and posture after boarding")
	check(p.coins==73 and p.choices==departure.choices and p.flags.house_child_done,"Narrative choices, childhood memory and personal money survive boarding")
	check(game.model.coins==250,"Boarding reward belongs to the crew fund")
	game.battle_host.active = false; game.battle_host.ending.reset(game.battle_host); game.battle_container.hide()
	game.model.phase = "port"; game.model.port = "madeira"; game.model.position = game.model.point(game.model.place("madeira").pos)
	game.auto_save = true
	check(game._save(false)==OK,"Port saves character and voyage in one checkpoint")
	var persisted: Dictionary = game.model.campaign_state.duplicate(true)
	check(Launch.matches_chapter(departure,SAVE),"Continue chapter recognises the voyage from this campaign")
	game.open_personal(); await frames()
	var words := ""
	for label in game.modal_root.find_children("*","Control",true,false): words += label.text if label is Label or label is Button else ""
	check(words.contains("73") and words.contains("250") and words.contains("Ligadura"),"Onboard character sheet shows actual wallet, crew fund and possessions")
	await capture("personal-bag")
	game.open_personal_item("PT-V02"); await capture("personal-item")
	game.free(); await frames()
	p.reset(); root.get_node("CampaignProfile").hero_name = "Miguel"
	check(not Launch.matches_chapter(p.snapshot(),SAVE),"A new campaign with the same name cannot resume the previous campaign by mistake")
	await mount(true)
	if p.snapshot()!=persisted:
		for key in persisted:
			if p.snapshot()[key]!=persisted[key]: print("CONTINUITY_DIFF ",key," ",p.snapshot()[key]," VS ",persisted[key])
	check(p.snapshot()==persisted,"Reload restores the complete character, choices and economy from the maritime checkpoint")
	game.model.phase = "sea"; game.model.port = ""; game.current_enemy = game.model.place("patrol"); game.begin_boarding()
	check(game.battle_host.combat.units[0].hp==85 and game.battle_host.combat.potions==1,"Next boarding starts with the persisted health and remaining bandage")
	check(game.battle_host.combat.units[1].hp==64 and game.battle_host.combat.units[1].qi==3,"Next boarding does not silently heal the companion")
	game.model.boarding_profile.vitals.hp = 1; game.model.campaign_state.vitals.hp = 1; p.vitals.hp = 1
	game.restore_safe()
	check(p.vitals.hp==85 and p.inventory["PT-C01"]==1,"Defeat/reload rolls back personal resources together with the ship")
	game.auto_save = true
	game.personal_action("equip","PT-V02")
	check(p.equipment.get("outfit","")=="PT-V02" and game.model.boarding_profile.equipment==p.equipment,"Equipment prepared ashore uses the shared personal rules and boarding kit")
	game.personal_action("use","PT-C03")
	check(p.inventory["PT-C03"]==1 and p.vitals.qi==7,"Port preparation consumes personal water and recovers real energy")
	game.personal_action("passive","GE21"); game.personal_action("passive","DU-P09")
	check(p.equipped_passives.has("GE21") and p.duarte_equipped_passives.has("DU-P09"),"Preparation preserves ownership of protagonist and companion passives")
	game.personal_action("duarte_use","PT-C03")
	check(p.companion_vitals.duarte.qi==8 and p.vitals.qi==7 and p.inventory["PT-C03"]==0,"Duarte can use shared supplies without changing the protagonist's resources")
	game.personal_action("equip","PT-W04")
	check(p.style=="FO" and game.model.style=="FO" and game.model.boarding_profile.equipment.weapon=="PT-W04","A previously learned weapon style changes consistently on land and at sea")
	var after_preparation: Dictionary = p.snapshot()
	check(game.model.load_from(SAVE)==OK,"Preparation is saved inside the voyage checkpoint")
	game._prepare_boarding_profile()
	if p.snapshot()!=after_preparation:
		for key in after_preparation:
			if p.snapshot()[key]!=after_preparation[key]: print("PREPARATION_DIFF ",key," ",p.snapshot()[key]," VS ",after_preparation[key])
	check(p.snapshot()==after_preparation,"Prepared equipment, water and passives round trip together")
	var safe: Dictionary = game.model.snapshot()
	game.model.phase = "sea"; game.model.port = ""; game.model.position = game.model.point(game.model.place("breaker").pos) if not game.model.place("breaker").is_empty() else game.model.point(game.model.place("patrol").pos)
	game.model.resolved.clear()
	game.personal_action("use","PT-C01")
	check(p.snapshot()==after_preparation,"An unsafe encounter cannot be bypassed by using the preparation menu")
	game.model.restore(safe)
	var carried_rules = load("res://scripts/navigation/boarding_rules.gd").new()
	carried_rules.progress_override = game.model.boarding_profile.duplicate(true); carried_rules.progress_override.vitals.hp = 0
	carried_rules.start_encounter("boarding","Miguel",game.model.style)
	check(carried_rules.units[0].hp==0 and carried_rules.units[1].hp==64,"A fallen protagonist is not silently revived by the safe-training rule")
	var valid: Dictionary = game.model.snapshot(); var before: Dictionary = p.snapshot()
	var invalid := valid.duplicate(true); invalid.campaign_state.inventory["unknown"] = 1
	check(not game.model.restore(invalid) and game.model.snapshot()==valid and p.snapshot()==before,"Malformed personal state rejects the entire voyage atomically")
	invalid = valid.duplicate(true); invalid.boarding_profile.vitals.hp = 10
	check(not game.model.restore(invalid) and p.snapshot()==before,"Divergent boarding and campaign resources cannot enter a checkpoint")
	var old := departure.duplicate(true); old.schema_version = 9; old.erase("run_id")
	check(p.restore(old)==OK and p.run_id.length()==64,"Version 9 chapter migrates with a stable campaign identity")
	var migrated: String = p.run_id
	check(p.restore(old)==OK and p.run_id==migrated,"Repeated legacy loading does not change campaign identity")
	old = valid.duplicate(true); old.version = 1; old.erase("campaign_state")
	old.boarding_profile.erase("companion_vitals")
	check(game.model.restore(old),"Version 1 voyage with its original character kit remains loadable")
	game._prepare_boarding_profile()
	check(game.model.campaign_state.run_id==migrated and p.coins==73 and p.style=="FO" and p.vitals.hp==85,"Legacy voyage joins its migrated chapter while preserving its actual remaining kit")
	check(game.model.save_to(SAVE)==OK and game.model.load_from(SAVE)==OK,"Migrated legacy voyage round trips in version 2")
	var last_good: Dictionary = game.model.snapshot()
	var saved_hash := FileAccess.get_sha256(SAVE)
	game.model.campaign_state.inventory["unknown"] = 1
	check(game.model.save_to(SAVE)==ERR_INVALID_DATA and FileAccess.get_sha256(SAVE)==saved_hash,"Invalid live state cannot overwrite the last good voyage")
	game.model.restore(last_good)
	var personal_before: Dictionary = p.snapshot()
	var broken: Dictionary = p.snapshot(); broken.companion_vitals = {"duarte":{"hp":121,"qi":12,"posture":100}}
	check(p.restore(broken)==ERR_INVALID_DATA and p.snapshot()==personal_before,"Companion resources above combat limits reject before mutating the campaign")
	game.free(); await frames()
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(SAVE+suffix): DirAccess.remove_absolute(SAVE+suffix)
	print("CAMPAIGN_CONTINUITY_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
