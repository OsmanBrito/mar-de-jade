extends RefCounted
const Catalog=preload("res://scripts/combat/mar_de_ferro/rpg_catalog.gd")
var data: Dictionary={}
var last_reward: Dictionary={}

func _init() -> void:
	reset()

func reset() -> void:
	last_reward.clear()
	data={"progression_version":2,"legacy_level":0,"xp":0,"gold":100,"bag":{"heal":3,"qi":2,"sword":1,"halberd":1,"coat":2,"charm":2},"claimed":[],"quest":0,"heroes":[],"options":{"difficulty":"normal","wide_timing":false,"reduced_fx":false,"fast_combat":false}}
	for i in 2:
		var base_passives=["duarte_sweep_recovery"] if i==0 else ["stride"]
		data.heroes.append({"alloc":[0,0,0],"known":[1,2,3],"slots":[1,2,3,-1,-1],"passive":base_passives[0],"passives":base_passives,"gear":{"weapon":"halberd" if i==0 else "sword","outfit":"coat","accessory":"charm"},"uses":{},"condition":{}})

func level() -> int:
	var result:=1
	for threshold in Catalog.XP:
		if data.xp>=threshold: result=Catalog.XP.find(threshold)+1
	return result

func restore(value: Dictionary) -> void:
	data=value.duplicate(true)
	if int(data.get("progression_version",1))<2:
		data.legacy_level=legacy_level()
		# Keep every previously earned level technique, including unequipped ones.
		for h in data.heroes:
			h.known=h.known.map(func(id): return int(id))
			for id in Catalog.LEGACY_TECHNIQUE_LEVELS:
				if Catalog.LEGACY_TECHNIQUE_LEVELS[id]<=data.legacy_level and not h.known.has(id): h.known.append(id)
	data.progression_version=2
	data.legacy_level=int(data.get("legacy_level",0))
	if not data.options.has("fast_combat"): data.options.fast_combat=false
	if not data.options.has("difficulty"): data.options.difficulty="normal"
	for key in ["xp","gold","quest"]: data[key]=int(data[key])
	for key in data.bag: data.bag[key]=int(data.bag[key])
	# Selling keeps the zero-count bag entry, so older journeys receive these
	# rewards once without recreating equipment the player already sold.
	for reward_id in Catalog.EXPLORATION_ITEMS:
		var equipment: String=Catalog.EXPLORATION_ITEMS[reward_id]
		if data.claimed.has(reward_id) and not data.bag.has(equipment): data.bag[equipment]=1
	for h in data.heroes:
		h.ultimate=int(h.get("ultimate",-1))
		if not h.has("condition") or not (h.condition is Dictionary): h.condition={}
		if not h.has("passives"): h.passives=[h.passive]
		h.passive=h.passives[0] if not h.passives.is_empty() else "parry"
		# Supremas command the seventh key, so free any slot an older build gave them.
		h.slots=h.slots.map(func(id): return -1 if Catalog.is_ultimate(int(id)) else id)
		if h.slots.size()==4: h.slots.append(-1)
		for key in ["alloc","known","slots"]: h[key]=h[key].map(func(n): return int(n))
		for key in h.uses: h.uses[key]=int(h.uses[key])
	# Older saves gave both heroes a sword. Keep the spare copy and equip Duarte
	# with his own weapon before new family restrictions are enforced.
	if not Catalog.can_wield(0,data.heroes[0].gear.weapon):
		data.bag.halberd=maxi(1,int(data.bag.get("halberd",0)))
		data.heroes[0].gear.weapon="halberd"
	if not Catalog.can_wield(1,data.heroes[1].gear.weapon):
		data.bag.sword=maxi(1,int(data.bag.get("sword",0)))
		data.heroes[1].gear.weapon="sword"
	# Recover newly introduced unlocks in journeys saved before this content existed.
	var prepared: Array=[]
	for h in data.heroes: prepared.append(h.slots.duplicate())
	for reward_id in Catalog.TECHNIQUE_UNLOCKS:
		if data.claimed.has(reward_id): learn(Catalog.TECHNIQUE_UNLOCKS[reward_id])
	learn_level_techniques()
	for hero in data.heroes.size(): data.heroes[hero].slots=prepared[hero]

