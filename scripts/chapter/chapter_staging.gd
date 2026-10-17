extends Node2D
## Scene-specific choreography and framing; story facts remain in ChapterProgress.
signal beat_changed(id: String)
const Actor = preload("res://scripts/chapter/actor_proxy.gd")
const Walk = preload("res://scripts/chapter/staged_walk.gd")
const Instrument = preload("res://scripts/chapter/staged_instrument.gd")
var director
var world
var camera: Camera2D
var subjects: Array = []
var framed := false
var audience: Array = []
var beats: Array[String] = []
var beat := ""
var effects
var voices: Array[AudioStreamPlayer] = []
var voice_index := 0
var drop_count := 0
var rescue

func _ready() -> void:
	world = get_parent()
	camera = Camera2D.new(); camera.name = "SceneCamera"; camera.enabled = false; add_child(camera)
	effects = preload("res://scripts/chapter/staged_contact.gd").new()
	effects.z_index = 8; world.add_child(effects)
	for i in 3:
		var voice := AudioStreamPlayer.new(); voice.volume_db = -23; voice.bus = GamePreferences.effects_bus; add_child(voice); voices.append(voice)

func configure(kind: String,id: String) -> void:
	if kind=="plaza":
		var cargo = world.sorted_world.get_node_or_null("Obstacle")
		if cargo!=null: cargo.position = Vector2(-350,215)
	if kind=="plaza" and id=="C01-M03/S01":
		director.actors.Mestre.position = Vector2(-90,205)
		director.actors.Combatente.position = Vector2(85,205)
		director.actors.Leonor.position = Vector2(215,310)
		world.player.position = Vector2(-180,390)
		director.actors.Duarte.position = Vector2(-260,385)
		world.player.presentation.facing = 2; director.actors.Duarte.facing = 2
		var group := Node2D.new(); group.name = "PublicAudience"; group.y_sort_enabled = true
		world.sorted_world.add_child(group)
		var people := [["worker",Vector2(-235,145)],["dock_woman",Vector2(-150,130)],["observer",Vector2(50,130)],["family",Vector2(240,150)],["attendant",Vector2(285,285)],["worker",Vector2(155,415)]]
		for spec in people:
			var person := Actor.new(); person.npc_id = spec[0]; person.position = spec[1]
			var direction: Vector2 = Vector2(0,205)-person.position
			person.facing = (3 if direction.x>0 else 1) if absf(direction.x)>absf(direction.y)*1.15 else (0 if direction.y>0 else 2)
			group.add_child(person); audience.append(person)
		frame([director.actors.Mestre,director.actors.Combatente],1.65)
	elif kind=="room" and ChapterProgress.flags.get("injured",false):
		var old_seat = world.sorted_world.get_node_or_null("TomeSeat")
		if old_seat!=null: old_seat.free()
		var tome = director.actors["Tomé"]
		tome.position = world.player.position+Vector2(95,35); tome.facing = 1
		world.player.presentation.facing = 3
		frame([world.player,tome],2.0)
	elif kind=="plaza":
		if id=="C01-M03/S02":
			world.player.position = Vector2(23,367); director.actors.Leonor.position = Vector2(106,366)
			world.player.presentation.posture = "seated"; director.actors.Leonor.posture = "seated"
			world.player.presentation.facing = 3; director.actors.Leonor.facing = 1
		if id=="C01-M03/S06": frame([world.player,director.actors.Duarte],1.9)
		elif director.actors.Leonor.visible: frame([world.player,director.actors.Leonor],2.0 if id in ["C01-M03/S02","C01-M03/S04","C01-M03/S05"] else 1.65)
	elif kind=="service": frame([world.player,director.actors.Leonor],1.85)
	elif kind=="deck": frame([world.player,director.actors.Rodrigo,director.actors.Beatriz],1.35)
	elif kind=="cais" and director.scene_index in [1,2,3]:
		director.actors.Trabalhador.position = Vector2(665,860)
		rescue = preload("res://scripts/chapter/rescue_setting.gd").new(); rescue.name = "RescueSupport"
		rescue.position = director._point("object"); world.sorted_world.add_child(rescue)
		rescue.supported = ChapterProgress.flags.get("cargo_freed",false); rescue.lifted = 1.0 if rescue.supported else 0.0
		if rescue.supported: director.actors["Trabalhador ferido"].position += Vector2(35,35)
		if ChapterProgress.flags.get("patient_helped",false): director.actors["Trabalhador ferido"].hide()
		frame([world.player,director.actors["Trabalhador ferido"],director.actors.Duarte],1.8)

