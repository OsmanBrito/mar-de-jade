extends RefCounted
## Walk to a place, then interact with its person/object to resume the story.
signal stage_arrived
const State = preload("res://scripts/chapter/lisbon_journey_state.gd")
const Marker = preload("res://scripts/chapter/local_request_marker.gd")
const Convent = preload("res://scripts/city/convent_plan.gd")
const House = preload("res://scripts/city/house_life.gd")
var director
var active := false
var state: Dictionary = {}
var definitions: Dictionary
var exits: Array = []
var goal_marker: Node2D
var goal := Vector2.ZERO
var goal_area := "cais"
var goal_label := ""
var notice := ""
var waiting_stage := false
var changing_area := false
var order_point := Vector2.INF
var order_marker: Node2D
var installed_area := ""
var discoveries: Array = []
var intent = preload("res://scripts/chapter/interaction_intent.gd").new()

func click(point: Vector2) -> void:
	var targets: Array = []
	if goal_reachable_here(): targets.append({"id":"goal","at":goal,"point":goal})
	for exit in exits: targets.append({"id":"exit:"+str(exit.to),"at":exit.point,"point":exit.point})
	if order_point!=Vector2.INF: targets.append({"id":"order","at":order_point,"point":order_point})
	for discovery in discoveries: targets.append({"id":"discovery:"+str(discovery.id),"at":discovery.point,"point":discovery.point})
	for id in House.rows(director.world):
		var row: Dictionary = House.rows(director.world)[id]
		targets.append({"id":"house:"+id,"at":row.at,"point":row.at})
	if safe_city():
		for id in director.harbor.city.markers:
			var marker = director.harbor.city.markers[id]
			if is_instance_valid(marker) and marker.available:
				var actor = director.harbor.city.cart if id=="cart" else director.harbor.city.residents[id]
				targets.append({"id":"resident:"+str(id),"at":actor.position,"point":director.harbor.city.approach(id)})
		if is_instance_valid(director.harbor.merchant):
			targets.append({"id":"shop","at":director.harbor.merchant.position,"point":director.harbor.merchant.approach})
	intent.begin(director.world,point,targets)

func guide_target() -> Vector2:
	if goal_reachable_here(): return goal
	var next := "room" if area()=="convent" and goal_area=="room" else "square"
	if continuous() and goal_area=="deck": next = "deck"
	elif area()=="deck": next = "cais"
	for exit in exits:
		if exit.to==next: return exit.point
	return director.world.player.position

func continuous() -> bool:
	return is_instance_valid(director.world) and director.world.has_meta("continuous_lisbon")

func goal_reachable_here() -> bool:
	return area()==goal_area or (continuous() and goal_area in ["square","cais"])

func _init(owner) -> void:
	director = owner
	definitions = JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_01/lisbon_routes.json"))

func area() -> String:
	if is_instance_valid(director.world) and director.world.has_meta("order_convent"): return "convent"
	if continuous(): return preload("res://scripts/city/lisbon_layout.gd").area(director.world.player.position)
	return zone(director.map_kind)
func location_title() -> String:
	return Convent.title(director.world.player.position) if area()=="convent" else str(definitions[area()].title)
static func zone(kind: String) -> String:
	return "square" if kind in ["plaza","courtyard"] else "convent" if kind=="service" else kind

static func open_paths(world) -> void:
	if world.has_meta("continuous_lisbon"): return
	for path in [[Vector2(-260,180),Vector2(-365,75)],[Vector2(460,288),Vector2(680,288)]]:
		var start: Vector2i = world.terrain.local_to_map(path[0])
		var end: Vector2i = world.terrain.local_to_map(path[1])
		for x in range(mini(start.x,end.x)-3,maxi(start.x,end.x)+4):
			for y in range(mini(start.y,end.y)-3,maxi(start.y,end.y)+4):
				var point: Vector2 = world.terrain.map_to_local(Vector2i(x,y))
				if point.distance_to(Geometry2D.get_closest_point_to_segment(point,path[0],path[1]))<65:
					world.terrain.set_cell(Vector2i(x,y),0,Vector2i.ZERO)
	world._refresh_ground()

