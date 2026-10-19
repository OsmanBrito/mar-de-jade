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
				if id==held:
					view.facing=3 if world.player.position.x>actor.position.x else 1
		was_enabled=false
		return
	held="";was_enabled=true;elapsed+=delta
	for id in PEOPLE:
		var actor=world.sorted_world.get_node_or_null(PEOPLE[id])
		if actor==null or young: continue
		var view=actor.presentation if actor.get("presentation")!=null else actor
		var beat:=fposmod(elapsed+float(PEOPLE.keys().find(id))*1.7,10.0)
		view.walking=false
		view.posture="crouched" if id in ["workshop","keeper"] and beat<2.2 else "standing"
		view.empty_bowl=id=="fisher"
		view.carries_bowl=id in ["fisher","neighbor"] and beat<5.5
		view.carries_cup=id=="neighbor" and beat>=5.5
		view.facing=2 if beat>7.5 else 3 if id in ["workshop","neighbor"] else 1
		view.queue_redraw()
