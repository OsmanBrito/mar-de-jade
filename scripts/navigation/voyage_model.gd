extends RefCounted
## Maritime state and simulation. All persistence is validated before mutation.
const DATA := "res://data/navigation/atlantic.json"
const SPEED := 64.0
const SAIL_RATIOS := [0.0,0.45,1.0,1.6]
const BoardingLoadout = preload("res://scripts/navigation/boarding_loadout.gd")
var chart: Dictionary
var position := Vector2.ZERO
var velocity := Vector2.ZERO
var heading := 2.45
var supplies := 100.0
var hull := 100.0
var coins := 180
var distance := 0.0
var elapsed := 0.0
var danger := 0.0
var discovered: Dictionary = {}
var visited: Dictionary = {}
var resolved: Dictionary = {}
var upgrades: Dictionary = {}
var route_marks: Dictionary = {}
var aid_used: Dictionary = {}
var traffic: Dictionary = {}
var route_known := false
var made_landfall := false
var hero_name := "Aprendiz"
var style := "ES"
var phase := "sea"
var port := ""
var immunity := 0.0
var safe_state: Dictionary = {}
var last_error := ""
var observed_signals: Dictionary = {}
var land_polygons: Array[PackedVector2Array] = []
var warned_ahead := false
var blocked_by_coast := false
var boarding_profile: Dictionary = {}
var tutorials: Dictionary = {}

func _init() -> void:
	chart = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	position = point(chart.start)
	for island in chart.land:
		var polygon := PackedVector2Array()
		for p in island.points: polygon.append(point(p))
		land_polygons.append(polygon)
	for place in chart.places:
		if place.get("known",false): discovered[place.id] = "known"
		elif place.get("rumor",false): discovered[place.id] = "rumor"
		if place.kind in ["merchant","fisher","hostile","boss"]: traffic[place.id] = point(place.pos)
	safe_state = snapshot()

func point(value: Array) -> Vector2: return Vector2(float(value[0]),float(value[1]))
func place(id: String) -> Dictionary:
	for entry in chart.places:
		if entry.id == id: return entry
	return {}
func place_position(entry: Dictionary) -> Vector2: return traffic.get(entry.id,point(entry.pos))
func reveal(id: String,state: String) -> void:
	var rank := {"rumor":0,"known":1,"sighted":2,"explored":3}
	if not rank.has(state) or place(id).is_empty(): return
	if not discovered.has(id) or rank[state]>rank.get(discovered[id],-1): discovered[id] = state
func water(at: Vector2) -> bool:
	if at.x < 300 or at.y < 300 or at.x > chart.size[0]-300 or at.y > chart.size[1]-300: return false
	for polygon in land_polygons:
		if Geometry2D.is_point_in_polygon(at,polygon): return false
	return true
func wind_factor(direction: Vector2) -> float:
	return 1.0 if direction.length_squared()<0.01 else 0.94+0.18*direction.normalized().dot(Vector2(-0.75,0.65).normalized())
func risk_at(at: Vector2) -> float:
	# An accessible regional sea, with a readable deep-ocean frontier.
	var edge: float = minf(minf(at.x,chart.size[0]-at.x),minf(at.y,chart.size[1]-at.y))
	var limit := 1800.0 if upgrades.get("hull",false) else 2700.0
	return clampf((limit-edge)/1000.0,0,2.5)
func safety_target() -> Vector2:
	var margin := 2250.0 if upgrades.get("hull",false) else 3150.0
	return position.clamp(Vector2.ONE*margin,point(chart.size)-Vector2.ONE*margin)
func contact(max_distance: float = 1800.0) -> Dictionary:
	var result := {}; var best := max_distance
	for entry in chart.places:
		if resolved.has(entry.id) or discovered.get(entry.id,"") not in ["sighted","explored"]: continue
		if visited.has(entry.id) and entry.kind in ["port","island","landmark"]: continue
		var d := position.distance_to(place_position(entry))
		if d<best: best = d; result = entry
	return result
