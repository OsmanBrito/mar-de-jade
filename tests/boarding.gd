extends SceneTree
const Loadout = preload("res://scripts/navigation/boarding_loadout.gd")
const Board = preload("res://scripts/combat/portugal_board.gd")
const Layout = preload("res://scripts/navigation/boarding_layout.gd")
const Launch = preload("res://scripts/navigation/voyage_launch.gd")
const Model = preload("res://scripts/navigation/voyage_model.gd")
const BoardingArt = preload("res://scripts/navigation/boarding_actor_art.gd")
const Assets = preload("res://scripts/navigation/boarding_assets.gd")
var checks := 0
var failures: Array[String] = []
var game
var Rules
var Boarding
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func frames(count: int = 3) -> void:
	for i in count: await process_frame
func key(code: Key) -> InputEventKey:
	var event := InputEventKey.new(); event.pressed = true; event.physical_keycode = code; return event
func capture(id: String) -> void:
	if DisplayServer.get_name()=="headless": return
	game.battle_host.queue_redraw(); await frames(); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/boarding-"+id+".png")
func drive() -> void:
	var host = game.battle_host; var b = host.combat; var v = host.tactical
	if host.ending.running(): host.update_ending(0.5); return
	if v.phase in ["choose","move","aim"] and v.is_player():
		if v.phase!="choose": v.cancel()
		if b.current().acted: v.start_facing(); v.facing = b.suggested_facing(b.current_id); v.confirm(); return
		var target := -1; var nearest := 999
		for enemy in b.enemies:
			if enemy.hp>0 and b.distance(b.current().cell,enemy.cell)<nearest: target = enemy.id; nearest = b.distance(b.current().cell,enemy.cell)
		if target<0: return
		var aim: Vector2i = b.units[target].cell
		if not b.valid_attack(0,aim):
			var best := Vector2i(-1,-1); var distance := 999
			for cell in b.reachable(b.current_id).costs:
				if b.distance(cell,aim)<distance: best = cell; distance = b.distance(cell,aim)
			if best!=Vector2i(-1,-1) and best!=b.current().cell: v.select_move(); v.select_cell(best); v.confirm()
			else: v.start_facing(); v.facing = b.suggested_facing(b.current_id); v.confirm()
			return
		v.select_skill(0); v.select_cell(aim); v.confirm()
	elif v.phase.begins_with("timing"): v.clock = v.duration*0.72; v.input_event(key(KEY_SPACE))
	else: v.update(1.8)