func begin(kind: String,target: int,stage: String = "") -> void:
	active = true
	state = {"kind":kind,"target":target,"event":-1 if kind in ["block","rest"] else director.event_index,"stage":stage,"area":area(),"position":[roundi(director.world.player.position.x),roundi(director.world.player.position.y)]}
	set_goal(); install(); resume(); save()
	if continuous() and ((kind=="block" and target==1) or kind=="fetch_return"): prepare_rescue()

func prepare_rescue() -> void:
	if director.map_kind=="cais": return
	if director.actors.has("Duarte"):
		var actor = director.actors.Duarte
		actor.show()
		var destination := Vector2(542,857)
		var from: Vector2i = director.world._nearest_id(actor.position)
		var to: Vector2i = director.world._nearest_id(destination)
		if from.x>=0 and to.x>=0:
			var route: PackedVector2Array = director.world.navigation.get_point_path(from,to)
			var points: Array[Vector2] = []
			for p in route: points.append(p)
			points.append(destination)
			preload("res://scripts/chapter/staged_walk.gd").along(actor,points,actor,160)
	if not director.actors.has("Trabalhador ferido"):
		director._add_actor("Trabalhador ferido",Vector2(552,882)); director.actors["Trabalhador ferido"].posture = "fallen"
	if not director.world.sorted_world.has_node("RescueApproach"):
		var rescue := preload("res://scripts/chapter/rescue_setting.gd").new(); rescue.name = "RescueApproach"; rescue.position = Vector2(502,877)
		rescue.supported = ChapterProgress.flags.get("cargo_freed",false); rescue.lifted = 1.0 if rescue.supported else 0.0
		director.world.sorted_world.add_child(rescue)

func restore(saved: Dictionary) -> void:
	if not State.valid(saved) or saved.is_empty(): return
	state = saved.duplicate(true); active = true; set_goal()
	load_area(state.area,Vector2(float(state.position[0]),float(state.position[1])))
	resume(); save()

func set_goal() -> void:
	var kind: String = state.kind
	if kind=="port_visit": goal_area = "cais"; goal = preload("res://scripts/city/lisbon_layout.gd").BOAT_ENTRY-Vector2(0,60); goal_label = "Regressar à Botafogo · retomar a viagem"; return
	if kind=="rest": goal_area = "room"; goal = Vector2(-110,300); goal_label = "Descansar · avaliação amanhã"; return
	if kind=="fetch": goal_area = "room"; goal = Vector2(185,340); goal_label = "Pedir a Tomé que vá ao cais"; return
	if kind=="fetch_return": goal_area = "cais"; goal = Vector2(492,927); goal_label = "Voltar ao trabalhador com Tomé"; return
	if kind=="delivery": goal_area = "cais"; goal = Vector2(315,997); goal_label = "Entregar os sacos à cozinha"; return
	if kind=="stage":
		goal_area = "square"
		goal = Vector2(-130,290) if state.stage=="delivery_return" else Vector2(180,370)
		goal_label = "Encontrar Duarte no pátio" if state.stage=="delivery_return" else "Falar com Tomé · escolher o manejo"
		return
	var destinations := {
		0:["square",Vector2(-130,290),"Encontrar Duarte no pátio"],
		1:["cais",Vector2(492,927),"Aproximar-se do acidente · ajudar Duarte"],
		4:["convent",Vector2(1310,20),"Recolher a refeição na cozinha da Ordem"],
		6:["square",Vector2(-180,390),"Observar a demonstração na praça"],
		7:["square",Vector2(23,402),"Sentar com Leonor no banco"],
		15:["room",Vector2(185,340),"Falar com Tomé · preparar a sacola"],
		16:["deck",Vector2(40,365),"Apresentar-se ao capitão Rodrigo"]
	}
	var spec: Array = destinations.get(int(state.target),[zone(director.blocks[int(state.target)].map),Vector2.ZERO,"Retomar o compromisso"])
	goal_area = spec[0]; goal = spec[1]; goal_label = spec[2]

func objective() -> String:
	if not active: return ""
	var detail := goal_label+" · "+str(definitions[goal_area].title)
	if state.kind=="fetch": detail = "Duarte fica com o ferido. Vai ao abrigo buscar Tomé e regressa com ele ao cais."
	elif state.kind=="fetch_return": detail = "Tomé segue contigo. Regressa pelo caminho da praça ao cais; Duarte espera com o ferido."
	elif state.kind=="rest": detail = "Leonor marcou a avaliação para amanhã. Regressa ao abrigo e descansa quando estiveres pronto."
	return detail

