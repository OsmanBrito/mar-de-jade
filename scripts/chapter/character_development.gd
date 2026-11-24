extends RefCounted
## Adult progression. No dependency on scene nodes, equipment or the combat reference.
const Content = preload("res://scripts/chapter/arc_content.gd")
const ATTRIBUTES := {"FOR":"Força","AGI":"Agilidade","VIG":"Vigor","ESP":"Espírito","PER":"Percepção"}
const STYLES := ["ES","LA","MC","FO","PU"]
const INFLUENCES := {"ES":["FOR","PER"],"LA":["FOR","AGI"],"MC":["FOR","VIG"],"FO":["PER","AGI"],"PU":["AGI","FOR"]}
const SKILL_PROFILES := {"ES07":[0.80,"PER","AGI"],"LA07":[0.90,"PER","FOR"],"FO07":[0.85,"PER","AGI"],"FO01":[1.05,"PER","AGI"],"FO09":[0.85,"AGI","PER"],"PU07":[0.85,"AGI","PER"],"LA09":[0.85,"AGI","FOR"],"MC09":[0.95,"FOR","AGI"],"FO10":[0.90,"PER","AGI"]}
const RANKS := ["Fundamento","Circulação","Integração","Manifestação","Plenitude"]
const STORY := {"C01-M01/S08":40,"C01-M02/S03":60,"C01-M03/S01":80,"C01-M03/S07":80,"C01-M04/S02":60,"C01-M04/S04":80}
const STORY_INDEX := {0:"C01-M01/S08",3:"C01-M02/S03",6:"C01-M03/S01",12:"C01-M03/S07",14:"C01-M04/S02",16:"C01-M04/S04"}
static func integer(v,low: int,high: int) -> bool:
	return (v is int or v is float) and is_finite(float(v)) and float(v)==int(v) and v>=low and v<=high
static func xp_to_next(level: int) -> int:
	return 100+25*(level-1)+5*(level-1)*(level-1) if level<60 else 0
static func threshold(level: int) -> int:
	var total := 0
	for l in range(1,clampi(level,1,60)): total += xp_to_next(l)
	return total
static func level_of(xp: int) -> int:
	var result := 1
	while result<60 and xp>=threshold(result+1): result += 1
	return result
static func new_member(level := 1) -> Dictionary:
	var attributes := {}; var proficiency := {}
	for key in ATTRIBUTES: attributes[key] = 5
	for key in STYLES: proficiency[key] = 0
	return {"xp":threshold(level),"attributes":attributes,"proficiency":proficiency,"practice":{},"active_skills":[],"cultivation":{"rank":0,"step":1}}
static func initial(skills: Array = [],duarte := false) -> Dictionary:
	var data := {"version":1,"members":{"hero":new_member()},"claimed":[]}
	if duarte: data.members.duarte = new_member(3)
	for id in skills: prepare_learned(data,id)
	return data
static func state(p) -> Dictionary:
	return p.get("development",{}) if p is Dictionary else p.development
static func ensure(p) -> Dictionary:
	var data := state(p)
	if data.is_empty():
		data = initial(p.skills,p.skills.has("DU01")); p.development = data
	return data
static func member(p,person := "hero") -> Dictionary:
	return state(p).get("members",{}).get(person,{})
static func recruit(p,person := "duarte") -> void:
	var data := ensure(p)
	if person=="duarte" and not data.members.has(person): data.members[person] = new_member(3)
static func prepare_learned(data: Dictionary,id: String) -> void:
	if id=="DP01" or not Content.executable(id): return
	var owner := Content.owner(id)
	if owner=="duarte" and not data.members.has(owner): data.members[owner] = new_member(3)
	if not data.members.has(owner): return
	var slots: Array = data.members[owner].active_skills
	if not slots.has(id) and slots.size()<6: slots.append(id)
static func learned(p,id: String) -> void:
	prepare_learned(ensure(p),id)
static func available_points(record: Dictionary) -> int:
	var used := 0
	for key in ATTRIBUTES: used += int(record.attributes[key])-5
	return 3*(level_of(int(record.xp))-1)-used