func frame(people: Array,zoom: float) -> void:
	subjects = people; framed = true
	camera.zoom = Vector2.ONE*zoom; camera.position = focus_point()
	camera.enabled = true; camera.make_current()

func focus_point() -> Vector2:
	var center := Vector2.ZERO; var count := 0
	for person in subjects:
		if is_instance_valid(person) and person.visible: center += person.position; count += 1
	return center/maxi(1,count)+Vector2(0,70)

func set_control_locked(locked: bool) -> void:
	if not framed: return
	camera.enabled = locked
	if locked: camera.make_current()
	else: world.player.camera.enabled = true; world.player.camera.make_current()

func _process(delta: float) -> void:
	if camera.enabled and framed: camera.position = camera.position.lerp(focus_point(),1.0-exp(-delta*5))

func mark(id: String) -> void:
	beat = id; beats.append(id); beat_changed.emit(id)

func support_cargo() -> void:
	rescue.supported = true; rescue.queue_redraw()
	director.actors.Duarte.posture = "crouched"
	mark("cargo_supported"); sound("footstep_wood",-29); await wait(0.5)

func lift_cargo() -> void:
	director.view.panel.hide(); world.player.presentation.posture = "crouched"
	mark("cargo_lift_together"); sound("creak",-23,0.9,true)
	var tween := create_tween(); tween.tween_property(rescue,"lifted",1.0,1.15)
	await tween.finished
	var patient = director.actors["Trabalhador ferido"]
	await move(patient,patient.position+Vector2(35,35),45)
	world.player.presentation.posture = "standing"; director.actors.Duarte.posture = "standing"
	mark("worker_freed"); await wait(0.45)

func perceive_injury() -> void:
	var patient = director.actors["Trabalhador ferido"]
	rescue.wound = patient.position-rescue.position+Vector2(5,-35)
	frame([world.player,patient],2.2)
	world.player.presentation.eye_glow = true
	director.view.status.text = "Uma pulsação sob o ferimento. Por um instante, o cais perde nitidez."
	mark("perception_without_healing")
	for i in 2:
		var tween := create_tween(); tween.tween_property(rescue,"pulse",1.0,0.35); tween.tween_property(rescue,"pulse",0.0,0.35)
		await tween.finished
	world.player.presentation.posture = "crouched"; await wait(0.6)
	world.player.presentation.posture = "standing"
	director.view.status.text = "O ferimento continua. É preciso buscar Tomé e o curativo."
	await wait(0.5)

func ordinary_treatment() -> void:
	var patient = director.actors["Trabalhador ferido"]
	var tome = director.actors["Tomé"]
	frame([patient,tome,world.player],2.05)
	await move(tome,patient.position+Vector2(-38,-2),65)
	tome.posture = "crouched"
	director.actors["Mulher do cais"].facing = 3
	mark("cloth_and_ordinary_care"); await wait(1.0)
	director.actors.Observador.position += Vector2(-30,-20)
	mark("observer_steps_back")

func leave_with_family() -> void:
	var patient = director.actors["Trabalhador ferido"]
	patient.posture = "standing"; patient.injured = true
	await move(patient,Vector2(382,917),50)
	patient.hide(); mark("patient_leaves_with_support")

func assisted_return() -> void:
	director.view.panel.hide(); director.view.status.text = "Duarte e Tomé ajudam no regresso ao abrigo."
	var tome = director.actors["Tomé"]; var duarte = director.actors.Duarte
	tome.posture = "crouched"; await wait(0.6)
	tome.posture = "standing"; duarte.posture = "standing"
	world.player.presentation.posture = "standing"; world.player.presentation.injured = true; world.player.presentation.facing = 1
	tome.position = world.player.position+Vector2(30,12); duarte.position = world.player.position+Vector2(-32,8)
	mark("assisted_return_begins")
	var tween := create_tween().set_parallel(true)
	var destination := Vector2(-190,315)
	tween.tween_property(world.player,"position",destination,2.8)
	tween.tween_property(tome,"position",destination+Vector2(30,12),2.8)
	tween.tween_property(duarte,"position",destination+Vector2(-32,8),2.8)
	tome.facing = 1; duarte.facing = 1
	await tween.finished; mark("assisted_return_leaves_square")

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds,false).timeout