func update(delta: float, direction: Vector2, throttle: float = 1.0) -> Array[String]:
	var messages: Array[String] = []
	if phase != "sea": return messages
	elapsed += delta; immunity = maxf(0,immunity-delta)
	var max_speed := SPEED*(1.12 if upgrades.get("pilot",false) else 1.0)
	if route_known and position.distance_to(Vector2(12600,22100))<3400: max_speed *= 1.22
	var target_speed := 0.0
	if direction.length()>0.04:
		var turn := angle_difference(heading,direction.angle())
		var rate := (1.9 if upgrades.get("pilot",false) else 1.45)*(1.0+0.4*(1.0-clampf(velocity.length()/SPEED,0,1)))
		heading += clampf(turn,-rate*delta,rate*delta)
		var alignment := clampf(1.0-absf(turn)/PI,0.25,1.0)
		target_speed = direction.length()*max_speed*wind_factor(Vector2.from_angle(heading))*throttle*(0.68+0.32*hull/100.0)*alignment
	var target := Vector2.from_angle(heading)*target_speed
	# The keel follows the bow. Preserve forward momentum, not lateral skating.
	var speed := move_toward(velocity.length(),target.length(),delta*(110.0 if target_speed<velocity.length() else 48.0))
	velocity = Vector2.from_angle(heading)*speed
	var proposed := position+velocity*delta
	blocked_by_coast = false
	if water(proposed):
		var moved := position.distance_to(proposed)
		position = proposed; distance += moved
		supplies = maxf(0,supplies-moved*0.00052)
	else: velocity = Vector2.ZERO; blocked_by_coast = true
	var before := danger
	var risk := risk_at(position)
	var ahead := risk_at(position+Vector2.from_angle(heading)*850)>0 and velocity.length()>5
	if ahead and risk<=0 and not warned_ahead:
		warned_ahead = true; messages.append("O piloto vê o mar a fechar: a espuma aumenta pela proa. Muda o rumo antes de sair da derrota preparada.")
	if not ahead and risk<=0: warned_ahead = false
	danger = clampf(danger+delta*(risk*5.0 if risk>0 else -10.0),0,100)
	if before<15 and danger>=15: messages.append("O piloto avisa: estamos além da derrota preparada. Regressa às águas interiores da carta.")
	if before<55 and danger>=55: messages.append("Mar muito pesado. A Botafogo não aguenta esta travessia. Inverte o rumo!")
	if before>0 and danger<=0: messages.append("O mar voltou a acalmar. A Botafogo recuperou águas seguras.")
	if supplies<=0: hull = maxf(0,hull-delta*0.18)
	if danger>=75: hull = maxf(0,hull-delta*(danger-70)*0.055)
	if hull<=0: phase = "game_over"; velocity = Vector2.ZERO
	for signal_info in chart.get("signals",[]):
		if observed_signals.has(signal_info.id): continue
		if position.distance_to(point(signal_info.pos))<980:
			observed_signals[signal_info.id] = true
			if not resolved.has(signal_info.leads_to): messages.append(signal_info.report)
	for entry in chart.places:
		if resolved.has(entry.id) and entry.kind not in ["port","island","landmark"]: continue
		var at := place_position(entry)
		var sight := 1700.0 if upgrades.get("cartographer",false) else 1150.0
		if at.distance_to(position)<sight and discovered.get(entry.id,"") not in ["sighted","explored"]:
			discovered[entry.id] = "sighted"
			if entry.id!="lisboa" or elapsed>10: messages.append("À vista: "+entry.name+". A carta foi atualizada.")
		if entry.kind in ["hostile","boss"] and not resolved.has(entry.id):
			var home := point(entry.pos)
			var chase := at.distance_to(position)<(2000 if entry.kind=="hostile" else 1500) and at.distance_to(home)<3700 and immunity<=0
			var goal := position if chase else home+Vector2(sin(elapsed*0.025),cos(elapsed*0.025))*450
			var next := at.move_toward(goal,delta*(49 if entry.kind=="hostile" else 42))
			if water(next): traffic[entry.id] = next
		elif entry.kind in ["merchant","fisher"]:
			traffic[entry.id] = point(entry.pos)+Vector2(sin(elapsed*0.018)*380,cos(elapsed*0.018)*220)
	return messages
func helm(delta: float,rudder: float,sail_level: int) -> Array[String]:
	if phase!="sea": return []
	var steerage := clampf(velocity.length()/30.0,0,1)
	# Some steerage when setting sail, but no spinning at anchor.
	if sail_level>0: steerage = maxf(0.3,steerage)
	heading += clampf(rudder,-1,1)*(1.18 if upgrades.get("pilot",false) else 0.95)*steerage*delta
	return update(delta,Vector2.from_angle(heading) if sail_level>0 else Vector2.ZERO,SAIL_RATIOS[clampi(sail_level,0,3)])
func closest(radius: float = 190.0) -> Dictionary:
	var found: Dictionary = {}; var nearest := radius
	for entry in chart.places:
		if resolved.has(entry.id) and entry.kind not in ["port","island","landmark"]: continue
		var d := position.distance_to(place_position(entry))
		if d<nearest: found = entry; nearest = d
	return found