func safe_city() -> bool:
	return (continuous() or area()=="cais") and ChapterProgress.flags.get("patient_helped",false) and not ChapterProgress.flags.get("injured",false)

func clear_markers() -> void:
	for discovery in discoveries:
		if is_instance_valid(discovery.marker): discovery.marker.queue_free()
	discoveries.clear()
	order_point = Vector2.INF
	if is_instance_valid(order_marker): order_marker.queue_free()
	order_marker = null
	for exit in exits:
		if is_instance_valid(exit.marker): exit.marker.queue_free()
	exits.clear()
	if is_instance_valid(goal_marker): goal_marker.queue_free()
	goal_marker = null

func install() -> void:
	clear_markers()
	installed_area = area()
	if area()=="convent":
		for id in Convent.NOTES:
			var row: Dictionary = Convent.NOTES[id]
			discoveries.append({"id":id,"point":row.point,"marker":mark(row.point,row.title,"i")})
	if continuous():
		for id in preload("res://scripts/city/lisbon_access.gd").rows(false):
			var row: Dictionary = preload("res://scripts/city/lisbon_access.gd").ROWS[id]
			var at := clear_point(row.at)
			discoveries.append({"id":"site:"+id,"point":at,"marker":mark(at,row.title,"i")})
	var notices: Dictionary = preload("res://scripts/chapter/order_house.gd").NOTICES
	if notices.has(area()):
		order_point = clear_point(notices[area()].point)
		order_marker = mark(order_point,notices[area()].title,"i")
	director.props.marker_active = false
	director.props.visible = state.kind=="delivery"
	director.props.delivery_active = state.kind=="delivery"; director.props.carrying = state.kind=="delivery"
	for definition in definitions[area()].exits:
		if continuous() and definition.to in ["square","cais"]: continue
		var point := Vector2(float(definition.at[0]),float(definition.at[1]))
		add_exit(definition.to,definition.label,point)
	if area()=="cais" and state.kind=="block" and int(state.target)==16:
		add_exit("deck","Subir à Botafogo · embarcar",preload("res://scripts/city/lisbon_layout.gd").BOAT_ENTRY if continuous() else Vector2(902,1037))
	if goal_reachable_here():
		goal = clear_point(goal)
		goal_marker = mark(goal,goal_label,"!")
	if safe_city():
		director.harbor.active = true
		director.harbor.city.install(director.world)
	else: director.harbor.active = false
	# The cook and Leonor wait at the table while the player reaches them.
	if area()=="cais" and state.kind=="block" and int(state.target)==4:
		if not director.actors.has("Ajudante da cozinha"):
			director._add_actor("Ajudante da cozinha",Vector2(470,830)); director.actors["Ajudante da cozinha"].npc_id = "attendant"
			director.actors["Ajudante da cozinha"].carries_bowl = true
	# Tomé travels with the player; ordinary care remains the objective.
	if state.kind=="fetch_return" and not director.actors.has("Tomé"): director._add_actor("Tomé",director.world.player.position+Vector2(-35,-20))
	if director.actors.has("Leonor") and ChapterProgress.flags.get("leonor_departed",false): director.actors.Leonor.hide()
	if director.actors.has("Trabalhador ferido") and ChapterProgress.flags.get("patient_helped",false): director.actors["Trabalhador ferido"].hide()
	if changing_area and area()!=goal_area and state.kind in ["block","stage","rest"]:
		for name in director.actors:
			if name!="Tomé" or area()!="room": director.actors[name].hide()
	if area()=="cais" and state.kind=="block" and int(state.target)==16:
		director.actors.Duarte.show(); director.actors.Duarte.position = director.harbor.GATE
	for actor in director.actors.values():
		for shape in actor.find_children("*","CollisionPolygon2D",true,false): shape.set_deferred("disabled",not actor.visible)
	if area()=="square" and state.kind=="block" and int(state.target)==7 and director.actors.has("Leonor"):
		var leonor = director.actors["Leonor"]
		if leonor.position.distance_to(Vector2(106,366))>5:
			var walk = preload("res://scripts/chapter/staged_walk.gd").along(leonor,[Vector2(106,366)],leonor,70)
			var actor_ref: WeakRef = weakref(leonor)
			walk.tween_callback(func():
				var actor = actor_ref.get_ref()
				if actor!=null: actor.posture = "seated")
	director.world.rebuild_navigation()

