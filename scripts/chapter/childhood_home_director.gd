extends Node
## New campaign opening: a lived-in home discovered through the child's movement.
signal scene_finished(scene_id: String)
const Plan = preload("res://scripts/chapter/childhood_home_plan.gd")
const Transition = preload("res://scripts/chapter/scene_transition.gd")
var phase := "explore"
var paused := false
var completed := false
var world
var view
var display: SubViewportContainer
var viewport: SubViewport
var choices: VBoxContainer
var dialogue: Array = []
var cursor := -1
var after := ""
var pending := ""
var battle_container: SubViewportContainer
var battle_host
var _save_clock := 0.0
var ambient_line := ""
var ambient_seconds := 0.0
var progress:
	get:return get_node("/root/ChapterProgress")

func _ready() -> void:
	if CampaignProfile.hero_name.is_empty():
		CampaignProfile.name_entry_destination=Plan.SCENE
		get_tree().change_scene_to_file.call_deferred("res://scenes/chapter_01/name_entry.tscn");return
	if not InputMap.has_action("move_left"):
		var bindings=preload("res://scripts/main.gd").new();bindings.configure_input();bindings.free()
	preload("res://scripts/chapter/childhood_pacing.gd").install(self)
	display=SubViewportContainer.new();display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	display.stretch=true;display.stretch_shrink=2;display.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	display.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(display)
	viewport=SubViewport.new();viewport.world_3d=World3D.new();viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d=Viewport.MSAA_DISABLED;display.add_child(viewport)
	world=preload("res://scripts/chapter/childhood_home_world.gd").new();viewport.add_child(world)
	var saved: Dictionary=progress.journey.duplicate(true)
	if saved.get("kind","")=="childhood_home":
		var at:=Vector2(saved.position[0],saved.position[1])
		if world.clear(at):world.player.position=Vector3(at.x,0,at.y);world.follow_camera(1,true)
	view=preload("res://scripts/chapter/dialogue_view.gd").new();add_child(view)
	view.independent_exploration_hud=true
	view.caption_label.text="Lisboa · Infância\nA casa onde cresceste"
	view.continuation_requested.connect(advance);view.replay_button.hide();view.guide.enabled=false
	choices=VBoxContainer.new();view.body.get_parent().add_child(choices);choices.hide()
	_create_battle()
	preload("res://scripts/chapter/childhood_menu.gd").install(self)
	progress.entry_scene=Plan.SCENE
	# The child already keeps his bowl in the approved opening. Carrying it
	# directly to the table avoids starting with an object-fetch tutorial.
	if not progress.flags.get("home_welcome",false):progress.flags.home_bowl=true
	if progress.flags.get("home_meal",false):world.target_tome=Vector2(-5.9,10.5)
	world.carried_bowl.visible=progress.flags.get("home_bowl",false) and not progress.flags.get("home_meal",false)
	world.waiting_bowl.visible=not progress.flags.get("home_bowl",false)
	resume()
	if not progress.flags.get("home_welcome",false):
		talk([["Tomé","Estão a chamar para comer."],["Herói criança","Já tenho esta."],["Tomé","Então traz. A Leonor passou por cá. Está à tua espera."]],"flag:home_welcome")
	save();Transition.reveal(self)

func objective() -> String:return Plan.objective(progress.flags)

func places() -> Dictionary:
	var result: Dictionary=Plan.PLACES.duplicate(true)
	var tome: Node3D=world.actors.tome_young
	result.tome.at=Vector2(tome.position.x,tome.position.z)
	if progress.flags.get("home_bowl",false):result.erase("bowl")
	return result

func resume() -> void:
	phase="explore";world.enabled=true;pending=""
	view.show();view.panel.hide();view.next_button.hide();choices.hide()
	view.hint.text="WASD / setas · caminhar     Clique · aproximar e interagir     E / A · interagir     J / Y · caderno     Esc / Start · menu"
	var focus=get_viewport().gui_get_focus_owner()
	if focus!=null:focus.release_focus()

func talk(rows: Array, then: String = "resume") -> void:
	phase="dialogue";pending="";world.enabled=false;world.stop();dialogue=rows;cursor=-1;after=then
	view.show();view.panel.show();view.next_button.show();view.next_button.text="Continuar";choices.hide()
	view.status.text="";view.hint.text="Enter / espaço / A · continuar     Esc / Start · menu";advance()

func advance() -> void:
	if paused or phase!="dialogue":return
	cursor+=1
	if cursor<dialogue.size():
		view.speaker.text=CampaignProfile.speaker_name(dialogue[cursor][0]);view.body.text=dialogue[cursor][1]
		view.remember(view.speaker.text,view.body.text);view.next_button.grab_focus();return
	if after.begins_with("flag:"):
		progress.flags[after.trim_prefix("flag:")]=true
		if after=="flag:home_welcome":world.target_tome=Vector2(-5.9,10.5)
		if after=="flag:home_meal":
			progress.flags.home_bowl=true;world.carried_bowl.hide();world.waiting_bowl.hide();world.target_tome=Vector2(-5.9,10.5)
		save()
	elif after=="practice":offer_practice();return
	elif after=="leave":depart();return
	resume()

