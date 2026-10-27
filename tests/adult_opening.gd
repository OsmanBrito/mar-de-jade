extends SceneTree
var failures: Array[String] = []
var checks := 0
var game
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func frames(n: int) -> void:
	for i in n: await physics_frame
func enter() -> InputEventKey:
	var event = InputEventKey.new()
	event.keycode = KEY_ENTER; event.pressed = true
	return event
func run() -> void:
	root.get_node("ChapterProgress").auto_save = false
	root.get_node("CampaignProfile").hero_name = "Inês"
	# A real keyboard transition from the completed promise scene.
	change_scene_to_file("res://scenes/chapter_01/promise.tscn")
	await process_frame
	await process_frame
	await frames(3)
	current_scene.completed = true
	current_scene._unhandled_input(enter())
	await process_frame
	await process_frame
	await frames(40)
	check(current_scene.scene_file_path == "res://scenes/chapter_01/adult_opening.tscn","Promise connects to adult opening without null viewport")
	for branch in ["assumir","desculpar"]:
		game = current_scene
		check(game.view.body.text == game.data.segments.common[0].text and game.view.body.text.contains("primeiro serviço"),"Adult opening explains the service before the approved conversation")
		var canonical: String = FileAccess.get_file_as_string("res://docs/narrativa/C01-portugal-aprovado.md").get_slice("### S07 — A correia e o prazo",1).get_slice("### S08",0)
		var expected: Array[String] = []
		for line in canonical.split("\n"):
			if line.contains(":** "): expected.append(line.get_slice(":** ",1).strip_edges())
		var actual: Array[String] = []
		for segment in ["common","assumir","desculpar"]:
			for line in game.data.segments[segment]:
				if segment == "common" and actual.is_empty() and line.text != "A que procuras é esta.": continue
				actual.append(line.text)
		check(actual == expected and actual.size() == 19,"All adult opening lines match approved scene")
		check(game.hero.identity == "hero" and game.hero.carries_bowl == false,"Adult presentation replaces child holding bowl")
		check(game.get_node("Abrigo/ActorsAndProps/Duarte").identity == "duarte","Duarte is present")
		for i in 300:
			if game.phase == "choice": break
			if not game.busy: game.advance()
			await frames(1)
		check(game.phase == "choice" and game.sack_ready,"Common dialogue stages strap before branch")
		game.advance()
		check(game.phase == "choice","Continue cannot choose the branch")
		game.choose(branch)
		check(root.get_node("CampaignProfile").origin_response == branch,"Choice recorded in chapter state")
		var selected: String = game.segment
		game.choose("desculpar" if branch == "assumir" else "assumir")
		check(game.segment == selected,"Branch cannot be changed after selection")
		for i in 300:
			if game.completed: break
			if not game.busy: game.advance()
			await frames(1)
		check(game.completed and game.sack_position == game.get_node("SackAtDoor").position,"Both branches finish with packed bag")
		check(not game.hero.walking and game.hero.position == game.get_node("HeroAtDoor").position,"The adult walks to the door and returns to an idle pose")
		check(game.sack_position.distance_to(game.hero.position)<40,"The flour bag hangs within reach rather than floating above the adult's head")
		check(game.view.body.text.contains("pátio da Ordem"),"The departure instruction matches the first Order service")
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://tests/adult-opening-check.png")
		if branch == "assumir":
			change_scene_to_file("res://scenes/chapter_01/adult_opening.tscn")
			await process_frame
			await process_frame
			await frames(3)
	print("ADULT_OPENING_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)




