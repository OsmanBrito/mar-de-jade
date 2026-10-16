extends RefCounted
## Batches simultaneous activations into readable pages without affecting combat.
const Catalog=preload("res://scripts/combat/mar_de_ferro/rpg_catalog.gd")
const HOLD:=3.8
const MAX_PENDING:=24
var pages: Array[Dictionary]=[]
var history: Array[Dictionary]=[]
var pulses: Dictionary={}

func clear() -> void:
	pages.clear(); history.clear(); pulses.clear()

func push(events: Array) -> void:
	var grouped: Dictionary={}
	for event in events:
		var key: String="%d:%s"%[event.actor,event.passive]
		if not grouped.has(key): grouped[key]={"actor":event.actor,"passive":event.passive,"effects":{},"targets":[]}
		var row: Dictionary=grouped[key]
		for effect in event.effects:
			# Base power is per hit; never advertise three targets as triple power.
			if effect in ["damage_base","posture_base","damage_percent","timing_percent","bleed_turns","resistance_percent","resistance_hits","momentum"]:
				row.effects[effect]=maxi(int(row.effects.get(effect,0)),int(event.effects[effect]))
			else: row.effects[effect]=int(row.effects.get(effect,0))+int(event.effects[effect])
		if event.target>=0 and not row.targets.has(event.target): row.targets.append(event.target)
		pulses[event.actor]={"life":1.25,"effects":row.effects}
	var rows: Array=grouped.values()
	for row in rows:
		history.append(row.duplicate(true))
		if history.size()>24: history.pop_front()
	for i in range(0,rows.size(),2): pages.append({"rows":rows.slice(i,i+2),"life":HOLD})
	while pages.size()>MAX_PENDING: pages.remove_at(1)

func update(delta: float, readable: bool) -> void:
	for actor in pulses.keys():
		pulses[actor].life-=delta
		if pulses[actor].life<=0: pulses.erase(actor)
	if not readable or pages.is_empty(): return
	pages[0].life-=delta
	if pages[0].life<=0: pages.pop_front()

static func summary(row: Dictionary, localization=null) -> String:
	var parts: Array[String]=[]
	var e: Dictionary=row.effects
	for entry in [["hp","+%d vida"],["qi","+%d alento"],["posture","+%d postura"],["movement","+%d movimento"],["damage_base","+%d dano base"],["posture_base","+%d pressão base"],["damage_percent","+%d%% dano"],["mitigated_posture","−%d pressão recebida"],["bleed_turns","+%d turnos de sangramento"],["timing_percent","+%d%% janela de ritmo"]]:
		if e.has(entry[0]): parts.append(entry[1]%e[entry[0]])
	if e.has("resistance_percent"): parts.append("Resistência %d%% · %d golpes"%[e.resistance_percent,e.get("resistance_hits",2)])
	if e.has("momentum"): parts.append("Próxima área: +%d dano base"%e.momentum)
	if e.has("guard"): parts.append("Guarda activada")
	if e.has("cleanse"): parts.append("Sangramento removido")
	if row.targets.size()>1: parts.append("%d alvos"%row.targets.size())
	if localization!=null:
		for i in parts.size(): parts[i]=localization.text(parts[i])
	return " · ".join(parts)

static func colour(effects: Dictionary) -> Color:
	if effects.has("hp") or effects.has("cleanse"): return Color("78c5af")
	if effects.has("qi") or effects.has("timing_percent"): return Color("74b5d0")
	return Color("e2b66c")

static func symbol(effects: Dictionary) -> String:
	if effects.has("hp") or effects.has("cleanse"): return "+"
	if effects.has("qi") or effects.has("timing_percent"): return "~"
	if effects.has("movement"): return ">"
	return "◆"

