extends RefCounted
## Reused Mar de Ferro recordings. Selection depends on the actual weapon and hit result.
const ROOT := "res://assets/audio/combat/"
var cache: Dictionary = {}
func stream(event: String) -> AudioStreamWAV:
	if not cache.has(event):
		var path := ROOT+event+".wav"
		cache[event] = load(path) if ResourceLoader.exists(path) else AudioStreamWAV.load_from_file(path)
	return cache[event]
func action_event(style: String,child: bool,support: bool = false) -> String:
	if support: return "gesture_cover_windup"
	if child: return "swing"
	return {"ES":"swing","LA":"gesture_thrust_windup","MC":"heavy_swing","FO":"gesture_thrust_windup","PU":"fast_swing"}.get(style,"swing")
func release_event(style: String,skill: int = 0) -> String:
	if style!="FO" or skill==8: return ""
	return {0:"firearm-basic",1:"firearm-measured",2:"firearm-prepared",3:"firearm-passage"}.get(skill,"firearm-basic")
func impact_events(style: String,child: bool,result: Dictionary,grades: Dictionary) -> Array[String]:
	var events: Array[String] = []
	var hit := false
	var block := false
	var perfect := false
	var broken := false
	for item in result.get("hits",[]):
		if item.get("damage",0)>0: hit = true
		elif item.get("damage",0)==0 and item.get("side","")!="Contra-ataque":
			block = true; perfect = perfect or int(grades.get(item.id,0))==2
		broken = broken or item.get("breaks",false)
	if hit: events.append("heavy_hit" if child or style in ["MC","PU","FO"] else ("gesture_thrust_impact" if style=="LA" else "metal_hit"))
	if block or (not grades.is_empty() and grades.values().has(1)): events.append("parry" if perfect else "guard")
	if result.get("skill",-1)==4: events.append("gesture_cover_impact")
	if broken: events.append("posture_break")
	return events