func sound(event: String,gain: float = -23,pitch: float = 1.0,nav: bool = false) -> void:
	if DisplayServer.get_name()=="headless": return
	var voice := voices[voice_index%voices.size()]; voice_index += 1
	voice.stream = load(("res://assets/audio/navigation/" if nav else "res://assets/audio/combat/")+event+".wav")
	voice.volume_db = gain; voice.pitch_scale = pitch; voice.play()

func foley(event: String,gain: float = -26) -> void:
	if DisplayServer.get_name()=="headless": return
	var voice := voices[voice_index%voices.size()]; voice_index += 1
	voice.stream = AudioStreamWAV.load_from_file("res://assets/audio/chapter/foley/"+event+".wav")
	voice.volume_db = gain; voice.pitch_scale = 1.0; voice.play()

func move(actor: Node2D,destination: Vector2,speed: float = 90) -> void:
	await Walk.along(actor,[destination],self,speed).finished

func strike(actor: Node2D,destination: Vector2,duration: float = 0.38) -> void:
	actor.walking = false
	var tween := create_tween().set_parallel(true)
	tween.tween_property(actor,"position",destination,duration).set_trans(Tween.TRANS_SINE)
	tween.tween_property(actor,"tool_angle",0.12,duration).from(-1.05)
	tween.tween_property(actor,"rotation",-0.045 if actor.facing==3 else 0.045,duration)
	sound("swing",-26,0.85)
	await tween.finished
	actor.rotation = 0

func disarm(actor: Node2D,destination: Vector2) -> void:
	actor.carries_training_tool = false
	drop_count += 1
	var tool := Instrument.new(); tool.name = "DroppedPracticeTool%d"%drop_count; tool.position = actor.position+Vector2(18,-45)
	world.sorted_world.add_child(tool)
	var origin := tool.position
	var tween := create_tween()
	tween.tween_method(func(t: float):
		tool.position = origin.lerp(destination,t)+Vector2(0,-sin(t*PI)*35)
		tool.angle = -1.0+t*4.5,0.0,1.0,0.55)
	sound("guard",-23,0.8)
	await tween.finished
	tool.grounded = true; sound("footstep_wood",-25,1.2)

func react() -> void:
	for person in audience:
		var origin: Vector2 = person.position
		var tween := create_tween()
		tween.tween_property(person,"position",origin+Vector2(0,5),0.15)
		tween.tween_property(person,"position",origin,0.5)

func master_demonstration() -> void:
	director.view.panel.hide()
	director.view.hint.text = "Esc / Start · pausar"
	var master = director.actors.Mestre; var fighter = director.actors.Combatente
	master.facing = 3; fighter.facing = 1
	mark("master_guard"); await wait(0.55)
	await move(master,Vector2(-35,205),110)
	mark("fighter_attacks"); await strike(fighter,Vector2(40,205),0.45)
	master.tool_angle = -0.9
	effects.contact(Vector2(7,166)); sound("guard",-25,0.9)
	await wait(0.35); await move(fighter,Vector2(85,205),120)
	mark("master_answers"); await strike(master,Vector2(18,205),0.4)
	effects.contact(Vector2(53,168)); await disarm(fighter,Vector2(135,270))
	fighter.posture = "crouched"; react()
	await move(master,Vector2(-35,205),100)
	master.facing = 3; master.tool_angle = 0.45
	mark("master_disarmed_fighter"); await wait(0.8)
	director.view.panel.show()

