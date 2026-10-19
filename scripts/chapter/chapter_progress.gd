extends Node
## Chapter checkpoints contain IDs and values, never scene nodes or combat instances.
const SAVE_PATH := "user://capitulo-01.json"
const SCHEMA_VERSION := 11
const CAMPAIGN_ID := "mar_de_jade"
const Items = preload("res://scripts/chapter/player_items.gd")
const LocalRequests = preload("res://scripts/chapter/local_request_state.gd")
var run_id := Crypto.new().generate_random_bytes(16).hex_encode()
var local_requests: Dictionary = {}
var dialogue_history: Array[Dictionary] = []
var journey: Dictionary = {}
var childhood_hunt: Dictionary = {}
var coins := 0
var equipment: Dictionary = {}
var shop_stock: Dictionary = {}
var payments: Array[String] = []
var companion_vitals: Dictionary = {}
var vitals: Dictionary = {"hp":100,"qi":8,"posture":100}
var checkpoint := 0
var entry_scene := "res://scenes/chapter_01/opening.tscn"
var flags: Dictionary = {}
var choices: Dictionary = {}
var style := "ES"
var tested_styles: Array[String] = []
var skills: Array[String] = []
var passives: Array[String] = []
var equipped_passives: Array[String] = []
var duarte_equipped_passives: Array[String] = []
var inventory: Dictionary = {"PT-Q01":1}
var completed := false
var resume_requested := false
var auto_save := true
var last_error := ""

func reset() -> void:
	run_id = Crypto.new().generate_random_bytes(16).hex_encode()
	dialogue_history.clear()
	companion_vitals.clear()
	local_requests.clear()
	journey.clear(); childhood_hunt.clear()
	checkpoint = 0; entry_scene = "res://scenes/chapter_01/opening.tscn"; flags.clear(); choices.clear(); style = "ES"
	tested_styles.clear(); skills.clear(); passives.clear(); equipped_passives.clear(); duarte_equipped_passives.clear()
	inventory = {"PT-Q01":1}; completed = false; resume_requested = false
	coins = 0; equipment = {}; shop_stock = Items.stock(); payments.clear()
	vitals = {"hp":100,"qi":8,"posture":100}

func _ready() -> void:
	shop_stock = Items.stock()

func snapshot() -> Dictionary:
	return {"schema_version":SCHEMA_VERSION,"dialogue_history":dialogue_history.duplicate(true),"campaign_id":CAMPAIGN_ID,"run_id":run_id,"hero_name":CampaignProfile.hero_name,"checkpoint":checkpoint,"entry_scene":entry_scene,"flags":string_keys(flags),"choices":string_keys(choices),"style":style,"tested_styles":tested_styles.duplicate(),"skills":skills.duplicate(),"passives":passives.duplicate(),"equipped_passives":equipped_passives.duplicate(),"duarte_equipped_passives":duarte_equipped_passives.duplicate(),"inventory":inventory.duplicate(true),"completed":completed,"coins":coins,"equipment":equipment.duplicate(),"shop_stock":shop_stock.duplicate(),"payments":payments.duplicate(),"vitals":vitals.duplicate(),"companion_vitals":companion_vitals.duplicate(true),"local_requests":local_requests.duplicate(),"journey":journey.duplicate(true),"childhood_hunt":childhood_hunt.duplicate(true)}

func save_to(path: String = SAVE_PATH) -> Error:
	if path==SAVE_PATH and preload("res://scripts/navigation/shore_bridge.gd").is_visit(snapshot()):
		var travel_error: Error = preload("res://scripts/navigation/shore_bridge.gd").sync(snapshot())
		if travel_error!=OK:
			last_error = "Não foi possível guardar a visita junto da viagem. O ponto seguro anterior foi preservado."
			return travel_error
	var file = FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file == null:
		last_error = "Não foi possível guardar o capítulo."
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(snapshot(),"\t")); file.flush(); file.close()
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(path+".bak"): DirAccess.remove_absolute(path+".bak")
		var backup_error := DirAccess.rename_absolute(path,path+".bak")
		if backup_error != OK:
			last_error = "Não foi possível guardar o capítulo."; return backup_error
	var error := DirAccess.rename_absolute(path+".tmp",path)
	if error != OK and FileAccess.file_exists(path+".bak"): DirAccess.rename_absolute(path+".bak",path)
	last_error = "" if error == OK else "Não foi possível guardar o capítulo."
	return error

func load_from(path: String = SAVE_PATH) -> Error:
	if path==SAVE_PATH and preload("res://scripts/navigation/shore_bridge.gd").is_visit(snapshot()):
		return preload("res://scripts/navigation/shore_bridge.gd").reload_current(self)
	if not FileAccess.file_exists(path): return ERR_FILE_NOT_FOUND
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary: return ERR_INVALID_DATA
	return restore(data)

