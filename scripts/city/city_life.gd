extends Node2D
## Work stays at the service points; passers-by use short checked public routes.
const PEOPLE := {"workshop":"OficialDaOficina","dock":"TrabalhadorDoPontao","fisher":"Pescadora","neighbor":"Vizinha","keeper":"MarinheiroDoBatel"}
var world
var elapsed := 0.0
var held := ""
var was_enabled := false
var walkers: Array = []
static func install(map) -> void:
	if Engine.is_editor_hint() or map.has_node("CityLife"): return
	var life := Node2D.new(); life.set_script(load("res://scripts/city/city_life.gd"));life.name="CityLife";life.world=map;map.add_child(life)
const CYCLES := {"workshop":[3.2,5.8,1.9,4.6,3.1],"dock":[2.6,6.7,2.1,5.3,4.0],"fisher":[4.1,7.2,2.2,4.3,3.5],"neighbor":[3.3,5.4,2.6,6.5,3.9],"keeper":[2.8,6.1,1.7,6.8,4.4]}
static func routine(id: String,time: float) -> Dictionary:
	var lengths: Array=CYCLES.get(id,CYCLES.workshop)
	var total:=0.0
	for value in lengths:total+=float(value)
	var at:=fposmod(maxf(0,time),total)
	var phase:=0
	while phase<lengths.size()-1 and at>=float(lengths[phase]):
		at-=float(lengths[phase]);phase+=1
	return {"phase":["preparar","trabalhar","pousar","conferir","descansar"][phase],"weight":at/float(lengths[phase]),"cycle":total}
func _ready() -> void:
	# They have no solid layer: an errand cannot block the player or a story actor.
	for spec in [["RecadosDaRibeira","worker",Vector2(1050,1000),Vector2(1220,1000)],["PassanteDaPraca","observer",Vector2(-240,450),Vector2(-60,450)]]:
		if not world.point_clear(spec[2]) or not world.point_clear(spec[3]): continue
		var person = preload("res://scripts/chapter/quay_resident.gd").new()
		person.name=spec[0];person.npc_id=spec[1];person.position=spec[2];person.route=PackedVector2Array([spec[2],spec[3]]);person.pause_seconds=5
		world.sorted_world.add_child(person);person.collision_layer=0;person.collision_mask=1|2
		person.set_meta("city_passerby",true);walkers.append(person)
func hold(id: String) -> void:
	held=id
	var actor = world.sorted_world.get_node_or_null(PEOPLE.get(id,""))
	if actor==null: return
	var view=actor.presentation if actor.get("presentation")!=null else actor
	view.walking=false
	if actor.has_node("WorkGesture"):actor.get_node("WorkGesture").active=false;actor.get_node("WorkGesture").queue_redraw()
func _process(delta: float) -> void:
	if not is_instance_valid(world.player): return
	var young: bool=world.childhood
	for person in walkers:
		person.visible=not young or person.name=="PassanteDaPraca"
	for id in PEOPLE:
		var actor=world.sorted_world.get_node_or_null(PEOPLE[id])
		if actor!=null: actor.visible=not young
	var enabled: bool=world.player.enabled
	if not enabled:
		if was_enabled:
			for id in PEOPLE:
				var actor=world.sorted_world.get_node_or_null(PEOPLE[id])
				if actor==null: continue
				var view=actor.presentation if actor.get("presentation")!=null else actor
				view.carries_bowl=false;view.carries_cup=false;view.posture="standing";view.walking=false
				if actor.has_node("WorkGesture"):actor.get_node("WorkGesture").active=false;actor.get_node("WorkGesture").queue_redraw()
				if id==held:
					view.facing=3 if world.player.position.x>actor.position.x else 1
		was_enabled=false
		return
	held="";was_enabled=true;elapsed+=delta
	for id in PEOPLE:
		var actor=world.sorted_world.get_node_or_null(PEOPLE[id])
		if actor==null or young: continue
		var view=actor.presentation if actor.get("presentation")!=null else actor
		var work:=routine(id,elapsed)
		actor.set_meta("work_phase",work.phase)
		view.walking=false
		view.posture="crouched" if id in ["workshop","keeper"] and work.phase in ["preparar","trabalhar"] else "standing"
		view.empty_bowl=id=="fisher"
		view.carries_bowl=id in ["fisher","neighbor"] and work.phase in ["preparar","trabalhar"]
		view.carries_cup=id=="neighbor" and work.phase in ["conferir","descansar"]
		view.facing=2 if work.phase=="conferir" else 0 if work.phase=="descansar" else 3 if id in ["workshop","neighbor"] else 1
		var gesture=actor.get_node_or_null("WorkGesture")
		if gesture==null:
			gesture=preload("res://scripts/city/work_gesture.gd").new();gesture.name="WorkGesture";gesture.job=id;actor.add_child(gesture)
		gesture.active=true;gesture.phase=work.phase;gesture.weight=work.weight;gesture.queue_redraw()
		view.queue_redraw()