static func base_stats(p,person := "hero",draft: Dictionary = {}) -> Dictionary:
	var record := member(p,person)
	if record.is_empty(): return {"hp":100 if person=="hero" else 120,"qi":20 if person=="hero" else 12,"posture":100,"defense":0,"speed":18 if person=="hero" else 24}
	var a: Dictionary = record.attributes if draft.is_empty() else draft
	var level := level_of(int(record.xp))
	return {"hp":100+10*(level-1)+14*(int(a.VIG)-5),"qi":20+int((level-1)/3)+2*(int(a.ESP)-5),"posture":100+2*(int(a.VIG)-5),"defense":int((int(a.VIG)-5)/5),"speed":(18 if person=="hero" else 24)+int((int(a.AGI)-5)/2)}
static func power(p,style: String,person := "hero",draft: Dictionary = {},pair: Array = []) -> float:
	var record := member(p,person)
	if record.is_empty(): return {"ES":22.0,"LA":20.0,"MC":28.0,"FO":20.0,"PU":18.0}[style]
	var a: Dictionary = record.attributes if draft.is_empty() else draft
	var keys: Array = INFLUENCES[style] if pair.is_empty() else pair
	return 18.0+0.9*int(a[keys[0]])+0.35*int(a[keys[1]])+2*(level_of(int(record.xp))-1)
static func grade(p,id: String,person := "hero") -> int:
	var uses := int(member(p,person).get("practice",{}).get(id,0))
	return 3 if uses>=20 else 2 if uses>=8 else 1
static func equipped(p,id: String,person := "hero") -> bool:
	var record := member(p,person)
	return p.skills.has(id) if record.is_empty() else record.active_skills.has(id)
static func toggle_skill(p,id: String) -> String:
	if id=="DP01": return "A Defesa Perfeita é uma reação; não ocupa vaga ativa."
	if not p.skills.has(id) or not Content.executable(id): return "Esta técnica ainda não foi aprendida."
	var person := Content.owner(id)
	var data := ensure(p)
	if not data.members.has(person): return "Este personagem ainda não foi recrutado."
	var slots: Array = data.members[person].active_skills
	if slots.has(id): slots.erase(id); return "Técnica retirada do repertório."
	if slots.size()>=6: return "As seis vagas estão ocupadas. Retira uma técnica primeiro."
	slots.append(id); return "Técnica preparada."
static func allocation_error(record: Dictionary,attributes: Dictionary) -> String:
	if attributes.size()!=5: return "Distribuição inválida."
	var used := 0
	for key in ATTRIBUTES:
		if not integer(attributes.get(key),5,60): return "Cada atributo deve ficar entre 5 e 60."
		used += int(attributes[key])-5
	if used>3*(level_of(int(record.xp))-1): return "Não há pontos suficientes."
	return ""
static func allocate(p,person: String,attributes: Dictionary) -> String:
	var record := member(p,person)
	if record.is_empty(): return "Este personagem ainda não foi recrutado."
	var reason := allocation_error(record,attributes)
	if not reason.is_empty(): return reason
	record.attributes = attributes.duplicate(true)
	return "Atributos confirmados. Redistribuição gratuita; recursos não foram recuperados."
static func add_xp(data: Dictionary,amount: int) -> Array[String]:
	var levels: Array[String] = []
	for person in data.members:
		var record: Dictionary = data.members[person]
		var before := level_of(int(record.xp))
		record.xp = mini(threshold(60),int(record.xp)+amount)
		if level_of(int(record.xp))>before: levels.append(person)
	return levels
static func award(p,id: String,amount: int,normal := true) -> Dictionary:
	var data := ensure(p)
	if amount<=0 or data.claimed.has(id): return {"xp":0,"levels":[]}
	data.claimed.append(id)
	var levels := add_xp(data,amount)
	if normal:
		for person in levels:
			var derived := base_stats(p,person)
			var current: Dictionary = p.vitals if person=="hero" else p.companion_vitals.get(person,{"hp":derived.hp,"qi":derived.qi,"posture":derived.posture}).duplicate()
			if int(current.hp)<=0 or (person=="hero" and p.flags.get("injured",false)): continue
			var limits := base_stats(p,person)
			if person=="hero":
				# Equipment is added by the integration layer after this base recovery.
				current.hp = limits.hp; current.qi = limits.qi
			else:
				current.hp = limits.hp; current.qi = limits.qi; p.companion_vitals[person] = current
	return {"xp":amount,"levels":levels}
