extends SceneTree
## Run against the current Maré de Ferro project, without editing it or saving progress.
const OUTPUT := "C:/Users/gamer/Documents/GitHub/mar-de-jade/.godot/ferro-current-"
var scene
func _initialize() -> void: call_deferred("run")
func frame(label: String) -> void:
	scene.toast_time = 0
	scene.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png(OUTPUT+label+".png")
	print("CURRENT_RENDER "+label+" "+str(result))
func run() -> void:
	scene = load("res://scenes/main.tscn").instantiate()
	scene.qa_mode = true
	root.add_child(scene)
	scene.set_process(false)
	scene.new_game(false)
	scene.localization.set_language("pt_PT")
	scene.state = "world"
	await frame("exploration")
	for encounter in ["training","lisbon_fire","cove_trial","prologue_raid"]:
		scene.begin_battle(encounter)
		scene.combat.current_id = 0
		scene.combat.order_index = scene.combat.order.find(0)
		scene.tactical.begin()
		scene.tactical.lesson = false
		scene.tactical.onboarding.active = ""
		await frame(encounter)
		scene.tactical.select_move()
		var reachable: Dictionary = scene.combat.reachable(0).costs
		for cell in reachable:
			if cell!=scene.combat.units[0].cell:
				scene.tactical.select_cell(cell)
				break
		await frame(encounter+"-move")
		scene.tactical.confirm()
		for i in 90: scene.tactical.update(1.0/60)
		await frame(encounter+"-moved")
	scene.free()
	await process_frame
	print("FERRO_CURRENT_REVIEW_COMPLETE")
	quit()