func focus() -> String:
	var result:="";var best:=1.3
	for id in places():
		var at: Vector2=places()[id].at
		var distance: float=world.point().distance_to(at)
		if distance<best and world.segment_clear(world.point(),at):result=id;best=distance
	return result

func interact(id: String = "") -> void:
	if paused or phase!="explore":return
	if id.is_empty():id=focus()
	if not places().has(id):return
	var at: Vector2=places()[id].at
	# Neither remote calls nor a click may bypass approaching the person or object.
	if world.point().distance_to(at)>1.3 or not world.segment_clear(world.point(),at):return
	match id:
		"bowl":
			progress.flags.home_bowl=true;world.carried_bowl.show();world.waiting_bowl.hide();save()
			talk([["Herói criança","Ainda está aqui."]])
		"tome":
			if not progress.flags.get("home_tome",false):
				talk([["Herói criança","O meu pai vem buscar-me?"],["Tomé","Hoje não veio."],["Herói criança","Tu vais sair?"],["Tomé","Vou comer. Vens comigo?"],["Herói criança","E amanhã?"],["Tomé","Amanhã também cá estou."]],"flag:home_tome")
			elif not progress.flags.get("home_meal",false):talk([["Tomé","O teu lugar está ali. Anda, antes que arrefeça."]])
			else:talk([["Tomé","A Leonor passou por cá. Disse que ia esperar-te à saída."],["Herói criança","Já vou."],["Tomé","Leva água."]])
		"table":
			if progress.flags.get("home_meal",false):talk([["Tomé","Se tens fome, ainda há um bocadinho."]]);return
			# Older saves may resume before picking up the bowl. Sitting down
			# still works; presentation and flags reconcile at the meal's end.
			var rows: Array=[["Tomé","Põe aqui. Chega-te mais para a mesa."],["Herói criança","E se amanhã não houver?"],["Tomé","Hoje há. Come enquanto está quente."]]
			if not progress.flags.get("home_bowl",false):rows[0]=["Tomé","Senta-te. Tenho aqui uma tigela para ti."]
			if not progress.flags.get("home_tome",false):
				rows.append_array([["Herói criança","O meu pai vem buscar-me?"],["Tomé","Hoje não veio."],["Herói criança","Tu vais sair?"],["Tomé","Agora? Não. Fico aqui contigo."],["Herói criança","E amanhã?"],["Tomé","Amanhã também cá estou."]]);progress.flags.home_tome=true
			talk(rows,"flag:home_meal")
		"child":
			if progress.flags.get("home_eyes",false):talk([["Criança","Vais à praça? Se vires a minha caneca, trazes?"]]);return
			talk([["Herói criança","Estás a olhar para quê?"],["Criança","Os teus olhos... Um é azul e o outro é verde."],["Herói criança","Eu sei."],["Criança","Estava só a ver. Vens?"],["Herói criança","Daqui a pouco."]],"flag:home_eyes")
		"stone":
			talk([["Herói criança","Esta cruz é diferente."],["Frei da casa","É mais antiga. Já estava aí antes de eu chegar."],["Herói criança","De quem era?"],["Frei da casa","Dos templários. Um dia destes conto-te. Agora deixa-me acabar de arrumar isto."]],"flag:home_stone")
		"voyage":
			talk([["Trabalhador","Cuidado com a corda. Ainda falta apertar esse caixote."],["Herói criança","Isto vai tudo no barco?"],["Trabalhador","Isto e mais o que está no armazém."],["Herói criança","Os cavaleiros também vão?"],["Trabalhador","Alguns. Os outros ficam. Alguém tem de tomar conta disto."]],"flag:home_voyage")
		"practice":
			talk([["Cavaleiro","Queres experimentar?"],["Herói criança","Posso?"],["Cavaleiro","A vara pequena. E dá espaço a quem está a treinar."]],"practice")
		"leonor":
			if not progress.flags.get("home_meal",false):talk([["Leonor criança","O frei está à tua espera. Vai comer. Depois vens ter comigo."]]);return
			talk([["Leonor criança","Vens à praça? Vou buscar as coisas."],["Herói criança","Vou."],["Leonor criança","Então traz a água."]],"leave")

func offer_practice() -> void:
	phase="choice";view.next_button.hide();choices.show()
	for node in choices.get_children():node.free()
	for row in [["Experimentar o alvo","practice"],["Ficar a ver","watch"]]:
		var button:=Button.new();button.text=row[0];choices.add_child(button)
		button.pressed.connect(choose_practice.bind(row[1]))
	choices.get_child(0).grab_focus()