func leonor_demonstration() -> void:
	director.view.panel.hide()
	director.view.hint.text = "Esc / Start · pausar"
	var master = director.actors.Mestre; var leonor = director.actors.Leonor
	var fighter = director.actors.Combatente
	fighter.posture = "standing"; await move(fighter,Vector2(195,330),110); fighter.posture = "crouched"
	frame([master,leonor],1.85)
	mark("leonor_enters"); await move(leonor,Vector2(72,205),125)
	leonor.facing = 1; master.facing = 3
	master.rotation = -0.05; await wait(0.35); master.rotation = 0
	leonor.tool_angle = -0.2; await wait(0.45)
	mark("master_first_attempt"); await strike(master,Vector2(1,205),0.36)
	leonor.tool_angle = -0.9; effects.contact(Vector2(38,166)); sound("guard",-24,1.1)
	await wait(0.3); await move(master,Vector2(-36,215),115); master.facing = 3
	mark("master_regroups"); master.tool_angle = -1.2; await wait(0.8)
	mark("master_second_attempt"); await strike(master,Vector2(7,210),0.33)
	leonor.position = Vector2(65,205); leonor.tool_angle = 0.08
	effects.contact(Vector2(37,165),true); await disarm(master,Vector2(-67,290))
	await move(master,Vector2(-12,215),80); master.facing = 3
	leonor.tool_angle = 0.08; leonor.rotation = 0
	mark("leonor_disarms_master"); react(); await wait(1.0)
	mark("leonor_holds_point"); await wait(0.7)
	director.view.panel.show()

func water_drunk() -> void:
	director.view.panel.hide()
	director.view.hint.text = "Esc / Start · pausar"
	var hero = world.player.presentation
	var bedside = world.sorted_world.get_node_or_null("BedsideSupport")
	if bedside!=null: bedside.cup_available = false
	hero.carries_cup = true; mark("water_lifted")
	var tween := create_tween(); tween.tween_property(hero,"cup_lift",18.0,0.45)
	await tween.finished; await wait(0.55)
	foley("water")
	tween = create_tween(); tween.tween_property(hero,"cup_lift",0.0,0.4)
	await tween.finished; hero.carries_cup = false
	if bedside!=null: bedside.cup_available = true
	foley("cup",-31)
	mark("water_drunk"); director.view.panel.show()

func recovery_time() -> void:
	director.view.panel.hide(); director.view.caption_label.text = "Portugal · Recuperação\nVoltar a caminhar"
	frame([world.player,director.actors["Tomé"]],1.75)
	mark("recovery_support")
	director.actors["Tomé"].posture = "standing"; director.actors["Tomé"].seat_support = false
	await wait(0.65)
	world.player.presentation.posture = "standing"; world.player.presentation.injured = false
	var landing: Vector2 = world.player.position+Vector2(-75,55)
	if world.point_clear(landing):
		var step := create_tween(); step.tween_property(world.player,"position",landing,0.6)
		await step.finished
	else: await wait(0.6)
	mark("recovery_ready")

func clean_cloth() -> void:
	foley("cloth")
	var cloth := Sprite2D.new(); cloth.name = "CleanCloth"
	cloth.texture = preload("res://scripts/chapter/dining_art.gd").texture("napkin")
	cloth.scale = Vector2.ONE*20.0/cloth.texture.get_width()
	cloth.position = director.props.object_position+Vector2(22,-28); cloth.z_index = 4
	world.sorted_world.add_child(cloth)
	var tween := create_tween()
	tween.tween_property(cloth,"position",director.props.object_position+Vector2(-35,-27),0.55)
	await tween.finished; mark("cloth_within_reach")

func cups_on_bench(close_to_hero: bool) -> void:
	var old = world.sorted_world.get_node_or_null("Bench/Cups")
	if old!=null: old.hide()
	if close_to_hero:
		var cup := Sprite2D.new(); cup.name = "CupWithinReach"
		cup.texture = preload("res://scripts/chapter/dining_art.gd").texture("cup")
		cup.scale = Vector2.ONE*11.0/cup.texture.get_width()
		cup.position = director.actors.Leonor.position+Vector2(-12,-15); world.sorted_world.add_child(cup)
		var tween := create_tween(); tween.tween_property(cup,"position",world.player.position+Vector2(30,-5),0.65)
		tween.tween_callback(func(): mark("cup_left_within_reach"))
	else:
		for point in [Vector2(55,326),Vector2(83,338)]:
			var cup := Sprite2D.new(); cup.texture = preload("res://scripts/chapter/dining_art.gd").texture("cup")
			cup.scale = Vector2.ONE*11.0/cup.texture.get_width(); cup.position = point; cup.z_index = 1; world.sorted_world.add_child(cup)
		mark("two_cups_on_same_bench"); await wait(0.5)
