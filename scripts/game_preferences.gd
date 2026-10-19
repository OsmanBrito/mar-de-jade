extends Node
## Preferences belong to the player, independently of chapter/ship checkpoints.
signal changed
var path := "user://preferencias.cfg"
var persist_enabled := true
var levels := {"music":0.6,"ambience":0.85,"effects":0.85}
var music_muted := false
var options := {"wide_timing":false,"difficulty":"normal","reduced_fx":false,"fast_combat":false}
var text_scale := 1.0
var controller := false
var effects_bus := "JadeEffects"
var ambience_bus := "JadeAmbience"
const DEFAULT_BINDINGS := {"move_left":KEY_A,"move_right":KEY_D,"move_up":KEY_W,"move_down":KEY_S,"interact":KEY_E,"combat_move":KEY_G,"combat_end":KEY_T,"combat_timing":KEY_SPACE,"combat_exit":KEY_R,"journal":KEY_J,"quick_save":KEY_F5}
var bindings: Dictionary = DEFAULT_BINDINGS.duplicate()
var binding_notice := ""
func navigation_reserved(action: String,key: int) -> bool:
	return not action.begins_with("combat_") and key in [KEY_M,KEY_C,KEY_B,KEY_V,KEY_R,KEY_SPACE]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()
	for bus in [effects_bus,ambience_bus]:
		if AudioServer.get_bus_index(bus)<0:
			AudioServer.add_bus(); AudioServer.set_bus_name(AudioServer.bus_count-1,bus)
	apply_audio()

func _input(event: InputEvent) -> void:
	var previous := controller
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value)>0.3): controller = true
	elif event is InputEventKey or event is InputEventMouseButton: controller = false
	if previous!=controller: changed.emit()

func set_level(key: String,value: float) -> void:
	if not levels.has(key) or not is_finite(value): return
	levels[key] = clampf(value,0,1); commit()
func set_option(key: String,value: bool) -> void:
	if key not in ["wide_timing","reduced_fx","fast_combat"]: return
	options[key] = value; commit()
func set_text_scale(value: float) -> void:
	if not is_finite(value): return
	text_scale = clampf(value,1.0,1.2); commit()
func set_music_muted(value: bool) -> void:
	music_muted = value; commit()
func commit() -> void:
	apply_audio(); changed.emit()
	if persist_enabled: save_settings()
func apply_audio() -> void:
	for key in ["effects","ambience"]:
		var index := AudioServer.get_bus_index(effects_bus if key=="effects" else ambience_bus)
		if index<0: continue
		AudioServer.set_bus_mute(index,levels[key]<=0)
		AudioServer.set_bus_volume_db(index,linear_to_db(maxf(0.001,levels[key])))
func font_size(base: int) -> int: return roundi(base*text_scale)
func bind_key(action: String,key: int) -> String:
	if not bindings.has(action): return "Comando desconhecido."
	if navigation_reserved(action,key): return "Essa tecla está reservada à navegação: carta, convés, regresso, rumo, reparo ou parada."
	if key<32 or (key>KEY_Z and key!=KEY_F5) or key in [KEY_F,KEY_Q,KEY_Z,KEY_1,KEY_2,KEY_3,KEY_4,KEY_9] or (key==KEY_E and action!="interact"): return "Essa tecla está reservada à interface."
	for other in bindings:
		if other!=action and bindings[other]==key: return "Essa tecla já pertence a outro comando."
	bindings[action] = key; apply_bindings(); commit(); return "Comando atualizado."
func apply_bindings() -> void:
	for action in ["move_left","move_right","move_up","move_down","interact","journal","quick_save"]:
		if not InputMap.has_action(action): continue
		for event in InputMap.action_get_events(action):
			if event is InputEventKey and event.physical_keycode not in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN]: InputMap.action_erase_event(action,event)
		var event := InputEventKey.new(); event.physical_keycode = bindings[action]; InputMap.action_add_event(action,event)
	# E used to be a second dialogue confirm. It must not bypass a remapped task.
	for event in InputMap.action_get_events("ui_accept"):
		if event is InputEventKey and event.physical_keycode==KEY_E: InputMap.action_erase_event("ui_accept",event)
func combat_key(key: int) -> int:
	for action in ["combat_move","combat_end","combat_timing","combat_exit"]:
		if bindings[action]==key: return DEFAULT_BINDINGS[action]
	for action in ["combat_move","combat_end","combat_timing","combat_exit"]:
		if key==DEFAULT_BINDINGS[action] and bindings[action]!=key: return 0
	return key
func hint_text(raw: String) -> String:
	var result := raw
	for pair in [["J ·","__JADE_JOURNAL__ ·"],["J / Y","__JADE_JOURNAL__"],["F5 / menu","Menu → Guardar" if controller else OS.get_keycode_string(bindings.quick_save)],["Enter / espaço / A","A" if controller else "Enter / espaço"],["Enter / A","A" if controller else "Enter"],["E / A","A" if controller else OS.get_keycode_string(bindings.interact)],["Esc / Start","Start" if controller else "Esc"],["R / Select","Select" if controller else OS.get_keycode_string(bindings.combat_exit)],["ESPAÇO / A","A" if controller else OS.get_keycode_string(bindings.combat_timing)],["WASD / setas / clique","Analógico / direcional" if controller else "Setas / clique"],["Esc / B","B" if controller else "Esc"]]:
		result = result.replace(pair[0],pair[1])
	result = result.replace("WASD / setas","Analógico / direcional" if controller else "%s%s%s%s / setas"%[OS.get_keycode_string(bindings.move_up),OS.get_keycode_string(bindings.move_left),OS.get_keycode_string(bindings.move_down),OS.get_keycode_string(bindings.move_right)])
	if controller: result = result.replace("     Clique · aproximar e interagir","")
	if controller:
		for pair in [["ESPAÇO","A"],["Espaço","A"],["Enter","A"],["Esc","Start"],["G ·","LB ·"],["T ·","RB ·"],["Q / E","LB / RB"],["F ·","L3 ·"],["Z ·","R3 ·"]]: result = result.replace(pair[0],pair[1])
	else:
		for pair in [["G ·",OS.get_keycode_string(bindings.combat_move)+" ·"],["T ·",OS.get_keycode_string(bindings.combat_end)+" ·"],["ESPAÇO",OS.get_keycode_string(bindings.combat_timing)]]: result = result.replace(pair[0],pair[1])
	return result.replace("__JADE_JOURNAL__","Y" if controller else OS.get_keycode_string(bindings.journal))