func clear_point(point: Vector2) -> Vector2:
	if director.world.point_clear(point): return point
	for radius in [16,32,48,64]:
		for direction in [Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT,Vector2.UP]:
			if director.world.point_clear(point+direction*radius): return point+direction*radius
	if continuous():
		for radius in [96,144,208,288]:
			for direction in 16:
				var candidate: Vector2 = point+Vector2.RIGHT.rotated(direction*TAU/16)*radius
				if director.world.point_clear(candidate): return candidate
		return director.world.get_node("Spawn").position
	return point

func mark(point: Vector2,caption: String,symbol: String) -> Node2D:
	var holder := Node2D.new(); holder.position = point; holder.z_index = 18
	var marker := Marker.new(); marker.caption = caption; marker.symbol = symbol; marker.position.y = 28
	holder.add_child(marker); director.world.sorted_world.add_child(holder)
	return holder

func add_exit(to: String,caption: String,point: Vector2) -> void:
	point = clear_point(point)
	exits.append({"to":to,"point":point,"caption":caption,"marker":mark(point,caption,"↗")})

func resume() -> void:
	if not active: return
	intent.cancel()
	director.busy = false; director.phase = "roaming"; director._clear_options()
	director.view.show(); director.view.panel.hide(); director.view.next_button.hide()
	director._lock_player(false)
	director.view.caption_label.text = location_title()
	director.view.status.text = objective()
	director.view.hint.text = "WASD / setas · mover     Clique · aproximar e interagir     E / A · interagir     J / Y · objetivo e pedidos     Esc / Start · menu"
	var focused = director.get_viewport().gui_get_focus_owner()
	if focused!=null: focused.release_focus()

func near(point: Vector2) -> bool:
	return director.world.player.position.distance_to(point)<60 and director.world.segment_clear(director.world.player.position,point)

func focus() -> String:
	var selected := ""; var closest := INF
	if goal_reachable_here() and near(goal):
		selected = "goal"; closest = director.world.player.position.distance_to(goal)
	for exit in exits:
		var distance: float = director.world.player.position.distance_to(exit.point)
		if near(exit.point) and distance<closest:
			closest = distance; selected = "exit:"+str(exit.to)
	if order_point!=Vector2.INF and near(order_point) and director.world.player.position.distance_to(order_point)<closest: selected = "order"
	for discovery in discoveries:
		var distance: float = director.world.player.position.distance_to(discovery.point)
		if near(discovery.point) and distance<closest: selected = "discovery:"+str(discovery.id); closest = distance
	for id in House.rows(director.world):
		var at: Vector2 = House.rows(director.world)[id].at
		var distance: float = director.world.player.position.distance_to(at)
		if near(at) and distance<closest: selected = "house:"+id; closest = distance
	if safe_city():
		var resident: String = director.harbor.city.focus()
		if not resident.is_empty():
			var distance: float = director.world.player.position.distance_to(director.harbor.city.approach(resident))
			if distance<closest: selected = "resident:"+resident; closest = distance
		if director.harbor.near_merchant():
			var distance: float = director.world.player.position.distance_to(director.harbor.merchant.approach)
			if distance<closest: selected = "shop"
	return selected

