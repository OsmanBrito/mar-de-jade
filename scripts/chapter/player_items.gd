extends RefCounted
## Single personal economy for Jade, including explicitly adapted source content.
const CATALOGS := ["res://data/chapter_01/items.json", "res://data/integration/ferro-items.json"]
const SLOTS := {"weapon":"Arma", "outfit":"Traje", "feet":"Calçado", "accessory":"Acessório"}
const STYLES := {"ES":"Espada", "LA":"Lança", "MC":"Machado", "FO":"Arma de fogo", "PU":"Desarmado"}
const Development = preload("res://scripts/chapter/character_development.gd")
const BASE := {"hp":100,"qi":20,"posture":100,"defense":0,"speed":18}
const POWER := {"ES":22,"LA":20,"MC":28,"FO":20,"PU":18}
const STAT_NAMES := {"hp":"Vida", "qi":"Alento", "posture":"Postura", "defense":"Proteção", "speed":"Iniciativa", "attack":"Potência"}
static var catalog: Dictionary = {}

static func items() -> Dictionary:
	if catalog.is_empty():
		for path in CATALOGS:
			for row in JSON.parse_string(FileAccess.get_file_as_string(path)).items:
				assert(not catalog.has(row.id), "Duplicate campaign item: "+str(row.id))
				catalog[row.id] = row
	return catalog

static func migrate_stock(saved: Dictionary) -> Dictionary:
	var result := saved.duplicate(true)
	for id in items():
		if id.begins_with("FERRO:") and not result.has(id):
			result[id] = int(items()[id].get("stock",0))
	return result

static func stock() -> Dictionary:
	var result := {}
	for id in items():
		if items()[id].get("stock",0) > 0: result[id] = int(items()[id].stock)
	return result

static func stats(p, loadout: Dictionary = {}) -> Dictionary:
	var result := Development.base_stats(p)
	result.attack = 0
	var gear: Dictionary = p.equipment if loadout.is_empty() else loadout
	for id in gear.values():
		var row: Dictionary = items().get(id,{})
		if row.is_empty() or int(p.inventory.get(id,0)) < 1: continue
		for key in row.stats: result[key] = int(result.get(key,0))+int(row.stats[key])
	result.power = floori(Development.power(p,p.style))+int(result.attack)
	return result

static func comparison(p, id: String) -> Dictionary:
	var row: Dictionary = items()[id]
	if row.slot == null: return {}
	var proposed: Dictionary = p.equipment.duplicate()
	proposed[row.slot] = id
	var before := stats(p)
	var after := stats(p,proposed)
	# Changing a weapon also changes the base power of the chosen style.
	after.power = floori(Development.power(p,row.get("style",p.style))) + after.attack
	var delta := {}
	for key in ["power","hp","qi","posture","defense","speed"]:
		delta[key] = int(after[key])-int(before[key])
	return delta

static func equip_reason(p, id: String) -> String:
	var row: Dictionary = items().get(id,{})
	if row.is_empty() or int(p.inventory.get(id,0)) < 1: return "Não tens este objeto."
	if row.slot == null: return "Este objeto não é equipamento."
	if not p.flags.get("recovered",false) or p.flags.get("injured",false): return "Poderás preparar equipamento depois de recuperar com Tomé."
	var style: String = row.get("style","")
	if not style.is_empty() and not p.tested_styles.has(style): return "Experimenta este manejo com Tomé primeiro."
	return ""

static func equip(p, id: String) -> String:
	var reason := equip_reason(p,id)
	if not reason.is_empty(): return reason
	var row: Dictionary = items()[id]
	p.equipment[row.slot] = id
	if row.has("style"): p.style = row.style
	clamp_vitals(p)
	return persist(p,"Equipado: "+row.name+".")

static func unequip(p, slot: String) -> String:
	if not p.flags.get("recovered",false) or p.flags.get("injured",false): return "Espera pela recuperação."
	if not p.equipment.has(slot): return "Esta vaga já está livre."
	if slot == "weapon" and not p.tested_styles.has("PU"): return "Experimenta o manejo desarmado com Tomé antes de largar a arma."
	p.equipment.erase(slot)
	if slot == "weapon": p.style = "PU"
	clamp_vitals(p)
	return persist(p,"Equipamento retirado.")

static func clamp_vitals(p) -> void:
	var limits := stats(p)
	for key in ["hp","qi","posture"]: p.vitals[key] = clampi(int(p.vitals[key]),0,int(limits[key]))

static func recovery_preview(p,id: String,person: String = "hero") -> Dictionary:
	var row: Dictionary = items().get(id,{})
	if not row.has("recovery"): return {}
	var limits: Dictionary = stats(p) if person=="hero" else preload("res://scripts/chapter/party_resources.gd").limits(person,p)
	if limits.is_empty(): return {}
	var vitals: Dictionary = p.vitals if person=="hero" else p.companion_vitals.get(person,limits)
	var result := {}
	for key in row.recovery:
		var dose: int = int(row.recovery[key])
		var amount: int = mini(dose,maxi(0,int(limits[key])-int(vitals[key])))
		result[key] = {"amount":amount,"capacity":dose,"waste":dose-amount}
	return result

static func recovery_text(p,id: String,person: String = "hero") -> String:
	var rows: Array[String] = []
	var preview := recovery_preview(p,id,person)
	for key in preview:
		var row: Dictionary = preview[key]
		rows.append("%s +%d · excedente %d"%[STAT_NAMES.get(key,key),row.amount,row.waste])
	return ("Duarte" if person=="duarte" else "Protagonista")+": "+" / ".join(rows)