func encounter() -> Dictionary:
	if immunity>0: return {}
	for entry in chart.places:
		if entry.kind in ["hostile","boss"] and not resolved.has(entry.id) and position.distance_to(place_position(entry))<105: return entry
	return {}
func investigate(id: String) -> String:
	var entry := place(id)
	if entry.is_empty(): return "Nada a investigar."
	discovered[id] = "explored"; visited[id] = true
	match entry.kind:
		"wreck":
			if resolved.has(id): return "A carga já foi recolhida."
			resolved[id] = true; supplies = minf(100,supplies+24); coins += 30
			return "Carga recolhida · +24 provisões · +30 de ouro. Um recibo aponta para Porto Santo."
		"rescue":
			if resolved.has(id): return "O sobrevivente já está a salvo."
			resolved[id] = true; coins += 35; reveal("porto_santo","rumor")
			return "Náufrago a salvo · +35 de ouro de gratificação. Ele conhece sinais de uma passagem junto das Desertas. Conversa com ele no convés."
		"landmark":
			route_marks[id] = true
			if route_marks.size()>=3 and not route_known:
				route_known = true; coins += 60; reveal("desertas","sighted")
				return "Rota descoberta por observação · Passagem das Desertas · +60 de ouro. A corrente é agora conhecida e a travessia fica mais rápida."
			return entry.detail+" · Marcas registadas: "+str(route_marks.size())+"/3."
	return entry.detail
func dock(id: String) -> void:
	port = id; visited[id] = true; discovered[id] = "explored"; velocity = Vector2.ZERO; phase = "port"
	if id=="madeira": made_landfall = true
func buy(id: String) -> String:
	var prices := {"supplies":12,"repair":15,"chart":35,"pilot":65,"cartographer":55,"hull":90}
	if not prices.has(id): return "Serviço desconhecido."
	if upgrades.has(id): return "Esse serviço já foi contratado."
	if id=="supplies" and supplies>=99: return "As reservas já estão completas."
	if id=="repair" and hull>=99: return "O casco já está em bom estado."
	if coins<prices[id]: return "Ouro insuficiente. O serviço do cais pode ajudar com o essencial."
	coins -= prices[id]
	match id:
		"supplies": supplies = minf(100,supplies+40)
		"repair": hull = minf(100,hull+45)
		"chart":
			upgrades[id] = true
			for destination in ["desertas","current_1","current_2","current_3"]: reveal(destination,"rumor")
		_: upgrades[id] = true
	return {"supplies":"Reservas repostas · +40 provisões.","repair":"Calafetagem concluída · +45 casco.","chart":"Carta parcial adquirida. Três marcas indicam a Passagem das Desertas.","pilot":"Piloto contratado. A manobra fica mais ágil e o vento rende melhor.","cartographer":"Cartógrafo contratado. Avistamentos mais distantes e pistas mais precisas.","hull":"Casco reforçado. Mais margem em mar pesado e proteção em batalha."}[id]
func safe_to_save() -> bool:
	if phase not in ["sea","port","island"] or hull<25 or supplies<15 or danger>0: return false
	if phase=="sea":
		for entry in chart.places:
			if entry.kind in ["hostile","boss"] and not resolved.has(entry.id) and position.distance_to(place_position(entry))<2200: return false
	return true
func snapshot() -> Dictionary:
	var ships := {}
	for id in traffic: ships[id] = [traffic[id].x,traffic[id].y]
	return {"version":1,"position":[position.x,position.y],"heading":heading,"supplies":supplies,"hull":hull,"coins":coins,"distance":distance,"elapsed":elapsed,"discovered":string_keys(discovered),"visited":string_keys(visited),"resolved":string_keys(resolved),"upgrades":string_keys(upgrades),"route_marks":string_keys(route_marks),"aid_used":string_keys(aid_used),"observed_signals":string_keys(observed_signals),"traffic":ships,"route_known":route_known,"made_landfall":made_landfall,"hero_name":hero_name,"style":style,"phase":phase,"port":port,"boarding_profile":boarding_profile.duplicate(true),"tutorials":tutorials.duplicate()}
func string_keys(data: Dictionary) -> Dictionary:
	var result := {}
	for key in data: result[str(key)] = data[key]
	return result