func update(delta: float) -> void:
	if not active or director.paused or director.phase!="roaming": return
	if area()!=installed_area:
		install(); director.view.caption_label.text = location_title(); save()
	if area()=="convent": director.view.caption_label.text = location_title()
	var arrived := intent.poll(director.world)
	if not arrived.is_empty(): interact(arrived); return
	director.view.guide.track(director.world,guide_target())
	var focused := focus()
	for exit in exits:
		if is_instance_valid(exit.marker): exit.marker.get_child(0).highlighted = focused=="exit:"+str(exit.to)
	if is_instance_valid(goal_marker): goal_marker.get_child(0).highlighted = focused=="goal"
	if is_instance_valid(order_marker): order_marker.get_child(0).highlighted = focused=="order"
	for discovery in discoveries:
		if not is_instance_valid(discovery.marker): continue
		discovery.marker.get_child(0).highlighted = focused=="discovery:"+str(discovery.id)
		discovery.marker.get_child(0).symbol = "·" if (preload("res://scripts/city/lisbon_access.gd").observed(ChapterProgress,str(discovery.id).trim_prefix("site:")) if str(discovery.id).begins_with("site:") else Convent.observed(ChapterProgress,discovery.id)) else "i"
	if state.kind=="fetch_return" and director.actors.has("Tomé"):
		var tome = director.actors["Tomé"]
		var destination: Vector2 = director.world.player.position+Vector2(-38,-15)
		if tome.position.distance_to(destination)>30:
			var next: Vector2 = tome.position.move_toward(destination,140*delta)
			if director.world.point_clear(next) and director.world.segment_clear(tome.position,next): tome.position = next
			else:
				for side in [Vector2(-35,20),Vector2(35,20),Vector2(0,40)]:
					var behind: Vector2 = director.world.player.position+side
					if director.world.point_clear(behind) and tome.position.distance_to(behind)<85: tome.position = tome.position.move_toward(behind,140*delta); break
			tome.walking = true; tome.frame_time += delta*7
		else: tome.walking = false
	if safe_city():
		director.harbor.city.update()
		for id in director.harbor.city.markers:
			var marker = director.harbor.city.markers[id]
			if is_instance_valid(marker): marker.highlighted = focused=="resident:"+str(id)
		if is_instance_valid(director.harbor.merchant):
			director.harbor.merchant.available = true
			director.harbor.merchant.highlighted = focused=="shop"
	var prompt := ""
	var selected := focus()
	if selected=="goal": prompt = "E / A · "+goal_label
	elif selected=="order": prompt = "E / A · "+str(preload("res://scripts/chapter/order_house.gd").NOTICES[area()].title)
	elif selected.begins_with("discovery:"):
		var id := selected.trim_prefix("discovery:")
		prompt = "E / A · "+str(preload("res://scripts/city/lisbon_access.gd").ROWS[id.trim_prefix("site:")].title if id.begins_with("site:") else Convent.NOTES[id].title)
	elif selected.begins_with("house:"): prompt = "E / A · "+str(House.rows(director.world)[selected.trim_prefix("house:")].title)
	elif selected.begins_with("resident:"):
		var id := selected.trim_prefix("resident:")
		prompt = director.harbor.city.interaction_prompt(id)
	elif selected=="shop": prompt = "E / A · negociar com o comerciante"
	else:
		for exit in exits:
			if selected=="exit:"+str(exit.to): prompt = "E / A · "+str(exit.caption); break
		if prompt.is_empty() and safe_city():
			prompt = director.harbor.city.prompt()
			if prompt.is_empty() and director.harbor.near_merchant(): prompt = "E / A · negociar com o comerciante"
	director.view.status.text = prompt if not prompt.is_empty() else objective()

