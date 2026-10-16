extends SceneTree
var game
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func frames(n: int) -> void:
	for i in n: await process_frame
func mount(mode: String,style := "ES") -> void:
	if is_instance_valid(game): game.free(); await frames(2)
	game = load("res://scenes/art/combat_study.tscn").instantiate(); game.encounter = mode; game.style = style; root.add_child(game)
	game.host.set_process(false); await frames(3)
func run() -> void:
	root.get_node("ChapterProgress").auto_save = false
	var pauses := {}
	for style in ["ES","LA","MC","FO","PU"]:
		await mount("school",style)
		var v = game.host.tactical; var model = game.host.combat
		var origin: Vector2i = model.units[0].cell
		var hp: int = model.units[2].hp
		var predicted: int = model.predict(0,2,0,2,model.units[2].cell).damage
		v.select_skill(0); v.select_cell(model.units[2].cell); v.confirm(); v.commit_timing(2)
		v.update(0.279)
		check(model.units[2].hp==hp and not v.release_sound_played,style+": neither damage nor shot precedes release")
		v.update(0.002)
		check(v.release_sound_played==(style=="FO") and model.units[2].hp==hp,style+": firearm release precedes target damage")
		var audio_cursor: int = game.host.effect_cursor
		v.update(0.168)
		check(model.units[2].hp==hp and game.host.effect_cursor==audio_cursor,style+": no duplicate report or premature impact")
		v.update(0.002)
		check(model.units[2].hp==hp-predicted and model.units[0].cell==origin,style+": new movement preserves predicted damage and logical cell")
		pauses[style] = v.hit_pause
		var contact_clock: float = v.clock
		v.update(0.015)
		check(is_equal_approx(v.clock,contact_clock),style+": contact pose holds during hit pause")
		v.update(0.4); game.host.queue_redraw(); await frames(2)
		if style=="FO": check(v.weapon_tips.has(0) and v.weapon_tips[0].is_finite(),"Live muzzle is anchored to the rendered weapon")
		v.update(1)
		check(v.phase=="choose" and v.unit_position(0).is_equal_approx(v.screen(origin)),style+": recovery returns feet to the original cell")
	check(pauses.MC>pauses.ES and pauses.ES>pauses.PU,"Heavy blow holds longer than a cut; a jab stays quick")
	await mount("perfect_defense")
	var v = game.host.tactical
	v.start_facing(); v.facing = 0; v.confirm(); v.update(1); v.update(2); v.commit_timing(2); v.update(0.451)
	check(v.result.hits.any(func(h): return h.id==0 and h.damage==0) and v.damage_reaction(0)==0,"Perfect block stays a parry instead of playing a hurt reaction")
	check(v.hit_pause>pauses.PU,"Perfect contact gets a readable hold")
	await mount("school","MC")
	v = game.host.tactical
	game.host.progress.data.options.reduced_fx = true
	var cell: Vector2i = game.host.combat.units[0].cell
	v.select_skill(0); v.select_cell(game.host.combat.units[2].cell); v.confirm(); v.commit_timing(2); v.update(0.451)
	check(v.hit_pause<=0.025 and v.unit_position(0).distance_to(v.screen(cell))<3,"Reduced effects shorten the hold and damp body travel")
	game.host.queue_redraw(); await frames(2)
	check(v.effect_kind(0,0)=="heavy","Reduced effects preserve the actual weapon identity")
	game.free(); await frames(2)
	print("COMBAT_FEEL_RESULT ",JSON.stringify({"checks":checks,"failures":failures,"contact_holds":pauses}))
	quit(0 if failures.is_empty() else 1)
