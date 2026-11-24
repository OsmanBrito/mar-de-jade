extends RefCounted
## The parked voyage remains authoritative during shore leave.
const Launch = preload("res://scripts/navigation/voyage_launch.gd")
const Kit = preload("res://scripts/navigation/boarding_loadout.gd")
static func is_visit(data: Dictionary) -> bool:
	return data.get("completed",false) and data.get("journey",{}).get("kind","")=="port_visit"
static func enter(model,path: String) -> Error:
	if model.phase!="port" or model.port!="lisboa" or model.campaign_state.is_empty() or not model.campaign_state.get("completed",false): return ERR_UNAVAILABLE
	var p = Engine.get_main_loop().root.get_node("ChapterProgress")
	var before: Dictionary = p.snapshot()
	if p.restore(model.campaign_state)!=OK: return ERR_INVALID_DATA
	p.checkpoint = 16; p.entry_scene = "res://scenes/chapter_01/chapter_flow.tscn"
	p.journey = {"kind":"port_visit","target":16,"event":-1,"stage":"","area":"cais","position":[1496,1105]}
	var old: Dictionary = model.snapshot()
	model.campaign_state = p.snapshot(); model.boarding_profile = Kit.capture(model.campaign_state)
	var error: Error = model.save_to(path)
	if error!=OK:
		model.restore(old); p.restore(before); return error
	Launch.travel_path = path
	return OK
static func sync(data: Dictionary,path: String = "") -> Error:
	var location := Launch.travel_path if path.is_empty() else path
	var parked = load("res://scripts/navigation/voyage_model.gd").new()
	var error: Error = parked.load_from(location)
	if error!=OK: return error
	if parked.phase!="port" or parked.port!="lisboa" or parked.campaign_state.get("run_id","")!=data.get("run_id",""): return ERR_INVALID_DATA
	if not is_visit(data) and not is_visit(parked.campaign_state): return ERR_INVALID_DATA
	var validator = load("res://scripts/chapter/chapter_progress.gd").new()
	var valid: bool = validator.restore(data,false)==OK; validator.free()
	if not valid: return ERR_INVALID_DATA
	parked.campaign_state = data.duplicate(true); parked.boarding_profile = Kit.capture(data); parked.style = data.style
	return parked.save_to(location)
static func embark(p) -> Error:
	var journey: Dictionary = p.journey.duplicate(true)
	p.journey = {}
	var error := sync(p.snapshot())
	if error!=OK: p.journey = journey
	return error

static func reload_current(p) -> Error:
	var parked = load("res://scripts/navigation/voyage_model.gd").new()
	var error: Error = parked.load_from(Launch.travel_path)
	if error!=OK: return error
	if not is_visit(parked.campaign_state) or parked.campaign_state.get("run_id","")!=p.run_id: return ERR_INVALID_DATA
	return p.restore(parked.campaign_state)