func points(hero: int) -> int:
	var a: Array=data.heroes[hero].alloc
	return (level()-1)*2-int(a[0])-int(a[1])-int(a[2])

func allocate(hero: int, stat: int) -> bool:
	if hero not in [0,1] or stat<0 or stat>2 or points(hero)<=0: return false
	data.heroes[hero].alloc[stat]+=1
	return true

func stats(hero: int, replacement := "", allocation: Array=[]) -> Dictionary:
	return stat_breakdown(hero,replacement,allocation).total

func stat_breakdown(hero: int, replacement := "", allocation: Array=[]) -> Dictionary:
	var h: Dictionary=data.heroes[hero]
	var a: Array=h.alloc if allocation.is_empty() else allocation
	var n:=level()-1
	var base: Dictionary={"hp":166 if hero==0 else 146,"qi":12 if hero==0 else 14,"attack":0,"defense":0,"posture":60 if hero==0 else 48,"speed":12 if hero==0 else 18,"movement":3,"break_power":0}
	var parts: Dictionary={"base":base,"level":{},"points":{},"gear":{},"passives":{},"limits":{},"total":{}}
	for source in ["level","points","gear","passives","limits","total"]:
		for key in base: parts[source][key]=0
	parts.level.hp=n*8; parts.level.attack=n*2
	for index in Catalog.ATTRIBUTES.size():
		var attribute: Dictionary=Catalog.ATTRIBUTES[index]
		for key in attribute.gains: parts.points[key]+=int(a[index])*int(attribute.gains[key])
		if attribute.has("defense_every"): parts.points.defense+=int(int(a[index])/int(attribute.defense_every))
		if attribute.has("break_every"): parts.points.break_power+=int(int(a[index])/int(attribute.break_every))
	for slot in h.gear:
		var compatible: bool=slot!="weapon" or Catalog.can_wield(hero,replacement)
		var id: String=replacement if not replacement.is_empty() and Catalog.ITEMS.has(replacement) and Catalog.ITEMS[replacement].slot==slot and compatible else h.gear[slot]
		for key in Catalog.ITEMS[id].stats: parts.gear[key]+=Catalog.ITEMS[id].stats[key]
	var active:Array=h.get("passives",[h.passive])
	if active.has("stride"): parts.passives.movement+=1
	if active.has("anchor"): parts.passives.posture+=8
	if active.has("focus"): parts.passives.qi+=2
	if active.has("sailor_eye"): parts.passives.speed+=3
	for key in base:
		for source in ["base","level","points","gear","passives"]: parts.total[key]+=parts[source][key]
	parts.limits.movement=clampi(int(parts.total.movement),2,5)-int(parts.total.movement)
	parts.total.movement+=parts.limits.movement
	return parts

func passive_catalog(hero: int) -> Array:
	var ids:Array=["parry","breath","anchor","focus","riposte","iron_breath"] if hero==0 else ["stride","breath","red_edge","focus","sailor_eye","precision"]
	ids.append("haft_hand" if hero==0 else "sword_eye")
	for id in Catalog.PASSIVES:
		if Catalog.PASSIVES[id].get("hero",-1)==hero and not ids.has(id): ids.append(id)
	for id in Catalog.PROC_PASSIVES:
		if int(Catalog.PROC_PASSIVES[id].get("hero",hero))==hero: ids.append(id)
	ids.sort_custom(func(a: String, b: String) -> bool:
		var level_a: int=passive_level(hero,a)
		var level_b: int=passive_level(hero,b)
		if level_a!=level_b: return level_a<level_b
		return Catalog.passive_def(a).name.naturalcasecmp_to(Catalog.passive_def(b).name)<0
	)
	return ids

