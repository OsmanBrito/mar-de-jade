extends RefCounted
## A separate, labelled end-of-Portugal preset; never alters ChapterProgress.
const Items = preload("res://scripts/chapter/player_items.gd")
const FIRST := {"ES":"ES07","LA":"LA07","MC":"MC08","FO":"FO07","PU":"PU07"}
static func readiness(data: Dictionary) -> String:
	if data.is_empty():return "Preparação pessoal indisponível nesta viagem."
	var limits:=Items.stats(data)
	var hero: Dictionary=data.vitals
	var companion_limits: Dictionary = preload("res://scripts/chapter/party_resources.gd").limits("duarte",data)
	var duarte: Dictionary=data.get("companion_vitals",{}).get("duarte",companion_limits)
	var text: String="%s · Vida %d/%d · Alento %d/%d · Postura %d/%d.\nDuarte · Vida %d/%d · Alento %d/%d · Postura %d/%d.\nSacola pessoal: %d ligadura(s) · %d água(s)."%[Items.STYLES[data.style],hero.hp,limits.hp,hero.qi,limits.qi,hero.posture,limits.posture,duarte.hp,companion_limits.hp,duarte.qi,companion_limits.qi,duarte.posture,companion_limits.posture,int(data.inventory.get("PT-C01",0)),int(data.inventory.get("PT-C03",0))]
	if hero.hp<limits.hp*.5 or duarte.hp<60:text+="\nO grupo está ferido; os recursos restantes seguem para a abordagem."
	if hero.qi<(7 if data.style=="MC" else 4):text+="\nPouco alento: o básico continua disponível e recupera 1."
	if hero.posture<limits.posture*.4:text+="\nPostura baixa: os próximos impactos podem interromper-te."
	return text

static func practice(style: String = "ES") -> Dictionary:
	var data := {"companion_vitals":{},"style":style,"flags":{"recovered":true,"perfect_defense":true},"skills":[FIRST[style],"DU01","DP01"],"inventory":{"PT-V02":1},"equipment":{"outfit":"PT-V02"},"vitals":{"hp":108,"qi":20,"posture":106},"equipped_passives":["GE21","GE22",style+"-P11"],"duarte_equipped_passives":["DU-P09"]}
	if style=="FO": preload("res://scripts/combat/firearm_skills.gd").upgrade_lesson(data.skills)
	for id in Items.items():
		if Items.items()[id].get("style","")==style:
			data.inventory[id] = 1; data.equipment.weapon = id; break
	data.vitals = Items.stats(data)
	data.vitals = {"hp":data.vitals.hp,"qi":data.vitals.qi,"posture":data.vitals.posture}
	return data
static func capture(data: Dictionary) -> Dictionary:
	if not data.get("flags") is Dictionary: return {}
	var result := {"flags":{"recovered":data.flags.get("recovered",false),"perfect_defense":data.flags.get("perfect_defense",false)}}
	for key in ["style","skills","inventory","equipment","vitals","equipped_passives","duarte_equipped_passives"]:
		if not data.has(key): return {}
		result[key] = data[key]
	if not preload("res://scripts/chapter/party_resources.gd").valid(data.get("companion_vitals",{}),data.get("development",{})): return {}
	if data.has("development"): result.development = data.development.duplicate(true)
	result.companion_vitals = preload("res://scripts/chapter/party_resources.gd").normalized(data.get("companion_vitals",{}))
	return result.duplicate(true) if valid(result) else {}
static func valid(data: Dictionary) -> bool:
	if data.has("development") and not preload("res://scripts/chapter/character_development.gd").valid(data.development,data.get("skills",[])): return false
	if not preload("res://scripts/chapter/party_resources.gd").valid(data.get("companion_vitals",{}),data.get("development",{})): return false
	if not data.get("style") is String or not FIRST.has(data.style): return false
	for key in ["flags","inventory","equipment","vitals"]:
		if not data.get(key) is Dictionary: return false
	if data.flags.size()!=2 or not data.flags.get("recovered") is bool or not data.flags.get("perfect_defense") is bool: return false
	if data.inventory.size()>256: return false
	for id in data.inventory:
		if not id is String or not Items.items().has(id) or not Items.whole(data.inventory[id],999): return false
	var skill_ids: Array = ["DP01"]
	for row in JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_01/skill_icons.json")).skills: skill_ids.append(row.id)
	var passive_ids: Array = []
	for row in JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_01/passives.json")).passives: passive_ids.append(row.id)
	for key in ["skills","equipped_passives","duarte_equipped_passives"]:
		if not data.get(key) is Array or data[key].size()>(64 if key=="skills" else 4): return false
		var seen := []
		for id in data[key]:
			if not id is String or seen.has(id): return false
			if key=="skills" and not skill_ids.has(id): return false
			if key!="skills" and (not passive_ids.has(id) or id.begins_with("DU")!=(key=="duarte_equipped_passives")): return false
			seen.append(id)
	var state := data.duplicate(true); state.coins = 0; state.shop_stock = {}; state.payments = []
	return Items.valid_state(state)