func restore(source_data: Dictionary, apply: bool = true) -> Error:
	var data := source_data.duplicate(true)
	# JSON stores numbers as floats; Array.has uses strict Variant types.
	if data.get("schema_version") != 1 and data.get("schema_version") != 2 and data.get("schema_version") != 3 and data.get("schema_version") != 4 and data.get("schema_version") != 5 and data.get("schema_version") != 6 and data.get("schema_version") != 7 and data.get("schema_version") != 8 and data.get("schema_version") != 9 and data.get("schema_version") != 10 and data.get("schema_version") != SCHEMA_VERSION: return ERR_INVALID_DATA
	if data.schema_version >= 4 and data.get("campaign_id") != CAMPAIGN_ID: return ERR_INVALID_DATA
	if not data.get("hero_name") is String or not CampaignProfile.name_error(data.hero_name).is_empty(): return ERR_INVALID_DATA
	if not data.get("checkpoint") is float and not data.get("checkpoint") is int: return ERR_INVALID_DATA
	if int(data.checkpoint) < 0 or int(data.checkpoint) >= 17 or float(data.checkpoint) != int(data.checkpoint): return ERR_INVALID_DATA
	if data.get("entry_scene") not in ["res://scenes/chapter_01/opening.tscn","res://scenes/chapter_01/plaza.tscn","res://scenes/chapter_01/training.tscn","res://scenes/chapter_01/promise.tscn","res://scenes/chapter_01/forest_hunt.tscn","res://scenes/chapter_01/adult_opening.tscn","res://scenes/chapter_01/chapter_flow.tscn"]: return ERR_INVALID_DATA
	if data.get("style") not in ["ES","LA","MC","FO","PU"]: return ERR_INVALID_DATA
	for key in ["flags","choices","inventory"]:
		if not data.get(key) is Dictionary: return ERR_INVALID_DATA
	if data.flags.size() > 100 or data.choices.size() > 10: return ERR_INVALID_DATA
	for key in ["tested_styles","skills","passives","equipped_passives","duarte_equipped_passives"]:
		if not data.get(key) is Array: return ERR_INVALID_DATA
		for id in data[key]:
			if not id is String: return ERR_INVALID_DATA
	if not data.get("completed") is bool or data.equipped_passives.size() > 4 or data.duarte_equipped_passives.size() > 4: return ERR_INVALID_DATA
	var skill_ids: Array = []
	for row in JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_01/skill_icons.json")).skills: skill_ids.append(row.id)
	var passive_ids: Array = []
	for row in JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_01/passives.json")).passives: passive_ids.append(row.id)
	var item_ids: Array = Items.items().keys()
	for id in data.skills:
		if not skill_ids.has(id): return ERR_INVALID_DATA
	for id in data.passives:
		if not passive_ids.has(id): return ERR_INVALID_DATA
	for id in data.inventory:
		if not item_ids.has(id): return ERR_INVALID_DATA
	for id in data.tested_styles:
		if id not in ["ES","LA","MC","FO","PU"]: return ERR_INVALID_DATA
	for count in data.inventory.values():
		if not Items.whole(count,999): return ERR_INVALID_DATA
	for value in data.flags.values():
		if not value is bool: return ERR_INVALID_DATA
	for value in data.choices.values():
		if not value is String: return ERR_INVALID_DATA
	for id in data.equipped_passives:
		if not data.passives.has(id) or id.begins_with("DU"): return ERR_INVALID_DATA
	for id in data.duarte_equipped_passives:
		if not data.passives.has(id) or id != "DU-P09": return ERR_INVALID_DATA
	# Validate the complete new economy before mutating any live state.
	if data.schema_version >= 2 and not Items.valid_state(data): return ERR_INVALID_DATA
	if data.schema_version >= 3 and not data.has("local_requests"): return ERR_INVALID_DATA
	if not LocalRequests.valid(data.get("local_requests",{}),data.inventory): return ERR_INVALID_DATA
	if data.schema_version==6:
		data.journey = preload("res://scripts/city/convent_plan.gd").migrate_v6_journey(data.get("journey",{}))
	if data.schema_version<9 and data.get("journey",{}) is Dictionary and data.get("journey",{}).get("kind","") in ["fetch","fetch_return"]:
		var old_journey: Dictionary = data.journey.duplicate(true)
		if old_journey.get("target",-1)==1 and old_journey.get("event",-1)==13:
			var rescue_events: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_01/chapter_flow.json")).scenes[1].events
			for i in rescue_events.size():
				if rescue_events[i].get("id","")=="fetch_tome": old_journey.event = i; break
			data.journey = old_journey
	if not preload("res://scripts/chapter/lisbon_journey_state.gd").valid(data.get("journey",{}),int(data.checkpoint),data.flags): return ERR_INVALID_DATA
	if data.get("journey",{}).get("kind","")=="port_visit" and (not data.completed or data.entry_scene!="res://scenes/chapter_01/chapter_flow.tscn"): return ERR_INVALID_DATA
	if data.get("journey",{}).get("kind","")=="childhood" and (data.schema_version<5 or data.entry_scene!="res://scenes/chapter_01/plaza.tscn"): return ERR_INVALID_DATA
	if data.get("journey",{}).get("area","")=="convent" and data.schema_version<6: return ERR_INVALID_DATA
	var hunt: Variant = data.get("childhood_hunt",{})
	if not preload("res://scripts/chapter/forest_hunt_state.gd").valid(hunt): return ERR_INVALID_DATA
	if data.entry_scene=="res://scenes/chapter_01/forest_hunt.tscn" and (data.schema_version<8 or hunt.is_empty()): return ERR_INVALID_DATA
	if not hunt.is_empty():
		if data.schema_version<8: return ERR_INVALID_DATA
		if int(hunt.stage)<9 and (data.entry_scene!="res://scenes/chapter_01/forest_hunt.tscn" or int(data.checkpoint)!=0 or not data.get("journey",{}).is_empty()): return ERR_INVALID_DATA
	var identity: Variant = data.get("run_id",("legacy:"+data.hero_name).sha256_text())
	if not identity is String or identity.length() not in [32,64] or not identity.is_valid_hex_number(false): return ERR_INVALID_DATA
	if data.schema_version>=10 and not data.has("run_id"): return ERR_INVALID_DATA
	if not preload("res://scripts/chapter/party_resources.gd").valid(data.get("companion_vitals",{})): return ERR_INVALID_DATA
	var transcript: Variant = data.get("dialogue_history",[])
	if data.schema_version>=11 and not data.has("dialogue_history"): return ERR_INVALID_DATA
	if not preload("res://scripts/chapter/dialogue_log.gd").valid(transcript): return ERR_INVALID_DATA
	if not apply: return OK
	dialogue_history.assign(transcript)
	companion_vitals = preload("res://scripts/chapter/party_resources.gd").normalized(data.get("companion_vitals",{}))
	run_id = identity
	childhood_hunt = hunt.duplicate(true)
	CampaignProfile.hero_name = data.hero_name
	checkpoint = int(data.checkpoint); entry_scene = data.entry_scene; flags = data.flags; choices = data.choices; style = data.style
	tested_styles.assign(data.tested_styles); skills.assign(data.skills); passives.assign(data.passives)
	equipped_passives.assign(data.equipped_passives); duarte_equipped_passives.assign(data.duarte_equipped_passives); inventory = {}
	for key in data.inventory: inventory[str(key)] = int(data.inventory[key])
	coins = int(data.get("coins",0)); equipment = data.get("equipment",Items.legacy_equipment(inventory,style))
	shop_stock = {}
	var saved_stock: Dictionary = data.get("shop_stock",Items.stock())
	if data.schema_version < 4: saved_stock = Items.migrate_stock(saved_stock)
	for id in saved_stock: shop_stock[id] = int(saved_stock[id])
	payments.assign(data.get("payments",[]))
	vitals = data.get("vitals",{"hp":100,"qi":8,"posture":100})
	if data.schema_version == 1 and flags.get("clear_passage",false): Items.pay_service(self)
	if data.schema_version == 1 and not equipment.is_empty(): flags.initial_weapon_received = true
	Items.clamp_vitals(self)
	completed = data.completed
	local_requests = data.get("local_requests",{}).duplicate()
	journey = data.get("journey",{}).duplicate(true)
	if not journey.is_empty():
		journey.target = int(journey.target); journey.event = int(journey.event)
		journey.position = [roundi(float(journey.position[0])),roundi(float(journey.position[1]))]
	CampaignProfile.origin_response = str(choices.get("origin_response",""))
	resume_requested = true
	return OK

func learn(id: String, kind: String = "skill") -> void:
	if kind not in ["skill","passive"] or not preload("res://scripts/chapter/arc_content.gd").executable(id,kind): return
	var list = skills if kind == "skill" else passives
	if not list.has(id): list.append(id)

func string_keys(values: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key in values: result[str(key)] = values[key]
	return result



func enter_scene(path: String) -> void:
	entry_scene = path; resume_requested = false
	if auto_save: save_to()



