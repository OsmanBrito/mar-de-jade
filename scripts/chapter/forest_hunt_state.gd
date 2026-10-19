extends RefCounted
const Plan = preload("res://scripts/city/forest_plan.gd")
const SCENE := "res://scenes/chapter_01/forest_hunt.tscn"
static func initial() -> Dictionary:
	return {"stage":0,"position":[Plan.SPAWN.x,Plan.SPAWN.y],"notes":[]}
static func valid(value: Variant) -> bool:
	if not value is Dictionary: return false
	if value.is_empty(): return true
	if value.size()!=3 or not value.has("stage") or not value.has("position") or not value.has("notes"): return false
	var stage: Variant = value.stage
	if not (stage is int or stage is float) or not is_finite(float(stage)) or float(stage)!=int(stage) or stage<0 or stage>9: return false
	if not value.position is Array or value.position.size()!=2: return false
	for coordinate in value.position:
		if not (coordinate is int or coordinate is float) or not is_finite(float(coordinate)): return false
	if not Plan.contains(Vector2(value.position[0],value.position[1])): return false
	if not value.notes is Array or value.notes.size()>Plan.DISCOVERIES.size(): return false
	var seen := {}
	for id in value.notes:
		if not id is String or not Plan.DISCOVERIES.has(id) or seen.has(id): return false
		seen[id] = true
	return true
