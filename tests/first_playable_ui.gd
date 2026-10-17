extends SceneTree
## Checks layout in the real campaign and live battle viewports; never writes player saves.
var checks := 0
var failures: Array[String] = []
var flow

func _initialize() -> void: call_deferred("run")
func check(value: bool,message: String) -> void:
	checks += 1
	if not value: failures.append(message); push_error(message)
func frames(count: int = 8) -> void:
	for i in count: await process_frame
func shot(name: String) -> void:
	if is_instance_valid(flow): flow.battle_host.queue_redraw()
	await frames(2)
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://previews/first-test-"+name+".png")
func dialogue_bounds() -> void:
	var view = flow.view
	var bounds: Rect2 = view.panel.get_global_rect()
	check(root.get_visible_rect().encloses(bounds),"Conversation stays inside the viewport")
	check(bounds.position.y>=120,"Conversation leaves room for the scene heading")
	check(view.body.size.x<=view.content_scroll.size.x,"Conversation text wraps within its scroll area")
	check(view.panel.size.y<=root.get_visible_rect().size.y-180,"Long choices cannot grow past the screen")

func run() -> void:
	root.get_node("ChapterProgress").auto_save = false
	root.get_node("CampaignProfile").hero_name = "Inês de Albuquerque"
	flow = load("res://scenes/chapter_01/chapter_flow.tscn").instantiate()
	root.add_child(flow); await frames()
	flow._begin_battle("school")
	flow.battle_host.set_process(false)
	await frames()
	await shot("battle")
	var host = flow.battle_host
	var view = host.tactical
	var commands: Array = host.buttons.filter(func(b): return b.id.begins_with("t_skill_"))
	check(commands.size()>=2,"Actual battle shows basic and technique commands")
	for i in host.buttons.size():
		check(Rect2(0,0,960,540).encloses(host.buttons[i].rect),"Battle command stays inside its viewport")
		for j in range(i+1,host.buttons.size()):
			check(not host.buttons[i].rect.intersects(host.buttons[j].rect),"Clickable battle commands do not overlap")
	view.select_skill(0); view.select_cell(host.combat.units[2].cell); view.confirm()
	await frames()
	await shot("timing")
	check(view.phase=="timing_attack","Real target confirmation opens attack timing")
	view.clock = view.duration*view.timing_center
	var event := InputEventMouseButton.new(); event.pressed = true; event.button_index = MOUSE_BUTTON_LEFT; event.position = Vector2(160,465)
	view.input_event(event)
	check(view.phase=="animate_player","Timing can be confirmed with the visible mouse button")
	flow.battle_container.hide(); flow.view.show()
	for block in flow.blocks:
		for action in block.events:
			if action.type=="styles": flow._show_styles(action.options)
	await frames(20)
	dialogue_bounds(); await shot("styles")
	var progress = root.get_node("ChapterProgress")
	progress.flags.recovered = true
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_01/passives.json"))
	for row in catalog.passives: progress.passives.append(row.id)
	flow._show_equipment(); await frames(20)
	dialogue_bounds(); await shot("passives")
	check(flow.options_box.get_child_count()==catalog.passives.size()+1,"Every learned passive and the return action is available")
	await shot("passives-bottom")
	flow._clear_options(); flow.view.next_button.show()
	flow.view.body.text = "A Botafogo espera no cais. ".repeat(140)
	await frames(20); dialogue_bounds(); await shot("long-conversation")
	check(flow.view.content_scroll.get_v_scroll_bar().max_value>flow.view.content_scroll.size.y,"Long conversation scrolls instead of overflowing")
	flow.view.next_button.grab_focus(); await frames(20)
	check(flow.view.content_scroll.scroll_vertical>0,"Keyboard focus scrolls to the continuation button")
	await shot("long-conversation-bottom")
	flow.free(); await frames()
	print("FIRST_PLAYABLE_UI_RESULT "+JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
