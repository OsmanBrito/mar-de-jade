extends "res://tests/combat_presentation.gd"
## Verify that visible route, target and obstruction information agrees with real input.
func refresh() -> void:
	game.host.queue_redraw(); await frames(2)
func pad(button: JoyButton) -> void:
	var event := InputEventJoypadButton.new(); event.button_index = button; event.pressed = true; root.push_input(event)
	event = event.duplicate(); event.pressed = false; root.push_input(event)
func run() -> void:
	root.get_node("ChapterProgress").auto_save = false
	root.get_node("CampaignProfile").hero_name = "Aprendiz"
	await mount("child_attack"); game.host.set_process(false)
	var v = game.host.tactical; var model = game.host.combat
	var origin: Vector2i = model.current().cell
	press(KEY_G); await refresh()
	check(v.phase=="move" and v.field_state.reachable==model.reachable(0).costs,"Move contour uses the exact reachable graph")
	click(v.screen(Vector2i(3,4))); await refresh()
	check(not v.field_state.valid and v.field_state.path.is_empty() and v.field_state.reason.contains("banco"),"Clicking a real bench shows a blocked destination without a path through it")
	check(game.host.buttons.any(func(b): return b.id=="t_confirm" and not b.enabled),"Blocked destination disables the real confirm button")
	press(KEY_ENTER); await refresh()
	check(model.current().cell==origin and model.current().moves==5,"Keyboard confirmation cannot move onto the marked obstacle")
	click(v.screen(Vector2i(7,4))); await refresh()
	check(not v.field_state.valid and v.field_state.cost>v.field_state.budget and not v.field_state.path.is_empty(),"Over-budget route exposes the full cost and its unaffordable part")
	press(KEY_ENTER); await refresh()
	check(model.current().cell==origin and model.current().moves==5,"Over-budget route cannot spend movement")
	click(v.screen(Vector2i(4,3))); await refresh()
	check(v.field_state.valid and v.field_state.cost==4 and v.field_state.path==model.path_to(0,Vector2i(4,3)),"Visible four-step detour equals the confirmed route")
	press(KEY_ENTER); await refresh()
	check(model.current().cell==Vector2i(4,3) and model.current().moves==1,"Actual move consumes exactly the displayed cost")
	v.update(1); press(KEY_Z); await refresh()
	check(model.current().cell==origin and model.current().moves==5,"Undo restores position and movement budget")
	pad(JOY_BUTTON_LEFT_SHOULDER); pad(JOY_BUTTON_DPAD_RIGHT); await refresh()
	check(v.phase=="move" and v.field_state.focus==Vector2i(3,5) and v.field_state.cost==1,"Controller navigation updates the same route markers")
	await mount("school","FO"); game.host.set_process(false); v = game.host.tactical; model = game.host.combat
	press(KEY_1); click(v.screen(model.units[2].cell)); await refresh()
	check(v.field_state.valid and v.field_state.targets.has(model.units[2].cell) and v.field_state.area==model.area(0,0,model.units[2].cell),"Valid firearm target and area use the actual attack query")
	model.units[2].cell = Vector2i(3,5)
	click(v.screen(model.units[2].cell)); await refresh()
	check(not v.field_state.valid and v.field_state.feedback.get("cell")==Vector2i(3,4),"Blocked shot points at the bench that actually interrupts the line")
	check(not v.field_state.targets.has(model.units[2].cell) and v.field_state.area.is_empty(),"Blocked shot has neither a valid-target bracket nor a promised damage area")
	var hp: int = model.units[2].hp
	press(KEY_ENTER); await refresh()
	check(model.units[2].hp==hp and v.phase=="aim","Blocked shot cannot begin offensive timing")
	model.units[2].cell = Vector2i(8,7)
	click(v.screen(model.units[2].cell)); await refresh()
	check(v.field_state.feedback.get("kind")=="range" and not v.field_state.targets.has(model.units[2].cell),"Distant target shows the actual maximum-range rejection")
	await mount("school","LA"); game.host.set_process(false); v = game.host.tactical; model = game.host.combat
	model.units[0].cell = Vector2i(4,3); v.refresh_paths()
	press(KEY_2); click(v.screen(model.units[2].cell)); await refresh()
	check(not v.field_state.valid and v.field_state.area.is_empty() and v.field_state.reason.contains("duas casas"),"Lance lesson rejects the adjacent target even inside maximum range")
	check(not v.field_state.targets.has(model.units[2].cell),"Lance restriction never gets a valid-target bracket")
	await mount("school","MC"); game.host.set_process(false); v = game.host.tactical; model = game.host.combat
	press(KEY_2); await refresh()
	check(v.field_state.valid and v.field_state.targets==[model.units[0].cell] and v.field_state.area==[model.units[0].cell],"Self preparation marks only its owner, not every battlefield cell")
	await mount("duarte_support"); game.host.set_process(false); v = game.host.tactical; model = game.host.combat
	press(KEY_2); await refresh()
	check(v.field_state.valid and v.field_state.targets==[model.units[0].cell],"Companion protection marks the actual eligible ally")
	click(v.screen(model.units[1].cell)); await refresh()
	check(not v.field_state.valid and not v.field_state.reason.contains("Inês"),"Invalid protection uses the current protagonist name instead of the reference game's name")
	await mount("child_defense"); game.host.set_process(false); v = game.host.tactical; model = game.host.combat
	press(KEY_T); press(KEY_E); await refresh()
	check(v.phase=="facing" and model.current().face!=v.facing,"Facing preview does not commit the orientation before confirmation")
	v.facing = 0; press(KEY_ENTER); v.update(1); await refresh()
	check(v.phase=="telegraph" and v.field_state.threats==v.plan.cells and v.field_state.threats.has(model.units[0].cell),"Announced strike highlights the actual threatened cells")
	game.free(); await frames(2)
	print("COMBAT_FIELD_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