func navigation_hint(raw: String, naval: bool = false) -> String:
	var result := raw
	if controller:
		for pair in [["W ↑ vela · S ↓ vela · A/D leme","Analógico ↑/↓ · vela · ←/→ · leme"],["WASD / analógico ou clique","Analógico / direcional"],["Espaço parar","RB parar"],["Parar · Espaço","Parar · RB"],["M carta","Y carta"],["Carta · M","Carta · Y"],["C convés","X convés"],["Convés · C","Convés · X"],["V retomar rumo","LB retomar rumo"],["Retomar rumo · V","Retomar rumo · LB"],["Águas seguras · V","Águas seguras · LB"],["Bombordo · Q","Bombordo · LB"],["Boreste · E","Boreste · RB"],["Ordens · Espaço","Ordens · Y"],["Reparo · R","Reparo · X"],["Retirada · F","Retirada · B"],["Alvo · 1 / 2 / 3","Alvo · Y"]]:
			result = result.replace(pair[0],pair[1])
	else:
		var up := OS.get_keycode_string(bindings.move_up)
		var down := OS.get_keycode_string(bindings.move_down)
		var left := OS.get_keycode_string(bindings.move_left)
		var right := OS.get_keycode_string(bindings.move_right)
		result = result.replace("W ↑ vela · S ↓ vela · A/D leme","%s ↑ vela · %s ↓ vela · %s/%s leme"%[up,down,left,right])
		result = result.replace("WASD / analógico ou clique","%s%s%s%s / setas ou clique"%[up,left,down,right])
	# Naval stopping/ordens is handled by Y; generic combat A does not apply.
	if controller and naval: result = result.replace("Espaço","Y")
	return hint_text(result)

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(path)!=OK:
		if path!="user://preferencias.cfg": return
		var chapter := ConfigFile.new(); var voyage := ConfigFile.new()
		var has_chapter := chapter.load("user://capitulo-audio.cfg")==OK
		var has_voyage := voyage.load("user://navegacao-audio.cfg")==OK
		for key in levels:
			var legacy: Variant = chapter.get_value("music","level",levels.music) if key=="music" and has_chapter else voyage.get_value("audio",key,levels[key]) if has_voyage else levels[key]
			if (legacy is int or legacy is float) and is_finite(float(legacy)): levels[key] = clampf(legacy,0,1)
		var mute: Variant = chapter.get_value("music","muted",false) if has_chapter else false
		if mute is bool: music_muted = mute
		return
	for key in levels:
		var value: Variant = config.get_value("audio",key,levels[key])
		if (value is int or value is float) and is_finite(float(value)): levels[key] = clampf(value,0,1)
	for key in ["wide_timing","reduced_fx","fast_combat"]:
		var value: Variant = config.get_value("combat",key,false)
		if value is bool: options[key] = value
	var scale_value: Variant = config.get_value("ui","text_scale",1.0)
	if (scale_value is float or scale_value is int) and is_finite(float(scale_value)): text_scale = clampf(scale_value,1.0,1.2)
	var muted: Variant = config.get_value("audio","muted",false)
	if muted is bool: music_muted = muted
	var candidate := bindings.duplicate()
	var used: Array = []
	for action in bindings:
		var key: Variant = config.get_value("keys",action,DEFAULT_BINDINGS[action])
		if not config.has_section_key("keys",action) and used.has(key):
			for fallback in [KEY_H,KEY_N,KEY_L,KEY_B,KEY_M,KEY_U,KEY_O]:
				if not used.has(fallback): key = fallback; break
		if not key is int or key<32 or (key>KEY_Z and key!=KEY_F5) or used.has(key): return
		candidate[action] = key; used.append(key)
	bindings = candidate
	binding_notice = ""
	for action in bindings:
		if not navigation_reserved(action,int(bindings[action])): continue
		for replacement in [DEFAULT_BINDINGS[action]]+range(KEY_A,KEY_Z+1):
			if not bindings.values().has(replacement) and not navigation_reserved(action,replacement) and replacement not in [KEY_F,KEY_Q,KEY_Z] and (replacement!=KEY_E or action=="interact"):
				bindings[action] = replacement
				binding_notice = "Teclas antigas que conflitavam com a navegação foram ajustadas. Confere os comandos abaixo."
				break
func save_settings() -> Error:
	var config := ConfigFile.new()
	for key in levels: config.set_value("audio",key,levels[key])
	for key in options: config.set_value("combat",key,options[key])
	config.set_value("audio","muted",music_muted); config.set_value("ui","text_scale",text_scale)
	for action in bindings: config.set_value("keys",action,bindings[action])
	return config.save(path)
