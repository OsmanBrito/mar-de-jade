extends SceneTree
const Model = preload("res://scripts/navigation/voyage_model.gd")
const Naval = preload("res://scripts/navigation/naval_battle.gd")
const Launch = preload("res://scripts/navigation/voyage_launch.gd")
var checks := 0
var failures: Array[String] = []
var game
var captures := {}
var route_seconds := 0.0
var ordinary_victory := false
var boss_victory := false
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func frames(count: int = 3) -> void:
	for i in count: await process_frame
func capture(id: String) -> void:
	if DisplayServer.get_name()=="headless": return
	if game!=null and is_instance_valid(game): game._process(0); game.view.queue_redraw(); game._refresh_status()
	await frames(3); await RenderingServer.frame_post_draw
	var path := "res://docs/navigation-"+id+".png"
	root.get_texture().get_image().save_png(path); captures[id] = path
func drive_naval(battle,dt: float = 0.1) -> void:
	var delta: Vector2 = battle.enemy-battle.player
	var distance: float = delta.length()
	var radial := delta.normalized()
	var direction := radial.orthogonal()
	if distance>350: direction = (direction+radial*1.5).normalized()
	elif distance<230: direction = (direction-radial*1.5).normalized()
	if battle.warning>0 and battle.attack_kind=="volley" and battle.player.distance_to(battle.aimed_at)<130:
		direction = (battle.player-battle.aimed_at).normalized()
		if direction==Vector2.ZERO: direction = radial.orthogonal()
	if battle.warning>0 and battle.attack_kind=="charge": direction = radial.orthogonal()
	if battle.player.x<150: direction.x = maxf(0.6,direction.x)
	if battle.player.x>1270: direction.x = minf(-0.6,direction.x)
	if battle.player.y<240: direction.y = maxf(0.6,direction.y)
	if battle.player.y>650: direction.y = minf(-0.6,direction.y)
	for side in 2:
		if battle.side_available(side) and battle.reloads[side]<=0: battle.fire(side)
	var turn := angle_difference(battle.heading,direction.angle())
	battle.helm(dt,clampf(turn/(1.7*dt),-1,1),3)
func drive_boarding() -> void:
	var b = game.battle_host.combat; var v = game.battle_host.tactical
	if v.phase in ["choose","move","aim"] and v.is_player():
		if v.phase!="choose": v.cancel()
		if b.current().acted: v.start_facing(); v.facing = b.suggested_facing(b.current_id); v.confirm(); return
		var target := -1
		var nearest := 999
		for enemy in b.enemies:
			if enemy.hp>0 and b.distance(b.current().cell,enemy.cell)<nearest: target = enemy.id; nearest = b.distance(b.current().cell,enemy.cell)
		if target<0: return
		var aim: Vector2i = b.units[target].cell
		if not b.valid_attack(0,aim):
			var best := Vector2i(-1,-1); var best_d := 999
			for cell in b.reachable(b.current_id).costs:
				if b.distance(cell,aim)<best_d: best = cell; best_d = b.distance(cell,aim)
			if best!=Vector2i(-1,-1) and best!=b.current().cell: v.select_move(); v.select_cell(best); v.confirm()
			else: v.start_facing(); v.facing = b.suggested_facing(b.current_id); v.confirm()
			return
		v.select_skill(0); v.select_cell(aim); v.confirm()
	elif v.phase.begins_with("timing"): v.commit_timing(2)
	else: v.update(1.8)

