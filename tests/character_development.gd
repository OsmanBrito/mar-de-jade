extends SceneTree
var Dev
var checks := 0
var failures: Array[String] = []
var game
func _initialize(): call_deferred("run")
func check(ok: bool,message: String):
	checks += 1
	if not ok: failures.append(message); push_error(message)
func frames(n := 3):
	for i in n: await process_frame
func run():
	Dev = load("res://scripts/chapter/character_development.gd")
	var Items = load("res://scripts/chapter/player_items.gd")
	var p = root.get_node("ChapterProgress"); p.auto_save = false; p.reset()
	root.get_node("GamePreferences").persist_enabled = false
	root.get_node("CampaignProfile").hero_name = "Miguel"
	check(Dev.threshold(2)==100 and Dev.threshold(3)==230 and Dev.threshold(4)==400 and Dev.threshold(60)==382320,"Documented cumulative XP curve")
	check(Dev.level_of(0)==1 and Dev.level_of(99)==1 and Dev.level_of(100)==2 and Dev.level_of(382320)==60,"Exact level thresholds and ceiling")
	check(Dev.available_points(Dev.member(p))==0 and Items.stats(p).hp==100,"Adult starts with five attributes at five and no granted points")
	p.flags.recovered = true; p.entry_scene = "res://scenes/chapter_01/chapter_flow.tscn"
	p.inventory["PT-V01"] = 1; p.equipment.outfit = "PT-V01"; p.vitals = {"hp":25,"qi":1,"posture":50}
	var first: Dictionary = p.award_development("test:first",100)
	check(first.levels==["hero"] and Dev.available_points(Dev.member(p))==3,"One gained level gives three manual points")
	check(p.vitals.hp==Items.stats(p).hp and p.vitals.qi==Items.stats(p).qi and p.vitals.posture==50,"Normal level recovery includes equipped maximums and preserves posture")
	var unchanged: Dictionary = p.snapshot()
	check(p.award_development("test:first",100).xp==0 and p.snapshot()==unchanged,"Claimed reward is idempotent")
	var draft: Dictionary = Dev.member(p).attributes.duplicate(); draft.VIG += 1; draft.ESP += 1; draft.FOR += 1
	check(Dev.allocate(p,"hero",draft).begins_with("Atributos confirmados") and Dev.available_points(Dev.member(p))==0,"Distribute exactly the earned budget")
	check(Items.stats(p).hp==unchanged.vitals.hp+14 and Items.stats(p).qi==22 and p.vitals.hp==unchanged.vitals.hp,"Attributes increase limits without healing")
	var excess: Dictionary = draft.duplicate(); excess.PER += 1
	check(not Dev.allocation_error(Dev.member(p),excess).is_empty(),"Overspending is rejected")
	var negative: Dictionary = draft.duplicate(); negative.FOR = 4
	check(not Dev.allocation_error(Dev.member(p),negative).is_empty(),"Attributes cannot go below five")
	p.learn("FO07"); p.learn("FO01"); p.learn("FO08"); p.learn("FO09")
	p.learn("ES07"); p.learn("LA07"); p.learn("MC08"); p.learn("PU07"); p.learn("DP01")
	check(Dev.member(p).active_skills.size()==6 and not Dev.member(p).active_skills.has("DP01"),"Six active slots shared across weapons; reactions outside slots")
	check(Dev.toggle_skill(p,"PU07").begins_with("As seis"),"Full deck rejects a seventh skill")
	Dev.toggle_skill(p,"ES07"); Dev.toggle_skill(p,"PU07")
	check(Dev.equipped(p,"PU07") and not Dev.equipped(p,"ES07") and p.skills.has("ES07"),"Unequipping preserves learned knowledge")
	Dev.training(p,"FO"); var proficiency: int = Dev.member(p).proficiency.FO
	Dev.training(p,"FO")
	check(proficiency==40 and Dev.member(p).proficiency.FO==40 and Dev.member(p).cultivation.step==2,"First teaching grants finite practice and its own cultivation proof")
	p.learn("DU01")
	check(Dev.level_of(int(Dev.member(p,"duarte").xp))==3 and Dev.available_points(Dev.member(p,"duarte"))==6,"Duarte joins at level three without earlier journey XP")
	var duarte_xp: int = Dev.member(p,"duarte").xp; var hero_xp: int = Dev.member(p).xp
	p.award_development("test:party",30)
	check(Dev.member(p,"duarte").xp-duarte_xp==Dev.member(p).xp-hero_xp,"Recruited members share equal XP without forced equal levels")
	root.get_node("GamePreferences").options.difficulty = "challenging"
	p.vitals.hp = 20; p.vitals.qi = 1; p.award_development("test:challenging",100)
	check(Dev.level_of(int(Dev.member(p).xp))==3 and p.vitals.hp==20 and p.vitals.qi==1,"Challenging mode does not recover resources on level up")
	root.get_node("GamePreferences").options.difficulty = "normal"
	p.flags.injured = true; p.vitals.hp = 1; p.award_development("test:injured",170)
	check(p.vitals.hp==1 and p.flags.injured,"Level up cannot remove narrative injury")
	p.flags.injured = false
	for amount in [7,1,12]:
		Dev.practice(p,"hero","FO",{"FO07":amount})
	check(Dev.member(p).practice.FO07==13,"Each victory caps per-technique counted uses")
	# Cap is six per technique per encounter, so the three encounters above grant 6+1+6.
	check(Dev.grade(p,"FO07")==2,"Eight valid uses produce degree II without level-based mastery")
	Dev.practice(p,"hero","FO",{"FO07":6}); Dev.practice(p,"hero","FO",{"FO07":6})
	check(Dev.grade(p,"FO07")==3 and Dev.member(p).practice.FO07==20,"Twenty valid uses produce degree III and cap practice")
	Dev.member(p).practice.FO08 = 8
	var unequal: Dictionary = Dev.member(p).attributes.duplicate(); unequal.AGI = 11; unequal.PER = 7
	check(is_equal_approx(Dev.power(p,"FO","hero",unequal,["AGI","PER"])-Dev.power(p,"FO","hero",unequal,["PER","AGI"]),2.2),"Individual skill primary and secondary attributes have distinct weights")
	check(Dev.SKILL_PROFILES.ES07==[0.8,"PER","AGI"] and Dev.SKILL_PROFILES.PU07==[0.85,"AGI","PER"] and Dev.SKILL_PROFILES.LA07==[0.9,"PER","FOR"],"Initial techniques retain their documented coefficients and own influences")
	var Rules = load("res://scripts/combat/campaign_rules.gd")
	var b = Rules.new(); b.start_encounter("school","Miguel","FO")
	check(is_equal_approx(b.skill_def(0,8).protection,0.33),"Defensive degree II grants three percentage points, not generic guard")
	check(b.skill_def(0,1).level==3 and b.skill_def(0,1).description.contains("PER/AGI"),"Skill definitions expose mastery and attribute influences")
	var saved: Dictionary = p.snapshot()
	check(p.restore(saved,false)==OK,"Developed character is valid before saving")
	var json_state: Dictionary = JSON.parse_string(JSON.stringify(saved))
	check(p.restore(json_state)==OK and Dev.member(p).practice.FO07==20,"JSON round trip retains XP, points, mastery and deck")
	for fault in ["points","slots","proficiency","cultivation","claim","unknown","type","missing","fraction"]:
		var bad: Dictionary = p.snapshot(); var before: Dictionary = p.snapshot()
		match fault:
			"points": bad.development.members.hero.attributes.FOR = 60
			"slots": bad.development.members.hero.active_skills.append(bad.development.members.hero.active_skills[0])
			"proficiency": bad.development.members.hero.proficiency.ES = 1001
			"cultivation": bad.development.members.hero.cultivation.rank = 5
			"claim": bad.development.claimed.append(bad.development.claimed[0])
			"unknown": bad.development.members.hero.practice.unknown = 8
			"type": bad.development = "invalid"
			"missing": bad.erase("development")
			"fraction": bad.development.members.hero.xp = 100.5
		check(p.restore(bad)==ERR_INVALID_DATA and p.snapshot()==before,"Atomic invalid save rejection: "+fault)
	var legacy_firearm: Dictionary = p.snapshot(); legacy_firearm.erase("development"); legacy_firearm.schema_version = 12; legacy_firearm.skills = ["FO07","DU01"]; legacy_firearm.companion_vitals = {"duarte":{"hp":70,"qi":4,"posture":60}}
	check(p.restore(legacy_firearm)==OK and Dev.member(p).active_skills.has("FO01") and Dev.member(p).active_skills.has("FO08") and Dev.member(p).active_skills.has("FO09"),"Legacy firearm lesson keeps all four techniques available in the new deck")
	var old: Dictionary = p.snapshot(); old.erase("development"); old.schema_version = 12
	old.completed = true; old.checkpoint = 16; old.vitals = {"hp":60,"qi":5,"posture":80}; old.companion_vitals = {"duarte":{"hp":70,"qi":4,"posture":60}}
	check(p.restore(old)==OK and Dev.level_of(int(Dev.member(p).xp))==4 and p.vitals.hp==60,"Legacy completed Portugal receives its main journey XP without healing or losing items")
	check(Dev.level_of(int(Dev.member(p,"duarte").xp))==3,"Legacy migration never awards Duarte XP from before recruitment")
	var migrated: Dictionary = p.snapshot()
	check(p.restore(migrated)==OK and p.snapshot()==migrated,"Migration is idempotent")
	var Kit = load("res://scripts/navigation/boarding_loadout.gd")
	var carried: Dictionary = Kit.capture(p.snapshot())
	check(Kit.valid(carried) and carried.development==p.development,"Boarding carries the same progression and deck")
	var ship = load("res://scripts/navigation/boarding_rules.gd").new(); ship.progress_override = carried; ship.start_encounter("boarding","Miguel","FO")
	check(ship.units[0].max_hp==Items.stats(p).hp and ship.units[1].max_qi==Dev.base_stats(p,"duarte").qi,"Real boarding uses both characters' derived maximums")
	var bar: Array = ship.commands(0)
	Dev.toggle_skill(carried,"FO01"); ship.start_encounter("boarding","Miguel","FO")
	check(bar.has(2) and not ship.commands(0).has(2) and ship.commands(0).has(0),"Only prepared compatible skills appear in real combat; basic remains available")
	var Panel = load("res://scripts/chapter/development_panel.gd")
	var panel = Panel.new(); root.add_child(panel)
	panel.setup(p.snapshot(),true)
	var snapshot_before: Dictionary = p.snapshot()
	panel.change_attribute("VIG",1)
	check(p.snapshot()==snapshot_before and panel.pending.development!=p.development,"Attribute preview cannot mutate the live character")
	var emitted: Array = []
	panel.committed.connect(func(data): emitted.append(data))
	panel.commit()
	check(emitted.size()==1 and p.snapshot()==snapshot_before and Dev.valid(emitted[0].development,emitted[0].skills),"Only explicit confirmation emits a valid independent draft")
	panel.setup(p.snapshot(),false); var locked: Dictionary = panel.pending.duplicate(true); panel.change_attribute("VIG",1); panel.commit()
	check(panel.pending==locked and emitted.size()==1,"Unsafe editor stays read-only even through direct method calls")
	panel.free()
	# Live menu and the same editor aboard.
	game = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate(); game.start_block = 14; root.add_child(game); await frames()
	game.phase = "exploration"; game.busy = false; game._menu("Evolução"); await frames()
	check(game.player_menu.tabs.has("Evolução") and game.player_menu.listing.get_child(0).has_signal("committed"),"Land menu opens the shared progression editor")
	game.free(); paused = false; await frames()
	# The voyage exposes the same editor and commits to the carried save.
	var launch = load("res://scripts/navigation/voyage_launch.gd"); launch.mode = "campaign"; launch.resume_requested = false
	game = load("res://scenes/navigation/voyage.tscn").instantiate(); game.auto_save = false; root.add_child(game); await frames()
	game.set_process(false); game.clear_overlay(); game.model.dock("lisboa"); game.open_personal("development"); await frames()
	var carrier_before: Dictionary = game.model.campaign_state.duplicate(true)
	var proposed: Dictionary = carrier_before.duplicate(true)
	proposed.development.members.hero.attributes.VIG += 1
	game._commit_development(proposed)
	check(game.model.boarding_profile.development==game.model.campaign_state.development and game.model.campaign_state.development.members.hero.attributes.VIG==6,"Aboard confirmation updates both authoritative character and combat preparation")
	game.model.phase = "naval"; var protected_state: Dictionary = game.model.campaign_state.duplicate(true)
	proposed = protected_state.duplicate(true); proposed.development.members.hero.attributes.VIG += 1
	game._commit_development(proposed)
	check(game.model.campaign_state==protected_state,"Unsafe ship state rejects a direct commit")
	game.model.phase = "port"; game.current_enemy = game.model.place("patrol")
	game.model.boarding_profile.development.members.hero.active_skills.clear()
	game.model.boarding_profile.development.members.duarte.active_skills.clear()
	game.begin_boarding(); game.battle_host.set_process(false)
	var host = game.battle_host; var view = host.tactical
	var empty_pad := InputEventJoypadButton.new(); empty_pad.pressed = true; empty_pad.button_index = JOY_BUTTON_Y
	host._unhandled_input(empty_pad)
	check(view.phase=="choose" and not host.note.is_empty(),"Y with an empty repertoire stays safe and explains the available basic")
	var bag_key := InputEventKey.new(); bag_key.pressed = true; bag_key.physical_keycode = KEY_2
	host._unhandled_input(bag_key)
	check(view.phase=="items","A keyboard slot mapped to the bag opens items instead of executing an invalid skill")
	host.combat.battle_practice = {"hero":{"FO07":2,"basic":1}}
	host.combat.units[0].hp = 0; host.combat.units[0].qi = 0
	host.combat.units[1].hp = 50; host.combat.units[1].qi = 4
	var xp_before: int = game.model.boarding_profile.development.members.hero.xp
	game._boarding_completed(true)
	check(game.model.boarding_profile.vitals.hp==1 and game.model.boarding_profile.vitals.qi==0,"Victory permits minimal return from incapacity without full healing or free alento")
	check(game.model.boarding_profile.development.members.hero.xp==xp_before+35,"A real boarding completion grants its finite journey reward")
	var usage_after: Dictionary = game.model.boarding_profile.development.duplicate(true)
	game._boarding_completed(true)
	check(game.model.boarding_profile.development==usage_after,"Repeated completion cannot duplicate XP, proficiency or mastery")
	game.free(); paused = false; await frames()
	var total := 0
	for id in Dev.STORY: total += int(Dev.STORY[id])
	check(total==400 and Dev.level_of(total)==4,"Portugal main milestones target level four without optional grinding")
	p.entry_scene = "res://scenes/chapter_01/chapter_flow.tscn"; p.local_requests.clear()
	p.flags = {"lisbon_tide_read":true,"lisbon_rope_read":true,"lisbon_manifest_read":true}
	var discovery_before: int = Dev.member(p).xp
	p.sync_development()
	check(Dev.member(p).xp==discovery_before+30,"The three authored Lisbon discovery flags each grant ten XP")
	p.sync_development()
	check(Dev.member(p).xp==discovery_before+30,"Reopening completed discovery rewards cannot duplicate XP")
	print("CHARACTER_DEVELOPMENT_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