func passive_level(hero: int, id: String) -> int:
	if hero not in [0,1]: return 99
	if Catalog.PROC_PASSIVES.has(id):
		var definition: Dictionary=Catalog.PROC_PASSIVES[id]
		return int(definition.level) if int(definition.get("hero",hero))==hero else 99
	if Catalog.WEAPON_PASSIVE_LEVELS.has(id):
		var weapon_def: Dictionary=Catalog.PASSIVES.get(id,{})
		if int(weapon_def.get("hero",-1))!=hero: return 99
		return Catalog.WEAPON_PASSIVE_LEVELS[id]
	var core_levels: Dictionary={"parry":1,"stride":1,"breath":2,"anchor":2,"red_edge":2,"haft_hand":2,"sword_eye":2,"focus":3,"riposte":4,"sailor_eye":4,"iron_breath":5,"precision":5}
	var hero_core: Array=["parry","breath","anchor","focus","riposte","iron_breath"] if hero==0 else ["stride","breath","red_edge","focus","sailor_eye","precision"]
	return int(core_levels.get(id,99)) if hero_core.has(id) else 99

func legacy_level() -> int:
	if int(data.get("progression_version",1))>=2: return int(data.get("legacy_level",0))
	var result:=1
	for i in Catalog.LEGACY_XP.size():
		if data.xp>=Catalog.LEGACY_XP[i]: result=i+1
	return result

func passive_unlocked(hero: int, id: String) -> bool:
	var required:=passive_level(hero,id)
	if required==99: return false
	return required<=level() or int(Catalog.LEGACY_PROC_LEVELS.get(id,required))<=legacy_level()

func passive_limit() -> int:
	return mini(3,level())

func toggle_passive(hero: int, id: String) -> bool:
	if hero not in [0,1] or not passive_catalog(hero).has(id): return false
	var h: Dictionary=data.heroes[hero]
	if h.passives.has(id): h.passives.erase(id)
	elif passive_unlocked(hero,id) and h.passives.size()<passive_limit(): h.passives.append(id)
	else: return false
	h.passive=h.passives[0] if not h.passives.is_empty() else "parry"
	return true

func learn_level_techniques() -> Array:
	var learned: Array=[]
	for id in Catalog.TECHNIQUE_LEVELS:
		if level()<Catalog.TECHNIQUE_LEVELS[id]: continue
		if data.heroes.any(func(h): return not h.known.has(id)): learned.append(id)
		learn(id)
	return learned

func learn(id: int) -> void:
	for h in data.heroes:
		if h.known.has(id): continue
		h.known.append(id)
		if Catalog.is_ultimate(id): continue
		var empty: int=h.slots.find(-1)
		if empty>=0: h.slots[empty]=id

func equip_ultimate(hero: int, id: int) -> bool:
	if hero not in [0,1] or not Catalog.is_ultimate(id) or not data.heroes[hero].known.has(id): return false
	data.heroes[hero].ultimate=id
	return true

func remove_passive(hero: int, id: String) -> bool:
	if hero not in [0,1] or not data.heroes[hero].passives.has(id): return false
	return toggle_passive(hero,id)

func replace_passive(hero: int, old: String, replacement: String) -> bool:
	if hero not in [0,1] or not passive_unlocked(hero,replacement): return false
	var h: Dictionary=data.heroes[hero]
	if not h.passives.has(old) or h.passives.has(replacement): return false
	h.passives[h.passives.find(old)]=replacement
	h.passive=h.passives[0]
	return true

func equip_skill(hero: int, slot: int, id: int) -> bool:
	if Catalog.is_ultimate(id) or hero not in [0,1] or slot<0 or slot>=5 or not data.heroes[hero].known.has(id): return false
	var slots: Array=data.heroes[hero].slots
	var old: int=slots.find(id)
	if old>=0: slots[old]=slots[slot]
	slots[slot]=id
	return true

func equipped_count(id: String) -> int:
	var count:=0
	for h in data.heroes:
		for equipped in h.gear.values():
			if equipped==id: count+=1
	return count

