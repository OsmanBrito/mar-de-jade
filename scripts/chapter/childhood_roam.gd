extends RefCounted
## Free childhood exploration before the approved encounter at the same bench.
const Marker = preload("res://scripts/chapter/local_request_marker.gd")
const Convent = preload("res://scripts/city/convent_plan.gd")
const House = preload("res://scripts/city/house_life.gd")
const PLACES := {
	"leonor":{"at":Vector2(80,400),"title":"Leonor · banco da praça"},
	"home":{"at":Vector2(-250,190),"title":"A casa da Ordem","speaker":"A casa da Ordem","text":"A cruz da Ordem de Cristo está sobre a entrada. Para lá da portaria ficam os lugares de acolhimento, a mesa comum e os corredores do claustro. É a casa onde Tomé te recebe todos os dias."},
	"child":{"at":Vector2(340,440),"title":"Criança do abrigo","speaker":"Criança","text":"O frei mandou guardar as canecas depois de beber. Deixei a tua junto do banco. A Leonor já está lá."},
	"arcade":{"at":Convent.ARCADE,"title":"Entrar no claustro · capela e enfermaria"},
	"portaria":{"at":Convent.PORTARIA,"title":"Entrar no acolhimento · dormitório e claustro"}
}
var host
var markers: Array[Node] = []
var child: Node2D
var plaza_world: Node2D
var intent = preload("res://scripts/chapter/interaction_intent.gd").new()
func _init(director) -> void: host = director
func click(point: Vector2) -> void:
	var targets: Array = []
	for id in places(): targets.append({"id":id,"at":places()[id].at,"point":places()[id].at})
	intent.begin(host.world,point,targets)
func inside() -> bool: return host.world.has_meta("order_convent")
func places() -> Dictionary:
	var rows: Dictionary = PLACES.duplicate(true) if not inside() else {"leave":{"at":Vector2(0,870),"title":"Voltar à praça · Leonor espera junto do banco"}}
	if inside():
		for id in Convent.NOTES:
			var row: Dictionary = Convent.NOTES[id]
			rows["note:"+id] = {"at":row.point,"title":row.title,"speaker":row.title,"text":row.text}
	if not inside():
		for id in preload("res://scripts/city/lisbon_access.gd").rows(true):
			rows["site:"+id]=preload("res://scripts/city/lisbon_access.gd").ROWS[id]
	for id in House.rows(host.world):
		var place: Dictionary = House.rows(host.world)[id]
		rows["house:"+id] = {"at":place.at,"title":place.title,"speaker":place.title,"text":""}
	return rows
func cleanup() -> void:
	if is_instance_valid(plaza_world) and not plaza_world.is_inside_tree(): plaza_world.free()
func control(enabled: bool) -> void:
	host.framing.activate(false)
	host.world.player.enabled = enabled; host.world.player.set_physics_process(enabled)
	host.world.player.destination_path.clear(); host.world.player.velocity = Vector2.ZERO
	host.world.player.presentation.walking = false
	host.world.player.camera.enabled = true; host.world.player.camera.make_current()
func visit(point: Vector2 = Convent.SPAWN) -> void:
	plaza_world = host.world; host.remove_child(plaza_world)
	host.world = load("res://scenes/maps/convento_ordem.tscn").instantiate(); host.world.childhood = true; host.add_child(host.world)
	if host.world.point_clear(point): host.world.player.position = point
	for id in places():
		var row: Dictionary = places()[id]
		var marker := Marker.new(); marker.position = row.at+Vector2(0,28); marker.caption = row.title; marker.symbol = "↗" if id=="leave" else "i"; marker.set_meta("place_id",id)
		host.world.sorted_world.add_child(marker)
	resume(); save(); preload("res://scripts/city/place_reveal.gd").show_place(host)
func leave() -> void:
	var old: Node2D = host.world
	host.world = plaza_world; host.remove_child(old); old.free(); host.add_child(plaza_world)
	var returns: Array = [Vector2(-690,145),Vector2(-690,170),Vector2(-670,145)] if ChapterProgress.flags.get("child_portaria_entry",false) else [Vector2(260,260),Vector2(240,240),Vector2(280,300)]
	for point in returns:
		if host.world.point_clear(point): host.world.player.position = point; break
	host.world.player.camera.reset_smoothing()
	resume(); save(); preload("res://scripts/city/place_reveal.gd").show_place(host)
func begin() -> void:
	plaza_world = host.world; host.tree_exiting.connect(cleanup)
	host.world.player.presentation.identity = "hero_child"
	host.world.set_meta("exploration_companion",host.leonor)
	host.leonor.posture="crouched";host.leonor.facing=1
	var tools:=preload("res://scenes/chapter_01/training_tools.tscn").instantiate()
	tools.name="LeonorPracticeTools";tools.position=Vector2(210,370);tools.scale=Vector2.ONE*.65
	host.world.sorted_world.add_child(tools)
	var saved: Dictionary = ChapterProgress.journey.duplicate(true)
	host.world.player.position = Vector2(-315,150)
	if saved.get("kind","")=="childhood" and saved.get("area","")=="square":
		var point := Vector2(saved.position[0],saved.position[1])
		if host.world.point_clear(point): host.world.player.position = point
	child = preload("res://scripts/chapter/actor_proxy.gd").new(); child.npc_id = "shelter_child"; child.position = Vector2(340,400)
	host.world.sorted_world.add_child(child)
	preload("res://scripts/city/lisbon_scenery.gd").body(child,PackedVector2Array([Vector2(-9,-5),Vector2(9,-5),Vector2(9,7),Vector2(-9,7)]))
	for id in PLACES:
		var marker := Marker.new(); marker.position = PLACES[id].at+Vector2(0,28); marker.caption = PLACES[id].title; marker.symbol = "!" if id=="leonor" else "↗" if id in ["arcade","portaria"] else "i"; marker.set_meta("place_id",id)
		host.world.sorted_world.add_child(marker); markers.append(marker)
	for id in preload("res://scripts/city/lisbon_access.gd").rows(true):
		var row: Dictionary = preload("res://scripts/city/lisbon_access.gd").ROWS[id]
		var marker:=Marker.new(); marker.position=row.at+Vector2(0,28); marker.caption=row.title;marker.symbol="i";marker.set_meta("place_id","site:"+id)
		host.world.sorted_world.add_child(marker);markers.append(marker)
	host.world.rebuild_navigation(); resume()
	if saved.get("kind","")=="childhood" and saved.get("area","")=="convent": visit(Vector2(saved.position[0],saved.position[1]))
	else: save()