func interact(requested: String = "") -> void:
	if not active or director.paused or director.busy or director.phase!="roaming": return
	intent.cancel()
	var selected := focus() if requested.is_empty() else requested
	if selected=="goal": arrive(); return
	if selected=="order": inspect_order(); return
	if selected.begins_with("house:"):
		var id := selected.trim_prefix("house:")
		if not House.rows(director.world).has(id) or not near(House.rows(director.world)[id].at): return
		var row := House.talk(director.world,ChapterProgress,id); save(); inspect(row); return
	if selected.begins_with("discovery:"):
		var id := selected.trim_prefix("discovery:")
		if id.begins_with("site:"):
			var access = preload("res://scripts/city/lisbon_access.gd"); var site := id.trim_prefix("site:")
			if not access.ROWS.has(site) or not near(access.ROWS[site].at): return
			access.observe(ChapterProgress,site); save(); inspect(access.ROWS[site]); return
		Convent.observe(ChapterProgress,id); save(); inspect(Convent.NOTES[id]); return
	if selected.begins_with("resident:") and safe_city():
		save(); director.harbor.city.interact(selected.trim_prefix("resident:")); return
	if selected=="shop" and safe_city() and director.harbor.near_merchant():
		save(); director._menu("Loja de Lisboa"); return
	for exit in exits:
		if selected!="exit:"+str(exit.to): continue
		if exit.to=="deck" and not (state.kind=="block" and int(state.target)==16): return
		if exit.to=="deck": review_boarding(); return
		var spawn := Vector2(570,288) if exit.to=="square" and area()=="cais" else preload("res://scripts/city/lisbon_layout.gd").ROOM_RETURN if exit.to=="square" else Vector2(-20,355) if exit.to=="room" else Vector2(-190,900) if exit.to=="cais" else Vector2(-140,385)
		if exit.to=="convent": spawn = Vector2(-280,680) if area()=="room" else Convent.SPAWN
		elif area()=="convent": spawn = Vector2(280,220) if exit.to=="square" else Vector2(210,270)
		if exit.to=="cais" and area()=="deck": spawn = preload("res://scripts/city/lisbon_layout.gd").BOAT_ENTRY-Vector2(0,45)
		load_area(exit.to,spawn); resume(); save(); return
	if safe_city():
		save()
		if director.harbor.city.interact(): return
		if director.harbor.near_merchant(): director._menu("Loja de Lisboa")

func inspect_order() -> void:
	var row: Dictionary = preload("res://scripts/chapter/order_house.gd").NOTICES[area()]
	inspect(row)
func inspect(row: Dictionary) -> void:
	director.phase = "order_inspection"; director._lock_player(true); director._clear_options()
	director.view.panel.show(); director.options_box.show(); director.view.next_button.hide()
	director.view.speaker.text = row.title; director.view.body.text = row.text
	director._option("Voltar à exploração",resume)
	director.options_box.get_child(0).grab_focus()

func review_boarding() -> void:
	director.phase = "boarding"; director._lock_player(true); director._clear_options()
	director.view.panel.show(); director.options_box.show(); director.view.next_button.hide()
	director.view.speaker.text = "Duarte · Pontão da Botafogo"
	director.view.body.text = "Madeira para mantimentos; depois Duas Águas e a busca pela caravela. Sobes como aprendiz. Ainda podes descer pela prancha antes de te apresentares ao capitão."
	director.view.body.text += "\n\n"+preload("res://scripts/chapter/optional_arc.gd").boarding(ChapterProgress)
	var pending:=preload("res://scripts/chapter/optional_arc.gd").pending(ChapterProgress)
	director.view.status.text = "Confere a sacola e os assuntos de Lisboa antes da partida." if pending.is_empty() else "Pedidos por concluir em Lisboa: %d. Podes continuar a explorar."%pending.size()
	director._option("Continuar a explorar",resume)
	director._option("Subir ao convés",board)
	director.options_box.get_child(0).grab_focus()

func board() -> void:
	if not active or director.paused or director.phase!="boarding": return
	load_area("deck",Vector2(-140,385)); resume(); save()

func load_area(next_area: String,position: Vector2) -> void:
	intent.cancel()
	clear_markers()
	var kind := next_area
	if next_area=="square": kind = "plaza" if state.kind=="block" and int(state.target) in [6,7] else "courtyard"
	var previous_index: int = director.scene_index
	if state.kind=="block": director.scene_index = int(state.target)
	director.harbor.building_visit = next_area=="cais" and ChapterProgress.flags.get("patient_helped",false)
	director._load_map(kind); director.harbor.building_visit = false
	director.scene_index = previous_index
	director.world.player.position = clear_point(position)
	director.world.player.presentation.posture = "standing"; director.world.player.presentation.carries_bowl = false
	director.world.player.camera.reset_smoothing()
	if state.kind=="fetch_return" and director.actors.has("Tomé"):
		director.actors["Tomé"].position = clear_point(director.world.player.position+Vector2(-38,20))
		director.actors["Tomé"].show(); director.actors["Tomé"].posture = "standing"
	state.area = next_area; changing_area = true; install(); changing_area = false
	# Installation can move an attendant onto the old landing point. Resolve
	# clearance after all actors and service footprints have reached their posts.
	director.world.player.position = clear_point(director.world.player.position)
	director.world.player.camera.reset_smoothing()
	preload("res://scripts/city/place_reveal.gd").show_place(director)
	if continuous() and ((state.kind=="block" and int(state.target)==1) or state.kind=="fetch_return"): prepare_rescue()