func free_count(id: String) -> int:
	return maxi(0,int(data.bag.get(id,0))-equipped_count(id))

func can_swap_gear(hero: int, id: String) -> bool:
	if hero not in [0,1] or not Catalog.ITEMS.has(id): return false
	var slot: String=Catalog.ITEMS[id].slot
	if slot=="weapon" and not Catalog.can_wield(hero,id): return false
	if slot=="item" or data.heroes[hero].gear[slot]==id: return false
	return data.heroes[1-hero].gear[slot]==id and free_count(id)==0

func swap_gear(hero: int, id: String) -> bool:
	if not can_swap_gear(hero,id): return false
	var slot: String=Catalog.ITEMS[id].slot
	var previous: String=data.heroes[hero].gear[slot]
	data.heroes[hero].gear[slot]=id
	data.heroes[1-hero].gear[slot]=previous
	return true

func equip(hero: int, id: String) -> bool:
	if hero not in [0,1] or not Catalog.ITEMS.has(id) or Catalog.ITEMS[id].slot=="item": return false
	if Catalog.ITEMS[id].slot=="weapon" and not Catalog.can_wield(hero,id): return false
	if data.heroes[hero].gear[Catalog.ITEMS[id].slot]==id or free_count(id)<=0: return false
	data.heroes[hero].gear[Catalog.ITEMS[id].slot]=id
	return true

func buy(id: String, quantity:=1, region: int = -1) -> bool:
	if quantity<1 or quantity>99 or not Catalog.sold_here(id,region) or data.gold<Catalog.ITEMS[id].price*quantity: return false
	data.gold-=Catalog.ITEMS[id].price*quantity
	data.bag[id]=int(data.bag.get(id,0))+quantity
	return true

func sell(id: String, quantity:=1) -> bool:
	if quantity<1 or quantity>99 or not Catalog.ITEMS.has(id) or free_count(id)<quantity: return false
	data.bag[id]-=quantity; data.gold+=int(Catalog.ITEMS[id].price/2)*quantity
	return true

func reward(id: String, recover_on_level: bool=true) -> String:
	last_reward={"xp":0,"gold":0,"from_level":level(),"to_level":level(),"learned":[],"passives":[],"items":[],"mastered":[],"full_recovery":false}
	if id=="cove_parley" and data.claimed.has("cove_trial") or id=="cove_trial" and data.claimed.has("cove_parley"): return "A escola da Enseada já foi escolhida."
	if data.claimed.has(id) or not Catalog.REWARDS.has(id): return "Sem recompensa repetida."
	var old_level:=level()
	var locked_passives: Array=[]
	for hero in 2:
		for passive in passive_catalog(hero):
			if not passive_unlocked(hero,passive): locked_passives.append({"hero":hero,"id":passive})
	var r: Dictionary=Catalog.REWARDS[id]
	data.claimed.append(id); data.xp+=r.xp; data.gold+=r.gold
	last_reward.learned=learn_level_techniques()
	for passive in locked_passives:
		if passive_unlocked(passive.hero,passive.id): last_reward.passives.append(passive)
	if Catalog.TECHNIQUE_UNLOCKS.has(id):
		var technique: int=Catalog.TECHNIQUE_UNLOCKS[id]
		if data.heroes.any(func(h): return not h.known.has(technique)): last_reward.learned.append(technique)
		learn(technique)
	if id=="refuge_legacy":
		for item in Catalog.LEGACY_ITEMS:
			data.bag[item]=int(data.bag.get(item,0))+1
			last_reward.items.append(item)
	if id=="quest": data.bag.medal=int(data.bag.get("medal",0))+1
	if id=="chest": data.bag.breaker=int(data.bag.get("breaker",0))+1; data.bag.rapier=int(data.bag.get("rapier",0))+1
	if id=="cove_cache":
		data.bag.heal=int(data.bag.get("heal",0))+1
		data.bag.qi=int(data.bag.get("qi",0))+1
	last_reward.xp=r.xp; last_reward.gold=r.gold; last_reward.from_level=old_level; last_reward.to_level=level()
	if id=="chest": last_reward.items=["breaker","rapier"]
	if id=="quest": last_reward.items=["medal"]
	if id=="cove_cache": last_reward.items=["heal","qi"]
	if Catalog.EXPLORATION_ITEMS.has(id):
		var equipment: String=Catalog.EXPLORATION_ITEMS[id]
		data.bag[equipment]=int(data.bag.get(equipment,0))+1
		last_reward.items.append(equipment)
	var message:="+%d EXP · +%d ouro"%[r.xp,r.gold]
	if Catalog.EXPLORATION_ITEMS.has(id): message+=" · "+Catalog.ITEMS[Catalog.EXPLORATION_ITEMS[id]].name
	if id=="cove_cache": message+=" · Infusão ×1 · Tónico ×1"
	if level()>old_level:
		message+=" · Nível %d! Distribui os novos pontos."%level()
		if recover_on_level and data.options.get("difficulty","normal")=="normal":
			recover_all(); last_reward.full_recovery=true
			message+=" A dupla recuperou por subir de nível."
	return message