static func training(p,style: String) -> void:
	var data := ensure(p); var id := "lesson:"+style
	if data.claimed.has(id): return
	data.claimed.append(id)
	data.members.hero.proficiency[style] = mini(1000,int(data.members.hero.proficiency[style])+40)
	data.members.hero.cultivation.step = 2
static func practice(p,person: String,style: String,uses: Dictionary) -> void:
	var record := member(p,person)
	if record.is_empty(): return
	var total := 0
	for id in uses:
		var count := mini(6,int(uses[id]))
		total += count
		if id!="basic" and p.skills.has(id) and Content.owner(id)==person:
			record.practice[id] = mini(20,int(record.practice.get(id,0))+count)
	record.proficiency[style] = mini(1000,int(record.proficiency[style])+mini(24,total*4))
static func migrate(data: Dictionary) -> Dictionary:
	if data.has("development"): return data.development.duplicate(true)
	var result := initial(data.get("skills",[]),data.get("skills",[]).has("DU01") or data.get("completed",false))
	for index in STORY_INDEX:
		if data.get("completed",false) or int(data.get("checkpoint",0))>index:
			var id: String = STORY_INDEX[index]; result.claimed.append("story:"+id); result.members.hero.xp = int(result.members.hero.xp)+int(STORY[id])
	if data.get("skills",[]).any(func(id): return id in ["ES07","LA07","MC08","FO07","PU07"]): result.members.hero.cultivation.step = 2
	for style in data.get("tested_styles",[]):
		result.members.hero.proficiency[style] = 40; result.claimed.append("lesson:"+style)
	return result
static func valid(value,skills: Array) -> bool:
	if not value is Dictionary or value.size()!=3 or value.get("version")!=1: return false
	if not value.get("members") is Dictionary or not value.members.has("hero") or value.members.size()>2: return false
	if not value.get("claimed") is Array or value.claimed.size()>512: return false
	var seen := {}
	for id in value.claimed:
		if not id is String or id.length()>128 or id.is_empty() or seen.has(id): return false
		seen[id] = true
	for person in value.members:
		if person not in ["hero","duarte"]: return false
		var r = value.members[person]
		if not r is Dictionary or r.size()!=6 or not integer(r.get("xp"),0,threshold(60)): return false
		if not r.get("attributes") is Dictionary or not allocation_error(r,r.attributes).is_empty(): return false
		if not r.get("proficiency") is Dictionary or r.proficiency.size()!=5: return false
		for style in STYLES:
			if not integer(r.proficiency.get(style),0,1000): return false
		if not r.get("cultivation") is Dictionary or r.cultivation.size()!=2: return false
		if not integer(r.cultivation.get("rank"),0,4) or not integer(r.cultivation.get("step"),1,3): return false
		if not r.get("practice") is Dictionary or r.practice.size()>skills.size(): return false
		for id in r.practice:
			if not skills.has(id) or Content.owner(id)!=person or not integer(r.practice[id],0,20): return false
		if not r.get("active_skills") is Array or r.active_skills.size()>6: return false
		seen = {}
		for id in r.active_skills:
			if not id is String or id=="DP01" or seen.has(id) or not skills.has(id) or Content.owner(id)!=person or not Content.executable(id): return false
			seen[id] = true
	return true

static func normalized(value: Dictionary) -> Dictionary:
	# Call only after validation: JSON floats must not silently round malformed input.
	var result := value.duplicate(true)
	result.version = 1
	for person in result.members:
		var r: Dictionary = result.members[person]
		r.xp = int(r.xp)
		for field in ["attributes","proficiency","practice","cultivation"]:
			for key in r[field]: r[field][key] = int(r[field][key])
	return result