func save() -> void:
	if not active: return
	state.area = area(); state.position = [roundi(director.world.player.position.x),roundi(director.world.player.position.y)]
	ChapterProgress.journey = state.duplicate(true)
	if ChapterProgress.auto_save: ChapterProgress.save_to()

func stop(cancel: bool = false) -> void:
	intent.cancel(); director.view.guide.enabled = false
	active = false; ChapterProgress.journey = {}; clear_markers(); director.harbor.active = false
	director.props.show(); director.props.delivery_active = false; director.props.carrying = false
	if cancel and waiting_stage: stage_arrived.emit()

func arrive() -> void:
	var kind: String = state.kind; var target: int = int(state.target); var cursor: int = int(state.event)
	if kind=="port_visit":
		director.phase = "shore_return"; director._lock_player(true); director._clear_options()
		director.view.panel.show(); director.options_box.show(); director.view.next_button.hide()
		director.view.speaker.text = "Botafogo · Regresso a bordo"
		director.view.body.text = "A visita conserva os pedidos, compras e recursos do grupo. O navio retoma o mesmo estado e a mesma viagem."
		director._option("Continuar em Lisboa",resume)
		director._option("Regressar à Botafogo",return_to_voyage)
		director.options_box.get_child(0).grab_focus(); return
	if kind=="rest":
		director.phase = "rest_confirm"; director._lock_player(true)
		director._clear_options(); director.view.panel.show(); director.options_box.show()
		director.view.speaker.text = "Abrigo · Fim do dia"
		director.view.body.text = "A avaliação na praça é amanhã. Podes descansar agora ou voltar à cidade antes de encerrar o dia."
		director._option("Continuar a explorar",resume)
		director._option("Descansar até à manhã seguinte",rest)
		director.options_box.get_child(0).grab_focus(); return
	if kind=="fetch":
		state.kind = "fetch_return"; set_goal(); install(); resume()
		director.actors["Tomé"].posture = "standing"
		director.view.status.text = "Tomé · Vamos. Duarte ficou com ele; leva-me até ao trabalhador."; save(); return
	if continuous() and kind in ["delivery","stage","fetch_return"]:
		var next_kind := "cais" if goal_area=="cais" else "courtyard"
		if director.map_kind!=next_kind:
			var tome: Vector2 = director.actors["Tomé"].position if director.actors.has("Tomé") else Vector2.ZERO
			director._load_map(next_kind)
			if kind=="fetch_return": director.actors["Tomé"].position = tome
	stop()
	if kind=="block": director._load_block(target,true)
	elif kind=="delivery": director._begin_task(director.events[cursor])
	elif kind=="fetch_return":
		ChapterProgress.flags.fetch_tome = true
		director.event_index = cursor; director.phase = "dialogue"; director.advance()
	else:
		director.phase = "dialogue"
		if waiting_stage: stage_arrived.emit()
		else:
			director.event_index = cursor; director.advance()

func rest() -> void:
	if director.paused or director.phase!="rest_confirm": return
	director.busy = true; director._clear_options(); director.view.panel.hide()
	director.world.player.presentation.posture = "seated"
	preload("res://scripts/chapter/scene_transition.gd").reveal(director)
	await director.get_tree().create_timer(0.45,false).timeout
	ChapterProgress.flags.evaluation_morning = true
	state.kind = "block"; state.event = -1; set_goal(); install()
	director.world.player.presentation.posture = "standing"
	resume(); director.view.caption_label.text = "Lisboa · Manhã seguinte"; save()

func return_to_voyage() -> void:
	if director.paused or director.phase!="shore_return": return
	save()
	var error: Error = preload("res://scripts/navigation/shore_bridge.gd").embark(ChapterProgress)
	if error!=OK:
		director.view.status.text = "Não foi possível guardar o regresso. Continua em Lisboa e tenta novamente."; return
	preload("res://scripts/navigation/voyage_launch.gd").start(director.get_tree(),true,true)