func restore(data: Dictionary) -> bool:
	if data.get("version")!=1: return false
	var lessons: Variant = data.get("tutorials",{})
	if not lessons is Dictionary or lessons.size()>5: return false
	for key in lessons:
		if key not in ["sail","turn","stop","chart","boarding"] or not lessons[key] is bool: return false
	if not data.get("position") is Array or data.position.size()!=2: return false
	for value in data.position:
		if not number(value): return false
	var at := point(data.position)
	if not water(at): return false
	for key in ["heading","supplies","hull","coins","distance","elapsed"]:
		if not number(data.get(key)): return false
	if data.supplies<15 or data.supplies>100 or data.hull<25 or data.hull>100 or data.coins<0 or data.coins>999999 or data.distance<0 or data.elapsed<0: return false
	if float(data.coins)!=int(data.coins): return false
	if data.get("phase") not in ["sea","port","island"]: return false
	var kit: Variant = data.get("boarding_profile",{})
	if not kit is Dictionary or (not kit.is_empty() and (not BoardingLoadout.valid(kit) or kit.style!=data.get("style"))): return false
	if not data.get("hero_name") is String or data.hero_name.length()>24 or data.get("style") not in ["ES","LA","MC","FO","PU"]: return false
	if not data.get("port") is String or (not data.port.is_empty() and place(data.port).is_empty()): return false
	if data.phase in ["port","island"] and place(data.port).is_empty(): return false
	if data.phase=="port" and place(data.port).kind!="port": return false
	if data.phase=="island" and place(data.port).kind!="island": return false
	for key in ["discovered","visited","resolved","upgrades","route_marks","aid_used"]:
		if not data.get(key) is Dictionary or data[key].size()>40: return false
		for id in data[key]:
			if not id is String: return false
			if key=="discovered":
				if place(id).is_empty() or data[key][id] not in ["known","rumor","sighted","explored"]: return false
			else:
				if not data[key][id] is bool: return false
				if key=="upgrades" and id not in ["chart","pilot","cartographer","hull"]: return false
				if key!="upgrades" and place(id).is_empty(): return false
	if not data.get("route_known") is bool or not data.get("made_landfall") is bool: return false
	if not data.get("observed_signals",{}) is Dictionary: return false
	var signs: Dictionary = data.get("observed_signals",{})
	if signs.size()>chart.get("signals",[]).size(): return false
	for id in signs:
		if not signs[id] is bool or not chart.get("signals",[]).any(func(s): return s.id==id): return false
	var edge: float = minf(minf(at.x,chart.size[0]-at.x),minf(at.y,chart.size[1]-at.y))
	if edge<(1800 if data.upgrades.get("hull",false) else 2700): return false
	if not data.get("traffic",{}) is Dictionary: return false
	var ships: Dictionary = data.get("traffic",{})
	if ships.size()>10: return false
	for id in ships:
		if not traffic.has(id) or not ships[id] is Array or ships[id].size()!=2: return false
		if not number(ships[id][0]) or not number(ships[id][1]) or not water(point(ships[id])): return false
	position = at; heading = data.heading; supplies = data.supplies; hull = data.hull; coins = int(data.coins); distance = data.distance; elapsed = data.elapsed
	for key in ["discovered","visited","resolved","upgrades","route_marks","aid_used"]: set(key,data[key].duplicate())
	route_known = data.route_known; made_landfall = data.made_landfall; hero_name = data.hero_name; style = data.style; phase = data.phase; port = data.port
	for id in traffic: traffic[id] = point(ships[id]) if ships.has(id) else point(place(id).pos)
	observed_signals = signs.duplicate()
	boarding_profile = kit.duplicate(true)
	tutorials = lessons.duplicate()
	velocity = Vector2.ZERO; danger = 0; immunity = 8; warned_ahead = false; blocked_by_coast = false
	return true
func number(value) -> bool:
	return (value is int or value is float) and is_finite(float(value))
func save_to(path: String) -> Error:
	if not safe_to_save(): last_error = "Procura águas seguras ou um porto para guardar."; return ERR_BUSY
	var data := snapshot()
	var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file==null: last_error = "Não foi possível guardar a viagem."; return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data,"\t")); file.flush(); file.close()
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(path+".bak"): DirAccess.remove_absolute(path+".bak")
		var backup := DirAccess.rename_absolute(path,path+".bak")
		if backup!=OK: last_error = "Não foi possível preservar a viagem anterior."; return backup
	var error := DirAccess.rename_absolute(path+".tmp",path)
	if error!=OK and FileAccess.file_exists(path+".bak"): DirAccess.rename_absolute(path+".bak",path)
	if error==OK: safe_state = data; last_error = ""
	return error
func load_from(path: String) -> Error:
	if not FileAccess.file_exists(path): return ERR_FILE_NOT_FOUND
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary or not restore(data): return ERR_INVALID_DATA
	safe_state = snapshot(); return OK