func run() -> void:
	Rules = load("res://scripts/combat/campaign_rules.gd"); Boarding = load("res://scripts/navigation/boarding_rules.gd")
	var reused: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/combat/boarding/reused-assets.json"))
	var hashes_match := true
	for copy in reused.copies:
		if FileAccess.get_sha256("res://"+copy.local)!=copy.sha256: hashes_match = false
	check(hashes_match and reused.copies.size()==14,"All 14 shipped art resources are exact Mar de Ferro copies with recorded SHA-256")
	for kind in ["guard","rogue","sailor","worker"]:
		var actor: Dictionary = Assets.data().actors[kind]
		check(actor.frames.size()==6 and actor.pivots.size()==6 and actor.height==60,kind+": original illustrated strip retains all six frames and a measured human-scale anchor")
		var pixels: Image = Assets.texture(actor.source.get_file()).diffuse_texture.get_image()
		check(pixels.has_mipmaps() and pixels.get_pixel(0,0).a==0,kind+": filtered art keeps transparency and mipmaps instead of an opaque rectangle")
	check(BoardingArt.frame("rogue","attack",0.45)==4 and BoardingArt.frame("guard","hurt",0.1)==5 and BoardingArt.frame("guard","parry",0.2)==3,"Actual contact, reaction and defense select the original combat poses")
	check(BoardingArt.frame("sailor","attack",0.45)==0 and BoardingArt.frame("worker","hurt",0.1)==0,"Civilian crew use idle/walk art without combat poses")
	var progress = root.get_node("ChapterProgress"); var saved: Dictionary = progress.snapshot()
	var profile = root.get_node("CampaignProfile"); var name_before: String = profile.hero_name
	for style in ["ES","LA","MC","FO","PU"]:
		var prepared: Dictionary = Loadout.practice(style)
		var original = Rules.new(); original.progress_override = prepared.duplicate(true); original.start_encounter("school","Aprendiz",style)
		var boarding = Boarding.new(); boarding.progress_override = prepared.duplicate(true); boarding.start_encounter("boarding","Aprendiz",style)
		original.current_id = 0; boarding.current_id = 0
		check(boarding.skill_def(0,0)==original.skill_def(0,0),style+": basic attack exactly matches Portugal's learned weapon and equipment")
		check(boarding.skill_def(0,1)==original.skill_def(0,1),style+": technique retains Portugal's full definition, not a renamed generic damage skill")
		check(boarding.units[0].hp==prepared.vitals.hp and boarding.units[0].max_hp==original.units[0].max_hp and boarding.units[0].qi==prepared.vitals.qi and boarding.units[0].max_qi==original.units[0].max_qi,style+": equipment limits match Portugal while boarding retains the real carried resources")
		check(boarding.commands(0)==[0,1,-1] and boarding.commands(1)==[0,4,-1] and boarding.perfect_defense_enabled,style+": learned commands, retreat and perfect defense remain available")
		# Sequence is executed, not just compared as metadata: a basic in the last
		# own turn discounts the first technique, just as in Portugal.
		boarding.units[0].cell = Vector2i(2,2); boarding.units[2].cell = Vector2i(3,2)
		boarding.units[2].hp = 200; boarding.units[2].max_hp = 200; boarding.units[2].posture = 200
		boarding.units[0].qi = 8
		var energy: int = boarding.units[0].qi
		var result: Dictionary = boarding.perform(0,boarding.units[2].cell,1)
		check(not result.has("error") and boarding.units[0].qi==energy+1,style+": basic recovers one alento through the shared execution path")
		boarding.units[0].turns += 1; boarding.units[0].acted = false
		check(boarding.skill_def(0,1).cost==(6 if style=="MC" else 3),style+": equipped Treino Paciente discounts the actual first technique")
		if style=="MC": check(boarding.skill_def(0,1).shape=="self" and boarding.skill_def(0,1).power==0,"Machado retains its preparation rather than becoming a damage strike")
		if style=="LA": check(not boarding.attack_reason(1,boarding.units[2].cell).is_empty(),"Lance technique still requires exactly two cells")
		if style=="FO":
			boarding.units[2].cell = boarding.units[0].cell+Vector2i(1,1)
			check(not boarding.attack_reason(1,boarding.units[2].cell).is_empty(),"Firearm technique still rejects a diagonal target")
	var support = Rules.new(); support.progress_override = Loadout.practice(); support.start_encounter("duarte_support","Aprendiz")
	var b = Boarding.new(); b.start_encounter("boarding","Aprendiz")
	check(b.skill_def(1,0)==support.skill_def(1,0) and b.skill_def(1,4)==support.skill_def(1,4),"Duarte's basic and Guarda Companheira match Portugal, including first-use passive cost")
	b.units[1].cover_target = 0
	var cover: Dictionary = b.cover_info(0,100)
	check(cover.id==1 and cover.remaining==60 and cover.damage==40,"Duarte retains the approved 60/40 interception split")
	check(not b.lesson_result().finished,"An interception does not prematurely finish a real boarding encounter")
	b.units[1].cover_target = -1; b.current_id = 2; b.units[2].cell = Vector2i(6,2); b.units[1].cell = Vector2i(5,2); b.units[0].cell = Vector2i.ZERO
	check(b.ai_plan().target==1,"A corsair can target nearby Duarte instead of using the child lesson's hero-only AI")
	var unlearned: Dictionary = Loadout.practice(); unlearned.skills = []; unlearned.flags.perfect_defense = false
	b = Boarding.new(); b.progress_override = unlearned; b.start_encounter("boarding","Aprendiz")
	check(b.commands(0)==[0,-1] and b.commands(1)==[0,-1] and not b.perfect_defense_enabled,"Unlearned characters retain only basic attack and retreat, without perfect defense")
	var arena = load("res://scripts/navigation/boarding_arena.gd").new(); var all_on_deck := true
	for x in Layout.SIZE.x:
		for y in Layout.SIZE.y:
			for p in Board.polygon(Vector2i(x,y)):
				if not Geometry2D.is_point_in_polygon(p,arena.deck_outline()): all_on_deck = false
	check(all_on_deck,"Every corner of every tactical cell lies inside the ship's actual deck")
	check(b.units.all(func(unit): return b.inside(unit.cell)) and b.obstacles.all(func(cell): return b.inside(cell)),"Both teams and all obstacles start on the enemy deck")
	var only_enemy := true
	for cell in b.reachable(1,100).costs:
		if cell.y>=Layout.SIZE.y: only_enemy = false
	check(only_enemy and not b.passable(Vector2i(2,6),1) and b.path_to(1,Vector2i(2,6),100).is_empty(),"Movement and pathfinding never enter the sea or the friendly ship")
	check(not b.valid_attack(0,Vector2i(2,6)),"The friendly ship cannot be selected as an attack destination")
	var ship = Model.new(); ship.style = "LA"; ship.boarding_profile = Loadout.practice("LA")
	var loaded_ship = Model.new()
	check(loaded_ship.restore(ship.snapshot()) and loaded_ship.boarding_profile==ship.boarding_profile,"Voyage saves retain the prepared character's weapon, vitals, techniques and passives")
	var valid_ship: Dictionary = loaded_ship.snapshot(); var bad_ship := valid_ship.duplicate(true)
	bad_ship.boarding_profile.vitals.hp = "broken"
	check(not loaded_ship.restore(bad_ship) and loaded_ship.snapshot()==valid_ship,"Malformed character vitals are rejected before changing the saved voyage")
	bad_ship = valid_ship.duplicate(true); bad_ship.boarding_profile.skills = ["unknown_skill"]
	check(not loaded_ship.restore(bad_ship) and loaded_ship.snapshot()==valid_ship,"Unknown learned techniques cannot enter the voyage checkpoint")
	var legacy_ship: Dictionary = ship.snapshot(); legacy_ship.erase("boarding_profile")
	check(loaded_ship.restore(legacy_ship) and loaded_ship.boarding_profile.is_empty(),"Older voyage saves without a character kit remain compatible")
	check(change_scene_to_file("res://scenes/chapter_01/name_entry.tscn")==OK,"Campaign entry loads without internal QA shortcuts")
	await frames()
	check(not current_scene.has_node("Center/Card/Margin/Content/BoardingQuickStart"),"Internal boarding shortcut is absent from the player menu")
	Launch.start(self,false,false,true); await frames(6)
	game = current_scene; game.set_process(false); game.battle_host.set_process(false)
	check(game.model.phase=="boarding" and not game.auto_save,"Shortcut starts an isolated boarding encounter without replacing voyage checkpoints")
	var view = game.battle_host.tactical; var reference_view = load("res://scripts/combat/portugal_view.gd").new()
	reference_view.setup(game.battle_host,game.battle_host.combat)
	check(view.tutorial_timing()==reference_view.tutorial_timing() and view.attack_timing_duration()==reference_view.attack_timing_duration() and view.defense_timing_duration()==reference_view.defense_timing_duration(),"Boarding keeps the same timing rhythm and durations as Portugal")
	check(view.screen(Vector2i(2,3))==reference_view.screen(Vector2i(2,3)) and view.tile_points(Vector2i(2,3))==reference_view.tile_points(Vector2i(2,3)),"Actor spacing and ground perspective are identical to land combat")
	var container: SubViewportContainer = game.battle_host.get_viewport().get_parent()
	var presentation: Transform2D = root.get_final_transform()*container.get_global_transform()
	check(is_equal_approx(presentation.x.length(),1.0) and is_equal_approx(presentation.y.length(),1.0) and game.battle_host.get_viewport().size==Vector2i(container.size),"Boarding presents one rendered texel per physical window pixel")
	if DisplayServer.get_name()!="headless":
		var original_size := root.size
		for window_size in [Vector2i(1600,900),Vector2i(1024,768)]:
			root.size = window_size; await frames(4)
			var transform: Transform2D = root.get_final_transform()*container.get_global_transform()*game.battle_host.get_viewport().canvas_transform
			check(is_equal_approx(transform.x.length(),transform.y.length()),"Window %s retains square pixels and the land combat's proportions"%window_size)
		root.size = original_size; await frames(4)
	view.select_move()
	for i in 12: view.input_event(key(KEY_DOWN))
	check(view.cursor_cell.y==3 and game.battle_host.combat.inside(view.selected_cell),"Keyboard selection stops at the enemy rail instead of disappearing onto the other ship")
	view.cancel(); view.select_skill(0)
	var field: Dictionary = view.field.snapshot(view)
	check(field.range.keys().all(func(cell): return game.battle_host.combat.inside(cell)),"The attack range contour stays entirely on the enemy deck")
	view.cancel()
	await capture("start")
	# The ordinary keyboard/mouse path is the same one used by Portugal.
	var actor_start: Vector2i = game.battle_host.combat.current().cell
	game.battle_host._unhandled_input(key(KEY_G))
	check(view.phase=="move","G opens the familiar movement command")
	var destination := actor_start+Vector2i.RIGHT
	var click := InputEventMouseButton.new(); click.pressed = true; click.button_index = MOUSE_BUTTON_LEFT; click.position = game.battle_host.get_viewport().canvas_transform*Board.screen(destination)
	game.battle_host._unhandled_input(click)
	game.battle_host._unhandled_input(key(KEY_ENTER))
	for i in 20: view.update(0.12)
	check(game.battle_host.combat.current().cell==destination and not game.battle_host.combat.current().acted,"Click, confirmation and walk preserve the action, as in Portugal")
	await capture("movement")
	var saw_defense := false; var saw_impact := false; var saw_victory := false
	for i in 2500:
		if game.model.phase!="boarding": break
		if view.phase=="timing_defend": saw_defense = true
		if view.phase.begins_with("animate") and view.result.get("impacted",false): saw_impact = true
		if i==15: await capture("combat")
		if game.battle_host.ending.phase=="hold" and not saw_victory:
			saw_victory = true; await capture("victory")
		drive()
	check(saw_defense and saw_impact,"A real fight includes defensive timing and impact/recovery phases")
	check(game.model.phase=="sea" and game.model.resolved.has("patrol"),"The complete turn battle is winnable and returns to the voyage")
	check(saw_victory and game.battle_host.ending.title=="CONVÉS RECUPERADO","The last impact reaches the naval victory presentation before returning to sea")
	for style in ["LA","MC","FO","PU"]:
		game.model.style = style; game.model.boarding_profile = Loadout.practice(style)
		game.begin_boarding()
		var safe_cells := true
		for i in 2500:
			if game.model.phase!="boarding": break
			for unit in game.battle_host.combat.units:
				if not game.battle_host.combat.inside(unit.cell): safe_cells = false
			drive()
		check(game.model.phase=="sea" and safe_cells,style+": the narrower deck supports a complete battle without actors entering water or the friendly ship")
	var old_chapter: Dictionary = Loadout.practice("FO"); old_chapter.vitals.hp = 62
	FileAccess.open("res://tests/boarding-chapter-kit.json",FileAccess.WRITE).store_string(JSON.stringify(old_chapter))
	Launch.mode = "campaign"; game.model.boarding_profile = {}
	game._prepare_boarding_profile("res://tests/boarding-chapter-kit.json")
	check(game.model.style=="FO" and game.model.boarding_profile.vitals.hp==62 and game.model.boarding_profile.skills.has("FO07"),"Legacy campaign voyages recover their actual kit from the chapter file without replaying Portugal")
	game.begin_boarding()
	check(game.battle_host.combat.style=="FO" and game.battle_host.combat.units[0].hp==62 and game.battle_host.combat.commands(0)==[0,1,-1],"Resumed campaign boarding uses the saved character instead of a replacement test character")
	# A real enemy strike at failed defensive timing must also complete safely.
	game.model.style = "ES"; game.model.boarding_profile = Loadout.practice()
	game.begin_boarding()
	var checkpoint: Dictionary = game.model.safe_state.duplicate(true)
	for hero in game.battle_host.combat.heroes: hero.hp = 1
	var saw_defeat := false
	for i in 500:
		if game.model.phase!="boarding": break
		var host = game.battle_host; var v = host.tactical
		if host.ending.running():
			if host.ending.phase=="hold" and not saw_defeat:
				saw_defeat = true; await capture("defeat")
			host.update_ending(0.5)
		elif v.is_player() and v.phase=="choose": v.start_facing(); v.confirm()
		elif v.phase.begins_with("timing"): v.commit_timing(0)
		else: v.update(1.8)
	check(saw_defeat and game.model.phase=="game_over" and game.model.safe_state==checkpoint,"Failed defensive timing can defeat the party, show the defeat result and preserve its safe checkpoint")
	check(progress.snapshot()==saved and profile.hero_name==name_before,"Quick testing leaves the campaign's name, equipment, vitals, learning and passives unchanged")
	var report := {"checks":checks,"failures":failures,"rendered":DisplayServer.get_name()!="headless"}
	FileAccess.open("res://tests/boarding-report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("BOARDING_RESULT ",JSON.stringify(report))
	game.queue_free(); await frames(); quit(0 if failures.is_empty() else 1)
