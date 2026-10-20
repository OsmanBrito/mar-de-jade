extends RefCounted
## Stable companion identity and the same limits used by Portugal's combat.
const LIMITS := {"duarte":{"hp":120,"qi":12,"posture":100}}
static func limits(person: String,p = null) -> Dictionary:
	if not LIMITS.has(person): return {}
	if p==null: return LIMITS[person].duplicate()
	var values := preload("res://scripts/chapter/character_development.gd").base_stats(p,person)
	return {"hp":values.hp,"qi":values.qi,"posture":values.posture}
static func valid(value: Variant,development: Dictionary = {}) -> bool:
	if not value is Dictionary or value.size()>LIMITS.size(): return false
	for id in value:
		if not LIMITS.has(id) or not value[id] is Dictionary or value[id].size()!=3: return false
		var maximum := limits(id,{"development":development})
		for key in LIMITS[id]:
			var amount: Variant = value[id].get(key)
			if not (amount is int or amount is float) or not is_finite(float(amount)): return false
			if amount<0 or amount>maximum[key] or float(amount)!=int(amount): return false
	return true

static func normalized(value: Dictionary) -> Dictionary:
	var result := {}
	for id in value:
		result[id] = {}
		for key in LIMITS[id]: result[id][key] = int(value[id][key])
	return result