func resume() -> void:
	intent.cancel()
	host.phase = "childhood_explore"; host.busy = false
	if inside(): control(true)
	else: host._set_staged(false)
	host.world.player.presentation.posture = "standing"; host.world.player.z_index = 0
	host.view.caption_label.text = "Lisboa · Infância · "+(Convent.title(host.world.player.position) if inside() else "A praça da casa da Ordem de Cristo")
	host.view.panel.hide(); host.view.next_button.hide()
	host.view.hint.text = "WASD / setas · explorar     Clique · aproximar e interagir     E / A · interagir     J / Y · caderno     F5 / menu · guardar     Esc / Start · menu"
	var focus = host.get_viewport().gui_get_focus_owner()
	if focus!=null: focus.release_focus()
func focus() -> String:
	var result := ""; var distance := 60.0
	for id in places():
		var p: Vector2 = places()[id].at
		var d: float = host.world.player.position.distance_to(p)
		if d<distance and host.world.segment_clear(host.world.player.position,p): result = id; distance = d
	return result
func update() -> void:
	if host.phase!="childhood_explore" or host.paused: return
	var arrived := intent.poll(host.world)
	if not arrived.is_empty(): interact(arrived); return
	var selected := focus()
	if not inside() and host.leonor.posture=="crouched" and host.world.player.position.distance_to(host.leonor.position)<150:
		host.leonor.posture="standing";host.leonor.facing=1 if host.world.player.position.x<host.leonor.position.x else 3
	host.view.guide.track(host.world,Vector2(0,870) if inside() else Vector2(80,400))
	for marker in host.world.sorted_world.get_children():
		if marker.get_script()!=Marker: continue
		var id: String = str(marker.get_meta("place_id",""))
		marker.highlighted = id==selected
		if id.begins_with("note:"): marker.symbol = "·" if Convent.observed(ChapterProgress,id.trim_prefix("note:")) else "i"
	host.view.set_exploration_prompt("Encontra a Leonor junto do banco. Trouxeste água para os dois.","E / A · "+str(places()[selected].title) if not selected.is_empty() else "")
	if inside(): host.view.caption_label.text = "Lisboa · Infância · "+Convent.title(host.world.player.position)
	remember()
func interact(requested: String = "") -> void:
	intent.cancel()
	var selected := focus() if requested.is_empty() else requested
	if selected.is_empty(): return
	if not places().has(selected) or host.world.player.position.distance_to(places()[selected].at)>=60 or not host.world.segment_clear(host.world.player.position,places()[selected].at):return
	if selected=="arcade": ChapterProgress.flags.child_portaria_entry=false; visit(); return
	if selected=="portaria": ChapterProgress.flags.child_portaria_entry=true; visit(Vector2(-690,700)); return
	if selected=="leave": leave(); return
	if selected=="leonor":
		ChapterProgress.journey = {}; host.view.guide.enabled = false
		for marker in markers:
			if is_instance_valid(marker): marker.queue_free()
		if is_instance_valid(child): child.queue_free()
		host.world.player.presentation.posture = "standing"; host.world.player.z_index = 1
		host.leonor.posture="standing"
		host.view.next_button.show(); host.phase = "bank"
		host._start_segment("bank")
		if ChapterProgress.auto_save: ChapterProgress.save_to()
		return
	var reading: Dictionary = places()[selected].duplicate(true)
	if selected=="child":
		if ChapterProgress.flags.get("city_child_met",false): reading.text="Já guardei as canecas. A tua ficou junto do banco; vou esperar pela refeição."
		ChapterProgress.flags.city_child_met=true;save()
	if selected.begins_with("house:"):
		var row := House.talk(host.world,ChapterProgress,selected.trim_prefix("house:"))
		reading = {"speaker":row.title,"text":row.text}; save()
	if selected.begins_with("site:"):
		if not places().has(selected) or host.world.player.position.distance_to(places()[selected].at)>60 or not host.world.segment_clear(host.world.player.position,places()[selected].at): return
		preload("res://scripts/city/lisbon_access.gd").observe(ChapterProgress,selected.trim_prefix("site:")); save()
	if selected.begins_with("note:"): Convent.observe(ChapterProgress,selected.trim_prefix("note:")); save()
	host.phase = "childhood_note"; control(false); host.view.panel.show(); host.view.next_button.show()
	host.view.speaker.text = reading.speaker; host.view.body.text = reading.text
	host.view.remember(host.view.speaker.text,host.view.body.text)
	host.view.next_button.text = "Continuar a explorar"; host.view.next_button.grab_focus()
func remember() -> void:
	ChapterProgress.journey = {"kind":"childhood","target":0,"event":-1,"stage":"","area":"convent" if inside() else "square","position":[roundi(host.world.player.position.x),roundi(host.world.player.position.y)]}
func save() -> void:
	remember()
	if ChapterProgress.auto_save: ChapterProgress.save_to()