func commit_battle(battle: RefCounted) -> String:
	var improved: Array=[]
	data.bag.heal=battle.potions; data.bag.qi=battle.tonics
	# Victories carry the party's remaining resources into the journey. Statuses are
	# battle-local, while wounds and spent alento make the next decision meaningful.
	for hero in 2:
		var unit: Dictionary=battle.units[hero]
		data.heroes[hero].condition={"hp":maxi(1,int(unit.hp)),"qi":maxi(0,int(unit.qi)),"posture":maxi(1,int(unit.posture))}
	# Mastery is awarded on first campaign victories, max. twice per technique per encounter.
	if not data.claimed.has(battle.encounter):
		for hero in 2:
			for id in battle.tech_uses[hero]:
				var key:=str(id)
				var before: int=data.heroes[hero].uses.get(key,0)
				if Catalog.extra_skill(hero,int(id)).get("ultimate",false): continue
				data.heroes[hero].uses[key]=mini(6,before+mini(2,battle.tech_uses[hero][id]))
				if int(before/3)<int(data.heroes[hero].uses[key]/3): improved.append({"hero":hero,"skill":int(id)})
	var first_victory: bool=not data.claimed.has(battle.encounter)
	var message:=reward(battle.encounter,not battle.encounter.begins_with("cove_trial"))
	if first_victory and battle.outcome()=="victory" and battle.optional_objective.get("completed",false):
		var bonus: Dictionary=battle.optional_objective
		data.gold+=int(bonus.gold); last_reward.gold+=int(bonus.gold)
		data.bag[bonus.item]=int(data.bag.get(bonus.item,0))+1
		last_reward.items.append(bonus.item)
		last_reward.optional=bonus.title
		message+=" · Objectivo opcional: +%d ouro"%int(bonus.gold)
	last_reward.mastered=improved
	return message

func rest_at_albergaria() -> bool:
	if data.gold<Catalog.ALBERGARIA_COST: return false
	data.gold-=Catalog.ALBERGARIA_COST
	recover_all()
	return true

func recover_all() -> void:
	for hero in 2:
		var s:=stats(hero)
		data.heroes[hero].condition={"hp":int(s.hp),"qi":int(s.qi),"posture":int(s.posture)}

func needs_rest() -> bool:
	for hero in 2:
		var s: Dictionary=stats(hero)
		var condition: Dictionary=data.heroes[hero].get("condition",{})
		for resource in ["hp","qi","posture"]:
			if int(condition.get(resource,s[resource]))<int(s[resource]): return true
	return false

func migrate(flags: Dictionary) -> void:
	reset()
	for id in ["training","patrol","secret","boss","manual","chest"]:
		if flags.get(id,false): reward(id)

