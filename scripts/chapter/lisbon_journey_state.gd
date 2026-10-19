extends RefCounted
## Optional additive field: old chapter saves have no journey in progress.
static func valid(value: Variant,checkpoint: int = -1,flags: Dictionary = {}) -> bool:
	if not value is Dictionary: return false
	if value.is_empty(): return true
	if value.size()!=6: return false
	if value.get("kind") not in ["block","rest","fetch","fetch_return","delivery","stage","childhood","port_visit"]: return false
	if value.get("area") not in ["cais","square","room","deck","convent"]: return false
	if value.get("stage") not in ["","delivery_return","return_courtyard"]: return false
	for key in ["target","event"]:
		var n: Variant = value.get(key)
		if not (n is int or n is float) or not is_finite(float(n)) or float(n)!=int(n): return false
	if value.target<0 or value.target>16 or value.event< -1 or value.event>100: return false
	if not value.get("position") is Array or value.position.size()!=2: return false
	for number in value.position:
		if not (number is int or number is float) or not is_finite(float(number)) or absf(float(number))>4000: return false
	var p := Vector2(value.position[0],value.position[1])
	if value.area=="convent" and not preload("res://scripts/city/convent_plan.gd").contains(p): return false
	if value.kind=="port_visit":
		return value.target==16 and checkpoint in [-1,16] and value.event==-1 and value.stage=="" and value.area in ["cais","square","room","convent"] and (checkpoint==-1 or (flags.get("embarked",false) and flags.get("recovered",false))) and (value.area not in ["cais","square"] or preload("res://scripts/city/lisbon_layout.gd").contains(p))
	if value.kind=="childhood":
		if value.target!=0 or value.event!=-1 or value.stage!="" or checkpoint not in [-1,0]: return false
		if value.area=="convent": return true
		return value.area=="square" and preload("res://scripts/city/lisbon_layout.gd").contains(p,true)
	if value.kind=="block" and value.event!=-1: return false
	if value.kind=="rest" and value.target!=6: return false
	if value.kind in ["fetch","fetch_return"] and value.target!=1: return false
	if value.kind=="delivery" and value.target!=0: return false
	if value.kind=="stage" and value.stage.is_empty(): return false
	if value.kind!="stage" and not value.stage.is_empty(): return false
	if value.area=="deck" and not (value.kind=="block" and value.target==16): return false
	if checkpoint>=0:
		if value.kind in ["block","rest"]:
			if int(value.target)!=checkpoint+1 or int(value.target) not in [1,4,6,7,15,16]: return false
		elif value.target!=checkpoint: return false
		if value.kind in ["fetch","fetch_return"]:
			var story: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_01/chapter_flow.json"))
			var events: Array = story.scenes[1].events
			if value.event<0 or value.event>=events.size() or events[int(value.event)].get("id","")!="fetch_tome": return false
		if value.kind=="delivery" and (value.event!=0 or not flags.get("delivery_pending",false)): return false
		if value.kind=="stage":
			if value.stage=="delivery_return" and (value.target!=0 or value.event!=2 or not flags.get("delivery_finished",false)): return false
			if value.stage=="return_courtyard" and (value.target!=13 or value.event!=3 or not flags.get("recovered",false)): return false
	return true