func run() -> void:
	var m = Model.new()
	check(m.water(m.position),"Departure starts in navigable water")
	for entry in m.chart.places: check(m.water(m.point(entry.pos)),"Water access to "+entry.id)
	check(not m.water(Vector2(6500,20000)),"Madeira terrain blocks navigation")
	var origin: Vector2 = m.position
	for i in 120: m.update(1.0/60.0,Vector2(-1,1).normalized())
	check(m.position.distance_to(origin)>20 and m.supplies<100,"Direct input accelerates the vessel and consumes supplies by distance")
	var still_supplies: float = m.supplies
	for i in 300: m.update(0.1,Vector2.ZERO)
	var stopped_supplies: float = m.supplies
	for i in 300: m.update(0.1,Vector2.ZERO)
	check(is_equal_approx(stopped_supplies,m.supplies) and still_supplies>=m.supplies,"An idle vessel stops consuming provisions")
	var steering = Model.new(); steering.heading = 0
	for i in 100: steering.update(0.05,Vector2.RIGHT)
	var heading_before: float = steering.heading
	steering.update(0.1,Vector2.LEFT)
	check(absf(angle_difference(heading_before,steering.heading))<0.25 and steering.velocity.x>0,"Reversing the rudder turns the ship gradually instead of reversing velocity instantly")
	for i in 100: steering.update(0.05,Vector2.LEFT)
	check(steering.velocity.x< -30 and absf(angle_difference(steering.heading,PI))<0.05,"A sustained turn completes and regains speed in the chosen direction")
	var stopping_start: Vector2 = steering.position
	for i in 80: steering.update(0.05,Vector2.ZERO)
	check(steering.velocity==Vector2.ZERO and steering.position.distance_to(stopping_start)>5,"Releasing the controls gives a short coast and then stops")
	var helm = Model.new(); helm.heading = 0
	var speeds := []
	for level in [1,2,3]:
		helm.velocity = Vector2.ZERO
		for i in 120: helm.helm(1.0/60,0,level)
		speeds.append(helm.velocity.length())
	check(speeds[0]<speeds[1] and speeds[2]>speeds[1]*1.5,"Three sail levels give distinct speeds, with a substantially faster full sail")
	var east_before: Vector2 = helm.position
	helm.helm(0.1,0,3)
	check(helm.position.x>east_before.x and is_equal_approx(helm.position.y,east_before.y),"Forward helm movement follows the bow rather than map north")
	var old_heading: float = helm.heading
	helm.helm(0.1,1,3)
	check(helm.heading>old_heading and absf(helm.velocity.normalized().cross(Vector2.from_angle(helm.heading)))<0.001,"Right rudder turns clockwise and keeps motion aligned with the keel")
	for i in 60: helm.helm(1.0/60,0,0)
	check(helm.velocity.length()<0.01,"Furling the sails stops full speed in under one second without long skating")
	var signals = Model.new(); var first_report := -1.0
	var destination: Vector2 = signals.point(signals.place("madeira").pos)
	for i in 300:
		signals.update(0.1,(destination-signals.position).normalized())
		if not signals.observed_signals.is_empty(): first_report = signals.elapsed; break
	check(first_report>0 and first_report<30,"A natural observation introduces the first discovery in under thirty seconds")
	var count: int = signals.observed_signals.size()
	for i in 20: signals.update(0.1,Vector2.ZERO)
	check(signals.observed_signals.size()==count,"The same sea sign is not repeatedly rediscovered while stopped")
	var retained = Model.new()
	check(retained.restore(signals.snapshot()) and retained.observed_signals==signals.observed_signals,"Observed signs persist in safe voyage checkpoints")
	var legacy: Dictionary = signals.snapshot(); legacy.erase("observed_signals")
	check(retained.restore(legacy),"Voyage saves from before the polish still load")
	var recovering = Model.new(); recovering.position = Vector2(2200,14000); recovering.heading = PI; recovering.danger = 45
	var risk_before: float = recovering.risk_at(recovering.position)
	var safety: Vector2 = recovering.safety_target()
	for i in 240: recovering.update(0.1,(safety-recovering.position).normalized())
	check(recovering.risk_at(recovering.position)<risk_before and recovering.hull==100,"The suggested recovery direction really leads out of heavy seas")
	var route = Model.new()
	var target: Vector2 = route.point(route.place("madeira").pos)
	for i in 7000:
		if route.position.distance_to(target)<120: break
		route.update(0.1,(target-route.position).normalized())
	check(route.position.distance_to(target)<120,"Lisboa–Madeira can be sailed through actual water without teleportation")
	route_seconds = route.elapsed
	check(route.elapsed>350 and route.elapsed<650,"Direct sailing duration leaves room for activities around the ten-minute target")
	check(route.supplies>75 and route.hull==100,"Main trip and reasonable detours have a generous provision budget")
	var save := m.snapshot(); var restored = Model.new()
	check(restored.restore(save) and restored.position.is_equal_approx(m.position),"Voyage snapshot round trip")
	check(restored.traffic==m.traffic,"Moving vessels retain their positions across loading")
	var invalid := save.duplicate(true); invalid.position = [6500,20000]
	check(not restored.restore(invalid) and restored.position.is_equal_approx(m.position),"Land-position saves are rejected without mutating live state")
	invalid = save.duplicate(true); invalid.hull = "broken"
	check(not restored.restore(invalid),"Invalid resource types are rejected")
	invalid = save.duplicate(true); invalid.traffic = []
	check(not restored.restore(invalid),"Malformed vessel state is rejected before assignment")
	var reinforced = Model.new(); reinforced.upgrades.hull = true; reinforced.position = Vector2(2200,15000)
	check(restored.restore(reinforced.snapshot()),"A reinforced ship can reload its legitimately extended safe range")
	var path := "res://tests/navigation-fixture.json"
	m.phase = "sea"; m.danger = 0; m.position = origin
	check(m.save_to(path)==OK,"Safe voyage saves successfully")
	m.hull = 10; m.position = Vector2(500,17000); m.danger = 80
	check(m.save_to(path)==ERR_BUSY,"Unsafe sailing cannot replace the safe checkpoint")
	check(restored.load_from(path)==OK and restored.hull>25,"Safe checkpoint remains usable after rejected save")
	var risk = Model.new(); risk.position = Vector2(700,14000)
	var warnings := 0
	for i in 1500:
		warnings += risk.update(0.1,Vector2.ZERO).size()
		if risk.phase=="game_over": break
	check(warnings>=2 and risk.phase=="game_over","Unprepared ocean crossing warns before lethal failure")
	var retreating = Model.new(); retreating.position = Vector2(2200,14000)
	for i in 100: retreating.update(0.1,Vector2.RIGHT)
	check(retreating.hull==100 and retreating.danger<75,"Timely retreat avoids lethal damage")
	var exploration = Model.new(); var coins: int = exploration.coins
	exploration.investigate("cargo"); var once: int = exploration.coins
	exploration.investigate("cargo")
	check(once>coins and exploration.coins==once,"Salvage pays once")
	exploration.investigate("castaway")
	check(exploration.resolved.has("castaway"),"Rescue persists independently of the chapter")
	for id in ["current_1","current_2","current_3"]: exploration.investigate(id)
	check(exploration.route_known and exploration.route_marks.size()==3,"Observation of the three marks discovers a route")
	exploration.dock("madeira"); exploration.hull = 40; exploration.supplies = 35
	exploration.buy("supplies"); exploration.buy("repair")
	check(exploration.supplies==75 and exploration.hull==85,"Port preparation restores meaningful resources")
	exploration.coins = 100; exploration.buy("pilot"); coins = exploration.coins; exploration.buy("pilot")
	check(exploration.upgrades.has("pilot") and coins==exploration.coins,"Specialists cannot be charged twice")
	exploration.coins = 100; exploration.buy("chart"); exploration.investigate("castaway")
	check(exploration.discovered.current_1=="explored","Buying a chart never downgrades a personally explored route marker")
	var battle = Naval.new(); battle.begin(false,100,false)
	battle.heading = 0; battle.player = Vector2(400,400); battle.enemy = Vector2(700,400)
	check(not battle.fire(0) and not battle.fire(1),"Cannons require a broadside, not a forward shot")
	battle.enemy = Vector2(400,650)
	var first_shot: bool = battle.fire(1)
	var second_shot: bool = battle.fire(1)
	print("RELOAD_CHECK ",first_shot," ",second_shot," ",battle.reloads," ",battle.note)
	check(first_shot and not second_shot,"Broadside fires and reload prevents continuous fire")
	for boss in [false,true]:
		battle = Naval.new(); battle.begin(boss,100,true)
		for i in 4500:
			if battle.state!="active": break
			drive_naval(battle)
		if boss: boss_victory = battle.state=="disabled"
		else: ordinary_victory = battle.state=="disabled"
		check(battle.state=="disabled","A moving vessel can defeat "+("the charging boss" if boss else "an ordinary ship")+" without modifying health")
		print("NAVAL_SIM ",boss," ",battle.state," hull=",battle.hull," time=",battle.clock)
	battle = Naval.new(); battle.begin(true,100,false)
	for i in 2000:
		if battle.state!="active": break
		battle.update(0.1,Vector2.ZERO)
	check(battle.state=="defeat","Ignoring the boss telegraphs can sink the player vessel")
	var chapter = root.get_node("ChapterProgress"); var profile = root.get_node("CampaignProfile")
	var chapter_before: Dictionary = chapter.snapshot(); var name_before: String = profile.hero_name
	check(change_scene_to_file("res://scenes/chapter_01/name_entry.tscn")==OK,"Initial menu loads")
	await frames()
	var shortcut: Button = current_scene.get_node("Center/Card/Margin/Content/NavigationQuickStart")
	check(shortcut!=null and not shortcut.disabled,"Quick navigation shortcut works without entering a name")
	await capture("menu")
	# Exercise the actual menu action, disabling live autosave before _ready.
	var isolate := func(node):
		if node.scene_file_path==Launch.SCENE: node.auto_save = false
	root.child_entered_tree.connect(isolate)
	shortcut.pressed.emit(); await frames(5)
	root.child_entered_tree.disconnect(isolate)
	game = current_scene
	check(game.scene_file_path==Launch.SCENE,"Quick shortcut actually opens the voyage scene")
	if game.battle_host==null: push_error("Voyage scene failed to initialize; stopping to avoid cascading errors."); quit(1); return
	game.clear_overlay()
	game.set_process(false)
	check(chapter.snapshot()==chapter_before and profile.hero_name==name_before,"Quick test preserves campaign identity and chapter progress")
	var input_start: Vector2 = game.model.position
	game.model.heading = PI; game.sail_level = 0
	Input.action_press("move_up"); game._process(0.2); game._process(0.2); Input.action_release("move_up"); game._process(0.1)
	check(game.model.position.x<input_start.x and absf(game.model.position.y-input_start.y)<0.01 and game.sail_level==1,"W raises one sail level while held, advancing along the bow instead of north")
	var momentum_before: Vector2 = game.model.position
	game._process(0.2)
	check(game.model.position.distance_to(momentum_before)>1 and game.sail_level==1,"Releasing W keeps the selected sail level and forward motion")
	for i in 2:
		Input.action_press("move_up"); game._process(0.1); Input.action_release("move_up"); game._process(0.1)
	check(game.sail_level==3,"Separate W taps reach full sail")
	Input.action_press("move_down"); game._process(0.1); Input.action_release("move_down"); game._process(0.1)
	check(game.sail_level==2,"S lowers sail level instead of steering south")
	game.stop_sailing(); game._process(1)
	check(game.sail_level==0 and game.model.velocity==Vector2.ZERO,"Space stop cancels the course and furls all sails")
	check(game.perspective.camera.projection==Camera3D.PROJECTION_PERSPECTIVE,"Voyage uses a real perspective camera")
	var camera_forward: Vector3 = -game.perspective.camera.global_basis.z
	check(camera_forward.y< -0.1 and camera_forward.y> -0.4,"The chase camera looks ahead at a shallow angle, leaving the horizon visible")
	var world_pick: Vector2 = game.perspective.sea_point(game.perspective.screen_point(game.model.position))
	check(world_pick.distance_to(game.model.position)<20,"Perspective screen picking returns the corresponding water location")
	check(not game.model.water(game.perspective.sea_point(Vector2(720,130))),"Clicking the sky cannot set a water course")
	var bow: Vector2 = game.model.position+Vector2.from_angle(game.model.heading)*800
	check(game.perspective.screen_point(bow).y<game.perspective.screen_point(game.model.position).y,"Water ahead of the bow appears ahead of the ship on screen")
	await capture("sea")
	game.model.position = game.model.point(game.model.place("madeira").pos)+Vector2(1800,-400)
	game.model.heading = PI; game.sail_level = 3; game._process(0); await capture("horizon")
	game.model.position = input_start; game.model.heading = 2.45; game.sail_level = 0; game._process(0)
	game.open_chart(); await capture("chart"); game.clear_overlay()
	var original_position: Vector2 = game.model.position
	game.model.position = game.model.point(game.model.chart.signals[0].pos)+Vector2(300,-200)
	game._sail(0.1,Vector2.ZERO)
	check(game.model.observed_signals.has("departing_birds"),"The visible bird flight triggers its corresponding lookout report")
	await capture("signals")
	if DisplayServer.get_name()!="headless": check(game.ambience.effects.size()==10 and game.ambience.sea.playing and game.ambience.music[0].playing,"Maritime layers and supplied soundtrack load and play in the rendered game")
	game.model.position = game.model.point(game.model.place("cargo").pos)+Vector2(620,-300)
	game.model.heading = (game.model.point(game.model.place("cargo").pos)-game.model.position).angle()
	game.model.velocity = Vector2.ZERO; game.set_course("madeira"); game.mark_contact("cargo")
	var course_back: Vector2 = game.return_course
	for i in 650:
		game._sail(0.05,Vector2.ZERO)
		if game.waypoint==Vector2.ZERO and game.model.velocity.length()<1: break
	check(game.model.closest().get("id","")=="cargo" and game.model.velocity.length()<2,"Approach course slows down and stops inside interaction range")
	await capture("approach")
	game.interact(); check(game.overlay=="discovery" and game.model.resolved.has("cargo"),"Investigating the approached contact presents the discovery result")
	await capture("discovery"); game.clear_overlay(); game.resume_course()
	check(game.waypoint==course_back and game.focus_id.is_empty(),"Resuming after discovery restores the original destination")
	game.change_sails(-1); check(game.sail_level==1,"Manoeuvring sail can be selected for observation and docking")
	game.change_sails(1); game.waypoint = Vector2.ZERO; game.model.position = original_position; game.model.velocity = Vector2.ZERO
	game.model.position = Vector2(2200,14000); game.model.danger = 45; game.resume_course()
	game._process(0)
	check(game.waypoint.x>game.model.position.x and not game.model.blocked_by_coast,"Retreat remains marked through a zero-duration frame without a false coast collision")
	await capture("danger")
	game.model.position = original_position; game.model.danger = 0; game.waypoint = Vector2.ZERO
	var p: Vector2 = game.model.position; var s: float = game.model.supplies
	game.enter_deck(); game._process(5)
	check(game.model.position==p and game.model.supplies==s,"Walking the deck pauses sailing and provision use")
	game._walk(0.5,Vector2.LEFT); check(game.walker.x<700,"Deck walking is playable")
	await capture("deck"); game.leave_stage()
	game.model.position = game.model.point(game.model.place("castaway").pos); game.interact(); game.clear_overlay(); game.enter_deck()
	check(game.stage_people().any(func(person): return person.id=="injured_worker"),"Rescued sailor appears on deck")
	game.leave_stage(); game.model.position = game.model.point(game.model.place("madeira").pos); game.interact(); game.clear_overlay()
	check(game.model.phase=="port" and game.model.made_landfall,"Madeira allows landing and remains freely explorable")
	await capture("madeira")
	game.leave_stage(); game.model.position = game.model.point(game.model.place("desertas").pos); game.interact(); game.clear_overlay()
	check(game.model.phase=="island" and game.stage_people().size()==2,"Uninhabited island uses an exploration cove rather than port services")
	await capture("island")
	game.leave_stage(); game.model.position = game.model.point(game.model.place("madeira").pos); game.interact(); game.clear_overlay()
	game.open_services(false); await capture("services"); game.clear_overlay()
	game.model.coins = 0; game.model.hull = 20; game.model.supplies = 5; game.walker = Vector2(350,660); game.interact(); game.clear_overlay()
	check(game.model.hull>=65 and game.model.supplies>=65 and game.model.coins==30,"One-time dock service prevents an economy softlock")
	game.leave_stage(); game.model.hull = 100
	game.begin_naval(game.model.place("boss")); game.clear_overlay()
	game.naval.update(2.1,Vector2.UP); game.naval.update(0.1,Vector2.UP)
	await capture("boss")
	game.open_orders(); var battle_clock: float = game.naval.clock; var battle_hull: float = game.naval.hull
	game._process(5)
	check(game.naval.clock==battle_clock and game.naval.hull==battle_hull,"Order pause freezes naval attacks, movement and reloads")
	await capture("orders"); game.clear_overlay()
	# A real ordinary victory, followed by the actual tactical approach pipeline.
	game.begin_naval(game.model.place("patrol")); game.clear_overlay()
	for i in 5000:
		if game.naval.state!="active": break
		drive_naval(game.naval)
	check(game.naval.state=="disabled","Integrated encounter reaches the approach decision")
	game.model.hull = game.naval.hull; game._naval_victory(); game.clear_overlay(); game.begin_boarding()
	await frames(); await capture("boarding")
	for i in 2000:
		if game.model.phase!="boarding": break
		drive_boarding(); await frames(1)
	check(game.model.phase=="sea" and game.model.resolved.has("patrol"),"Tactical approach is winnable and returns to sailing with the encounter resolved")
	check(game.model.encounter().is_empty(),"Returning from combat does not immediately trigger the same contact")
	game.model.safe_state = game.model.snapshot(); game.model.safe_state.phase = "sea"; game.model.safe_state.hull = 80; game.save_path = "res://tests/navigation-missing-save.json"
	game.game_over("Teste de recuperação"); game.clear_overlay(); game.restore_safe()
	check(game.model.phase=="sea" and game.model.hull==80,"Game over can recover the in-memory safe checkpoint")
	check(game.sail_level==0 and game.waypoint==Vector2.ZERO,"Loading a safe checkpoint resumes with furled sails and no stale autopilot")
	check(chapter.snapshot()==chapter_before and profile.hero_name==name_before,"Sailing, purchases and approach preserve Portugal's save state")
	var report := {"checks":checks,"failures":failures,"first_observation_seconds":first_report,"direct_sailing_seconds":route_seconds,"ordinary_victory":ordinary_victory,"boss_victory":boss_victory,"rendered":DisplayServer.get_name()!="headless","captures":captures}
	var file := FileAccess.open("res://tests/navigation-report.json",FileAccess.WRITE); file.store_string(JSON.stringify(report,"\t")); file.close()
	print("NAVIGATION_RESULT ",JSON.stringify(report))
	game.queue_free(); await frames(); quit(0 if failures.is_empty() else 1)
