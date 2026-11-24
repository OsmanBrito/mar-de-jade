extends RefCounted
## Original local content, separate from the campaign's canonical Oxx numbering.
const ID := "C01-LIS-01"
const PART := "PT-T03"
const STAGES := ["inspect","parts","fit","return","completed"]
static var catalog: Dictionary = {}

static func data() -> Dictionary:
	if catalog.is_empty(): catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_01/local_requests.json"))
	return catalog

static func definition() -> Dictionary:
	return data().requests[ID]

static func stage(p) -> String:
	return p.local_requests.get(ID,"")

static func objective(p) -> String:
	return definition().objectives.get(stage(p),"Fala com os moradores do cais para descobrir pedidos.")

static func transition(p, expected: String, next: String) -> bool:
	if stage(p) != expected or not STAGES.has(next): return false
	p.local_requests[ID] = next
	return true

static func take_part(p) -> bool:
	if not transition(p,"parts","fit"): return false
	p.inventory[PART] = 1
	return true

static func repair(p) -> bool:
	if stage(p) != "fit" or int(p.inventory.get(PART,0)) != 1: return false
	p.inventory.erase(PART)
	p.local_requests[ID] = "return"
	return true

static func claim(p) -> bool:
	if not transition(p,"return","completed"): return false
	var row := definition()
	p.coins = mini(1000000,p.coins+int(row.reward_gold))
	p.inventory[row.reward_item] = mini(999,int(p.inventory.get(row.reward_item,0))+1)
	return true

static func valid(states, inventory: Dictionary) -> bool:
	if not states is Dictionary or states.size()>1+preload("res://scripts/chapter/lisbon_errands.gd").DEFINITIONS.size(): return false
	for id in states:
		if id==ID:
			if not states[id] is String or not STAGES.has(states[id]): return false
		elif not preload("res://scripts/chapter/lisbon_errands.gd").DEFINITIONS.has(id): return false
	if not preload("res://scripts/chapter/lisbon_errands.gd").valid(states): return false
	var count = inventory.get(PART,0)
	if not (count is int or count is float): return false
	return count == (1 if states.get(ID,"") == "fit" else 0)
