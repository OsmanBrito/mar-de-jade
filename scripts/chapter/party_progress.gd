extends RefCounted
## Stable identity adapters over the existing save. No duplicate wallets or bags.
const Content = preload("res://scripts/chapter/arc_content.gd")
const Resources = preload("res://scripts/chapter/party_resources.gd")
static func member(p,id: String) -> Dictionary:
	if id not in ["hero","duarte"]: return {}
	var learned: Array = []; var practices: Array = []
	var hero_name: String = str(p.get("hero_name","Protagonista")) if p is Dictionary else str(p.snapshot().hero_name)
	for skill in p.skills:
		if Content.owner(skill)==id: learned.append(skill)
	for skill in p.passives:
		if Content.owner(skill,"passive")==id: practices.append(skill)
	return {"id":id,"name":hero_name if id=="hero" else "Duarte","skills":learned,"passives":practices,"equipped_passives":p.equipped_passives.duplicate() if id=="hero" else p.duarte_equipped_passives.duplicate(),"equipment":p.equipment.duplicate() if id=="hero" else {"story_kit":"duarte"},"vitals":p.vitals.duplicate() if id=="hero" else p.companion_vitals.get("duarte",Resources.limits("duarte",p)).duplicate(),"equipment_policy":Content.data().party[id].equipment}
static func recruit_duarte(p) -> void:
	preload("res://scripts/chapter/character_development.gd").recruit(p)
	p.learn("DU01"); p.learn("DU-P09","passive")