static func use_reason(p, id: String, person: String = "hero") -> String:
	var row: Dictionary = items().get(id,{})
	if row.is_empty() or int(p.inventory.get(id,0)) < 1: return "Não tens este objeto."
	if not row.has("recovery"): return "Este objeto não é consumível."
	if p.flags.get("injured",false) or not p.flags.get("recovered",false): return "O tratamento de Tomé precisa de terminar primeiro."
	var limits: Dictionary = stats(p) if person=="hero" else preload("res://scripts/chapter/party_resources.gd").limits(person,p)
	if limits.is_empty(): return "Companheiro desconhecido."
	var vitals: Dictionary = p.vitals if person=="hero" else p.companion_vitals.get(person,limits).duplicate()
	if int(vitals.hp)<=0: return "Este personagem está incapacitado; consumíveis comuns não o levantam."
	for key in row.recovery:
		if int(vitals[key]) < int(limits[key]): return ""
	return "Já estás recuperado; o suprimento não será gasto."

static func use(p, id: String, person: String = "hero") -> String:
	var reason := use_reason(p,id,person)
	if not reason.is_empty(): return reason
	var row: Dictionary = items()[id]
	var limits: Dictionary = stats(p) if person=="hero" else preload("res://scripts/chapter/party_resources.gd").limits(person,p)
	if limits.is_empty(): return "Companheiro desconhecido."
	var vitals: Dictionary = p.vitals if person=="hero" else p.companion_vitals.get(person,limits).duplicate()
	for key in row.recovery: vitals[key] = mini(int(limits[key]),int(vitals[key])+int(row.recovery[key]))
	if person!="hero": p.companion_vitals[person] = vitals
	p.inventory[id] -= 1
	return persist(p,"Usado: "+row.name+".")

static func buy_reason(p, id: String) -> String:
	var row: Dictionary = items().get(id,{})
	if row.is_empty() or not row.tradeable or row.price == null: return "Este objeto não está à venda."
	if int(p.shop_stock.get(id,0)) < 1: return "Esgotado."
	if p.coins < int(row.price): return "Ouro insuficiente."
	if int(p.inventory.get(id,0)) >= 999: return "A quantidade máxima é 999."
	return ""

static func buy(p, id: String) -> String:
	var reason := buy_reason(p,id)
	if not reason.is_empty(): return reason
	var row: Dictionary = items()[id]
	p.coins -= int(row.price); p.shop_stock[id] -= 1
	p.inventory[id] = int(p.inventory.get(id,0))+1
	return persist(p,"Comprado: "+row.name+".")

static func sell_reason(p, id: String) -> String:
	var row: Dictionary = items().get(id,{})
	if row.is_empty() or int(p.inventory.get(id,0)) < 1: return "Não tens este objeto."
	if not row.tradeable or row.price == null: return "Objeto protegido; fica contigo."
	if p.equipment.values().has(id) and int(p.inventory[id]) <= 1: return "Retira o equipamento antes de vender."
	if int(p.shop_stock.get(id,0)) >= 999: return "A loja não aceita mais unidades deste objeto."
	if p.coins+maxi(1,int(row.price)/2) > 1000000: return "A bolsa atingiu o limite de ouro."
	return ""

static func sell(p, id: String) -> String:
	var reason := sell_reason(p,id)
	if not reason.is_empty(): return reason
	var row: Dictionary = items()[id]
	p.inventory[id] -= 1; p.coins += maxi(1,int(row.price)/2)
	p.shop_stock[id] = int(p.shop_stock.get(id,0))+1
	return persist(p,"Vendido: "+row.name+".")

static func pay_service(p) -> void:
	if p.payments.has("cais_service"): return
	p.payments.append("cais_service"); p.coins += 40

static func persist(p, message: String) -> String:
	if p.auto_save and p.save_to() != OK: return message+" Não foi possível guardar; tenta Guardar novamente."
	return message

static func describe_stats(values: Dictionary) -> String:
	var lines: Array[String] = []
	for key in values: lines.append("%s %+d" % [STAT_NAMES.get(key,key),int(values[key])])
	return " · ".join(lines)

static func legacy_equipment(inventory: Dictionary, style: String) -> Dictionary:
	for id in items():
		if items()[id].get("style","") == style and int(inventory.get(id,0)) > 0: return {"weapon":id}
	return {}

static func valid_state(data: Dictionary) -> bool:
	for key in ["coins","equipment","shop_stock","payments","vitals"]:
		if not data.has(key): return false
	if not whole(data.coins,1000000) or not data.equipment is Dictionary or not data.shop_stock is Dictionary or not data.payments is Array or not data.vitals is Dictionary: return false
	if data.payments.size() > 1 or (data.payments.size() == 1 and data.payments[0] != "cais_service"): return false
	for slot in data.equipment:
		var id = data.equipment[slot]
		if not slot in SLOTS or not id is String or not items().has(id): return false
		if items()[id].slot != slot or int(data.inventory.get(id,0)) < 1: return false
		if items()[id].has("style") and items()[id].style != data.style: return false
	for id in data.shop_stock:
		if not items().has(id) or not items()[id].tradeable or not whole(data.shop_stock[id],999): return false
	if data.vitals.size() != 3: return false
	var limits := Development.base_stats(data)
	for id in data.equipment.values():
		for key in items()[id].stats:
			if limits.has(key): limits[key] += int(items()[id].stats[key])
	for key in ["hp","qi","posture"]:
		if not data.vitals.has(key) or not whole(data.vitals[key],int(limits[key])): return false
	return true

static func whole(value, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) >= 0 and float(value) <= maximum and float(value) == int(value)