static func integer(value: Variant, minimum: int, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value==int(value) and value>=minimum and value<=maximum

func valid(value: Variant) -> bool:
	if not value is Dictionary: return false
	for key in ["xp","gold","bag","claimed","quest","heroes","options"]:
		if not value.has(key): return false
	if not integer(value.get("progression_version",1),1,2) or not integer(value.get("legacy_level",0),0,12): return false
	if not integer(value.xp,0,10000) or not integer(value.gold,0,1000000) or not integer(value.quest,0,3): return false
	if not value.bag is Dictionary or not value.claimed is Array or not value.heroes is Array or value.heroes.size()!=2: return false
	if not value.options is Dictionary or not value.options.get("wide_timing") is bool or not value.options.get("reduced_fx") is bool: return false
	if value.options.has("fast_combat") and not value.options.fast_combat is bool: return false
	if value.options.get("difficulty","normal") not in ["normal","challenging"]: return false
	for key in value.bag:
		if not Catalog.ITEMS.has(key) or not integer(value.bag[key],0,9999): return false
	if not value.bag.has("heal") or not value.bag.has("qi"): return false
	for id in value.claimed:
		if not Catalog.REWARDS.has(id) or value.claimed.count(id)!=1: return false
	if value.claimed.has("cove_parley") and value.claimed.has("cove_trial"): return false
	var candidate= get_script().new()
	candidate.data=value
	var equipped: Dictionary={}
	for hero_index in 2:
		var h: Variant=value.heroes[hero_index]
		if not h is Dictionary: return false
		for key in ["alloc","known","slots","passive","gear","uses"]:
			if not h.has(key): return false
		if not h.alloc is Array or h.alloc.size()!=3 or not h.known is Array or not h.slots is Array or h.slots.size() not in [4,5]: return false
		var allocated:=0
		for n in h.alloc:
			if not integer(n,0,(Catalog.XP.size()-1)*2): return false
			allocated+=int(n)
		if allocated>(candidate.level()-1)*2: return false
		if not Catalog.passive_exists(h.passive) or not h.gear is Dictionary or not h.uses is Dictionary: return false
		if h.has("condition"):
			if not (h.condition is Dictionary): return false
			for resource in h.condition:
				if resource not in ["hp","qi","posture"] or not integer(h.condition[resource],0,9999): return false
		var active: Variant=h.get("passives",[h.passive])
		if not active is Array or active.size()>candidate.passive_limit(): return false
		for passive in active:
			if not Catalog.passive_exists(passive) or active.count(passive)!=1 or not candidate.passive_unlocked(hero_index,passive): return false
		for id in h.known:
			if not integer(id,1,Catalog.TECHNIQUES.max()) or not Catalog.TECHNIQUES.has(int(id)) or h.known.count(id)!=1: return false
		if h.has("ultimate"):
			if not integer(h.ultimate,-1,Catalog.TECHNIQUES.max()): return false
			# JSON stores numbers as floats; compare normalized, validated technique IDs.
			var known_ids: Array=h.known.map(func(id): return int(id))
			if int(h.ultimate)!=-1 and (not Catalog.is_ultimate(int(h.ultimate)) or not known_ids.has(int(h.ultimate))): return false
		for id in h.slots:
			# A supreme parked in a space is legacy shape, not corruption: loading frees
			# it. Rejecting it here would make older journeys unreadable.
			if not integer(id,-1,Catalog.TECHNIQUES.max()): return false
			if id!=-1 and (not h.known.has(id) or h.slots.count(id)!=1): return false
		for slot in ["weapon","outfit","accessory"]:
			if not h.gear.has(slot) or not Catalog.ITEMS.has(h.gear[slot]) or Catalog.ITEMS[h.gear[slot]].slot!=slot: return false
			equipped[h.gear[slot]]=int(equipped.get(h.gear[slot],0))+1
		for key in h.uses:
			if not key is String or not key.is_valid_int() or not Catalog.TECHNIQUES.has(int(key)) or not integer(h.uses[key],0,6): return false
	for key in equipped:
		if int(value.bag.get(key,0))<equipped[key]: return false
	return true