func choose_practice(option: String) -> void:
	if phase!="choice" or paused:return
	if option=="watch":resume();return
	if option!="practice":return
	phase="battle";world.enabled=false;world.stop();view.hide();battle_container.show()
	battle_host.begin(0,CampaignProfile.hero_name)
	battle_host.combat.caption="Uma primeira tentativa · O alvo do pátio"
	battle_host.note="Aproxima-te do alvo e experimenta dois golpes. É um treino seguro; podes sair pelo menu de pausa."

func _create_battle() -> void:
	var layer:=CanvasLayer.new();layer.layer=10;add_child(layer)
	battle_container=SubViewportContainer.new();battle_container.stretch=true;layer.add_child(battle_container)
	preload("res://scripts/combat/battle_stage.gd").install(layer,battle_container)
	var battle_view:=SubViewport.new();battle_view.world_2d=World2D.new();battle_view.size=Vector2i(960,540);battle_container.add_child(battle_view)
	battle_host=preload("res://scripts/combat/battle_host.gd").new();battle_host.allow_practice_exit=true;battle_view.add_child(battle_host)
	battle_host.lesson_completed.connect(_practice_finished)
	battle_host.practice_aborted.connect(func():battle_container.hide();resume())
	get_viewport().size_changed.connect(_resize);_resize();battle_container.hide()

func _resize() -> void:
	preload("res://scripts/combat/battle_stage.gd").fit(battle_container,get_viewport().get_visible_rect().size)

func _practice_finished(success: bool) -> void:
	battle_container.hide()
	if success:
		progress.flags.home_practice=true;save()
		talk([["Cavaleiro","Está bem. Pousa-a ali, com as outras."],["Herói criança","Só mais uma vez."],["Cavaleiro","Podes voltar. O alvo fica cá."]])
	else:resume()

func save() -> void:
	if not is_instance_valid(world) or completed:return
	var at: Vector2=world.point()
	progress.journey={"kind":"childhood_home","target":0,"event":-1,"stage":"","area":"home","position":[snappedf(at.x,.01),snappedf(at.y,.01)]}
	progress.entry_scene=Plan.SCENE
	if progress.auto_save:progress.save_to()

func depart() -> void:
	completed=true;phase="leaving";world.enabled=false;world.stop()
	progress.flags.home_departed=true;progress.journey.clear()
	progress.enter_scene("res://scenes/chapter_01/plaza.tscn")
	scene_finished.emit("C01-HOME")
	Transition.travel(get_tree(),"res://scenes/chapter_01/plaza.tscn")

func _process(delta: float) -> void:
	if paused or not is_instance_valid(world) or phase!="explore":return
	ambient_seconds=maxf(0,ambient_seconds-delta)
	if progress.flags.get("home_meal",false) and world.point().y<4.5 and not progress.flags.get("home_cloister",false):
		progress.flags.home_cloister=true;ambient_line="Do pátio chega uma voz: «Outra vez. Sem baixar a guarda!»";ambient_seconds=5.5;save()
	view.caption_label.text="Lisboa · Infância · "+Plan.title(world.point())
	var id:=focus()
	var prompt: String="E / A · "+str(places()[id].title) if not id.is_empty() else ambient_line if ambient_seconds>0 else ""
	view.set_exploration_prompt(objective(),prompt)
	if not pending.is_empty():
		if Input.get_vector("move_left","move_right","move_up","move_down").length()>.1:pending=""
		elif focus()==pending:var selected:=pending;pending="";interact(selected)
		elif world.destination_path.is_empty():pending=""
	_save_clock+=delta
	if _save_clock>4:_save_clock=0;save()

func click(screen: Vector2) -> void:
	var local:=screen/display.size*Vector2(viewport.size)
	var origin: Vector3=world.camera.project_ray_origin(local)
	var direction: Vector3=world.camera.project_ray_normal(local)
	var hit: Variant=Plane(Vector3.UP,0).intersects_ray(origin,direction)
	if hit==null:return
	var at:=Vector2(hit.x,hit.z);var best:=1.2;var selected:=""
	for id in places():
		var distance: float=at.distance_to(places()[id].at)
		if distance<best:best=distance;selected=id
	pending=""
	if not selected.is_empty():
		if focus()==selected:interact(selected)
		elif world.walk_to(places()[selected].at):pending=selected
	else:world.walk_to(at)

func _input(event: InputEvent) -> void:
	if paused or phase!="dialogue":return
	if event.is_action("ui_accept"):
		get_viewport().set_input_as_handled()
		if event.is_action_pressed("ui_accept"):advance()

func _unhandled_input(event: InputEvent) -> void:
	if paused or phase!="explore":return
	if event.is_action_pressed("interact"):interact();get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		click(event.position);get_viewport().set_input_as_handled()
